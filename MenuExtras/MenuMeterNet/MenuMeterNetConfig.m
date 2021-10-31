//
//  MenuMeterNetConfig.m
//
//  Reader object for network config info
//
//  Copyright (c) 2002-2014 Alex Harper
//
//  This file is part of MenuMeters.
//
//  MenuMeters is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License version 2 as
//  published by the Free Software Foundation.
//
//  MenuMeters is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with MenuMeters; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//

#import "MenuMeterNetConfig.h"

///////////////////////////////////////////////////////////////
//
//  Private methods and constants
//
///////////////////////////////////////////////////////////////

// Speed defines
#define kInterfaceDefaultSpeed -1
#define kModemInterfaceDefaultSpeed 56000

@interface MenuMeterNetConfig (PrivateMethods)

- (void)clearCaches;

- (NSDictionary *)sysconfigValueForKey:(NSString *)key;

- (NSNumber *)speedForInterfaceName:(NSString *)bsdInterface;
@end

///////////////////////////////////////////////////////////////
//
//  SystemConfiguration notification callbacks
//
///////////////////////////////////////////////////////////////

static void scChangeCallback(SCDynamicStoreRef store, CFArrayRef changedKeys, void *info) {

	if (info)
		[(__bridge MenuMeterNetConfig *)info clearCaches];

} // scChangeCallback

///////////////////////////////////////////////////////////////
//
//  init/dealloc
//
///////////////////////////////////////////////////////////////

@implementation MenuMeterNetConfig

- (id)init {

	self = [super init];
	if (!self) {
		return nil;
	}

	// Get the PPP data puller
	pppGatherer = [MenuMeterNetPPP sharedPPP];
	if (!pppGatherer) {
		NSLog(@"MenuMeterNetConfig unable to establish pppconfd session.");
		return nil;
	}

	// Connect to SystemConfiguration
	SCDynamicStoreContext scContext;
	scContext.version = 0;
	scContext.info = (__bridge void *_Nullable)(self);
	scContext.retain = NULL;
	scContext.release = NULL;
	scContext.copyDescription = NULL;
	scSession = SCDynamicStoreCreate(kCFAllocatorDefault,
									 (CFStringRef)[self description],
									 scChangeCallback,
									 &scContext);
	if (!scSession) {
		NSLog(@"MenuMeterNetConfig unable to establish configd session.");
		return nil;
	}
	if (!SCDynamicStoreSetNotificationKeys(scSession,
										   (CFArrayRef)[NSArray arrayWithObjects:
																	@"State:/Network/Global/IPv4",
																	@"Setup:/Network/Global/IPv4",
																	@"State:/Network/Interface", nil],
										   (CFArrayRef)[NSArray arrayWithObjects:
																	@"State:/Network/Interface.*", nil])) {
		NSLog(@"MenuMeterNetConfig unable to install notification keys.");
		return nil;
	}
	scRunSource = SCDynamicStoreCreateRunLoopSource(kCFAllocatorDefault, scSession, 0);
	if (!scRunSource) {
		NSLog(@"MenuMeterNetConfig unable to get notification keys run loop source.");
		return nil;
	}
	CFRunLoopAddSource(CFRunLoopGetCurrent(), scRunSource, kCFRunLoopDefaultMode);

	// Set up IOKit port
	kern_return_t err = IOMasterPort(MACH_PORT_NULL, &masterPort);
	if ((err != KERN_SUCCESS) || !masterPort) {
		NSLog(@"MenuMeterNetConfig unable to establish IOKit port.");
		return nil;
	}

	// Set up first time caches, we cache where we can because
	// SystemConfiguration Framework can be very slow
	[self interfaceDetails];
	[self primaryInterfaceName];
	[self primaryServiceID];

	// Send on back
	return self;

} // init

- (void)dealloc {

	CFRunLoopRemoveSource(CFRunLoopGetCurrent(), scRunSource, kCFRunLoopDefaultMode);
	CFRelease(scSession);
	mach_port_deallocate(mach_task_self(), masterPort);

} // dealloc

///////////////////////////////////////////////////////////////
//
//  Network config info
//
///////////////////////////////////////////////////////////////

- (NSString *)computerName {

	CFStringRef name = SCDynamicStoreCopyComputerName(scSession, NULL);
	return (NSString *)CFBridgingRelease(name);

} // computerName

- (NSDictionary *)interfaceConfigForInterfaceName:(NSString *)name {

	// Load up the service if we can. If there is no name or its "primary"
	// use the primary.
	NSString *service = nil;
	if (name && ![name isEqualToString:kNetPrimaryInterface]) {
		service = [self serviceForInterfaceName:name];
	}
	if (!service) {
		service = [self primaryServiceID];
		NSString *statName = [self underlyingInterfaceNameForServiceID:[self primaryServiceID]];
		NSString *primaryName = [self primaryInterfaceName];
		if (service && (statName || primaryName)) {
			return [NSDictionary dictionaryWithObjectsAndKeys:
									 service,
									 @"service",
									 (statName ? statName : primaryName),
									 @"statname",
									 [self speedForServiceID:service],
									 @"speed",
									 kNetPrimaryInterface,
									 @"name",
									 [NSNumber numberWithBool:[self interfaceNameIsUp:(statName ? statName : primaryName)]],
									 @"interfaceup",
									 nil];
		}
		else {
			return nil;
		}
	}

	// Good service
	NSString *statName = [self underlyingInterfaceNameForServiceID:service];
	if (service && statName) {
		return [NSDictionary dictionaryWithObjectsAndKeys:
								 service,
								 @"service",
								 statName,
								 @"statname",
								 [self speedForServiceID:service],
								 @"speed",
								 name,
								 @"name",
								 [NSNumber numberWithBool:[self interfaceNameIsUp:statName]],
								 @"interfaceup",
								 nil];
	}
	return nil;

} // interfaceConfigForInterfaceName

- (NSArray *)interfaceDetails {

	// Cache?
	if (cachedInterfaceDetails) {
		// Cache is close, but we have to interate looking for ppp status. If
		// we find one it needs updating
		NSEnumerator *servicesEnum = [cachedInterfaceDetails objectEnumerator];
		NSMutableDictionary *interfaceDetail = nil;
		while ((interfaceDetail = [servicesEnum nextObject])) {
			if ([interfaceDetail objectForKey:@"pppstatus"]) {
				NSDictionary *newStatus = [pppGatherer statusForServiceID:[interfaceDetail objectForKey:@"service"]];
				if (newStatus) {
					[interfaceDetail setObject:newStatus forKey:@"pppstatus"];
				}
			}
		}
		return cachedInterfaceDetails;
	}

	// Get the dict block for services
	NSDictionary *servicesDict = [self sysconfigValueForKey:@"Setup:/Network/Global/IPv4"];
	if (!servicesDict)
		return nil;

	// Get the array of services
	NSMutableArray *allServices = [[servicesDict objectForKey:@"ServiceOrder"] mutableCopy];
	if (!allServices)
		return nil;

	// Reorder services so the primary is first if possible
	if ([self primaryServiceID]) {
		CFIndex index = [allServices indexOfObject:[self primaryServiceID]];
		if ((index != NSNotFound) && (index != 0)) {
			[allServices insertObject:[allServices objectAtIndex:index] atIndex:0];
			[allServices removeObjectAtIndex:index + 1];
		}
	}

	// Set up the enumerator and loop the services
	NSEnumerator *servicesEnum = [allServices objectEnumerator];
	NSString *serviceID = nil;
	NSMutableArray *interfaceDetailList = [NSMutableArray array];
	while ((serviceID = [servicesEnum nextObject])) {
		NSMutableDictionary *interfaceDetail = [NSMutableDictionary dictionary];
		// Store the service ID
		[interfaceDetail setObject:serviceID forKey:@"service"];
		// Is this the primary?
		if ([[self primaryServiceID] isEqualToString:serviceID]) {
			[interfaceDetail setObject:[NSNumber numberWithBool:YES] forKey:@"primary"];
		}
		else {
			[interfaceDetail setObject:[NSNumber numberWithBool:NO] forKey:@"primary"];
		}
		// Get the interface name
		NSDictionary *serviceDict = [self sysconfigValueForKey:
											  [NSString stringWithFormat:@"Setup:/Network/Service/%@", serviceID]];
		if ([serviceDict objectForKey:@"UserDefinedName"]) {
			[interfaceDetail setObject:[serviceDict objectForKey:@"UserDefinedName"] forKey:@"name"];
		}
		// Get interface details
		NSDictionary *interfaceDict = [self sysconfigValueForKey:
												[NSString stringWithFormat:@"Setup:/Network/Service/%@/Interface", serviceID]];
		if (!interfaceDict) {
			// If the details aren't present then skip, we can learn nothing here
			continue;
		}
		// Add a name if we haven't already
		if (![interfaceDetail objectForKey:@"name"]) {
			if ([interfaceDict objectForKey:@"UserDefinedName"]) {
				[interfaceDetail setObject:[interfaceDict objectForKey:@"UserDefinedName"] forKey:@"name"];
			}
			else if ([interfaceDict objectForKey:@"Hardware"]) {
				[interfaceDetail setObject:[interfaceDict objectForKey:@"Hardware"] forKey:@"name"];
			}
			else {
				[interfaceDetail setObject:@"Unknown Interface" forKey:@"name"];
			}
		}
		// Device name, this is weird from some VPN software so leave it null in that case
		if ([interfaceDict objectForKey:@"DeviceName"]) {
			[interfaceDetail setObject:[interfaceDict objectForKey:@"DeviceName"] forKey:@"devicename"];
		}
		// Connection type
		if ([interfaceDict objectForKey:@"SubType"]) {
			[interfaceDetail setObject:[interfaceDict objectForKey:@"SubType"] forKey:@"connectiontype"];
		}
		else if ([interfaceDict objectForKey:@"Type"]) {
			[interfaceDetail setObject:[interfaceDict objectForKey:@"Type"] forKey:@"connectiontype"];
		}
		// Now get info that may or may not be there, starting with PPP name
		NSDictionary *pppDict = [self sysconfigValueForKey:
										  [NSString stringWithFormat:@"State:/Network/Service/%@/PPP", serviceID]];
		if ([pppDict objectForKey:@"InterfaceName"]) {
			[interfaceDetail setObject:[pppDict objectForKey:@"InterfaceName"] forKey:@"devicepppname"];
		}
		pppDict = [self sysconfigValueForKey:[NSString stringWithFormat:@"Setup:/Network/Service/%@/PPP", serviceID]];
		if (pppDict) {
			// It's PPP, get the status info
			NSDictionary *pppStatusDict = [pppGatherer statusForServiceID:serviceID];
			if (pppStatusDict) {
				[interfaceDetail setObject:pppStatusDict forKey:@"pppstatus"];
			}
		}
		// IPv4 info
		NSDictionary *ipDict = [self sysconfigValueForKey:
										 [NSString stringWithFormat:@"State:/Network/Service/%@/IPv4", serviceID]];
		if ([ipDict objectForKey:@"Addresses"]) {
			[interfaceDetail setObject:[ipDict objectForKey:@"Addresses"] forKey:@"ipv4addresses"];
		}
		// IPv6 info
		if ([interfaceDetail objectForKey:@"devicename"]) {
			ipDict = [self sysconfigValueForKey:
							   [NSString stringWithFormat:@"State:/Network/Interface/%@/IPv6",
														  [interfaceDetail objectForKey:@"devicename"]]];
			if ([ipDict objectForKey:@"Addresses"]) {
				[interfaceDetail setObject:[ipDict objectForKey:@"Addresses"] forKey:@"ipv6addresses"];
			}
		}
		// Appletalk
		NSDictionary *appletalkDict = [self sysconfigValueForKey:
												[NSString stringWithFormat:@"State:/Network/Interface/%@/AppleTalk",
																		   [interfaceDetail objectForKey:@"devicename"]]];
		if ([appletalkDict objectForKey:@"NetworkID"] &&
			[appletalkDict objectForKey:@"NodeID"] &&
			[appletalkDict objectForKey:@"DefaultZone"]) {
			[interfaceDetail setObject:[appletalkDict objectForKey:@"NetworkID"] forKey:@"appletalknetid"];
			[interfaceDetail setObject:[appletalkDict objectForKey:@"NodeID"] forKey:@"appletalknodeid"];
			[interfaceDetail setObject:[appletalkDict objectForKey:@"DefaultZone"] forKey:@"appletalkzone"];
		}
		// Link status
		NSDictionary *linkDict = [self sysconfigValueForKey:
										   [NSString stringWithFormat:@"State:/Network/Interface/%@/Link",
																	  [interfaceDetail objectForKey:@"devicename"]]];
		if ([linkDict objectForKey:@"Active"]) {
			[interfaceDetail setObject:[linkDict objectForKey:@"Active"] forKey:@"linkactive"];
		}

		// Link speed is set from interface type, if no interface type is known we do not guess here, just leave it blank
		// This is OK in this context, it is not OK in the speedForService call, so see that method for how we handled that case.
		if ([interfaceDetail objectForKey:@"devicename"]) {
			if ([[interfaceDetail objectForKey:@"devicename"] hasPrefix:@"en"]) {
				// Ethernet interface so we can ask IOKit
				[interfaceDetail setObject:[self speedForInterfaceName:[interfaceDetail objectForKey:@"devicename"]] forKey:@"linkspeed"];
			}
			else if ([[interfaceDetail objectForKey:@"devicename"] isEqualToString:@"modem"]) {
				// Modem data can be had from config framework
				NSDictionary *modemDict = [self sysconfigValueForKey:
													[NSString stringWithFormat:@"State:/Network/Service/%@/Modem", serviceID]];
				if ([modemDict objectForKey:@"ConnectSpeed"]) {
					// Its a modem, but is it connected?
					pppDict = [self sysconfigValueForKey:
										[NSString stringWithFormat:@"State:/Network/Service/%@/PPP", serviceID]];
					if ([pppDict objectForKey:@"Status"] &&
						([[pppDict objectForKey:@"Status"] intValue] == PPP_RUNNING) &&
						[pppDict objectForKey:@"ConnectSpeed"]) {
						[interfaceDetail setObject:[pppDict objectForKey:@"ConnectSpeed"] forKey:@"linkspeed"];
					}
				}
			}
		}
		// Add to list
		[interfaceDetailList addObject:interfaceDetail];
	} // end of interface iteration

	// Update the cache
	cachedInterfaceDetails = interfaceDetailList;

	// Send the details back
	return interfaceDetailList;

} // interfaceDetails

- (NSString *)primaryInterfaceName {

	// Cache?
	if (cachedPrimaryName)
		return cachedPrimaryName;

	// Get the primary service number
	NSDictionary *ipDict = [self sysconfigValueForKey:@"State:/Network/Global/IPv4"];
	if ([ipDict objectForKey:@"PrimaryInterface"]) {
		cachedPrimaryName = [ipDict objectForKey:@"PrimaryInterface"];
	}
	else {
		cachedPrimaryName = nil;
	}
	return cachedPrimaryName;

} // primaryInterfaceName

- (NSString *)primaryServiceID {

	// Cache?
	if (cachedPrimaryService)
		return cachedPrimaryService;

	// Get the primary service number
	NSDictionary *ipDict = [self sysconfigValueForKey:@"State:/Network/Global/IPv4"];
	if ([ipDict objectForKey:@"PrimaryService"]) {
		cachedPrimaryService = [ipDict objectForKey:@"PrimaryService"];
	}
	else {
		cachedPrimaryService = nil;
	}
	return cachedPrimaryService;

} // primaryServiceID

- (NSString *)interfaceNameForServiceID:(NSString *)serviceID {

	if (!serviceID)
		return nil;

	// Cache?
	if ([cachedServiceToName objectForKey:serviceID]) {
		return [cachedServiceToName objectForKey:serviceID];
	}
	else if (!cachedServiceToName) {
		cachedServiceToName = [NSMutableDictionary dictionary];
	}

	// Get interface details
	NSDictionary *interfaceDict = [self sysconfigValueForKey:
											[NSString stringWithFormat:@"Setup:/Network/Service/%@/Interface", serviceID]];
	NSDictionary *pppDict = [self sysconfigValueForKey:
									  [NSString stringWithFormat:@"State:/Network/Service/%@/PPP", serviceID]];
	// Check for PPP first
	if ([pppDict objectForKey:@"InterfaceName"]) {
		[cachedServiceToName setObject:[pppDict objectForKey:@"InterfaceName"] forKey:serviceID];
		return [pppDict objectForKey:@"InterfaceName"];
	}
	// Otherwise try the hardware name
	if ([interfaceDict objectForKey:@"DeviceName"]) {
		[cachedServiceToName setObject:[interfaceDict objectForKey:@"DeviceName"] forKey:serviceID];
		return [interfaceDict objectForKey:@"DeviceName"];
	}
	return nil;

} // interfaceNameForServiceID

- (NSString *)serviceForInterfaceName:(NSString *)interfaceName {

	if (!interfaceName)
		return nil;

	if ([cachedNameToService objectForKey:interfaceName]) {
		return [cachedNameToService objectForKey:interfaceName];
	}
	else if (!cachedNameToService) {
		cachedNameToService = [NSMutableDictionary dictionary];
	}

	// Get the dict block for services
	NSDictionary *ipDict = [self sysconfigValueForKey:@"Setup:/Network/Global/IPv4"];
	if (!ipDict)
		return nil;
	// Get the array of services
	NSMutableArray *allServices = [[ipDict objectForKey:@"ServiceOrder"] mutableCopy];
	if (!allServices)
		return nil;

	// Set up the enumerator and loop the services
	NSEnumerator *servicesEnum = [allServices objectEnumerator];
	NSString *serviceID = nil;
	while ((serviceID = [servicesEnum nextObject])) {
		// Get interface details
		NSDictionary *interfaceDict = [self sysconfigValueForKey:
												[NSString stringWithFormat:@"Setup:/Network/Service/%@/Interface", serviceID]];
		if ([[interfaceDict objectForKey:@"DeviceName"] isEqualToString:interfaceName]) {
			[cachedNameToService setObject:serviceID forKey:interfaceName];
			return serviceID;
		}
		NSDictionary *pppDict = [self sysconfigValueForKey:
										  [NSString stringWithFormat:@"State:/Network/Service/%@/PPP", serviceID]];
		if ([[pppDict objectForKey:@"InterfaceName"] isEqualToString:interfaceName]) {
			[cachedNameToService setObject:serviceID forKey:interfaceName];
			return serviceID;
		}
	}
	return nil;

} // serviceForInterfaceName

- (NSNumber *)speedForServiceID:(NSString *)serviceID {

	if (!serviceID)
		return [NSNumber numberWithLong:kInterfaceDefaultSpeed];

	// Cache?
	if ([cachedServiceSpeed objectForKey:serviceID]) {
		return [cachedServiceSpeed objectForKey:serviceID];
	}
	else if (!cachedServiceSpeed) {
		cachedServiceSpeed = [NSMutableDictionary dictionary];
	}

	// This routine must return _something_ always. The problem is that in the case of ppp interface names we really
	// ought to be able to get to the right sysconfig framework data on the basis of the BSD name returned by primaryName.
	// Sadly, there doesn't seem to be a way to do this. So we sort of muck about here figuring it out.
	NSDictionary *modemDict = [self sysconfigValueForKey:[NSString stringWithFormat:@"State:/Network/Service/%@/Modem", serviceID]];
	NSDictionary *pppDict = [self sysconfigValueForKey:[NSString stringWithFormat:@"State:/Network/Service/%@/PPP", serviceID]];
	// If the modem key exists assume we are using a PPP connection
	if (modemDict) {
		if ([modemDict objectForKey:@"ConnectSpeed"] && ([[pppDict objectForKey:@"Status"] intValue] == PPP_RUNNING)) {
			[cachedServiceSpeed setObject:[modemDict objectForKey:@"ConnectSpeed"] forKey:serviceID];
			return [modemDict objectForKey:@"ConnectSpeed"];
		}
		else {
			// Not connected or bad data, so use the modem default but don't cache
			return [NSNumber numberWithLong:kModemInterfaceDefaultSpeed];
		}
	}

	// If we're still around, try checking for ethernet with BSD interface speed
	NSString *interfaceName = [self interfaceNameForServiceID:serviceID];
	if ([interfaceName hasPrefix:@"en"]) {
		NSNumber *speed = [self speedForInterfaceName:interfaceName];
		if (speed) {
			[cachedServiceSpeed setObject:speed forKey:serviceID];
			return speed;
		}
	}

	// Return a default but don't cache
	return [NSNumber numberWithLong:kInterfaceDefaultSpeed];

} // speedForService

- (NSString *)underlyingInterfaceNameForServiceID:(NSString *)serviceID {

	if (!serviceID)
		return nil;

	// Cache?
	if ([cachedUnderlyingInterface objectForKey:serviceID]) {
		return [cachedUnderlyingInterface objectForKey:serviceID];
	}
	else if (!cachedUnderlyingInterface) {
		cachedUnderlyingInterface = [NSMutableDictionary dictionary];
	}

	// There appears to be a bug in pppconfd's handling of bytes sent for
	// PPPoE connections. Try to work around by finding the underlying ethernet
	// interface for these connections.
	NSDictionary *interfaceDict = [self sysconfigValueForKey:
											[NSString stringWithFormat:@"Setup:/Network/Service/%@/Interface", serviceID]];
	NSDictionary *pppDict = [self sysconfigValueForKey:
									  [NSString stringWithFormat:@"State:/Network/Service/%@/PPP", serviceID]];
	// Check for PPP name
	if ([pppDict objectForKey:@"InterfaceName"]) {
		// There appears to be a bug in pppconfd's handling of bytes sent for
		// PPPoE connections. Try to work around by finding the underlying ethernet
		// interface for these connections
		if ([[interfaceDict objectForKey:@"DeviceName"] hasPrefix:@"en"]) {
			[cachedUnderlyingInterface setObject:[interfaceDict objectForKey:@"DeviceName"] forKey:serviceID];
			return [interfaceDict objectForKey:@"DeviceName"];
		}
		else {
			[cachedUnderlyingInterface setObject:[pppDict objectForKey:@"InterfaceName"] forKey:serviceID];
			return [pppDict objectForKey:@"InterfaceName"];
		}
	}
	// Use the hardware name if no PPP name
	if ([interfaceDict objectForKey:@"DeviceName"]) {
		[cachedUnderlyingInterface setObject:[interfaceDict objectForKey:@"DeviceName"] forKey:serviceID];
		return [interfaceDict objectForKey:@"DeviceName"];
	}

	return nil;

} // underlyingInterfaceNameForServiceID

// Based on patch contributed by Da Woon Jung

- (BOOL)interfaceNameIsUp:(NSString *)interfaceName {

	if (!interfaceName)
		return NO;

	// Cache?
	if ([cachedInterfaceUp objectForKey:interfaceName]) {
		return [[cachedInterfaceUp objectForKey:interfaceName] boolValue];
	}
	else if (!cachedInterfaceUp) {
		cachedInterfaceUp = [NSMutableDictionary dictionary];
	}

	if ([interfaceName hasPrefix:@"en"]) {
		// Ethernet
		NSDictionary *linkDict = [self sysconfigValueForKey:
										   [NSString stringWithFormat:@"State:/Network/Interface/%@/Link", interfaceName]];
		if ([linkDict objectForKey:@"Active"]) {
			[cachedInterfaceUp setObject:[linkDict objectForKey:@"Active"] forKey:interfaceName];
			return [[linkDict objectForKey:@"Active"] boolValue];
		}
	}
	else if ([interfaceName hasPrefix:@"ppp"]) {
		// PPP
		NSDictionary *pppDict = [pppGatherer statusForInterfaceName:interfaceName];
		if ([[pppDict objectForKey:@"status"] intValue] == PPP_RUNNING) {
			[cachedInterfaceUp setObject:[NSNumber numberWithBool:YES] forKey:interfaceName];
			return YES;
		}
		else {
			[cachedInterfaceUp setObject:[NSNumber numberWithBool:NO] forKey:interfaceName];
			return NO;
		}
	}

	// Fall through, assume interface is active
	return YES;

} // interfaceNameIsUp

///////////////////////////////////////////////////////////////
//
//  Private methods
//
///////////////////////////////////////////////////////////////

// taken from https://stackoverflow.com/a/12310154/239243

- (NSString *)runCommand:(NSString *)commandToRun {
	NSTask *task = [[NSTask alloc] init];
	[task setLaunchPath:@"/bin/sh"];

	NSArray *arguments = [NSArray arrayWithObjects:
									  @"-c",
									  [NSString stringWithFormat:@"%@", commandToRun],
									  nil];
	//    NSLog(@"run command:%@", commandToRun);
	[task setArguments:arguments];

	NSPipe *pipe = [NSPipe pipe];
	[task setStandardOutput:pipe];
	[task setStandardError:pipe];

	NSFileHandle *file = [pipe fileHandleForReading];

	[task launch];

	NSData *data = [file readDataToEndOfFile];
	[file closeFile];

	NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	return output;
}

- (NSNumber *)speedForInterfaceName:(NSString *)bsdInterface {
	{
		NSDictionary *airportDict = [self sysconfigValueForKey:[NSString stringWithFormat:@"Setup:/Network/Interface/%@/AirPort", bsdInterface]];
		if (airportDict) {
			NSNumber *x = [self speedForAirport];
			if (x) {
				return x;
			}
		}
	}
	{
		NSNumber *x = [self speedForInterfaceNameViaIOKit:bsdInterface];
		if (x) {
			return x;
		}
	}
	{
		NSNumber *x = [self speedForInterfaceNameViaIfConfig:bsdInterface];
		if (x) {
			return x;
		}
	}
	return [NSNumber numberWithLong:kInterfaceDefaultSpeed];
}

- (NSNumber *)speedForAirport {
	NSString *line = [self runCommand:@"/System/Library/PrivateFrameworks/Apple80211.framework/Versions/A/Resources/airport -I | grep maxRate"];
	NSRange r = [line rangeOfString:@":"];
	if (r.location == NSNotFound) {
		return nil;
	}
	line = [line substringFromIndex:r.location + 1];
	return [NSNumber numberWithDouble:[line doubleValue] * 1000 * 1000];
}

- (NSNumber *)speedForInterfaceNameViaIfConfig:(NSString *)bsdInterface {

	if (!bsdInterface)
		return [NSNumber numberWithLong:kInterfaceDefaultSpeed];
	NSLog(@"getting the speed for %@", bsdInterface);
	/* The old way to get the speed via IOKit no longer reliably works, most probably due to the slow move to DriverKit.
	 The link speed as reported by NetworkUtility.app can also be obtained by ifconfig, whose source code is available at
	 https://opensource.apple.com/source/network_cmds/network_cmds-596/ifconfig.tproj/
	 e.g. for Catalina. Unfortunately the ioctl used there is not exposed in the standard development headers, although you can presumably use it by copying the content of the private headers.
	 Here instead I just directly call ifconfig.
	 */
	NSString *line = [self runCommand:[NSString stringWithFormat:@"ifconfig -v %@ | egrep 'link rate|uplink'", bsdInterface]];
	if ([line containsString:@"does not"]) {
		return [NSNumber numberWithLong:0];
	}
	NSRange r = [line rangeOfString:@"/"];
	if (r.location == NSNotFound) {
		r = [line rangeOfString:@": "];
	}
	if (r.location == NSNotFound) {
		return [NSNumber numberWithLong:0];
	}
	line = [line substringFromIndex:r.location + 1];
	double factor = 1;
	if ((r = [line rangeOfString:@"Gbps"]).location != NSNotFound) {
		factor = 1000 * 1000 * 1000;
	}
	else if ((r = [line rangeOfString:@"Mbps"]).location != NSNotFound) {
		factor = 1000 * 1000;
	}
	else if ((r = [line rangeOfString:@"Kbps"]).location != NSNotFound) {
		factor = 1000;
	}
	else if ((r = [line rangeOfString:@"bps"]).location != NSNotFound) {
		factor = 1;
	}
	else {
		factor = 0;
	}

	line = [line substringToIndex:r.location];
	return [NSNumber numberWithDouble:[line doubleValue] * factor];
}

- (NSNumber *)speedForInterfaceNameViaIOKit:(NSString *)bsdInterface {
	// Get the speed from IOKit
	io_iterator_t iterator;
	IOServiceGetMatchingServices(masterPort,
								 IOBSDNameMatching(masterPort, kNilOptions, [bsdInterface UTF8String]),
								 &iterator);
	// If we didn't get an iterator guess 10Mbit
	if (!iterator)
		return nil;

	// Otherwise poke around IOKit
	io_registry_entry_t regEntry = IOIteratorNext(iterator);
	if (!regEntry) {
		IOObjectRelease(iterator);
		return [NSNumber numberWithLong:kInterfaceDefaultSpeed];
	}
	io_object_t controllerService = 0;
	IORegistryEntryGetParentEntry(regEntry, kIOServicePlane, &controllerService);
	if (!controllerService) {
		IOObjectRelease(regEntry);
		IOObjectRelease(iterator);
		return [NSNumber numberWithLong:kInterfaceDefaultSpeed];
	}
	NSNumber *linkSpeed = (NSNumber *)CFBridgingRelease(IORegistryEntryCreateCFProperty(controllerService,
																						CFSTR(kIOLinkSpeed),
																						kCFAllocatorDefault,
																						kNilOptions));
	IOObjectRelease(controllerService);
	IOObjectRelease(regEntry);
	IOObjectRelease(iterator);
	if (linkSpeed && ([linkSpeed unsignedLongLongValue] > 0)) {
		return linkSpeed;
	}
	else {
		return nil;
	}
} // speedForInterfaceName

- (NSDictionary *)sysconfigValueForKey:(NSString *)key {

	return (NSDictionary *)CFBridgingRelease(SCDynamicStoreCopyValue(scSession, (CFStringRef)key));
} // sysconfigValueForKey

- (void)clearCaches {

	// Drop all current cached values
	cachedInterfaceDetails = nil;
	cachedPrimaryName = nil;
	cachedPrimaryService = nil;
	cachedServiceToName = nil;
	cachedNameToService = nil;
	cachedServiceSpeed = nil;
	cachedUnderlyingInterface = nil;
	cachedInterfaceUp = nil;

} // clearCaches

@end

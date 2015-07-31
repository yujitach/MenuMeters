//
//  MenuMeterNetConfig.h
//
// 	Reader object for network config info
//
//	Copyright (c) 2002-2014 Alex Harper
//
// 	This file is part of MenuMeters.
//
// 	MenuMeters is free software; you can redistribute it and/or modify
// 	it under the terms of the GNU General Public License version 2 as
//  published by the Free Software Foundation.
//
// 	MenuMeters is distributed in the hope that it will be useful,
// 	but WITHOUT ANY WARRANTY; without even the implied warranty of
// 	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// 	GNU General Public License for more details.
//
// 	You should have received a copy of the GNU General Public License
// 	along with MenuMeters; if not, write to the Free Software
// 	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <IOKit/IOKitLib.h>
#import <IOKit/network/IOEthernetInterface.h>
#import <IOKit/network/IONetworkInterface.h>
#import <IOKit/network/IOEthernetController.h>
#import <mach/mach_port.h>
#import "MenuMeterNet.h"
#import "MenuMeterNetPPP.h"


@interface MenuMeterNetConfig : NSObject {

	// PPP data pull
	MenuMeterNetPPP				*pppGatherer;
	// Values for SystemConfiguration sessions
	SCDynamicStoreRef			scSession;
	CFRunLoopSourceRef			scRunSource;
	// Mach port for IOKit
	mach_port_t					masterPort;
	// Caches of current data
	NSArray						*cachedInterfaceDetails;
	NSString					*cachedPrimaryName;
	NSString					*cachedPrimaryService;
	NSMutableDictionary			*cachedServiceToName;
	NSMutableDictionary			*cachedNameToService;
	NSMutableDictionary			*cachedServiceSpeed;
	NSMutableDictionary			*cachedUnderlyingInterface;
	NSMutableDictionary			*cachedInterfaceUp;

} // MenuMeterNetConfig

// Network config info
- (NSString *)computerName;
- (NSDictionary *)interfaceConfigForInterfaceName:(NSString *)name;
- (NSArray *)interfaceDetails;
- (NSString *)primaryInterfaceName;
- (NSString *)primaryServiceID;
- (NSString *)serviceForInterfaceName:(NSString *)interfaceName;
- (NSString *)interfaceNameForServiceID:(NSString *)serviceID;
- (NSNumber *)speedForServiceID:(NSString *)serviceID;
- (NSString *)underlyingInterfaceNameForServiceID:(NSString *)serviceID;
- (BOOL)interfaceNameIsUp:(NSString *)interfaceName;

@end

//
//  MenuMeterNetExtra.m
//
//  Menu Extra implementation
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

#import "MenuMeterNetExtra.h"

///////////////////////////////////////////////////////////////
//
//  Private methods and constants
//
///////////////////////////////////////////////////////////////

// Apple network settings we'll try to use
#define kAppleNetworkConnectDefaultsDomain CFSTR("com.apple.networkConnect")

@interface MenuMeterNetExtra (PrivateMethods)

// Image renderers

- (void)renderGraphImageSize:(NSSize)imageSize;

- (void)renderActivityImageSize:(NSSize)imageSize;

- (void)renderThroughputImageSize:(NSSize)imageSize;

// Timer callbacks

- (void)updateMenuWhenDown;

// Menu actions

- (void)openNetworkUtil:(id)sender;

- (void)openNetworkPrefs:(id)sender;

- (void)openInternetConnect:(id)sender;

- (void)switchDisplay:(id)sender;

- (void)copyAddress:(id)sender;

- (void)pppConnect:(id)sender;

- (void)pppDisconnect:(id)sender;

// Prefs

- (void)configFromPrefs:(NSNotification *)notification;

// Data formatting

- (NSString *)throughputStringForBytesPerSecond:(double)bps;

- (NSString *)throughputStringForBytes:(double)bytes inInterval:(NSTimeInterval)interval;

- (NSString *)trafficStringForNumber:(NSNumber *)throughputNumber withLabel:(NSString *)directionLabel;

- (NSUInteger)scaleDown:(double *)num usingBase:(NSUInteger)base withLimit:(NSUInteger)limit;

- (NSString *)stringifyNumber:(double)num withUnitLabel:(NSString *)label andFormat:(NSString *)format;

- (NSString *)throughputStringForBytes:(NSNumber *)throughputNumber;

@end

///////////////////////////////////////////////////////////////
//
//  Localized strings
//
///////////////////////////////////////////////////////////////

#define kTxLabel @"Tx:"
#define kRxLabel @"Rx:"
#define kPPPTitle @"PPP:"
#define kTCPIPTitle @"TCP/IP:"
#define kIPv4Title @"IPv4:"
#define kIPv6Title @"IPv6:"
#define kTCPIPInactiveTitle @"Inactive"
#define kAppleTalkTitle @"AppleTalk:"
#define kAppleTalkFormat @"Net: %@ Node: %@ Zone: %@"
#define kThroughputTitle @"Throughput:"
#define kPeakThroughputTitle @"Peak Throughput:"
#define kTrafficTotalTitle @"Traffic Totals:"
#define kOpenNetworkUtilityTitle @"Open Network Utility"
#define kOpenNetworkPrefsTitle @"Open Network Preferences"
#define kOpenInternetConnectTitle @"Open Internet Connect"
#define kSelectPrimaryInterfaceTitle @"Display primary interface"
#define kSelectInterfaceTitle @"Display this interface"
#define kCopyIPv4Title @"Copy IPv4 address"
#define kCopyIPv6Title @"Copy IPv6 address"
#define kResetTrafficTotalsTitle @"Reset traffic totals"
#define kPPPConnectTitle @"Connect"
#define kPPPDisconnectTitle @"Disconnect"
#define kNoInterfaceErrorMessage @"No Active Interfaces"
#define kBitsLabel @"bits"
#define kBytesLabel @"bytes"
#define kBitLabel @"b"
#define kKbLabel @"Kb"
#define kMbLabel @"Mb"
#define kGbLabel @"Gb"
#define kTbLabel @"Tb"
#define kByteLabel @"B"
#define kKBLabel @"KB"
#define kMBLabel @"MB"
#define kGBLabel @"GB"
#define kTBLabel @"TB"
#define kBpsLabel @"bps"
#define kKbpsLabel @"Kbps"
#define kMbpsLabel @"Mbps"
#define kGbpsLabel @"Gbps"
#define kBitPerSecondLabel @"b/s"
#define kKbPerSecondLabel @"Kb/s"
#define kMbPerSecondLabel @"Mb/s"
#define kGbPerSecondLabel @"Gb/s"
#define kBytePerSecondLabel @"B/s"
#define kKBPerSecondLabel @"KB/s"
#define kMBPerSecondLabel @"MB/s"
#define kGBPerSecondLabel @"GB/s"
#define kPPPNoConnectTitle @"Not Connected"
#define kPPPConnectingTitle @"Connecting..."
#define kPPPConnectedTitle @"Connected"
#define kPPPConnectedWithTimeTitle @"Connected %02d:%02d:%02d"
#define kPPPDisconnectingTitle @"Disconnecting..."
#define kKiloBinary 1024
#define kKiloDecimal 1000

///////////////////////////////////////////////////////////////
//
//  init/unload/dealloc
//
///////////////////////////////////////////////////////////////

@implementation MenuMeterNetExtra

- (instancetype)init {

	self = [super initWithBundleID:kNetMenuBundleID];
	if (!self) {
		return nil;
	}

	ourPrefs = [MenuMeterDefaults sharedMenuMeterDefaults];
	if (!ourPrefs) {
		NSLog(@"MenuMeterCPU unable to connect to preferences. Abort.");
		return nil;
	}

	// Build our data gatherers
	netConfig = [[MenuMeterNetConfig alloc] init];
	netStats = [[MenuMeterNetStats alloc] init];
	pppControl = [MenuMeterNetPPP sharedPPP];
	netHistoryData = [NSMutableArray array];
	netHistoryIntervals = [NSMutableArray array];
	if (!(netConfig && netStats && pppControl && netHistoryData)) {
		NSLog(@"MenuMeterNet unable to load data gatherers/controllers. Abort.");
		return nil;
	}

	// Setup our menu
	extraMenu = [[NSMenu alloc] initWithTitle:@""];
	if (!extraMenu) {
		return nil;
	}
	// Disable menu autoenabling
	[extraMenu setAutoenablesItems:NO];

	// TODO: move the following into MenuMetersPref ??
	CGFloat menuBarHeight = [[NSApp mainMenu] menuBarHeight];
	if (menuBarHeight > 23) { // on MacBooks with notch. (TODO: or when "Menu bar size" is set to "large" system preferences?)
		NSArray *screens = NSScreen.screens;
		tallMenuBar = screens.count == 1; // If there is a screen attached, it has its own (small) menu and I can’t distinguish the two right now.
	}
	throughputFont = [NSFont monospacedDigitSystemFontOfSize:tallMenuBar ? 12 : 9.5 weight:NSFontWeightRegular];
	NSFont *traitFont = [NSFontManager.sharedFontManager convertFont:throughputFont toHaveTrait:NSCondensedFontMask];
	if (traitFont) {
		throughputFont = traitFont;
	}

	// Set up a NumberFormatter for localization. This is based on code contributed by Mike Fischer
	// (mike.fischer at fi-works.de) for use in MenuMeters.
	NSNumberFormatter *tempFormat = [[NSNumberFormatter alloc] init];
	[tempFormat setLocalizesFormat:YES];
	[tempFormat setFormat:@"###0.0"];
	// Go through an archive/unarchive cycle to work around a bug on pre-10.2.2 systems
	// see http://cocoa.mamasam.com/COCOADEV/2001/12/2/21029.php
	bytesFormatter = [NSUnarchiver unarchiveObjectWithData:[NSArchiver archivedDataWithRootObject:tempFormat]];
	tempFormat = [[NSNumberFormatter alloc] init];
	[tempFormat setLocalizesFormat:YES];
	[tempFormat setFormat:@"#,##0"];
	prettyIntFormatter = [NSUnarchiver unarchiveObjectWithData:[NSArchiver archivedDataWithRootObject:tempFormat]];

	// And configure directly from prefs on first load
	[self configFromPrefs:nil];

	// And hand ourself back to SystemUIServer
	NSLog(@"MenuMeterNet loaded.");
	return self;

} // initWithBundle

// dealloc

///////////////////////////////////////////////////////////////
//
//  NSMenuExtra view callbacks
//
///////////////////////////////////////////////////////////////

- (NSImage *)image {

	[self setupAppearance];

	// Don't render without data
	if (![netHistoryData count])
		return nil;

	// Image to render into (and return to view)
	NSSize imageSize = NSMakeSize(menuWidth, self.height);
	int netDisplayModePrefs = [ourPrefs netDisplayMode];

	NSImage *currentImage = [NSImage imageWithSize:imageSize
										   flipped:NO
									drawingHandler:^BOOL(NSRect dstRect) {
		// Draw displays
		if (netDisplayModePrefs & kNetDisplayGraph) {
			[self renderGraphImageSize:imageSize];
		}
		if (netDisplayModePrefs & kNetDisplayArrows) {
			[self renderActivityImageSize:imageSize];
		}
		if (netDisplayModePrefs & kNetDisplayThroughput) {
			[self renderThroughputImageSize:imageSize];
		}
		return YES;
	}];
	// Send it back for the view to render
	return currentImage;

} // image

// Boy does this need refactoring... *sigh*

- (NSMenu *)menu {

	// New cache
	updateMenuItems = [NSMutableDictionary dictionary];

	// Empty the menu
	while ([extraMenu numberOfItems]) {
		[extraMenu removeItemAtIndex:0];
	}

	// Hostname
	NSString *hostname = [netConfig computerName];
	if (hostname) {
		[[extraMenu addItemWithTitle:hostname action:nil keyEquivalent:@""] setEnabled:NO];
		[extraMenu addItem:[NSMenuItem separatorItem]];
	}

	// Interface detail array
	BOOL pppPresent = NO;
	NSArray *interfaceDetails = [netConfig interfaceDetails];
	if ([interfaceDetails count]) {
		NSEnumerator *detailEnum = [interfaceDetails objectEnumerator];
		NSDictionary *details = nil;
		while ((details = [detailEnum nextObject])) {
			// Array entry is a service/interface
			NSMutableDictionary *interfaceUpdateMenuItems = [NSMutableDictionary dictionary];
			NSString *interfaceDescription = [details objectForKey:@"name"];
			NSString *speed = nil;
			// Best guess if this is an active interface, default to assume it is active
			BOOL isActiveInterface = YES;

			if ([details objectForKey:@"linkactive"]) {
				isActiveInterface = [[details objectForKey:@"linkactive"] boolValue];
			}

			if ([details objectForKey:@"pppstatus"]) {
				if ([(NSNumber *)[[details objectForKey:@"pppstatus"] objectForKey:@"status"] unsignedIntValue] == PPP_IDLE) {
					isActiveInterface = NO;
				}
			}

			// Calc speed
			if ([details objectForKey:@"linkspeed"] && isActiveInterface) {
				if ([[details objectForKey:@"linkspeed"] doubleValue] < 0) {
					speed = nil;
				}
				else if ([[details objectForKey:@"linkspeed"] doubleValue] > 1000000000) {
					speed = [NSString stringWithFormat:@" %.0f %@",
							 ([[details objectForKey:@"linkspeed"] doubleValue] / 1000000000),
							 [localizedStrings objectForKey:kGbpsLabel]];
				}
				else if ([[details objectForKey:@"linkspeed"] doubleValue] > 1000000) {
					speed = [NSString stringWithFormat:@" %.0f %@",
							 ([[details objectForKey:@"linkspeed"] doubleValue] / 1000000),
							 [localizedStrings objectForKey:kMbpsLabel]];
				}
				else {
					speed = [NSString stringWithFormat:@" %@ %@",
							 [bytesFormatter stringForObjectValue:
							  [NSNumber numberWithDouble:([[details objectForKey:@"linkspeed"] doubleValue] / 1000)]],
							 [localizedStrings objectForKey:kKbpsLabel]];
				}
			}
			// Weird string cat because some of these values may not be present
			// Also skip device name bit if the driver name (UserDefined name) already includes it (SourceForge wireless driver)
			if ([details objectForKey:@"devicename"] &&
				![interfaceDescription hasSuffix:[NSString stringWithFormat:@"(%@)", [details objectForKey:@"devicename"]]]) {
				// If there is a PPP name use it too
				if ([details objectForKey:@"devicepppname"]) {
					interfaceDescription = [NSString stringWithFormat:@"%@ (%@, %@)",
											interfaceDescription,
											[details objectForKey:@"devicename"],
											[details objectForKey:@"devicepppname"]];
				}
				else {
					interfaceDescription = [NSString stringWithFormat:@"%@ (%@)",
											interfaceDescription,
											[details objectForKey:@"devicename"]];
				}
			}
			if (speed || [details objectForKey:@"connectiontype"]) {
				interfaceDescription = [NSString stringWithFormat:@"%@ -%@%@",
										interfaceDescription,
										([details objectForKey:@"connectiontype"] ? [NSString stringWithFormat:@" %@", [details objectForKey:@"connectiontype"]] : @""),
										(speed ? speed : @"")];
			}
			NSMenuItem *titleItem = [extraMenu addItemWithTitle:interfaceDescription action:nil keyEquivalent:@""];
			// PPP Status
			if ([details objectForKey:@"pppstatus"]) {
				// PPP is present
				pppPresent = YES;
				NSMenuItem *pppStatusItem = nil;
				// Use the connection type title for PPP when we can
				if ([details objectForKey:@"connectiontype"]) {
					[[extraMenu addItemWithTitle:[NSString stringWithFormat:kMenuIndentFormat,
												  [NSString stringWithFormat:@"%@:", [details objectForKey:@"connectiontype"]]]
										  action:nil
								   keyEquivalent:@""] setEnabled:NO];
				}
				else {
					[[extraMenu addItemWithTitle:[NSString stringWithFormat:kMenuIndentFormat, [localizedStrings objectForKey:kPPPTitle]]
										  action:nil
								   keyEquivalent:@""] setEnabled:NO];
				}
				switch ([(NSNumber *)[[details objectForKey:@"pppstatus"] objectForKey:@"status"] unsignedIntValue]) {
					case PPP_IDLE:
						pppStatusItem = [extraMenu addItemWithTitle:[NSString stringWithFormat:kMenuDoubleIndentFormat,
																	 [localizedStrings objectForKey:kPPPNoConnectTitle]]
															 action:nil
													  keyEquivalent:@""];
						break;
					case PPP_INITIALIZE:
					case PPP_CONNECTLINK:
					case PPP_STATERESERVED:
					case PPP_ESTABLISH:
					case PPP_AUTHENTICATE:
					case PPP_CALLBACK:
					case PPP_NETWORK:
					case PPP_HOLDOFF:
					case PPP_ONHOLD:
					case PPP_WAITONBUSY:
						pppStatusItem = [extraMenu addItemWithTitle:[NSString stringWithFormat:kMenuDoubleIndentFormat,
																	 [localizedStrings objectForKey:kPPPConnectingTitle]]
															 action:nil
													  keyEquivalent:@""];
						break;
					case PPP_RUNNING:
						if ([[details objectForKey:@"pppstatus"] objectForKey:@"timeElapsed"]) {
							uint32_t secs = [[[details objectForKey:@"pppstatus"] objectForKey:@"timeElapsed"] unsignedIntValue];
							uint32_t hours = secs / (60 * 60);
							secs %= (60 * 60);
							uint32_t mins = secs / 60;
							secs %= 60;
							pppStatusItem = [extraMenu addItemWithTitle:[NSString stringWithFormat:kMenuDoubleIndentFormat,
																		 [NSString stringWithFormat:
																		  [localizedStrings objectForKey:kPPPConnectedWithTimeTitle],
																		  hours, mins, secs]]
																 action:nil
														  keyEquivalent:@""];
						}
						else {
							pppStatusItem = [extraMenu addItemWithTitle:[NSString stringWithFormat:kMenuDoubleIndentFormat, kPPPConnectedTitle]
																 action:nil
														  keyEquivalent:@""];
						}
						break;
					case PPP_TERMINATE:
					case PPP_DISCONNECTLINK:
						pppStatusItem = [extraMenu addItemWithTitle:[NSString stringWithFormat:kMenuIndentFormat,
																	 [localizedStrings objectForKey:kPPPDisconnectingTitle]]
															 action:nil
													  keyEquivalent:@""];
						break;
				};
				if (pppStatusItem) {
					[pppStatusItem setEnabled:NO];
					[interfaceUpdateMenuItems setObject:pppStatusItem forKey:@"pppstatusitem"];
				}
			}
			// TCP/IP
			[[extraMenu addItemWithTitle:[NSString stringWithFormat:kMenuIndentFormat, [localizedStrings objectForKey:kTCPIPTitle]]
								  action:nil
						   keyEquivalent:@""] setEnabled:NO];
			if ([[details objectForKey:@"ipv4addresses"] count] && [[details objectForKey:@"ipv6addresses"] count]) {
				[[extraMenu addItemWithTitle:[NSString stringWithFormat:kMenuDoubleIndentFormat, [localizedStrings objectForKey:kIPv4Title]]
									  action:nil
							   keyEquivalent:@""] setEnabled:NO];
				NSEnumerator *addressEnum = [[details objectForKey:@"ipv4addresses"] objectEnumerator];
				NSString *address = nil;
				while ((address = [addressEnum nextObject])) {
					[[extraMenu addItemWithTitle:[NSString stringWithFormat:kMenuTripleIndentFormat, address]
										  action:nil
								   keyEquivalent:@""] setEnabled:NO];
				}
				[[extraMenu addItemWithTitle:[NSString stringWithFormat:kMenuDoubleIndentFormat, [localizedStrings objectForKey:kIPv6Title]]
									  action:nil
							   keyEquivalent:@""] setEnabled:NO];
				addressEnum = [[details objectForKey:@"ipv6addresses"] objectEnumerator];
				while ((address = [addressEnum nextObject])) {
					[[extraMenu addItemWithTitle:[NSString stringWithFormat:kMenuTripleIndentFormat, address]
										  action:nil
								   keyEquivalent:@""] setEnabled:NO];
				}
			}
			else if ([[details objectForKey:@"ipv4addresses"] count]) {
				NSEnumerator *addressEnum = [[details objectForKey:@"ipv4addresses"] objectEnumerator];
				NSString *address = nil;
				while ((address = [addressEnum nextObject])) {
					[[extraMenu addItemWithTitle:[NSString stringWithFormat:kMenuDoubleIndentFormat, address]
										  action:nil
								   keyEquivalent:@""] setEnabled:NO];
				}
			}
			else {
				[[extraMenu addItemWithTitle:[NSString stringWithFormat:kMenuDoubleIndentFormat,
											  [localizedStrings objectForKey:kTCPIPInactiveTitle]]
									  action:nil
							   keyEquivalent:@""] setEnabled:NO];
			}
			// AppleTalk
			if ([details objectForKey:@"appletalknetid"]) {
				[[extraMenu addItemWithTitle:[NSString stringWithFormat:kMenuIndentFormat,
											  [localizedStrings objectForKey:kAppleTalkTitle]]
									  action:nil
							   keyEquivalent:@""] setEnabled:NO];
				[[extraMenu addItemWithTitle:[NSString stringWithFormat:kMenuDoubleIndentFormat,
											  [NSString stringWithFormat:[localizedStrings objectForKey:kAppleTalkFormat],
											   [details objectForKey:@"appletalknetid"],
											   [details objectForKey:@"appletalknodeid"],
											   [details objectForKey:@"appletalkzone"]]]
									  action:nil
							   keyEquivalent:@""] setEnabled:NO];
			}
			// Throughput
			NSNumber *sampleIntervalNum = [netHistoryIntervals lastObject];
			NSDictionary *throughputDetails = nil;
			NSString *throughputInterface = nil;
			// Do some dancing to make sure to get serial and VPN PPP interfaces, but not PPPoE
			if ([netHistoryData lastObject] && ([details objectForKey:@"devicename"] || [details objectForKey:@"devicepppname"])) {
				if ([details objectForKey:@"devicepppname"] && ![[details objectForKey:@"devicename"] hasPrefix:@"en"]) {
					throughputInterface = [details objectForKey:@"devicepppname"];
					throughputDetails = [[netHistoryData lastObject] objectForKey:[details objectForKey:@"devicepppname"]];
				}
				else {
					throughputInterface = [details objectForKey:@"devicename"];
					throughputDetails = [[netHistoryData lastObject] objectForKey:[details objectForKey:@"devicename"]];
				}
			}
			// Do we have throughput info on an active interface?
			if (isActiveInterface && sampleIntervalNum && throughputInterface && throughputDetails) {
				NSNumber *throughputOutNumber = [throughputDetails objectForKey:@"deltaout"];
				NSNumber *throughputInNumber = [throughputDetails objectForKey:@"deltain"];
				if (throughputOutNumber && throughputInNumber) {
					[[extraMenu addItemWithTitle:[NSString stringWithFormat:kMenuIndentFormat, [localizedStrings objectForKey:kThroughputTitle]]
										  action:nil
								   keyEquivalent:@""] setEnabled:NO];
					NSMenuItem *throughputItem = [extraMenu addItemWithTitle:[NSString stringWithFormat:kMenuDoubleIndentFormat,
																			  [NSString stringWithFormat:@"%@ %@",
																			   [localizedStrings objectForKey:kTxLabel],
																			   [self throughputStringForBytes:[throughputOutNumber doubleValue]
																								   inInterval:[sampleIntervalNum doubleValue]]]]
																	  action:nil
															   keyEquivalent:@""];
					[throughputItem setEnabled:NO];
					[interfaceUpdateMenuItems setObject:throughputItem forKey:@"deltaoutitem"];
					throughputItem = [extraMenu addItemWithTitle:[NSString stringWithFormat:kMenuDoubleIndentFormat,
																  [NSString stringWithFormat:@"%@ %@",
																   [localizedStrings objectForKey:kRxLabel],
																   [self throughputStringForBytes:[throughputInNumber doubleValue]
																					   inInterval:[sampleIntervalNum doubleValue]]]]
														  action:nil
												   keyEquivalent:@""];
					[throughputItem setEnabled:NO];
					[interfaceUpdateMenuItems setObject:throughputItem forKey:@"deltainitem"];
				}
				// Add peak throughput
				NSNumber *peakNumber = [throughputDetails objectForKey:@"peak"];
				if (peakNumber) {
					[[extraMenu addItemWithTitle:[NSString stringWithFormat:kMenuIndentFormat, [localizedStrings objectForKey:kPeakThroughputTitle]]
										  action:nil
								   keyEquivalent:@""] setEnabled:NO];
					NSMenuItem *peakItem = [extraMenu addItemWithTitle:[NSString stringWithFormat:kMenuDoubleIndentFormat,
																		[self throughputStringForBytesPerSecond:[peakNumber doubleValue]]]
																action:nil
														 keyEquivalent:@""];
					[peakItem setEnabled:NO];
					[interfaceUpdateMenuItems setObject:peakItem forKey:@"peakitem"];
				}
				// Add traffic totals
				throughputOutNumber = [throughputDetails objectForKey:@"totalout"];
				throughputInNumber = [throughputDetails objectForKey:@"totalin"];
				if (throughputOutNumber && throughputInNumber) {
					[[extraMenu addItemWithTitle:[NSString stringWithFormat:kMenuIndentFormat, [localizedStrings objectForKey:kTrafficTotalTitle]]
										  action:nil
								   keyEquivalent:@""] setEnabled:NO];
					NSMenuItem *totalItem = [extraMenu addItemWithTitle:[NSString stringWithFormat:kMenuDoubleIndentFormat,
																		 [self trafficStringForNumber:throughputOutNumber
																							withLabel:[localizedStrings objectForKey:kTxLabel]]]
																 action:nil
														  keyEquivalent:@""];
					[totalItem setEnabled:NO];
					[interfaceUpdateMenuItems setObject:totalItem forKey:@"totaloutitem"];
					totalItem = [extraMenu addItemWithTitle:[NSString stringWithFormat:kMenuDoubleIndentFormat,
															 [self trafficStringForNumber:throughputInNumber
																				withLabel:[localizedStrings objectForKey:kRxLabel]]]
													 action:nil
											  keyEquivalent:@""];
					[totalItem setEnabled:NO];
					[interfaceUpdateMenuItems setObject:totalItem forKey:@"totalinitem"];
				}
				// Store the name to use in throughput reads for items we will update later
				[interfaceUpdateMenuItems setObject:throughputInterface forKey:@"throughinterface"];
			}

			// Store the update items we built for this interface if needed
			if ([interfaceUpdateMenuItems count]) {
				[updateMenuItems setObject:interfaceUpdateMenuItems forKey:[details objectForKey:@"service"]];
			}

			// Now set up the submenu for this interface
			NSMenu *interfaceSubmenu = [[NSMenu alloc] initWithTitle:@""];
			// Disable menu autoenabling
			[interfaceSubmenu setAutoenablesItems:NO];
			// Add the submenu
			[titleItem setSubmenu:interfaceSubmenu];
			// PPP controller if needed and we can control the connection type on this OS version
			if ([details objectForKey:@"pppstatus"]) {
				NSMenuItem *pppControlItem = nil;
				switch ([(NSNumber *)[[details objectForKey:@"pppstatus"] objectForKey:@"status"] unsignedIntValue]) {
					case PPP_IDLE:
						pppControlItem = [interfaceSubmenu addItemWithTitle:[localizedStrings objectForKey:kPPPConnectTitle]
																	 action:@selector(pppConnect:)
															  keyEquivalent:@""];
						break;
					case PPP_INITIALIZE:
					case PPP_CONNECTLINK:
					case PPP_STATERESERVED:
					case PPP_ESTABLISH:
					case PPP_AUTHENTICATE:
					case PPP_CALLBACK:
					case PPP_NETWORK:
					case PPP_HOLDOFF:
					case PPP_ONHOLD:
					case PPP_WAITONBUSY:
					case PPP_RUNNING:
						pppControlItem = [interfaceSubmenu addItemWithTitle:[localizedStrings objectForKey:kPPPDisconnectTitle]
																	 action:@selector(pppDisconnect:)
															  keyEquivalent:@""];
						break;
					case PPP_TERMINATE:
					case PPP_DISCONNECTLINK:
						pppControlItem = [interfaceSubmenu addItemWithTitle:[localizedStrings objectForKey:kPPPConnectTitle]
																	 action:@selector(pppConnect:)
															  keyEquivalent:@""];
						break;
				};
				[pppControlItem setTarget:self];
				[pppControlItem setRepresentedObject:[details objectForKey:@"service"]];
				[interfaceSubmenu addItem:[NSMenuItem separatorItem]];
			}

			// Add interface selection submenus
			BOOL hadInterfaceSelector = NO;
			if ([[details objectForKey:@"primary"] boolValue]) {
				NSMenuItem *primarySwitchItem = [interfaceSubmenu addItemWithTitle:[localizedStrings objectForKey:kSelectPrimaryInterfaceTitle]
																			action:@selector(switchDisplay:)
																	 keyEquivalent:@""];
				[primarySwitchItem setRepresentedObject:kNetPrimaryInterface];
				[primarySwitchItem setTarget:self];
				if ([[ourPrefs netPreferInterface] isEqualToString:kNetPrimaryInterface]) {
					[primarySwitchItem setEnabled:NO];
				}
				else {
					[primarySwitchItem setEnabled:YES];
				}
				hadInterfaceSelector = YES;
			}

			// Other choose interface
			if ([details objectForKey:@"devicename"]) {
				NSMenuItem *interfaceSwitchItem = [interfaceSubmenu addItemWithTitle:[localizedStrings objectForKey:kSelectInterfaceTitle]
																			  action:@selector(switchDisplay:)
																	   keyEquivalent:@""];
				[interfaceSwitchItem setRepresentedObject:[details objectForKey:@"devicename"]];
				[interfaceSwitchItem setTarget:self];
				// Disable if this is preferred
				if ([[details objectForKey:@"devicename"] isEqualToString:[ourPrefs netPreferInterface]]) {
					[interfaceSwitchItem setEnabled:NO];
				}
				hadInterfaceSelector = YES;
			}

			if (hadInterfaceSelector) {
				[interfaceSubmenu addItem:[NSMenuItem separatorItem]];
			}

			// Checkmark the interface menu if we haven't found one already
			if ([[ourPrefs netPreferInterface] isEqualToString:kNetPrimaryInterface] && [[details objectForKey:@"primary"] boolValue]) {
				// This is the primary and the primary is preferred
				[titleItem setState:NSOnState];
			}
			else if (preferredInterfaceConfig && [details objectForKey:@"devicename"]) {
				// Is this device the one being graphed?
				if ([[details objectForKey:@"devicename"] isEqualToString:[preferredInterfaceConfig objectForKey:@"name"]] ||
					[[details objectForKey:@"devicename"] isEqualToString:[preferredInterfaceConfig objectForKey:@"statname"]]) {
					[titleItem setState:NSOnState];
				}
			}
			else if (preferredInterfaceConfig && [details objectForKey:@"devicepppname"]) {
				if ([[details objectForKey:@"devicepppname"] isEqualToString:[preferredInterfaceConfig objectForKey:@"name"]] ||
					[[details objectForKey:@"devicepppname"] isEqualToString:[preferredInterfaceConfig objectForKey:@"statname"]]) {
					[titleItem setState:NSOnState];
				}
			}

			// Copy IP
			NSMenuItem *copyIPItem = [interfaceSubmenu addItemWithTitle:[localizedStrings objectForKey:kCopyIPv4Title]
																 action:@selector(copyAddress:)
														  keyEquivalent:@""];
			[copyIPItem setTarget:self];
			if ([[details objectForKey:@"ipv4addresses"] count]) {
				[copyIPItem setRepresentedObject:[details objectForKey:@"ipv4addresses"]];
			}
			else {
				[copyIPItem setEnabled:NO];
			}
			if ([[details objectForKey:@"ipv6addresses"] count]) {
				copyIPItem = [interfaceSubmenu addItemWithTitle:[localizedStrings objectForKey:kCopyIPv6Title]
														 action:@selector(copyAddress:)
												  keyEquivalent:@""];
				[copyIPItem setTarget:self];
				if ([[details objectForKey:@"ipv6addresses"] count]) {
					[copyIPItem setRepresentedObject:[details objectForKey:@"ipv6addresses"]];
				}
				else {
					[copyIPItem setEnabled:NO];
				}
			}
			if ([details objectForKey:@"devicename"]) {
				NSMenuItem *resetTotals = [interfaceSubmenu addItemWithTitle:[localizedStrings objectForKey:kResetTrafficTotalsTitle]
																	  action:@selector(resetTotals:)
															   keyEquivalent:@""];
				[resetTotals setTarget:self];
				[resetTotals setRepresentedObject:[details objectForKey:@"devicename"]];
			}
		}
	}
	else {
		[[extraMenu addItemWithTitle:[localizedStrings objectForKey:kNoInterfaceErrorMessage]
							  action:nil
					   keyEquivalent:@""] setEnabled:NO];
	}

	// Add utility items
	[extraMenu addItem:[NSMenuItem separatorItem]];
	[[extraMenu addItemWithTitle:[localizedStrings objectForKey:kOpenNetworkUtilityTitle]
						  action:@selector(openNetworkUtil:)
				   keyEquivalent:@""] setTarget:self];
	[[extraMenu addItemWithTitle:[localizedStrings objectForKey:kOpenNetworkPrefsTitle]
						  action:@selector(openNetworkPrefs:)
				   keyEquivalent:@""] setTarget:self];
	// Open Internet Connect if PPP
	if (pppPresent) {
		[[extraMenu addItemWithTitle:[localizedStrings objectForKey:kOpenInternetConnectTitle]
							  action:@selector(openInternetConnect:)
					   keyEquivalent:@""] setTarget:self];
	}
	[self addStandardMenuEntriesTo:extraMenu];

	// Send the menu back to SystemUIServer
	return extraMenu;

} // menu

///////////////////////////////////////////////////////////////
//
//  Image renderers
//
///////////////////////////////////////////////////////////////

- (void)renderGraphImageSize:(NSSize)imageSize {

	// Cache style and other values for duration of this method
	int graphStyle = [ourPrefs netGraphStyle];
	BOOL rxOnTop = ([ourPrefs netDisplayOrientation] == kNetDisplayOrientRxTx) ? YES : NO;
	float graphHeight = (float)floor((imageSize.height - 1) / 2);

	// Graph paths
	NSBezierPath *topPath = [NSBezierPath bezierPath];
	NSBezierPath *bottomPath = [NSBezierPath bezierPath];
	if ((graphStyle == kNetGraphStyleOpposed) || (graphStyle == kNetGraphStyleInverseOpposed)) {
		[bottomPath moveToPoint:NSMakePoint(0, 0)];
		[bottomPath lineToPoint:NSMakePoint(0, 0.5)];
		[topPath moveToPoint:NSMakePoint(0, imageSize.height)];
		[topPath lineToPoint:NSMakePoint(0, imageSize.height - 0.5)];
	}
	else if (graphStyle == kNetGraphStyleCentered) {
		[topPath moveToPoint:NSMakePoint(0, graphHeight + 1)];
		[topPath lineToPoint:NSMakePoint(0, graphHeight + 1.5)];
		[bottomPath moveToPoint:NSMakePoint(0, graphHeight)];
		[bottomPath lineToPoint:NSMakePoint(0, graphHeight - 0.5)];
	}
	else {
		[topPath moveToPoint:NSMakePoint(0, graphHeight + 1)];
		[topPath lineToPoint:NSMakePoint(0, graphHeight + 1.5)];
		[bottomPath moveToPoint:NSMakePoint(0, 0)];
		[bottomPath lineToPoint:NSMakePoint(0, 0.5)];
	}

	// Get scale (scale is based on latest primary data, not historical)
	float scaleFactor = 0;
	switch ([ourPrefs netScaleMode]) {
		case kNetScaleInterfaceSpeed:
			if ([preferredInterfaceConfig objectForKey:@"speed"]) {
				scaleFactor = [[preferredInterfaceConfig objectForKey:@"speed"] floatValue] / 8; // Convert to bytes
			}
			break;
		case kNetScalePeakTraffic:
			if (![preferredInterfaceConfig objectForKey:@"statname"])
				break;
			if (![netHistoryData count])
				break;
			NSDictionary *primaryStats = [[netHistoryData objectAtIndex:0]
				objectForKey:[preferredInterfaceConfig objectForKey:@"statname"]];
			if (![primaryStats objectForKey:@"peak"])
				break;
			scaleFactor = [[primaryStats objectForKey:@"peak"] floatValue];
			break;
	}
	if (scaleFactor > 0) {
		switch ([ourPrefs netScaleCalc]) {
			case kNetScaleCalcLinear:
				// Nothing
				break;
			case kNetScaleCalcSquareRoot:
				scaleFactor = sqrtf(scaleFactor);
				break;
			case kNetScaleCalcCubeRoot:
				scaleFactor = cbrtf(scaleFactor);
				break;
			case kNetScaleCalcLog:
				scaleFactor = logf(scaleFactor);
				break;
		}
	}

	// Loop over pixels in desired width until we're out of data
	int renderPosition = 0;
	float renderHeight = graphHeight - 0.5; // Save room for baseline
	for (renderPosition = 0; renderPosition < [ourPrefs netGraphLength]; renderPosition++) {
		// No data at this position?
		if ((renderPosition >= [netHistoryData count]) ||
			(renderPosition >= [netHistoryIntervals count]))
			break;

		// Can't scale by zero
		if (scaleFactor <= 0)
			continue;

		// Grab history data
		NSDictionary *netHistoryEntry = [netHistoryData objectAtIndex:renderPosition];
		if (!netHistoryData)
			continue;
		float sampleInterval = [[netHistoryIntervals objectAtIndex:renderPosition] floatValue];
		if (sampleInterval <= 0)
			continue;

		// Grab stats for the primary
		if (![preferredInterfaceConfig objectForKey:@"statname"])
			continue;
		NSDictionary *primaryStats = [netHistoryEntry objectForKey:[preferredInterfaceConfig objectForKey:@"statname"]];
		if (!primaryStats)
			continue;

		// Calc scaled values
		float txValue = [[primaryStats objectForKey:@"deltaout"] floatValue] / sampleInterval;
		float rxValue = [[primaryStats objectForKey:@"deltain"] floatValue] / sampleInterval;
		switch ([ourPrefs netScaleCalc]) {
			case kNetScaleCalcLinear:
				txValue = txValue / scaleFactor;
				rxValue = rxValue / scaleFactor;
				break;
			case kNetScaleCalcSquareRoot:
				txValue = sqrtf(txValue) / scaleFactor;
				rxValue = sqrtf(rxValue) / scaleFactor;
				break;
			case kNetScaleCalcCubeRoot:
				txValue = cbrtf(txValue) / scaleFactor;
				rxValue = cbrtf(rxValue) / scaleFactor;
				break;
			case kNetScaleCalcLog:
				txValue = logf(txValue) / scaleFactor;
				rxValue = logf(rxValue) / scaleFactor;
				break;
		}
		// Bound
		if (txValue > 1) {
			txValue = 1;
		}
		if (rxValue > 1) {
			rxValue = 1;
		}
		if (txValue < 0) {
			txValue = 0;
		}
		if (rxValue < 0) {
			rxValue = 0;
		}

		// Update paths
		if (graphStyle == kNetGraphStyleInverseOpposed) {
			if (rxOnTop) {
				[topPath lineToPoint:NSMakePoint(renderPosition, imageSize.height - (rxValue * renderHeight) - 0.5)];
				[bottomPath lineToPoint:NSMakePoint(renderPosition, (txValue * renderHeight) + 0.5)];
			}
			else {
				[topPath lineToPoint:NSMakePoint(renderPosition, imageSize.height - (txValue * renderHeight) - 0.5)];
				[bottomPath lineToPoint:NSMakePoint(renderPosition, (rxValue * renderHeight) + 0.5)];
			}
		}
		else if (graphStyle == kNetGraphStyleOpposed) {
			if (rxOnTop) {
				[topPath lineToPoint:NSMakePoint(renderPosition, imageSize.height - (txValue * renderHeight) - 0.5)];
				[bottomPath lineToPoint:NSMakePoint(renderPosition, (rxValue * renderHeight) + 0.5)];
			}
			else {
				[topPath lineToPoint:NSMakePoint(renderPosition, imageSize.height - (rxValue * renderHeight) - 0.5)];
				[bottomPath lineToPoint:NSMakePoint(renderPosition, (txValue * renderHeight) + 0.5)];
			}
		}
		else if (graphStyle == kNetGraphStyleCentered) {
			if (rxOnTop) {
				[topPath lineToPoint:NSMakePoint(renderPosition, (rxValue * renderHeight) + graphHeight + 1.5)];
				[bottomPath lineToPoint:NSMakePoint(renderPosition, graphHeight - (txValue * renderHeight) - 0.5)];
			}
			else {
				[topPath lineToPoint:NSMakePoint(renderPosition, (txValue * renderHeight) + graphHeight + 1.5)];
				[bottomPath lineToPoint:NSMakePoint(renderPosition, graphHeight - (rxValue * renderHeight) - 0.5)];
			}
		}
		else {
			if (rxOnTop) {
				[topPath lineToPoint:NSMakePoint(renderPosition, (rxValue * renderHeight) + graphHeight + 1.5)];
				[bottomPath lineToPoint:NSMakePoint(renderPosition, (txValue * renderHeight) + 0.5)];
			}
			else {
				[topPath lineToPoint:NSMakePoint(renderPosition, (txValue * renderHeight) + graphHeight + 1.5)];
				[bottomPath lineToPoint:NSMakePoint(renderPosition, (rxValue * renderHeight) + 0.5)];
			}
		}
	}

	// Return to lower edge (fill will close the graph)
	if ((graphStyle == kNetGraphStyleOpposed) || (graphStyle == kNetGraphStyleInverseOpposed)) {
		[topPath lineToPoint:NSMakePoint(renderPosition - 1, imageSize.height - 0.5)];
		[topPath lineToPoint:NSMakePoint(renderPosition - 1, imageSize.height)];
		[bottomPath lineToPoint:NSMakePoint(renderPosition - 1, 0.5)];
		[bottomPath lineToPoint:NSMakePoint(renderPosition - 1, 0)];
	}
	else if (graphStyle == kNetGraphStyleCentered) {
		[topPath lineToPoint:NSMakePoint(renderPosition - 1, graphHeight + 1.5)];
		[topPath lineToPoint:NSMakePoint(renderPosition - 1, graphHeight + 1)];
		[bottomPath lineToPoint:NSMakePoint(renderPosition - 1, graphHeight - 0.5)];
		[bottomPath lineToPoint:NSMakePoint(renderPosition - 1, graphHeight)];
	}
	else {
		[topPath lineToPoint:NSMakePoint(renderPosition - 1, graphHeight + 1.5)];
		[topPath lineToPoint:NSMakePoint(renderPosition - 1, graphHeight + 1)];
		[bottomPath lineToPoint:NSMakePoint(renderPosition - 1, 0.5)];
		[bottomPath lineToPoint:NSMakePoint(renderPosition - 1, 0)];
	}

	// Draw
	if (![preferredInterfaceConfig objectForKey:@"interfaceup"]) {
		[inactiveColor set];
		[topPath fill];
		[bottomPath fill];
	}
	else {
		if (rxOnTop) {
			[rxColor set];
			[topPath fill];
			[txColor set];
			[bottomPath fill];
		}
		else {
			[rxColor set];
			[bottomPath fill];
			[txColor set];
			[topPath fill];
		}
	}
} // renderGraphIntoImage

- (void)renderActivityImageSize:(NSSize)imageSize {

	// Get scale (scale is based on latest primary data, not historical)
	float scaleFactor = 0;
	switch ([ourPrefs netScaleMode]) {
		case kNetScaleInterfaceSpeed:
			if ([preferredInterfaceConfig objectForKey:@"speed"]) {
				scaleFactor = [[preferredInterfaceConfig objectForKey:@"speed"] floatValue] / 8; // Convert to bytes
			}
			break;
		case kNetScalePeakTraffic:
			if (![preferredInterfaceConfig objectForKey:@"statname"])
				break;
			if (![netHistoryData count])
				break;
			NSDictionary *primaryStats = [[netHistoryData objectAtIndex:0]
				objectForKey:[preferredInterfaceConfig objectForKey:@"statname"]];
			if (![primaryStats objectForKey:@"peak"])
				break;
			scaleFactor = [[primaryStats objectForKey:@"peak"] floatValue];
			break;
	}
	if (scaleFactor > 0) {
		switch ([ourPrefs netScaleCalc]) {
			case kNetScaleCalcLinear:
				// Nothing
				break;
			case kNetScaleCalcSquareRoot:
				scaleFactor = sqrtf(scaleFactor);
				break;
			case kNetScaleCalcCubeRoot:
				scaleFactor = cbrtf(scaleFactor);
				break;
			case kNetScaleCalcLog:
				scaleFactor = logf(scaleFactor);
				break;
		}
	}

	// Get traffic value
	float txValue = 0;
	float rxValue = 0;
	if ([preferredInterfaceConfig objectForKey:@"statname"]) {
		NSDictionary *primaryStats = [[netHistoryData lastObject] objectForKey:[preferredInterfaceConfig objectForKey:@"statname"]];
		NSNumber *sampleIntervalNum = [netHistoryIntervals lastObject];
		if (primaryStats && sampleIntervalNum && ([sampleIntervalNum floatValue] > 0) && (scaleFactor > 0)) {
			txValue = [[primaryStats objectForKey:@"deltaout"] floatValue] / [sampleIntervalNum floatValue];
			rxValue = [[primaryStats objectForKey:@"deltain"] floatValue] / [sampleIntervalNum floatValue];
			switch ([ourPrefs netScaleCalc]) {
				case kNetScaleCalcLinear:
					txValue = txValue / scaleFactor;
					rxValue = rxValue / scaleFactor;
					break;
				case kNetScaleCalcSquareRoot:
					txValue = sqrtf(txValue) / scaleFactor;
					rxValue = sqrtf(rxValue) / scaleFactor;
					break;
				case kNetScaleCalcCubeRoot:
					txValue = cbrtf(txValue) / scaleFactor;
					rxValue = cbrtf(rxValue) / scaleFactor;
					break;
				case kNetScaleCalcLog:
					txValue = logf(txValue) / scaleFactor;
					rxValue = logf(rxValue) / scaleFactor;
					break;
			}
		}
	}
	// Bound
	if (txValue > 1) {
		txValue = 1;
	}
	if (rxValue > 1) {
		rxValue = 1;
	}
	if (txValue < 0) {
		txValue = 0;
	}
	if (rxValue < 0) {
		rxValue = 0;
	}

	// Draw
	if ([[preferredInterfaceConfig objectForKey:@"interfaceup"] boolValue]) {
		if ([ourPrefs netDisplayOrientation] == kNetDisplayOrientRxTx) {
			[[rxColor colorWithAlphaComponent:rxValue] set];
			[upArrow fill];
			[rxColor set];
			[upArrow stroke];
			[[txColor colorWithAlphaComponent:txValue] set];
			[downArrow fill];
			[txColor set];
			[downArrow stroke];
		}
		else {
			[[txColor colorWithAlphaComponent:txValue] set];
			[upArrow fill];
			[txColor set];
			[upArrow stroke];
			[[rxColor colorWithAlphaComponent:rxValue] set];
			[downArrow fill];
			[rxColor set];
			[downArrow stroke];
		}
	}
	else {
		[inactiveColor set];
		[upArrow stroke];
		[downArrow stroke];
	}
} // renderActivityIntoImage

- (void)renderThroughputImageSize:(NSSize)imageSize {

	// Get the primary stats
	double txValue = 0;
	double rxValue = 0;
	BOOL interfaceUp = [[preferredInterfaceConfig objectForKey:@"interfaceup"] boolValue];
	if (interfaceUp) {
		NSDictionary *primaryStats = [[netHistoryData lastObject] objectForKey:[preferredInterfaceConfig objectForKey:@"statname"]];
		if (primaryStats) {
			txValue = [[primaryStats objectForKey:@"deltaout"] doubleValue];
			rxValue = [[primaryStats objectForKey:@"deltain"] doubleValue];
		}
	}
	if (txValue < 0) {
		txValue = 0;
	}
	if (rxValue < 0) {
		rxValue = 0;
	}

	// Construct strings
	double sampleInterval = [ourPrefs netInterval];
	NSNumber *sampleIntervalNum = [netHistoryIntervals lastObject];
	if (!sampleIntervalNum && ([sampleIntervalNum doubleValue] > 0)) {
		sampleInterval = [sampleIntervalNum doubleValue];
	}
	NSString *txString = [self throughputStringForBytes:txValue inInterval:sampleInterval];
	NSString *rxString = [self throughputStringForBytes:rxValue inInterval:sampleInterval];

	NSDictionary *attributes = @{NSFontAttributeName: throughputFont,
								 NSForegroundColorAttributeName: interfaceUp ? txColor : inactiveColor};
	NSAttributedString *renderTxString = [[NSAttributedString alloc]
		initWithString:txString
			attributes:attributes];
	attributes = @{NSFontAttributeName: throughputFont,
				   NSForegroundColorAttributeName: interfaceUp ? rxColor : inactiveColor};
	NSAttributedString *renderRxString = [[NSAttributedString alloc]
		initWithString:rxString
			attributes:attributes];
	// Draw label if needed
	if ([ourPrefs netThroughputLabel]) {
		CGFloat labelOffset = 0;
		if ([ourPrefs netDisplayMode] & kNetDisplayGraph) {
			labelOffset += [ourPrefs netGraphLength] + kNetDisplayGapWidth;
		}
		if ([ourPrefs netDisplayMode] & kNetDisplayArrows) {
			labelOffset += kNetArrowDisplayWidth + kNetDisplayGapWidth;
		}
		if (interfaceUp) {
			[throughputLabel compositeToPoint:NSMakePoint(labelOffset, 0) operation:NSCompositeSourceOver];
		}
		else {
			[inactiveThroughputLabel compositeToPoint:NSMakePoint(labelOffset, 0) operation:NSCompositeSourceOver];
		}
	}
	// No descenders, so render lower
	NSPoint rxPos;
	NSPoint txPos;
	if ([ourPrefs netDisplayOrientation] == kNetDisplayOrientRxTx) {
		rxPos = NSMakePoint((float)ceil(menuWidth - [renderRxString size].width), floor(imageSize.height / 2) - 1);
		txPos = NSMakePoint((float)ceil(menuWidth - [renderTxString size].width), tallMenuBar ? -3 : -1);
	}
	else {
		txPos = NSMakePoint((float)ceil(menuWidth - [renderTxString size].width), floor(imageSize.height / 2) - 1);
		rxPos = NSMakePoint((float)ceil(menuWidth - [renderRxString size].width), tallMenuBar ? -3 : -1);
	}
	[renderTxString drawAtPoint:txPos];
	[renderRxString drawAtPoint:rxPos];
} // renderThroughputIntoImage

///////////////////////////////////////////////////////////////
//
//  Timer callbacks
//
///////////////////////////////////////////////////////////////

- (void)timerFired:(NSTimer *)timer {
	// Get new config
	preferredInterfaceConfig = [netConfig interfaceConfigForInterfaceName:[ourPrefs netPreferInterface]];

	// Get interval for the sample
	NSTimeInterval currentSampleInterval = [ourPrefs netInterval];
	if (lastSampleDate) {
		currentSampleInterval = -[lastSampleDate timeIntervalSinceNow];
	}

	// Load new net data
	NSDictionary *netLoad = [netStats netStatsForInterval:currentSampleInterval];
	if (netLoad) { // fix for https://github.com/yujitach/MenuMeters/issues/120
		// Add to history (at least one)
		if ([ourPrefs netDisplayMode] & kNetDisplayGraph) {
			if ([netHistoryData count] >= [ourPrefs netGraphLength]) {
				[netHistoryData removeObjectsInRange:NSMakeRange(0, [netHistoryData count] - [ourPrefs netGraphLength] + 1)];
			}
			if ([netHistoryIntervals count] >= [ourPrefs netGraphLength]) {
				[netHistoryIntervals removeObjectsInRange:NSMakeRange(0, [netHistoryIntervals count] - [ourPrefs netGraphLength] + 1)];
			}
		}
		else {
			[netHistoryData removeAllObjects];
			[netHistoryIntervals removeAllObjects];
		}
		[netHistoryData addObject:netLoad];
		[netHistoryIntervals addObject:[NSNumber numberWithDouble:currentSampleInterval]];

		// Update for next sample
		lastSampleDate = [NSDate date];
	}
	// If the menu is down force it to update
	if (self.isMenuVisible) {
		[self updateMenuWhenDown];
	}

	[super timerFired:timer];
} // timerFired

- (void)updateMenuWhenDown {

	// If no menu items are currently live, do nothing
	if (!updateMenuItems)
		return;

	// Pull in latest data and iterate, updating existing menu items
	NSArray *detailsArray = [netConfig interfaceDetails];
	if (![detailsArray count])
		return;
	NSEnumerator *detailsEnum = [detailsArray objectEnumerator];
	NSDictionary *details = nil;
	while ((details = [detailsEnum nextObject])) {
		// Do we have updates?
		if (![details objectForKey:@"service"] || ![updateMenuItems objectForKey:[details objectForKey:@"service"]]) {
			continue;
		}
		NSDictionary *updateInfoForService = [updateMenuItems objectForKey:[details objectForKey:@"service"]];

		// PPP updates
		if ([updateInfoForService objectForKey:@"pppstatusitem"]) {
			NSMenuItem *pppMenuItem = [updateInfoForService objectForKey:@"pppstatusitem"];
			switch ([(NSNumber *)[[details objectForKey:@"pppstatus"] objectForKey:@"status"] unsignedIntValue]) {
				case PPP_IDLE:
					LiveUpdateMenuItemTitle(extraMenu,
											[extraMenu indexOfItem:pppMenuItem],
											[NSString stringWithFormat:kMenuDoubleIndentFormat,
											 [localizedStrings objectForKey:kPPPNoConnectTitle]]);
					break;
				case PPP_INITIALIZE:
				case PPP_CONNECTLINK:
				case PPP_STATERESERVED:
				case PPP_ESTABLISH:
				case PPP_AUTHENTICATE:
				case PPP_CALLBACK:
				case PPP_NETWORK:
				case PPP_HOLDOFF:
				case PPP_ONHOLD:
				case PPP_WAITONBUSY:
					LiveUpdateMenuItemTitle(extraMenu,
											[extraMenu indexOfItem:pppMenuItem],
											[NSString stringWithFormat:kMenuDoubleIndentFormat,
											 [localizedStrings objectForKey:kPPPConnectingTitle]]);
					break;
				case PPP_RUNNING:
					if ([[details objectForKey:@"pppstatus"] objectForKey:@"timeElapsed"]) {
						uint32_t secs = [[[details objectForKey:@"pppstatus"] objectForKey:@"timeElapsed"] unsignedIntValue];
						uint32_t hours = secs / (60 * 60);
						secs %= (60 * 60);
						uint32_t mins = secs / 60;
						secs %= 60;
						LiveUpdateMenuItemTitle(extraMenu,
												[extraMenu indexOfItem:pppMenuItem],
												[NSString stringWithFormat:kMenuDoubleIndentFormat,
												 [NSString stringWithFormat:
												  [localizedStrings objectForKey:kPPPConnectedWithTimeTitle],
												  hours, mins, secs]]);
					}
					else {
						LiveUpdateMenuItemTitle(extraMenu,
												[extraMenu indexOfItem:pppMenuItem],
												[NSString stringWithFormat:kMenuDoubleIndentFormat, kPPPConnectedTitle]);
					}
					break;
					break;
				case PPP_TERMINATE:
				case PPP_DISCONNECTLINK:
					LiveUpdateMenuItemTitle(extraMenu,
											[extraMenu indexOfItem:pppMenuItem],
											[NSString stringWithFormat:kMenuDoubleIndentFormat,
											 [localizedStrings objectForKey:kPPPDisconnectingTitle]]);
			};
		}
		// Throughput updates
		if ([updateInfoForService objectForKey:@"throughinterface"]) {
			NSNumber *sampleIntervalNum = [netHistoryIntervals lastObject];
			NSDictionary *throughputDetails = [[netHistoryData lastObject] objectForKey:[updateInfoForService objectForKey:@"throughinterface"]];
			if (throughputDetails && sampleIntervalNum) {
				// Update for this interface
				NSMenuItem *targetItem = [updateInfoForService objectForKey:@"deltaoutitem"];
				NSNumber *throughputNumber = [throughputDetails objectForKey:@"deltaout"];
				if (targetItem && throughputNumber) {
					LiveUpdateMenuItemTitle(extraMenu,
											[extraMenu indexOfItem:targetItem],
											[NSString stringWithFormat:kMenuDoubleIndentFormat,
											 [NSString stringWithFormat:@"%@ %@",
											  [localizedStrings objectForKey:kTxLabel],
											  [self throughputStringForBytes:[throughputNumber doubleValue]
																  inInterval:[sampleIntervalNum doubleValue]]]]);
				}
				targetItem = [updateInfoForService objectForKey:@"deltainitem"];
				throughputNumber = [throughputDetails objectForKey:@"deltain"];
				if (targetItem && throughputNumber) {
					LiveUpdateMenuItemTitle(extraMenu,
											[extraMenu indexOfItem:targetItem],
											[NSString stringWithFormat:kMenuDoubleIndentFormat,
											 [NSString stringWithFormat:@"%@ %@",
											  [localizedStrings objectForKey:kRxLabel],
											  [self throughputStringForBytes:[throughputNumber doubleValue]
																  inInterval:[sampleIntervalNum doubleValue]]]]);
				}
				targetItem = [updateInfoForService objectForKey:@"totaloutitem"];
				throughputNumber = [throughputDetails objectForKey:@"totalout"];
				if (targetItem && throughputNumber) {
					LiveUpdateMenuItemTitle(extraMenu,
											[extraMenu indexOfItem:targetItem],
											[NSString stringWithFormat:kMenuDoubleIndentFormat,
											 [self trafficStringForNumber:throughputNumber
																withLabel:[localizedStrings objectForKey:kTxLabel]]]);
				}
				targetItem = [updateInfoForService objectForKey:@"totalinitem"];
				throughputNumber = [throughputDetails objectForKey:@"totalin"];
				if (targetItem && throughputNumber) {
					LiveUpdateMenuItemTitle(extraMenu,
											[extraMenu indexOfItem:targetItem],
											[NSString stringWithFormat:kMenuDoubleIndentFormat,
											 [self trafficStringForNumber:throughputNumber
																withLabel:[localizedStrings objectForKey:kRxLabel]]]);
				}
				targetItem = [updateInfoForService objectForKey:@"peakitem"];
				throughputNumber = [throughputDetails objectForKey:@"peak"];
				if (targetItem && throughputNumber) {
					LiveUpdateMenuItemTitle(extraMenu,
											[extraMenu indexOfItem:targetItem],
											[NSString stringWithFormat:kMenuDoubleIndentFormat,
											 [self throughputStringForBytesPerSecond:[throughputNumber doubleValue]]]);
				}
			}
		}
	} // end details loop

	// Force the menu to redraw
	LiveUpdateMenu(extraMenu);

} // updateMenuWhenDown

///////////////////////////////////////////////////////////////
//
//  Menu actions
//
///////////////////////////////////////////////////////////////

- (void)openNetworkUtil:(id)sender {

	if (![[NSWorkspace sharedWorkspace] launchApplication:@"Network Utility.app"]) {
		NSLog(@"MenuMeterNet unable to launch the Network Utility.");
	}

} // openNetworkUtil

- (void)openNetworkPrefs:(id)sender {

	if (![[NSWorkspace sharedWorkspace] openFile:@"/System/Library/PreferencePanes/Network.prefPane"]) {
		NSLog(@"MenuMeterNet unable to launch the Network Preferences.");
	}

} // openNetworkPrefs

- (void)openInternetConnect:(id)sender {

	if (![[NSWorkspace sharedWorkspace] launchApplication:@"Internet Connect.app"]) {
		NSLog(@"MenuMeterNet unable to launch the Internet Connect application.");
	}

} // openInternetConnect

- (void)resetTotals:(id)sender {
	NSString *interfaceName = [sender representedObject];
	if (!interfaceName)
		return;
	[netStats resetTotalsForInterfaceName:interfaceName];
}

- (void)switchDisplay:(id)sender {

	NSString *interfaceName = [sender representedObject];
	if (!interfaceName)
		return;

	// Sanity the name
	NSDictionary *newConfig = [netConfig interfaceConfigForInterfaceName:interfaceName];
	if (!newConfig)
		return;
	preferredInterfaceConfig = newConfig;

	// Update prefs
	[ourPrefs saveNetPreferInterface:interfaceName];
	// Send the notification to the pref pane
	[[NSNotificationCenter defaultCenter] postNotificationName:kPrefPaneBundleID
														object:kPrefChangeNotification];

} // switchDisplay

- (void)copyAddress:(id)sender {

	if ([[sender representedObject] count]) {
		[[NSPasteboard generalPasteboard] declareTypes:[NSArray arrayWithObjects:NSStringPboardType, nil]
												 owner:nil];
		NSString *clipContent = [[sender representedObject] componentsJoinedByString:@", "];
		[[NSPasteboard generalPasteboard] setString:clipContent forType:NSStringPboardType];
	}
	else {
		NSLog(@"MenuMeterNet unable to copy IP addresses to clipboard.");
	}

} // copyAddress

- (void)pppConnect:(id)sender {

	if ([sender representedObject]) {
		// SC connection
		SCNetworkConnectionRef connection = SCNetworkConnectionCreateWithServiceID(
																				   kCFAllocatorDefault,
																				   (CFStringRef)[sender representedObject],
																				   NULL,
																				   NULL);

		// Undoc preference values
		CFArrayRef connectionOptionList = CFPreferencesCopyValue((CFStringRef)[sender representedObject],
																 kAppleNetworkConnectDefaultsDomain,
																 kCFPreferencesCurrentUser,
																 kCFPreferencesCurrentHost);
		if (connection) {
			if (connectionOptionList && CFArrayGetCount(connectionOptionList)) {
				SCNetworkConnectionStart(connection, CFArrayGetValueAtIndex(connectionOptionList, 0), TRUE);
			}
			else {
				SCNetworkConnectionStart(connection, NULL, TRUE);
			}
		}
		if (connection)
			CFRelease(connection);
		if (connectionOptionList)
			CFRelease(connectionOptionList);
	}

} // pppConnect

- (void)pppDisconnect:(id)sender {

	if ([sender representedObject]) {
		SCNetworkConnectionRef connection = SCNetworkConnectionCreateWithServiceID(
			kCFAllocatorDefault,
			(CFStringRef)[sender representedObject],
			NULL,
			NULL);
		if (connection) {
			SCNetworkConnectionStop(connection, TRUE);
			CFRelease(connection);
		}
	}

} // pppDisconnect

///////////////////////////////////////////////////////////////
//
//  Pref routines
//
///////////////////////////////////////////////////////////////

- (void)configFromPrefs:(NSNotification *)notification {
#ifdef ELCAPITAN
	[super configDisplay:kNetMenuBundleID
			   fromPrefs:ourPrefs
	   withTimerInterval:[ourPrefs netInterval]];
#endif

	// Cache colors to skip archiver
	txColor = [self colorByAdjustingForLightDark:[ourPrefs netTransmitColor]];
	rxColor = [self colorByAdjustingForLightDark:[ourPrefs netReceiveColor]];
	inactiveColor = [self colorByAdjustingForLightDark:[ourPrefs netInactiveColor]];

	// Generate arrow bezier path offset as needed for current display mode
	float arrowOffset = 0;
	float viewHeight = self.height;
	if ([ourPrefs netDisplayMode] & kNetDisplayGraph) {
		arrowOffset = [ourPrefs netGraphLength] + kNetDisplayGapWidth;
	}
	NSBezierPath *arrow = [NSBezierPath bezierPath];
	[arrow moveToPoint:NSMakePoint(kNetArrowDisplayWidth / 2 + 0.5, tallMenuBar ? 0.5 : 2.5)];
	[arrow lineToPoint:NSMakePoint(0.5, tallMenuBar ? 5.5 : 6.5)];
	[arrow lineToPoint:NSMakePoint(2.5, tallMenuBar ? 5.5 : 6.5)];
	[arrow lineToPoint:NSMakePoint(2.5, tallMenuBar ? 9.5 : 9.5)];
	[arrow lineToPoint:NSMakePoint(kNetArrowDisplayWidth - 2.5, tallMenuBar ? 9.5 : 9.5)];
	[arrow lineToPoint:NSMakePoint(kNetArrowDisplayWidth - 2.5, tallMenuBar ? 5.5 : 6.5)];
	[arrow lineToPoint:NSMakePoint(kNetArrowDisplayWidth - 0.5, tallMenuBar ? 5.5 : 6.5)];
	[arrow closePath];
	[arrow setLineWidth:0.8];
	upArrow = [arrow copy];
	NSAffineTransform *transform = [NSAffineTransform new];
	[transform translateXBy:arrowOffset yBy:viewHeight];
	[transform scaleXBy:1 yBy:-1];
	[upArrow transformUsingAffineTransform:transform];
	downArrow = [arrow copy];
	transform = [NSAffineTransform new];
	[transform translateXBy:arrowOffset yBy:0];
	[downArrow transformUsingAffineTransform:transform];

	// Prerender throughput labels
	NSDictionary *attributes = @{NSFontAttributeName: throughputFont,
								 NSForegroundColorAttributeName: txColor};
	NSAttributedString *renderTxString = [[NSAttributedString alloc]
		initWithString:[localizedStrings objectForKey:kTxLabel]
			attributes:attributes];
	attributes = @{NSFontAttributeName: throughputFont,
				   NSForegroundColorAttributeName: rxColor};
	NSAttributedString *renderRxString = [[NSAttributedString alloc]
		initWithString:[localizedStrings objectForKey:kRxLabel]
			attributes:attributes];

	NSSize renderTxSize = renderTxString.size;
	NSSize renderRxSize = renderRxString.size;

	NSSize throughputLabelSize;
	if (renderTxSize.width > renderRxSize.width) {
		throughputLabelSize = renderTxSize;
	}
	else {
		throughputLabelSize = renderRxSize;
	}
	NSPoint renderRxPoint;
	NSPoint renderTxPoint;
	if ([ourPrefs netDisplayOrientation] == kNetDisplayOrientRxTx) {
		renderRxPoint = NSMakePoint(0, floor(viewHeight / 2) - 2);
		renderTxPoint = NSMakePoint(0, -1);
	}
	else {
		renderTxPoint = NSMakePoint(0, floor(viewHeight / 2) - 2);
		renderRxPoint = NSMakePoint(0, -1);
	}
	throughputLabel = [NSImage imageWithSize:throughputLabelSize
									 flipped:NO
							  drawingHandler:^BOOL(NSRect dstRect) {
								  [renderRxString drawAtPoint:renderRxPoint];
								  [renderTxString drawAtPoint:renderTxPoint];
								  return YES;
							  }];
	attributes = @{NSFontAttributeName: throughputFont,
				   NSForegroundColorAttributeName: inactiveColor};
	renderTxString = [[NSAttributedString alloc]
		initWithString:[localizedStrings objectForKey:kTxLabel]
			attributes:attributes];
	renderRxString = [[NSAttributedString alloc]
		initWithString:[localizedStrings objectForKey:kRxLabel]
			attributes:attributes];
	inactiveThroughputLabel = [NSImage imageWithSize:throughputLabelSize
											 flipped:NO
									  drawingHandler:^BOOL(NSRect dstRect) {
										  [renderRxString drawAtPoint:renderRxPoint];
										  [renderTxString drawAtPoint:renderTxPoint];
										  return YES;
									  }];

	// Fix our menu view size to match our config
	menuWidth = 0;
	int displayCount = 0;
	if ([ourPrefs netDisplayMode] & kNetDisplayGraph) {
		menuWidth += [ourPrefs netGraphLength];
		displayCount++;
	}
	if ([ourPrefs netDisplayMode] & kNetDisplayArrows) {
		menuWidth += kNetArrowDisplayWidth;
		displayCount++;
	}
	if ([ourPrefs netDisplayMode] & kNetDisplayThroughput) {
		displayCount++;
		if ([ourPrefs netThroughputLabel])
			menuWidth += (float)ceil([throughputLabel size].width);
		// Deal with localizable throughput suffix
		CGFloat suffixMaxWidth = 0;

		NSDictionary *attributes = @{NSFontAttributeName: throughputFont};
		NSSize numberSize = [@"999.9\u2009" sizeWithAttributes:attributes];

		NSSize suffixSize;
		suffixSize = [kBitPerSecondLabel sizeWithAttributes:attributes];
		if (suffixSize.width > suffixMaxWidth) {
			suffixMaxWidth = suffixSize.width;
		}
		suffixSize = [kKbPerSecondLabel sizeWithAttributes:attributes];
		if (suffixSize.width > suffixMaxWidth) {
			suffixMaxWidth = suffixSize.width;
		}
		suffixSize = [kMbPerSecondLabel sizeWithAttributes:attributes];
		if (suffixSize.width > suffixMaxWidth) {
			suffixMaxWidth = suffixSize.width;
		}
		suffixSize = [kGbPerSecondLabel sizeWithAttributes:attributes];
		if (suffixSize.width > suffixMaxWidth) {
			suffixMaxWidth = suffixSize.width;
		}
		suffixMaxWidth += numberSize.width;

		menuWidth += ceil(suffixMaxWidth);
	}
	// If more than one display is present we need to add a gaps
	if (displayCount) {
		menuWidth += (displayCount - 1) * kNetDisplayGapWidth;
	}

	// Force initial update
	statusItem.button.image = self.image;
} // configFromPrefs

///////////////////////////////////////////////////////////////
//
//  Data formatting
//
///////////////////////////////////////////////////////////////

- (NSString *)throughputStringForBytes:(double)bytes inInterval:(NSTimeInterval)interval {

	if (interval <= 0)
		return nil;
	return [self throughputStringForBytesPerSecond:bytes / interval];

} // throughputStringForBytes:inInterval:

- (NSString *)throughputStringForBytesPerSecond:(double)bps {

	NSArray *labels = @[kBytePerSecondLabel, kKBPerSecondLabel, kMBPerSecondLabel, kGBPerSecondLabel];
	int kilo = kKiloBinary;

	if ([ourPrefs netThroughputBits]) {
		labels = @[kBitPerSecondLabel, kKbPerSecondLabel, kMbPerSecondLabel, kGbPerSecondLabel];
		kilo = kKiloDecimal;
		bps *= 8;
	}

	if ((bps < kilo) && [ourPrefs netThroughput1KBound]) {
		bps = 0;
	}

	NSUInteger labelIndex = [self scaleDown:&bps usingBase:kilo withLimit:[labels count] - 1];
	NSString *unitLabel = [labels objectAtIndex:labelIndex];

	NSString *format = @"%.1f";
	if (labelIndex == 0 || bps >= 1000) {
		format = @"%.0f";
	}

	format = [NSString stringWithFormat:@"%@\u2009%%@", format];

	return [self stringifyNumber:bps withUnitLabel:unitLabel andFormat:format];

} // throughputStringForBytesPerSecond:withFormat:

- (NSString *)trafficStringForNumber:(NSNumber *)throughputNumber withLabel:(NSString *)directionLabel {

	NSArray *labels = @[kByteLabel, kKBLabel, kMBLabel, kGBLabel, kTBLabel];
	double throughput = [throughputNumber doubleValue];
	int kilo = kKiloBinary;

	if ([ourPrefs netThroughputBits]) {
		labels = @[kBitLabel, kKbLabel, kMbLabel, kGbLabel, kTbLabel];
		kilo = kKiloDecimal;
		throughput *= 8;
	}

	NSUInteger labelIndex = [self scaleDown:&throughput usingBase:kilo withLimit:[labels count] - 1];
	NSString *unitLabel = [labels objectAtIndex:labelIndex];

	NSString *format = @"%.1f %@";
	if (labelIndex == 0) {
		format = @"%.0f %@";
	}

	NSString *scaledTrafficTotal = [self stringifyNumber:throughput withUnitLabel:unitLabel andFormat:format];
	NSString *unscaledTrafficTotal = [self throughputStringForBytes:throughputNumber];

	return [NSString stringWithFormat:@"%@ %@ (%@)", directionLabel, scaledTrafficTotal, unscaledTrafficTotal];

} // trafficStringForNumber:withLabel:

- (NSUInteger)scaleDown:(double *)num usingBase:(NSUInteger)base withLimit:(NSUInteger)limit {

	NSUInteger exponent = 0;

	if (base > 1) {
		for (; *num >= base && exponent < limit; exponent++) {
			*num /= base;
		}
	}

	return exponent;

} // scaleDown:usingBase:withLimit:

- (NSString *)stringifyNumber:(double)num withUnitLabel:(NSString *)label andFormat:(NSString *)format {

	return [NSString stringWithFormat:format, num, [localizedStrings objectForKey:label]];

} // stringifyNumber:withUnitLabel:andFormat:

- (NSString *)throughputStringForBytes:(NSNumber *)throughputNumber {

	double throughput = [throughputNumber doubleValue];
	NSString *unitLabel = kBytesLabel;

	if ([ourPrefs netThroughputBits]) {
		unitLabel = kBitsLabel;
		throughput *= 8;
	};

	NSString *prettyTotal = [prettyIntFormatter stringForObjectValue:[NSNumber numberWithDouble:throughput]];

	return [NSString stringWithFormat:@"%@ %@", prettyTotal, unitLabel];

} // throughputStringForBytes

@end

//
//  MenuMeterMemExtra.m
//
//	Menu Extra implementation
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

#import "MenuMeterMemExtra.h"


///////////////////////////////////////////////////////////////
//
//	Private methods
//
///////////////////////////////////////////////////////////////

@interface MenuMeterMemExtra (PrivateMethods)

// Menu generation
- (void)updateMenuContent;

// Image renderers
- (void)renderPieIntoImage:(NSImage *)image;
- (void)renderNumbersIntoImage:(NSImage *)image;
- (void)renderBarIntoImage:(NSImage *)image;
- (void)renderMemHistoryIntoImage:(NSImage *)image;
- (void)renderPageIndicatorIntoImage:(NSImage *)image;

// Timer callbacks
- (void)updateMemDisplay:(NSTimer *)timer;
- (void)updateMenuWhenDown;

// Prefs
- (void)configFromPrefs:(NSNotification *)notification;

@end

///////////////////////////////////////////////////////////////
//
//	Localized strings
//
///////////////////////////////////////////////////////////////

#define	kFreeLabel							@"F:"
#define	kUsedLabel							@"U:"
#define kUsageTitle							@"Memory Usage:"
#define kPageStatsTitle						@"Memory Pages:"
#define kVMStatsTitle						@"VM Statistics:"
#define kSwapStatsTitle						@"Swap Files:"
#define kUsageFormat						@"%@ used, %@ free, %@ total"
#define kActiveWiredFormat					@"%@ active, %@ wired"
#define kInactiveFreeFormat					@"%@ inactive, %@ free"
#define kCompressedFormat					@"%@ compressed (%@)"
#define kVMPagingFormat						@"%@ pageins, %@ pageouts"
#define kVMCacheFormat						@"%@ cache lookups, %@ cache hits (%@)"
#define kVMFaultCopyOnWriteFormat			@"%@ page faults, %@ copy-on-writes"
#define kSingleSwapFormat					@"%@ swap file present in %@"
#define kMultiSwapFormat					@"%@ swap files present in %@"
#define kSingleEncryptedSwapFormat			@"%@ encrypted swap file present in %@"
#define kMultiEncryptedSwapFormat			@"%@ encrypted swap files present in %@"
#define kMaxSingleSwapFormat				@"%@ swap file at peak usage"
#define kMaxMultiSwapFormat					@"%@ swap files at peak usage"
#define kSwapSizeFormat						@"%@ total swap space"
#define kSwapSizeUsedFormat					@"%@ total swap space (%@ used)"
#define kMBLabel							@"MB"

///////////////////////////////////////////////////////////////
//
//	init/unload/dealloc
//
///////////////////////////////////////////////////////////////

@implementation MenuMeterMemExtra

- initWithBundle:(NSBundle *)bundle {

	self = [super initWithBundle:bundle];
	if (!self) {
		return nil;
	}

	// Panther and Tiger check
	isPantherOrLater = OSIsPantherOrLater();
	isTigerOrLater = OSIsTigerOrLater();

	// Load our pref bundle, we do this as a bundle because we are a plugin
	// to SystemUIServer and as a result cannot have the same class loaded
	// from every meter. Using a shared bundle each loads fixes this.
	NSString *prefBundlePath = [[[bundle bundlePath] stringByDeletingLastPathComponent]
									stringByAppendingPathComponent:kPrefBundleName];
	ourPrefs = [[[[NSBundle bundleWithPath:prefBundlePath] principalClass] alloc] init];
	if (!ourPrefs) {
		NSLog(@"MenuMeterMem unable to connect to preferences. Abort.");
		[self release];
		return nil;
	}

	// Build our CPU statistics gatherer and history
	memStats = [[MenuMeterMemStats alloc] init];
	memHistory = [[NSMutableArray array] retain];
	if (!(memStats && memHistory)) {
		NSLog(@"MenuMeterMem unable to load data gatherer or storage. Abort.");
		[self release];
		return nil;
	}

	// Setup our menu
	extraMenu = [[NSMenu alloc] initWithTitle:@""];
	if (!extraMenu) {
		[self release];
		return nil;
	}
	// Disable menu autoenabling
	[extraMenu setAutoenablesItems:NO];

	// Setup menu content
	NSMenuItem *menuItem = nil;

	// Add memory usage menu items and placeholder
	menuItem = (NSMenuItem *)[extraMenu addItemWithTitle:[bundle localizedStringForKey:kUsageTitle value:nil table:nil]
												  action:nil
										   keyEquivalent:@""];
	[menuItem setEnabled:NO];
	menuItem = (NSMenuItem *)[extraMenu addItemWithTitle:@"" action:nil keyEquivalent:@""];
	[menuItem setEnabled:NO];

	// Add memory page stats title and placeholders
	menuItem = (NSMenuItem *)[extraMenu addItemWithTitle:[bundle localizedStringForKey:kPageStatsTitle value:nil table:nil]
												  action:nil
										   keyEquivalent:@""];
	[menuItem setEnabled:NO];
	menuItem = (NSMenuItem *)[extraMenu addItemWithTitle:@"" action:nil keyEquivalent:@""];
	[menuItem setEnabled:NO];
	menuItem = (NSMenuItem *)[extraMenu addItemWithTitle:@"" action:nil keyEquivalent:@""];
	[menuItem setEnabled:NO];
	menuItem = (NSMenuItem *)[extraMenu addItemWithTitle:@"" action:nil keyEquivalent:@""];
	[menuItem setEnabled:NO];

	// Add VM stats menu items and placeholders
	menuItem = (NSMenuItem *)[extraMenu addItemWithTitle:[bundle localizedStringForKey:kVMStatsTitle value:nil table:nil]
												  action:nil
										   keyEquivalent:@""];
	[menuItem setEnabled:NO];
	menuItem = (NSMenuItem *)[extraMenu addItemWithTitle:@"" action:nil keyEquivalent:@""];
	[menuItem setEnabled:NO];
	menuItem = (NSMenuItem *)[extraMenu addItemWithTitle:@"" action:nil keyEquivalent:@""];
	[menuItem setEnabled:NO];
	menuItem = (NSMenuItem *)[extraMenu addItemWithTitle:@"" action:nil keyEquivalent:@""];
	[menuItem setEnabled:NO];

	// Swap file stats menu item and placeholders
	menuItem = (NSMenuItem *)[extraMenu addItemWithTitle:[bundle localizedStringForKey:kSwapStatsTitle value:nil table:nil]
												  action:nil
										   keyEquivalent:@""];
	[menuItem setEnabled:NO];
	menuItem = (NSMenuItem *)[extraMenu addItemWithTitle:@"" action:nil keyEquivalent:@""];
	[menuItem setEnabled:NO];
	menuItem = (NSMenuItem *)[extraMenu addItemWithTitle:@"" action:nil keyEquivalent:@""];
	[menuItem setEnabled:NO];
	menuItem = (NSMenuItem *)[extraMenu addItemWithTitle:@"" action:nil keyEquivalent:@""];
	[menuItem setEnabled:NO];

	// Get our view
    extraView = [[MenuMeterMemView alloc] initWithFrame:[[self view] frame] menuExtra:self];
	if (!extraView) {
		[self release];
		return nil;
	}
    [self setView:extraView];

	// Load localized strings
	localizedStrings = [[NSDictionary dictionaryWithObjectsAndKeys:
							[[NSBundle bundleForClass:[self class]] localizedStringForKey:kUsageFormat value:nil table:nil],
							kUsageFormat,
							[[NSBundle bundleForClass:[self class]] localizedStringForKey:kActiveWiredFormat value:nil table:nil],
							kActiveWiredFormat,
							[[NSBundle bundleForClass:[self class]] localizedStringForKey:kInactiveFreeFormat value:nil table:nil],
							kInactiveFreeFormat,
							[[NSBundle bundleForClass:[self class]] localizedStringForKey:kCompressedFormat value:nil table:nil],
							kCompressedFormat,
							[[NSBundle bundleForClass:[self class]] localizedStringForKey:kVMPagingFormat value:nil table:nil],
							kVMPagingFormat,
							[[NSBundle bundleForClass:[self class]] localizedStringForKey:kVMCacheFormat value:nil table:nil],
							kVMCacheFormat,
							[[NSBundle bundleForClass:[self class]] localizedStringForKey:kVMFaultCopyOnWriteFormat value:nil table:nil],
							kVMFaultCopyOnWriteFormat,
							[[NSBundle bundleForClass:[self class]] localizedStringForKey:kSingleSwapFormat value:nil table:nil],
							kSingleSwapFormat,
							[[NSBundle bundleForClass:[self class]] localizedStringForKey:kMultiSwapFormat value:nil table:nil],
							kMultiSwapFormat,
							[[NSBundle bundleForClass:[self class]] localizedStringForKey:kMaxSingleSwapFormat value:nil table:nil],
							kMaxSingleSwapFormat,
							[[NSBundle bundleForClass:[self class]] localizedStringForKey:kMaxMultiSwapFormat value:nil table:nil],
							kMaxMultiSwapFormat,
							[[NSBundle bundleForClass:[self class]] localizedStringForKey:kSingleEncryptedSwapFormat value:nil table:nil],
							kSingleEncryptedSwapFormat,
							[[NSBundle bundleForClass:[self class]] localizedStringForKey:kMultiEncryptedSwapFormat value:nil table:nil],
							kMultiEncryptedSwapFormat,
							[[NSBundle bundleForClass:[self class]] localizedStringForKey:kSwapSizeFormat value:nil table:nil],
							kSwapSizeFormat,
							[[NSBundle bundleForClass:[self class]] localizedStringForKey:kSwapSizeUsedFormat value:nil table:nil],
							kSwapSizeUsedFormat,
							[[NSBundle bundleForClass:[self class]] localizedStringForKey:kMBLabel value:nil table:nil],
							kMBLabel,
							nil] retain];
	if (!localizedStrings) {
		[self release];
		return nil;
	}

	// Set up a NumberFormatter for localization. This is based on code contributed by Mike Fischer
	// (mike.fischer at fi-works.de) for use in MenuMeters.
	NSNumberFormatter *tempFormat = [[[NSNumberFormatter alloc] init] autorelease];
	[tempFormat setLocalizesFormat:YES];
	[tempFormat setFormat:[NSString stringWithFormat:@"#,##0.0%@", [localizedStrings objectForKey:kMBLabel]]];
	// Go through an archive/unarchive cycle to work around a bug on pre-10.2.2 systems
	// see http://cocoa.mamasam.com/COCOADEV/2001/12/2/21029.php
	memFloatMBFormatter = [[NSUnarchiver unarchiveObjectWithData:[NSArchiver archivedDataWithRootObject:tempFormat]] retain];
	[tempFormat setFormat:[NSString stringWithFormat:@"#,##0%@", [localizedStrings objectForKey:kMBLabel]]];
	memIntMBFormatter = [[NSUnarchiver unarchiveObjectWithData:[NSArchiver archivedDataWithRootObject:tempFormat]] retain];
	[tempFormat setFormat:@"#,##0"];
	prettyIntFormatter = [[NSUnarchiver unarchiveObjectWithData:[NSArchiver archivedDataWithRootObject:tempFormat]] retain];
	[tempFormat setFormat:@"##0.0%"];
	percentFormatter = [[NSUnarchiver unarchiveObjectWithData:[NSArchiver archivedDataWithRootObject:tempFormat]] retain];
	if (!(memFloatMBFormatter && memIntMBFormatter && prettyIntFormatter && percentFormatter)) {
		[self release];
		return nil;
	}

	// Register for pref changes
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self
														selector:@selector(configFromPrefs:)
															name:kMemMenuBundleID
														  object:kPrefChangeNotification];
	// Register for 10.10 theme changes
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self
														selector:@selector(configFromPrefs:)
															name:kAppleInterfaceThemeChangedNotification
														  object:nil];

	// And configure directly from prefs on first load
	[self configFromPrefs:nil];

	// Fake a timer call to config initial values
	[self updateMemDisplay:nil];

    // And hand ourself back to SystemUIServer
	NSLog(@"MenuMeterMem loaded.");
    return self;

} // initWithBundle

- (void)willUnload {

	// Stop the timer
	[updateTimer invalidate];  // Released by the runloop
	updateTimer = nil;

	// Unregister pref change notifications
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self
															   name:nil
															 object:nil];

	// Let the pref panel know we have been removed
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:kMemMenuBundleID
																   object:kMemMenuUnloadNotification];

	// Let super do the rest
    [super willUnload];

} // willUnload

- (void)dealloc {

	// Release the view and menu
	[extraView release];
    [extraMenu release];
	[updateTimer invalidate];  // Released by the runloop
	[ourPrefs release];
	[memStats release];
	[localizedStrings release];
	[memFloatMBFormatter release];
	[memIntMBFormatter release];
	[prettyIntFormatter release];
	[percentFormatter release];
	[freeColor release];
	[usedColor release];
	[activeColor release];
	[inactiveColor release];
	[wireColor release];
	[compressedColor release];
	[pageInColor release];
	[pageOutColor release];
	[numberLabelPrerender release];
	[memHistory release];
	[currentSwapStats release];
	[fgMenuThemeColor release];
	[super dealloc];

} // dealloc

///////////////////////////////////////////////////////////////
//
//	NSMenuExtra view callbacks
//
///////////////////////////////////////////////////////////////

- (NSImage *)image {

	// Image to render into (and return to view)
	NSImage *currentImage = [[[NSImage alloc] initWithSize:NSMakeSize(menuWidth,
																	  [extraView frame].size.height - 1)] autorelease];

	// Don't render without data
	if (![memHistory count]) return nil;

	switch ([ourPrefs memDisplayMode]) {
		case kMemDisplayPie:
			[self renderPieIntoImage:currentImage];
			break;
		case kMemDisplayNumber:
			[self renderNumbersIntoImage:currentImage];
			break;
		case kMemDisplayBar:
			[self renderBarIntoImage:currentImage];
			break;
		case kMemDisplayGraph:
			[self renderMemHistoryIntoImage:currentImage];
	}
	if ([ourPrefs memPageIndicator]) {
		[self renderPageIndicatorIntoImage:currentImage];
	}

	// Send it back for the view to render
	return currentImage;

} // image

- (NSMenu *)menu {

	// Since we want the menu and view to match data we update the data now
	// (menu is called before image for view)
	NSDictionary *currentStats = [memStats memStats];
	if (currentStats) {
		if ([ourPrefs memDisplayMode] == kMemDisplayGraph) {
			if ([memHistory count] >= [ourPrefs memGraphLength]) {
				[memHistory removeObjectsInRange:NSMakeRange(0, [memHistory count] - [ourPrefs memGraphLength] + 1)];
			}
		} else {
			[memHistory removeAllObjects];
		}
		[memHistory addObject:currentStats];
	}
	NSDictionary *newSwapStats = [memStats swapStats];
	if (newSwapStats) {
		[currentSwapStats release];
		currentSwapStats = [newSwapStats retain];
	}

	// Update the menu content
	[self updateMenuContent];

	// Send the menu back to SystemUIServer
	return extraMenu;

} // menu

///////////////////////////////////////////////////////////////
//
//	Menu generation
//
///////////////////////////////////////////////////////////////

// This code is split out (unlike all the other meters) to deal
// with the special case. The memory meter is set to update slowly
// so we have its menu method pull new data when rendering. This prevents
// the menu from having obviously stale data when the update interval is
// long. However, by doing it this way we would pull data twice per
// timer update with the menu down if the updateMenuWhenDown method
// called the menu method directly.

- (void)updateMenuContent {
	NSString		*title = nil;

	// Fetch stats
	NSDictionary *currentMemStats = [memHistory objectAtIndex:0];
	if (!(currentMemStats && currentSwapStats)) return;

	// Usage
	title = [NSString stringWithFormat:kMenuIndentFormat,
				[NSString stringWithFormat:[localizedStrings objectForKey:kUsageFormat],
					[memFloatMBFormatter stringForObjectValue:[currentMemStats objectForKey:@"usedmb"]],
					[memFloatMBFormatter stringForObjectValue:[currentMemStats objectForKey:@"freemb"]],
					[memIntMBFormatter stringForObjectValue:[currentMemStats objectForKey:@"totalmb"]]]];
	LiveUpdateMenuItemTitle(extraMenu, kMemUsageInfoMenuIndex, title);
	// Wired
	title = [NSString stringWithFormat:kMenuIndentFormat,
				[NSString stringWithFormat:[localizedStrings objectForKey:kActiveWiredFormat],
					[memFloatMBFormatter stringForObjectValue:[currentMemStats objectForKey:@"activemb"]],
					[memFloatMBFormatter stringForObjectValue:[currentMemStats objectForKey:@"wiremb"]]]];
	LiveUpdateMenuItemTitle(extraMenu, kMemActiveWiredInfoMenuIndex, title);
	// Inactive/Free
	title = [NSString stringWithFormat:kMenuIndentFormat,
				[NSString stringWithFormat:[localizedStrings objectForKey:kInactiveFreeFormat],
					[memFloatMBFormatter stringForObjectValue:[currentMemStats objectForKey:@"inactivemb"]],
					[memFloatMBFormatter stringForObjectValue:[currentMemStats objectForKey:@"freepagemb"]]]];
	LiveUpdateMenuItemTitle(extraMenu, kMemInactiveFreeInfoMenuIndex, title);
	// Compressed
	title = [NSString stringWithFormat:kMenuIndentFormat,
				[NSString stringWithFormat:[localizedStrings objectForKey:kCompressedFormat],
					[memFloatMBFormatter stringForObjectValue:[currentMemStats objectForKey:@"compressedmb"]],
					[memFloatMBFormatter stringForObjectValue:[currentMemStats objectForKey:@"uncompressedmb"]]]];
	LiveUpdateMenuItemTitle(extraMenu, kMemCompressedInfoMenuIndex, title);
	// VM paging
	title = [NSString stringWithFormat:kMenuIndentFormat,
				[NSString stringWithFormat:[localizedStrings objectForKey:kVMPagingFormat],
					[prettyIntFormatter stringForObjectValue:[currentMemStats objectForKey:@"pageins"]],
					[prettyIntFormatter stringForObjectValue:[currentMemStats objectForKey:@"pageouts"]]]];
	LiveUpdateMenuItemTitle(extraMenu, kMemVMPageInfoMenuIndex, title);
	// VM cache
	title = [NSString stringWithFormat:kMenuIndentFormat,
				[NSString stringWithFormat:[localizedStrings objectForKey:kVMCacheFormat],
					[prettyIntFormatter stringForObjectValue:[currentMemStats objectForKey:@"lookups"]],
					[prettyIntFormatter stringForObjectValue:[currentMemStats objectForKey:@"hits"]],
					[percentFormatter stringForObjectValue:
						[NSNumber numberWithDouble:
							(double)(([[currentMemStats objectForKey:@"hits"] doubleValue] /
									  [[currentMemStats objectForKey:@"lookups"] doubleValue]) * 100.0)]]]];
	LiveUpdateMenuItemTitle(extraMenu, kMemVMCacheInfoMenuIndex, title);
	// VM fault
	title = [NSString stringWithFormat:kMenuIndentFormat,
				[NSString stringWithFormat:[localizedStrings objectForKey:kVMFaultCopyOnWriteFormat],
					[prettyIntFormatter stringForObjectValue:[currentMemStats objectForKey:@"faults"]],
					[prettyIntFormatter stringForObjectValue:[currentMemStats objectForKey:@"cowfaults"]]]];
	LiveUpdateMenuItemTitle(extraMenu, kMemVMFaultInfoMenuIndex, title);
	// Swap count/path, Tiger swap encryptioninfo from Michael Nordmeyer (http://goodyworks.com)
	if (isTigerOrLater && [[currentSwapStats objectForKey:@"swapencrypted"] boolValue]) {
		title = [NSString stringWithFormat:kMenuIndentFormat,
					[NSString stringWithFormat:
						(([[currentSwapStats objectForKey:@"swapcount"] unsignedIntValue] > 1) ?
							[localizedStrings objectForKey:kMultiEncryptedSwapFormat] :
							[localizedStrings objectForKey:kSingleEncryptedSwapFormat]),
						[prettyIntFormatter stringForObjectValue:[currentSwapStats objectForKey:@"swapcount"]],
						[currentSwapStats objectForKey:@"swappath"]]];
	} else {
		title = [NSString stringWithFormat:kMenuIndentFormat,
					[NSString stringWithFormat:
						(([[currentSwapStats objectForKey:@"swapcount"] unsignedIntValue] > 1) ?
							[localizedStrings objectForKey:kMultiSwapFormat] :
							[localizedStrings objectForKey:kSingleSwapFormat]),
						[prettyIntFormatter stringForObjectValue:[currentSwapStats objectForKey:@"swapcount"]],
						[currentSwapStats objectForKey:@"swappath"]]];
	}
	LiveUpdateMenuItemTitle(extraMenu, kMemSwapCountInfoMenuIndex, title);
	// Swap max
	title = [NSString stringWithFormat:kMenuIndentFormat,
				[NSString stringWithFormat:
					(([[currentSwapStats objectForKey:@"swapcountpeak"] unsignedIntValue] > 1) ?
						[localizedStrings objectForKey:kMaxMultiSwapFormat] :
						[localizedStrings objectForKey:kMaxSingleSwapFormat]),
					[prettyIntFormatter stringForObjectValue:[currentSwapStats objectForKey:@"swapcountpeak"]]]];
	LiveUpdateMenuItemTitle(extraMenu, kMemSwapMaxCountInfoMenuIndex, title);
	// Swap size, Tiger swap used path from Michael Nordmeyer (http://goodyworks.com)
	if (isTigerOrLater) {
		title = [NSString stringWithFormat:kMenuIndentFormat,
			[NSString stringWithFormat:[localizedStrings objectForKey:kSwapSizeUsedFormat],
				[memIntMBFormatter stringForObjectValue:[currentSwapStats objectForKey:@"swapsizemb"]],
				[memIntMBFormatter stringForObjectValue:[currentSwapStats objectForKey:@"swapusedmb"]]]];
	} else {
		title = [NSString stringWithFormat:kMenuIndentFormat,
					[NSString stringWithFormat:[localizedStrings objectForKey:kSwapSizeFormat],
						[memIntMBFormatter stringForObjectValue:[currentSwapStats objectForKey:@"swapsize"]]]];
	}
	LiveUpdateMenuItemTitle(extraMenu, kMemSwapSizeInfoMenuIndex, title);

} // updateMenuContent

///////////////////////////////////////////////////////////////
//
//	Image renderers
//
///////////////////////////////////////////////////////////////

- (void)renderPieIntoImage:(NSImage *)image {

	// Load current stats
	float totalMB = 1.0f, activeMB = 0, inactiveMB = 0, wireMB = 0, compressedMB = 0;
	NSDictionary *currentMemStats = [memHistory objectAtIndex:0];
	if (currentMemStats) {
		totalMB = [[currentMemStats objectForKey:@"totalmb"] floatValue];
		activeMB = [[currentMemStats objectForKey:@"activemb"] floatValue];
		inactiveMB = [[currentMemStats objectForKey:@"inactivemb"] floatValue];
		wireMB = [[currentMemStats objectForKey:@"wiremb"] floatValue];
		compressedMB = [[currentMemStats objectForKey:@"compressedmb"] floatValue];
	}
	if (activeMB < 0) { activeMB = 0; };
	if (inactiveMB < 0) { inactiveMB = 0; };
	if (wireMB < 0) { wireMB = 0; };
	if (compressedMB < 0) { compressedMB = 0; };
	if (activeMB > totalMB) { activeMB = totalMB; };
	if (inactiveMB > totalMB) { inactiveMB = totalMB; };
	if (wireMB > totalMB) { wireMB = totalMB; };
	if (compressedMB > totalMB) { compressedMB = totalMB; };

	// Lock focus and draw curves around a center
	[image lockFocus];
	NSBezierPath *renderPath = nil;
	float totalArc = 0;
	NSPoint pieCenter = NSMakePoint(kMemPieDisplayWidth / 2, (float)[image size].height / 2);

	// Draw wired
	renderPath = [NSBezierPath bezierPath];
	[renderPath	appendBezierPathWithArcWithCenter:pieCenter
										   radius:(kMemPieDisplayWidth / 2)
									   startAngle:(360 * totalArc) + 90
										 endAngle:(360 * (wireMB / totalMB + totalArc)) + 90
										clockwise:NO];
	[renderPath lineToPoint:pieCenter];
	[wireColor set];
	[renderPath fill];
	totalArc += wireMB / totalMB;

	// Draw the active
	renderPath = [NSBezierPath bezierPath];
	[renderPath appendBezierPathWithArcWithCenter:pieCenter
										   radius:(kMemPieDisplayWidth / 2)
									   startAngle:(360 * totalArc) + 90
										 endAngle:(360 * (activeMB / totalMB + totalArc)) + 90
										clockwise:NO];
	[renderPath lineToPoint:pieCenter];
	[activeColor set];
	[renderPath fill];
	totalArc += activeMB / totalMB;

	// Draw the compressed
	renderPath = [NSBezierPath bezierPath];
	[renderPath appendBezierPathWithArcWithCenter:pieCenter
										   radius:(kMemPieDisplayWidth / 2)
									   startAngle:(360 * totalArc) + 90
										 endAngle:(360 * (compressedMB / totalMB + totalArc)) + 90
										clockwise:NO];
	[renderPath lineToPoint:pieCenter];
	[compressedColor set];
	[renderPath fill];
	totalArc += compressedMB / totalMB;

	// Draw the inactive
	renderPath = [NSBezierPath bezierPath];
	[renderPath appendBezierPathWithArcWithCenter:pieCenter
										   radius:(kMemPieDisplayWidth / 2)
									   startAngle:(360 * totalArc) + 90
										 endAngle:(360 * (inactiveMB / totalMB + totalArc)) + 90
										clockwise:NO];
	[renderPath lineToPoint:pieCenter];
	[inactiveColor set];
	[renderPath fill];
	totalArc += inactiveMB / totalMB;

	// Finish arc with black or gray
	if (IsMenuMeterMenuBarDarkThemed()) {
		[[NSColor darkGrayColor] set];		
	} else {
		[[NSColor blackColor] set];
	}

	// Close the circle if needed
	if (totalArc < 1) {
		renderPath = [NSBezierPath bezierPath];
		[renderPath appendBezierPathWithArcWithCenter:pieCenter
											   radius:(kMemPieDisplayWidth / 2) - 0.5f // Inset radius slightly
										   startAngle:(360 * totalArc) + 90
											 endAngle:450
											clockwise:NO];
		[renderPath setLineWidth:0.6f];  // Lighter line
		[renderPath stroke];
	}

	// Unlock focus
	[image unlockFocus];

} // renderPieIntoImage

- (void)renderNumbersIntoImage:(NSImage *)image {

	// Read in the RAM data
	double freeMB = 0, usedMB = 0;
	NSDictionary *currentMemStats = [memHistory objectAtIndex:0];
	if (currentMemStats) {
		freeMB = [[currentMemStats objectForKey:@"freemb"] doubleValue];
		usedMB = [[currentMemStats objectForKey:@"usedmb"] doubleValue];
	}
	if (freeMB < 0) freeMB = 0;
	if (usedMB < 0) usedMB = 0;

	// Lock focus
	[image lockFocus];

	// Construct strings
	NSMutableAttributedString *renderUString = [[[NSAttributedString alloc]
													initWithString:[NSString stringWithFormat:@"%.0f%@",
																		usedMB,
																		[localizedStrings objectForKey:kMBLabel]]
														attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																		[NSFont systemFontOfSize:9.5f], NSFontAttributeName,
																		usedColor, NSForegroundColorAttributeName,
																		nil]] autorelease];
	// Construct and draw the free string
	NSMutableAttributedString *renderFString = [[[NSAttributedString alloc]
													initWithString:[NSString stringWithFormat:@"%.0f%@",
																		freeMB,
																		[localizedStrings objectForKey:kMBLabel]]
														attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																		[NSFont systemFontOfSize:9.5f], NSFontAttributeName,
																		freeColor, NSForegroundColorAttributeName,
																		nil]] autorelease];

	// Draw the prerendered label
	if ([ourPrefs memUsedFreeLabel]) {
		[numberLabelPrerender compositeToPoint:NSMakePoint(0,0) operation:NSCompositeSourceOver];
	}
	// Using NSParagraphStyle to right align clipped weird, so do it manually
	// No descenders so render lower
	[renderUString drawAtPoint:NSMakePoint(textWidth - (float)round([renderUString size].width),
										   (float)floor([image size].height / 2) - 1)];
	[renderFString drawAtPoint:NSMakePoint(textWidth - (float)round([renderFString size].width), -1)];

	// Unlock focus
	[image unlockFocus];

} // renderNumbersIntoImage

//  Bar mode memory view contributed by Bernhard Baehr
- (void)renderBarIntoImage:(NSImage *)image {

	// Load current stats
	float totalMB = 1.0f, activeMB = 0, inactiveMB = 0, wireMB = 0, compressedMB = 0;
	NSDictionary *currentMemStats = [memHistory objectAtIndex:0];
	if (currentMemStats) {
		totalMB = [[currentMemStats objectForKey:@"totalmb"] floatValue];
		activeMB = [[currentMemStats objectForKey:@"activemb"] floatValue];
		inactiveMB = [[currentMemStats objectForKey:@"inactivemb"] floatValue];
		wireMB = [[currentMemStats objectForKey:@"wiremb"] floatValue];
		compressedMB = [[currentMemStats objectForKey:@"compressedmb"] floatValue];
	}
	if (activeMB < 0) { activeMB = 0; };
	if (inactiveMB < 0) { inactiveMB = 0; };
	if (wireMB < 0) { wireMB = 0; };
	if (compressedMB < 0) { compressedMB = 0; };
	if (activeMB > totalMB) { activeMB = totalMB; };
	if (inactiveMB > totalMB) { inactiveMB = totalMB; };
	if (wireMB > totalMB) { wireMB = totalMB; };
	if (compressedMB > totalMB) { compressedMB = totalMB; };

	// Lock focus and draw
	[image lockFocus];
	float thermometerTotalHeight = (float)[image size].height - 3.0f;

	NSBezierPath *wirePath = [NSBezierPath bezierPathWithRect:NSMakeRect(1.5f, 1.5f, kMemThermometerDisplayWidth - 3,
																		 thermometerTotalHeight * (wireMB / totalMB))];
	NSBezierPath *activePath = [NSBezierPath bezierPathWithRect:NSMakeRect(1.5f, 1.5f, kMemThermometerDisplayWidth - 3,
																		   thermometerTotalHeight * ((wireMB + activeMB) / totalMB))];
	NSBezierPath *compressedPath = [NSBezierPath bezierPathWithRect:NSMakeRect(1.5f, 1.5f, kMemThermometerDisplayWidth - 3,
																			   thermometerTotalHeight * ((wireMB + activeMB + compressedMB) / totalMB))];
	NSBezierPath *inactivePath = [NSBezierPath bezierPathWithRect:NSMakeRect(1.5f, 1.5f, kMemThermometerDisplayWidth - 3,
																		   thermometerTotalHeight * ((wireMB + activeMB + compressedMB + inactiveMB) / totalMB))];
	NSBezierPath *framePath = [NSBezierPath bezierPathWithRect:NSMakeRect(1.5f, 1.5f, kMemThermometerDisplayWidth - 3, thermometerTotalHeight)];
	[inactiveColor set];
	[inactivePath fill];
	[compressedColor set];
	[compressedPath fill];
	[activeColor set];
	[activePath fill];
	[wireColor set];
	[wirePath fill];
	if (IsMenuMeterMenuBarDarkThemed()) {
		[[NSColor darkGrayColor] set];
	} else {
		[fgMenuThemeColor set];
	}
	[framePath stroke];

	// Reset
	[[NSColor blackColor] set];
	[image unlockFocus];

} // renderBarIntoImage

- (void)renderMemHistoryIntoImage:(NSImage *)image {

	// Construct paths
	NSBezierPath *wirePath =  [NSBezierPath bezierPath];
	NSBezierPath *activePath =  [NSBezierPath bezierPath];
	NSBezierPath *compressedPath =  [NSBezierPath bezierPath];
	NSBezierPath *inactivePath =  [NSBezierPath bezierPath];
	if (!(wirePath && activePath && inactivePath)) return;

	// Position for initial offset
	[wirePath moveToPoint:NSMakePoint(0, 0)];
	[activePath moveToPoint:NSMakePoint(0, 0)];
	[compressedPath moveToPoint:NSMakePoint(0, 0)];
	[inactivePath moveToPoint:NSMakePoint(0, 0)];

	// Loop over pixels in desired width until we're out of data
	int renderPosition = 0;
	// Graph height does not include baseline, reserve the space for real data
	// since memory usage can never be zero.
	float renderHeight = (float)[image size].height;
 	for (renderPosition = 0; renderPosition < [ourPrefs memGraphLength]; renderPosition++) {

		// No data at this position?
		if (renderPosition >= [memHistory count]) break;

		// Grab data
		NSDictionary *memData = [memHistory objectAtIndex:renderPosition];
		if (!memData) continue;
		float activeMB = [[memData objectForKey:@"activemb"] floatValue];
		float inactiveMB = [[memData objectForKey:@"inactivemb"] floatValue];
		float wireMB = [[memData objectForKey:@"wiremb"] floatValue];
		float compressedMB = [[memData objectForKey:@"compressedmb"] floatValue];
		float totalMB = [[memData objectForKey:@"totalmb"] floatValue];
		if (activeMB < 0) { activeMB = 0; };
		if (inactiveMB < 0) { inactiveMB = 0; };
		if (wireMB < 0) { wireMB = 0; };
		if (compressedMB < 0) { compressedMB = 0; };
		if (activeMB > totalMB) { activeMB = totalMB; };
		if (inactiveMB > totalMB) { inactiveMB = totalMB; };
		if (wireMB > totalMB) { wireMB = totalMB; };
		if (compressedMB > totalMB) { compressedMB = totalMB; };

		// Update paths (adding baseline)
		[inactivePath lineToPoint:NSMakePoint(renderPosition,
											  (inactiveMB + compressedMB + activeMB + wireMB) > totalMB ? totalMB : ((inactiveMB + compressedMB + activeMB + wireMB) / totalMB) * renderHeight)];
		[compressedPath lineToPoint:NSMakePoint(renderPosition,
											  (compressedMB + activeMB + wireMB) > totalMB ? totalMB : ((compressedMB + activeMB + wireMB) / totalMB) * renderHeight)];
		[activePath lineToPoint:NSMakePoint(renderPosition,
											(activeMB + wireMB) > totalMB ? totalMB : ((activeMB + wireMB) / totalMB) * renderHeight)];
		[wirePath lineToPoint:NSMakePoint(renderPosition,
										  wireMB / totalMB * renderHeight)];
	}

	// Return to lower edge (fill will close the graph)
	[inactivePath lineToPoint:NSMakePoint(renderPosition - 1, 0)];
	[compressedPath lineToPoint:NSMakePoint(renderPosition - 1, 0)];
	[activePath lineToPoint:NSMakePoint(renderPosition - 1, 0)];
	[wirePath lineToPoint:NSMakePoint(renderPosition - 1, 0)];


	// Render the graph
	[image lockFocus];
	[inactiveColor set];
	[inactivePath fill];
	[compressedColor set];
	[compressedPath fill];
	[activeColor set];
	[activePath fill];
	[wireColor set];
	[wirePath fill];

	// Clean up
	[[NSColor blackColor] set];
	[image unlockFocus];

} // renderMemHistoryIntoImages

// Paging indicator from Bernhard Baehr. Originally an overlay to the bar display, I liked
// it so much I broke the display out so it could be used with any mode.
- (void)renderPageIndicatorIntoImage:(NSImage *)image {

	// Read in the paging deltas
	uint64_t pageIns = 0, pageOuts = 0;
	NSDictionary *currentMemStats = [memHistory objectAtIndex:0];
	if (currentMemStats) {
		pageIns = [[currentMemStats objectForKey:@"deltapageins"] unsignedLongLongValue];
		pageOuts = [[currentMemStats objectForKey:@"deltapageouts"] unsignedLongLongValue];
	}

	// Lock focus and get height
	[image lockFocus];
	float indicatorHeight = (float)[image size].height;
	
	BOOL darkTheme = IsMenuMeterMenuBarDarkThemed();

	// Set up the pageout path
	NSBezierPath *arrow = [NSBezierPath bezierPath];
	[arrow moveToPoint:NSMakePoint(kMemPagingDisplayWidth / 2.0f + (menuWidth - kMemPagingDisplayWidth) - 0.5f, 1)];
	[arrow lineToPoint:NSMakePoint(kMemPagingDisplayWidth / 2.0f + (menuWidth - kMemPagingDisplayWidth) + 4.5f, 5.0f)];
	[arrow lineToPoint:NSMakePoint(kMemPagingDisplayWidth / 2.0f + (menuWidth - kMemPagingDisplayWidth) - 5.5f, 5.0f)];
	[arrow closePath];
	// Draw
	if (pageIns) {
		[pageInColor set];
	} else {
		if (darkTheme) {
			[[NSColor darkGrayColor] set];
		} else {
			[[pageInColor colorWithAlphaComponent:0.25f] set];
		}
	}
	[arrow fill];

	// Set up the pagein path
	arrow = [NSBezierPath bezierPath];
	[arrow moveToPoint:NSMakePoint(kMemPagingDisplayWidth / 2.0f + (menuWidth - kMemPagingDisplayWidth) - 0.5f, indicatorHeight - 1)];
	[arrow lineToPoint:NSMakePoint(kMemPagingDisplayWidth / 2.0f + (menuWidth - kMemPagingDisplayWidth) + 4.5f, indicatorHeight - 5.0f)];
	[arrow lineToPoint:NSMakePoint(kMemPagingDisplayWidth / 2.0f + (menuWidth - kMemPagingDisplayWidth) - 5.5f, indicatorHeight - 5.0f)];
	[arrow closePath];
	// Draw
	if (pageOuts) {
		[pageOutColor set];
	} else {
		if (darkTheme) {
			[[NSColor darkGrayColor] set];
		} else {
			[[pageOutColor colorWithAlphaComponent:0.25f] set];
		}
	}
	[arrow fill];

	// Draw the activity count
	NSString *countString = nil;
	if ((pageIns + pageOuts) >= 1000) {
		countString = @"1k+";
	} else {
		countString = [NSString stringWithFormat:@"%d", pageIns + pageOuts];
	}
	NSAttributedString *renderString = [[[NSAttributedString alloc]
											initWithString:countString
												attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																[NSFont systemFontOfSize:9.5f], NSFontAttributeName,
																fgMenuThemeColor, NSForegroundColorAttributeName,
																nil]] autorelease];
	// Using NSParagraphStyle to right align clipped weird, so do it manually
	// Also draw low to ignore descenders
	NSSize renderSize = [renderString size];
	[renderString drawAtPoint:NSMakePoint(menuWidth - kMemPagingDisplayWidth +
											roundf((kMemPagingDisplayWidth - (float)renderSize.width) / 2.0f),
										  4.0f)];  // Just hardcode the vertical offset

	// Unlock focus
	[image unlockFocus];

} // renderPageIndicator

///////////////////////////////////////////////////////////////
//
//	Timer callbacks
//
///////////////////////////////////////////////////////////////

- (void)updateMemDisplay:(NSTimer *)timer {

	NSDictionary *currentStats = [memStats memStats];
	if (!currentStats) return;

	// Add to history (at least one)
	if ([ourPrefs memDisplayMode] == kMemDisplayGraph) {
		if ([memHistory count] >= [ourPrefs memGraphLength]) {
			[memHistory removeObjectsInRange:NSMakeRange(0, [memHistory count] - [ourPrefs memGraphLength] + 1)];
		}
	} else {
		[memHistory removeAllObjects];
	}
	[memHistory addObject:currentStats];

	// This code used to try to avoid a redraw if nothing had changed, but
	// the cost of a redraw is so low its a false optimization.
	[extraView setNeedsDisplay:YES];

	// If the menu is down, update it
	if ([self isMenuDown] || 
		([self respondsToSelector:@selector(isMenuDownForAX)] && [self isMenuDownForAX])) {
		[self updateMenuWhenDown];
	}

} // updateMemDisplay

- (void)updateMenuWhenDown {

	NSDictionary *newSwapStats = [memStats swapStats];
	if (newSwapStats) {
		[currentSwapStats release];
		currentSwapStats = [newSwapStats retain];
	}

	// Update the menu content
	[self updateMenuContent];

	// Force the menu to redraw
	LiveUpdateMenu(extraMenu);

} // updateMenuWhenDown

///////////////////////////////////////////////////////////////
//
//	Prefs
//
///////////////////////////////////////////////////////////////

- (void)configFromPrefs:(NSNotification *)notification {

	// Update prefs
	[ourPrefs syncWithDisk];

	// Handle menubar theme changes
	[fgMenuThemeColor release];
	fgMenuThemeColor = [MenuItemTextColor() retain];
	
	// Cache colors to skip archive cycle from prefs
	[freeColor release];
	freeColor = [[ourPrefs memFreeColor] retain];
	[usedColor release];
	usedColor = [[ourPrefs memUsedColor] retain];
	[activeColor release];
	activeColor = [[ourPrefs memActiveColor] retain];
	[inactiveColor release];
	inactiveColor = [[ourPrefs memInactiveColor] retain];
	[wireColor release];
	wireColor = [[ourPrefs memWireColor] retain];
	[compressedColor release];
	compressedColor = [[ourPrefs memCompressedColor] retain];
	[pageInColor release];
	pageInColor = [[ourPrefs memPageInColor] retain];
	[pageOutColor release];
	pageOutColor = [[ourPrefs memPageOutColor] retain];

	// Since text rendering is so CPU intensive we minimize this by
	// prerendering what we can if we need it
	[numberLabelPrerender release];
	numberLabelPrerender = nil;
	NSAttributedString *renderUString = [[[NSAttributedString alloc]
											initWithString:[[NSBundle bundleForClass:[self class]]
															   localizedStringForKey:kUsedLabel
																			   value:nil
																			   table:nil]
												attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																[NSFont systemFontOfSize:9.5f], NSFontAttributeName,
																[ourPrefs memUsedColor], NSForegroundColorAttributeName,
																nil]] autorelease];
	NSAttributedString *renderFString = [[[NSAttributedString alloc]
											initWithString:[[NSBundle bundleForClass:[self class]]
																localizedStringForKey:kFreeLabel
																				value:nil
																				table:nil]
												attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																[NSFont systemFontOfSize:9.5f], NSFontAttributeName,
																[ourPrefs memFreeColor], NSForegroundColorAttributeName,
																nil]] autorelease];
	if ([renderUString size].width > [renderFString size].width) {
		numberLabelPrerender = [[NSImage alloc] initWithSize:NSMakeSize([renderUString size].width,
																		[extraView frame].size.height - 1)];
	} else {
		numberLabelPrerender = [[NSImage alloc] initWithSize:NSMakeSize([renderFString size].width,
																		[extraView frame].size.height - 1)];
	}
	[numberLabelPrerender lockFocus];
	// No descenders so render both lines lower than normal
	[renderUString drawAtPoint:NSMakePoint(0, (float)floor([numberLabelPrerender size].height / 2) - 1)];
	[renderFString drawAtPoint:NSMakePoint(0, -1)];
	[numberLabelPrerender unlockFocus];

	// Figure out the length of "MB" localization
	float mbLength = 0;
	if ([ourPrefs memDisplayMode] == kMemDisplayNumber) {
		NSAttributedString *renderMBString =  [[[NSAttributedString alloc]
													initWithString:[localizedStrings objectForKey:kMBLabel]
														attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																		[NSFont systemFontOfSize:9.5f], NSFontAttributeName,
																		nil]] autorelease];
		mbLength = (float)ceil([renderMBString size].width);
	}

	// Fix our menu size to match our config
	menuWidth = 0;
	switch ([ourPrefs memDisplayMode]) {
		case kMemDisplayPie:
			menuWidth = kMemPieDisplayWidth;
			break;
		case kMemDisplayNumber:
			// Read in the total RAM, and change length to accomodate those with more RAM
			if ([[[memStats memStats] objectForKey:@"totalmb"] unsignedLongLongValue] >= 10000) {
				menuWidth = kMemNumberDisplayExtraLongWidth + mbLength;
				textWidth = kMemNumberDisplayExtraLongWidth + mbLength;
			} else if ([[[memStats memStats] objectForKey:@"totalmb"] unsignedLongLongValue] >= 1000) {
				menuWidth = kMemNumberDisplayLongWidth + mbLength;
				textWidth = kMemNumberDisplayLongWidth + mbLength;
			} else {
				menuWidth = kMemNumberDisplayShortWidth + mbLength;
				textWidth = kMemNumberDisplayShortWidth + mbLength;
			}
			if ([ourPrefs memUsedFreeLabel]) {
				menuWidth += (float)ceil([numberLabelPrerender size].width);
				textWidth += (float)ceil([numberLabelPrerender size].width);
			}
			break;
		case kMemDisplayBar:
			menuWidth = kMemThermometerDisplayWidth;
			break;
		case kMemDisplayGraph:
			menuWidth = [ourPrefs memGraphLength];
			break;
	}
	// Adjust width for paging indicator
	if ([ourPrefs memPageIndicator]) {
		menuWidth += kMemPagingDisplayWidth + kMemPagingDisplayGapWidth;
	}

	// Restart the timer
	[updateTimer invalidate];  // Runloop releases and retains the next one
	updateTimer = [NSTimer scheduledTimerWithTimeInterval:[ourPrefs memInterval]
												   target:self
												 selector:@selector(updateMemDisplay:)
												 userInfo:nil
												  repeats:YES];
	// On newer OS versions we need to put the timer into EventTracking to update while the menus are down
	if (isPantherOrLater) {
		[[NSRunLoop currentRunLoop] addTimer:updateTimer
									 forMode:NSEventTrackingRunLoopMode];
	}

	// Resize the view
	[extraView setFrameSize:NSMakeSize(menuWidth, [extraView frame].size.height)];
	[self setLength:menuWidth];

	// Flag us for redisplay
	[extraView setNeedsDisplay:YES];

} // configFromPrefs

@end

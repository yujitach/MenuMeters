//
//  MenuMeterMemExtra.m
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

#import "MenuMeterMemExtra.h"

///////////////////////////////////////////////////////////////
//
//  Private methods
//
///////////////////////////////////////////////////////////////

@interface MenuMeterMemExtra (PrivateMethods)

// Menu generation

- (void)updateMenuContent;

// Image renderers

- (void)renderPieImageSize:(NSSize)imageSize;

- (void)renderNumbersImageSize:(NSSize)imageSize;

- (void)renderBarImageSize:(NSSize)imageSize;

- (void)renderPressureBarImageSize:(NSSize)imageSize;

- (void)renderMemHistoryImageSize:(NSSize)imageSize;

- (void)renderPageIndicatorImageSize:(NSSize)imageSize;

// Timer callbacks

- (void)updateMenuWhenDown;

// Prefs

- (void)configFromPrefs:(NSNotification *)notification;

@end

///////////////////////////////////////////////////////////////
//
//  Localized strings
//
///////////////////////////////////////////////////////////////

#define kFreeLabel @"F:"
#define kUsedLabel @"U:"
#define kUsageTitle @"Memory Usage:"
#define kPageStatsTitle @"Memory Pages:"
#define kVMStatsTitle @"VM Statistics:"
#define kMemPressureTitle @"Memory Pressure:"
#define kMemPressureFormat @"%@%%\t(level %@)"
#define kSwapStatsTitle @"Swap Files:"
#define kUsageFormat @"%@ used, %@ free, %@ total"
#define kActiveWiredFormat @"%@ active, %@ wired"
#define kInactiveFreeFormat @"%@ inactive, %@ free"
#define kCompressedFormat @"%@ compressed (%@)"
#define kVMPagingFormat @"%@ pageins, %@ pageouts"
#define kVMCacheFormat @"%@ cache lookups, %@ cache hits (%@)"
#define kVMFaultCopyOnWriteFormat @"%@ page faults, %@ copy-on-writes"
#define kSingleSwapFormat @"%@ swap file present in %@"
#define kMultiSwapFormat @"%@ swap files present in %@"
#define kSingleEncryptedSwapFormat @"%@ encrypted swap file present in %@"
#define kMultiEncryptedSwapFormat @"%@ encrypted swap files present in %@"
#define kMaxSingleSwapFormat @"%@ swap file at peak usage"
#define kMaxMultiSwapFormat @"%@ swap files at peak usage"
#define kSwapSizeFormat @"%@ total swap space"
#define kSwapSizeUsedFormat @"%@ total swap space (%@ used)"
#define kMBLabel @"MB"

///////////////////////////////////////////////////////////////
//
//  init/unload/dealloc
//
///////////////////////////////////////////////////////////////

@implementation MenuMeterMemExtra

- (instancetype)init {

	self = [super initWithBundleID:kMemMenuBundleID];
	NSBundle *bundle = [NSBundle mainBundle];
	if (!self) {
		return nil;
	}

	ourPrefs = [MenuMeterDefaults sharedMenuMeterDefaults];
	if (!ourPrefs) {
		NSLog(@"MenuMeterMem unable to connect to preferences. Abort.");
		return nil;
	}

	// Build our CPU statistics gatherer and history
	memStats = [[MenuMeterMemStats alloc] init];
	memHistory = [NSMutableArray array];
	if (!(memStats && memHistory)) {
		NSLog(@"MenuMeterMem unable to load data gatherer or storage. Abort.");
		return nil;
	}

	// Setup our menu
	extraMenu = [[NSMenu alloc] initWithTitle:@""];
	if (!extraMenu) {
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

	// add items for memory pressure
	menuItem = (NSMenuItem *)[extraMenu addItemWithTitle:[bundle localizedStringForKey:kMemPressureTitle value:nil table:nil]
												  action:nil
										   keyEquivalent:@""];
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
	[extraMenu addItem:[NSMenuItem separatorItem]];
	[self addStandardMenuEntriesTo:extraMenu];

	// Set up a NumberFormatter for localization. This is based on code contributed by Mike Fischer
	// (mike.fischer at fi-works.de) for use in MenuMeters.
	NSNumberFormatter *tempFormat = [[NSNumberFormatter alloc] init];
	[tempFormat setLocalizesFormat:YES];
	[tempFormat setFormat:[NSString stringWithFormat:@"#,##0.0%@", [localizedStrings objectForKey:kMBLabel]]];
	// Go through an archive/unarchive cycle to work around a bug on pre-10.2.2 systems
	// see http://cocoa.mamasam.com/COCOADEV/2001/12/2/21029.php
	memFloatMBFormatter = [NSUnarchiver unarchiveObjectWithData:[NSArchiver archivedDataWithRootObject:tempFormat]];
	[tempFormat setFormat:[NSString stringWithFormat:@"#,##0%@", [localizedStrings objectForKey:kMBLabel]]];
	memIntMBFormatter = [NSUnarchiver unarchiveObjectWithData:[NSArchiver archivedDataWithRootObject:tempFormat]];
	[tempFormat setFormat:@"#,##0"];
	prettyIntFormatter = [NSUnarchiver unarchiveObjectWithData:[NSArchiver archivedDataWithRootObject:tempFormat]];
	[tempFormat setFormat:@"##0.0%"];
	percentFormatter = [NSUnarchiver unarchiveObjectWithData:[NSArchiver archivedDataWithRootObject:tempFormat]];
	if (!(memFloatMBFormatter && memIntMBFormatter && prettyIntFormatter && percentFormatter)) {
		return nil;
	}

	// And configure directly from prefs on first load
	[self configFromPrefs:nil];

	// And hand ourself back to SystemUIServer
	NSLog(@"MenuMeterMem loaded.");
	return self;

} // initWithBundle

// dealloc

///////////////////////////////////////////////////////////////
//
//  NSMenuExtra view callbacks
//
///////////////////////////////////////////////////////////////

- (NSImage *)image {

	// Don't render without data
	if (![memHistory count])
		return nil;

	[self setupAppearance];

	NSSize imageSize = NSMakeSize(menuWidth, self.height - 1);
	// Image to render into (and return to view)
	MenuMeterDefaults *prefs = ourPrefs;
	NSImage *currentImage = [NSImage imageWithSize:imageSize
										   flipped:NO
									drawingHandler:^BOOL(NSRect dstRect) {
		switch ([prefs memDisplayMode]) {
			case kMemDisplayPie:
				[self renderPieImageSize:imageSize];
				break;
			case kMemDisplayNumber:
				[self renderNumbersImageSize:imageSize];
				break;
			case kMemDisplayBar:
				if ([prefs memPressure]) {
					[self renderPressureBarImageSize:imageSize];
				}
				else {
					[self renderBarImageSize:imageSize];
				}
				break;
			case kMemDisplayGraph:
				if ([prefs memPressure]) {
					[self renderPressureHistoryImageSize:imageSize];
				}
				else {
					[self renderMemHistoryImageSize:imageSize];
				}
		}
		if ([prefs memPageIndicator]) {
			[self renderPageIndicatorImageSize:imageSize];
		}
		return YES;
	}];
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
		}
		else {
			[memHistory removeAllObjects];
		}
		[memHistory addObject:currentStats];
	}
	NSDictionary *newSwapStats = [memStats swapStats];
	if (newSwapStats) {
		currentSwapStats = newSwapStats;
	}

	// Update the menu content
	[self updateMenuContent];

	// Send the menu back to SystemUIServer
	return extraMenu;

} // menu

///////////////////////////////////////////////////////////////
//
//  Menu generation
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
	NSString *title = nil;

	// Fetch stats
	NSDictionary *currentMemStats = [memHistory objectAtIndex:0];
	if (!(currentMemStats && currentSwapStats))
		return;

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
	const double divisor = [[currentMemStats objectForKey:@"lookups"] doubleValue];
	title = [NSString stringWithFormat:kMenuIndentFormat,
									   [NSString stringWithFormat:[localizedStrings objectForKey:kVMCacheFormat],
																  [prettyIntFormatter stringForObjectValue:[currentMemStats objectForKey:@"lookups"]],
																  [prettyIntFormatter stringForObjectValue:[currentMemStats objectForKey:@"hits"]],
																  [percentFormatter stringForObjectValue:
																						[NSNumber numberWithDouble:
																									  divisor == 0.0 ? 0.0 : (double)(([[currentMemStats objectForKey:@"hits"] doubleValue] / divisor) * 100.0)]]]];
	LiveUpdateMenuItemTitle(extraMenu, kMemVMCacheInfoMenuIndex, title);
	// VM fault
	title = [NSString stringWithFormat:kMenuIndentFormat,
									   [NSString stringWithFormat:[localizedStrings objectForKey:kVMFaultCopyOnWriteFormat],
																  [prettyIntFormatter stringForObjectValue:[currentMemStats objectForKey:@"faults"]],
																  [prettyIntFormatter stringForObjectValue:[currentMemStats objectForKey:@"cowfaults"]]]];
	LiveUpdateMenuItemTitle(extraMenu, kMemVMFaultInfoMenuIndex, title);

	title = [NSString stringWithFormat:kMenuIndentFormat,
									   [NSString stringWithFormat:[localizedStrings objectForKey:kMemPressureFormat], [currentMemStats objectForKey:@"mempress"], [currentMemStats objectForKey:@"mempresslevel"]]];
	LiveUpdateMenuItemTitle(extraMenu, kMemMemPressureInfoMenuIndex, title);

	// Swap count/path, Tiger swap encryptioninfo from Michael Nordmeyer (http://goodyworks.com)
	if ([[currentSwapStats objectForKey:@"swapencrypted"] boolValue]) {
		title = [NSString stringWithFormat:kMenuIndentFormat,
										   [NSString stringWithFormat:
														 (([[currentSwapStats objectForKey:@"swapcount"] unsignedIntValue] != 1) ? [localizedStrings objectForKey:kMultiEncryptedSwapFormat] : [localizedStrings objectForKey:kSingleEncryptedSwapFormat]),
														 [prettyIntFormatter stringForObjectValue:[currentSwapStats objectForKey:@"swapcount"]],
														 [currentSwapStats objectForKey:@"swappath"]]];
	}
	LiveUpdateMenuItemTitle(extraMenu, kMemSwapCountInfoMenuIndex, title);
	// Swap max
	title = [NSString stringWithFormat:kMenuIndentFormat,
									   [NSString stringWithFormat:
													 (([[currentSwapStats objectForKey:@"swapcountpeak"] unsignedIntValue] != 1) ? [localizedStrings objectForKey:kMaxMultiSwapFormat] : [localizedStrings objectForKey:kMaxSingleSwapFormat]),
													 [prettyIntFormatter stringForObjectValue:[currentSwapStats objectForKey:@"swapcountpeak"]]]];
	LiveUpdateMenuItemTitle(extraMenu, kMemSwapMaxCountInfoMenuIndex, title);
	// Swap size, Tiger swap used path from Michael Nordmeyer (http://goodyworks.com)
	title = [NSString stringWithFormat:kMenuIndentFormat,
									   [NSString stringWithFormat:[localizedStrings objectForKey:kSwapSizeUsedFormat],
																  [memIntMBFormatter stringForObjectValue:[currentSwapStats objectForKey:@"swapsizemb"]],
																  [memIntMBFormatter stringForObjectValue:[currentSwapStats objectForKey:@"swapusedmb"]]]];
	LiveUpdateMenuItemTitle(extraMenu, kMemSwapSizeInfoMenuIndex, title);

} // updateMenuContent

///////////////////////////////////////////////////////////////
//
//  Image renderers
//
///////////////////////////////////////////////////////////////

- (void)renderPieImageSize:(NSSize)imageSize {

	// Load current stats
	float totalMB = 1.0, activeMB = 0, inactiveMB = 0, wireMB = 0, compressedMB = 0;
	NSDictionary *currentMemStats = [memHistory objectAtIndex:0];
	if (currentMemStats) {
		totalMB = [[currentMemStats objectForKey:@"totalmb"] floatValue];
		activeMB = [[currentMemStats objectForKey:@"activemb"] floatValue];
		inactiveMB = [[currentMemStats objectForKey:@"inactivemb"] floatValue];
		wireMB = [[currentMemStats objectForKey:@"wiremb"] floatValue];
		compressedMB = [[currentMemStats objectForKey:@"compressedmb"] floatValue];
	}
	if (activeMB < 0) {
		activeMB = 0;
	};
	if (inactiveMB < 0) {
		inactiveMB = 0;
	};
	if (wireMB < 0) {
		wireMB = 0;
	};
	if (compressedMB < 0) {
		compressedMB = 0;
	};
	if (activeMB > totalMB) {
		activeMB = totalMB;
	};
	if (inactiveMB > totalMB) {
		inactiveMB = totalMB;
	};
	if (wireMB > totalMB) {
		wireMB = totalMB;
	};
	if (compressedMB > totalMB) {
		compressedMB = totalMB;
	};

	// Draw curves around a center
	NSBezierPath *renderPath = nil;
	float totalArc = 0;
	NSPoint pieCenter = NSMakePoint(kMemPieDisplayWidth / 2, imageSize.height / 2);

	// Draw wired
	renderPath = [NSBezierPath bezierPath];
	[renderPath appendBezierPathWithArcWithCenter:pieCenter
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

	// Finish arc with the default color
	[[fgMenuThemeColor colorWithAlphaComponent:kBorderAlpha] set];

	// Close the circle if needed
	if (totalArc < 1) {
		renderPath = [NSBezierPath bezierPath];
		[renderPath appendBezierPathWithArcWithCenter:pieCenter
											   radius:(kMemPieDisplayWidth / 2) - 0.5 // Inset radius slightly
										   startAngle:(360 * totalArc) + 90
											 endAngle:450
											clockwise:NO];
		[renderPath setLineWidth:0.6]; // Lighter line
		[renderPath stroke];
	}
} // renderPieIntoImage

- (void)renderNumbersImageSize:(NSSize)imageSize {

	// Read in the RAM data
	double freeMB = 0, usedMB = 0;
	NSDictionary *currentMemStats = [memHistory objectAtIndex:0];
	if (currentMemStats) {
		freeMB = [[currentMemStats objectForKey:@"freemb"] doubleValue];
		usedMB = [[currentMemStats objectForKey:@"usedmb"] doubleValue];
	}
	if (freeMB < 0)
		freeMB = 0;
	if (usedMB < 0)
		usedMB = 0;

	// Construct strings
	NSAttributedString *renderUString = [[NSAttributedString alloc]
		initWithString:[NSString stringWithFormat:@"%.0f%@",
												  usedMB,
												  [localizedStrings objectForKey:kMBLabel]]
			attributes:[NSDictionary dictionaryWithObjectsAndKeys:
										 [NSFont monospacedDigitSystemFontOfSize:9.5
																		  weight:NSFontWeightRegular],
										 NSFontAttributeName,
										 usedColor, NSForegroundColorAttributeName,
										 nil]];
	// Construct and draw the free string
	NSAttributedString *renderFString = [[NSAttributedString alloc]
		initWithString:[NSString stringWithFormat:@"%.0f%@",
												  freeMB,
												  [localizedStrings objectForKey:kMBLabel]]
			attributes:[NSDictionary dictionaryWithObjectsAndKeys:
										 [NSFont monospacedDigitSystemFontOfSize:9.5
																		  weight:NSFontWeightRegular],
										 NSFontAttributeName,
										 freeColor, NSForegroundColorAttributeName,
										 nil]];

	// Draw the prerendered label
	if ([ourPrefs memUsedFreeLabel]) {
		[numberLabelPrerender compositeToPoint:NSMakePoint(0, 0) operation:NSCompositeSourceOver];
	}
	// Using NSParagraphStyle to right align clipped weird, so do it manually
	// No descenders so render lower
	[renderUString drawAtPoint:NSMakePoint(textWidth - round([renderUString size].width),
										   floor(imageSize.height / 2) - 1)];
	[renderFString drawAtPoint:NSMakePoint(textWidth - round([renderFString size].width), -1)];
} // renderNumbersIntoImage

- (void)renderPressureBarImageSize:(NSSize)imageSize {
	// Load current stats
	float pressure = 0.2;
	NSDictionary *currentMemStats = [memHistory objectAtIndex:0];
	if (currentMemStats) {
		pressure = [[currentMemStats objectForKey:@"mempress"] intValue] / 100.0;
	}

	if (pressure < 0) {
		pressure = 0;
	};

	// Draw
	NSRect barFrame = NSMakeRect(0, 0, kMemThermometerDisplayWidth, imageSize.height);

	NSRect pressureRect = barFrame;
	pressureRect.size.height *= pressure;

	NSBezierPath *pressurePath = [NSBezierPath bezierPathWithRect:pressureRect];

	NSBezierPath *framePath = [NSBezierPath bezierPathWithRoundedRect:barFrame xRadius:2 yRadius:2];

	[NSGraphicsContext saveGraphicsState];
	[framePath addClip];
	[[fgMenuThemeColor colorWithAlphaComponent:0.2] set];
	[framePath fill];

	[activeColor set];
	[pressurePath fill];
	[NSGraphicsContext restoreGraphicsState];

}

//  Bar mode memory view contributed by Bernhard Baehr

- (void)renderBarImageSize:(NSSize)imageSize {

	// Load current stats
	float totalMB = 1.0, activeMB = 0, inactiveMB = 0, wireMB = 0, compressedMB = 0;
	NSDictionary *currentMemStats = [memHistory objectAtIndex:0];
	if (currentMemStats) {
		totalMB = [[currentMemStats objectForKey:@"totalmb"] floatValue];
		activeMB = [[currentMemStats objectForKey:@"activemb"] floatValue];
		inactiveMB = [[currentMemStats objectForKey:@"inactivemb"] floatValue];
		wireMB = [[currentMemStats objectForKey:@"wiremb"] floatValue];
		compressedMB = [[currentMemStats objectForKey:@"compressedmb"] floatValue];
	}
	if (activeMB < 0) {
		activeMB = 0;
	};
	if (inactiveMB < 0) {
		inactiveMB = 0;
	};
	if (wireMB < 0) {
		wireMB = 0;
	};
	if (compressedMB < 0) {
		compressedMB = 0;
	};
	if (activeMB > totalMB) {
		activeMB = totalMB;
	};
	if (inactiveMB > totalMB) {
		inactiveMB = totalMB;
	};
	if (wireMB > totalMB) {
		wireMB = totalMB;
	};
	if (compressedMB > totalMB) {
		compressedMB = totalMB;
	};

	// Draw
	NSRect barFrame = NSMakeRect(0, 0, kMemThermometerDisplayWidth, imageSize.height);

	NSRect wireRect = barFrame;
	wireRect.size.height *= wireMB / totalMB;

	NSRect activeRect = barFrame;
	activeRect.size.height *= (wireMB + activeMB) / totalMB;

	NSRect compressedRect = barFrame;
	compressedRect.size.height *= (wireMB + activeMB + compressedMB) / totalMB;

	NSRect inactiveRect = barFrame;
	inactiveRect.size.height *= (wireMB + activeMB + compressedMB + inactiveMB) / totalMB;

	NSBezierPath *wirePath = [NSBezierPath bezierPathWithRect:wireRect];
	
	NSBezierPath *activePath = [NSBezierPath bezierPathWithRect:activeRect];

	NSBezierPath *compressedPath = [NSBezierPath bezierPathWithRect:compressedRect];

	NSBezierPath *inactivePath = [NSBezierPath bezierPathWithRect:inactiveRect];

	NSBezierPath *framePath = [NSBezierPath bezierPathWithRoundedRect:barFrame xRadius:2 yRadius:2];

	[NSGraphicsContext saveGraphicsState];
	[framePath addClip];
	[[fgMenuThemeColor colorWithAlphaComponent:0.2] set];
	[framePath fill];

	[inactiveColor set];
	[inactivePath fill];
	[compressedColor set];
	[compressedPath fill];
	[activeColor set];
	[activePath fill];
	[wireColor set];
	[wirePath fill];
	[NSGraphicsContext restoreGraphicsState];

} // renderBarIntoImage

- (void)renderPressureHistoryImageSize:(NSSize)imageSize {

	// Construct paths
	NSBezierPath *activePath = [NSBezierPath bezierPath];

	// Position for initial offset
	[activePath moveToPoint:NSMakePoint(0, 0)];

	// Loop over pixels in desired width until we're out of data
	int renderPosition = 0;
	// Graph height does not include baseline, reserve the space for real data
	// since memory usage can never be zero.
	float renderHeight = (float)imageSize.height;
	for (renderPosition = 0; renderPosition < [ourPrefs memGraphLength]; renderPosition++) {

		// No data at this position?
		if (renderPosition >= [memHistory count])
			break;

		// Grab data
		NSDictionary *memData = [memHistory objectAtIndex:renderPosition];
		if (!memData)
			continue;
		int pressure = [[memData objectForKey:@"mempress"] intValue];
		if (pressure < 0) {
			pressure = 0;
		};
		if (pressure > 100) {
			pressure = 100;
		};

		// Update paths (adding baseline)
		[activePath lineToPoint:NSMakePoint(renderPosition,
											pressure / 100.f * renderHeight)];
	}

	// Return to lower edge (fill will close the graph)
	[activePath lineToPoint:NSMakePoint(renderPosition - 1, 0)];

	// Render the graph
	[activeColor set];
	[activePath fill];
} // renderMemHistoryIntoImages

- (void)renderMemHistoryImageSize:(NSSize)imageSize {

	// Construct paths
	NSBezierPath *wirePath = [NSBezierPath bezierPath];
	NSBezierPath *activePath = [NSBezierPath bezierPath];
	NSBezierPath *compressedPath = [NSBezierPath bezierPath];
	NSBezierPath *inactivePath = [NSBezierPath bezierPath];
	if (!(wirePath && activePath && inactivePath))
		return;

	// Position for initial offset
	[wirePath moveToPoint:NSMakePoint(0, 0)];
	[activePath moveToPoint:NSMakePoint(0, 0)];
	[compressedPath moveToPoint:NSMakePoint(0, 0)];
	[inactivePath moveToPoint:NSMakePoint(0, 0)];

	// Loop over pixels in desired width until we're out of data
	int renderPosition = 0;
	// Graph height does not include baseline, reserve the space for real data
	// since memory usage can never be zero.
	float renderHeight = (float)imageSize.height;
	for (renderPosition = 0; renderPosition < [ourPrefs memGraphLength]; renderPosition++) {

		// No data at this position?
		if (renderPosition >= [memHistory count])
			break;

		// Grab data
		NSDictionary *memData = [memHistory objectAtIndex:renderPosition];
		if (!memData)
			continue;
		float activeMB = [[memData objectForKey:@"activemb"] floatValue];
		float inactiveMB = [[memData objectForKey:@"inactivemb"] floatValue];
		float wireMB = [[memData objectForKey:@"wiremb"] floatValue];
		float compressedMB = [[memData objectForKey:@"compressedmb"] floatValue];
		float totalMB = [[memData objectForKey:@"totalmb"] floatValue];
		if (activeMB < 0) {
			activeMB = 0;
		};
		if (inactiveMB < 0) {
			inactiveMB = 0;
		};
		if (wireMB < 0) {
			wireMB = 0;
		};
		if (compressedMB < 0) {
			compressedMB = 0;
		};
		if (activeMB > totalMB) {
			activeMB = totalMB;
		};
		if (inactiveMB > totalMB) {
			inactiveMB = totalMB;
		};
		if (wireMB > totalMB) {
			wireMB = totalMB;
		};
		if (compressedMB > totalMB) {
			compressedMB = totalMB;
		};

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
	[inactiveColor set];
	[inactivePath fill];
	[compressedColor set];
	[compressedPath fill];
	[activeColor set];
	[activePath fill];
	[wireColor set];
	[wirePath fill];
} // renderMemHistoryIntoImages

// Paging indicator from Bernhard Baehr. Originally an overlay to the bar display, I liked
// it so much I broke the display out so it could be used with any mode.

- (void)renderPageIndicatorImageSize:(NSSize)imageSize {

	// Read in the paging deltas
	uint64_t pageIns = 0, pageOuts = 0;
	NSDictionary *currentMemStats = [memHistory objectAtIndex:0];
	if (currentMemStats) {
		pageIns = [[currentMemStats objectForKey:@"deltapageins"] unsignedLongLongValue];
		pageOuts = [[currentMemStats objectForKey:@"deltapageouts"] unsignedLongLongValue];
	}

	// Get height
	float indicatorHeight = imageSize.height;

	BOOL darkTheme = self.isDark;

	// Set up the pageout path
	NSBezierPath *arrow = [NSBezierPath bezierPath];
	[arrow moveToPoint:NSMakePoint(kMemPagingDisplayWidth / 2.0 + (menuWidth - kMemPagingDisplayWidth) - 0.5, 1)];
	[arrow lineToPoint:NSMakePoint(kMemPagingDisplayWidth / 2.0 + (menuWidth - kMemPagingDisplayWidth) + 4.5, 5.0)];
	[arrow lineToPoint:NSMakePoint(kMemPagingDisplayWidth / 2.0 + (menuWidth - kMemPagingDisplayWidth) - 5.5, 5.0)];
	[arrow closePath];
	// Draw
	if (pageIns) {
		[pageInColor set];
	}
	else {
		if (darkTheme) {
			[[NSColor darkGrayColor] set];
		}
		else {
			[[pageInColor colorWithAlphaComponent:0.25] set];
		}
	}
	[arrow fill];

	// Set up the pagein path
	arrow = [NSBezierPath bezierPath];
	[arrow moveToPoint:NSMakePoint(kMemPagingDisplayWidth / 2.0 + (menuWidth - kMemPagingDisplayWidth) - 0.5, indicatorHeight - 1)];
	[arrow lineToPoint:NSMakePoint(kMemPagingDisplayWidth / 2.0 + (menuWidth - kMemPagingDisplayWidth) + 4.5, indicatorHeight - 5.0)];
	[arrow lineToPoint:NSMakePoint(kMemPagingDisplayWidth / 2.0 + (menuWidth - kMemPagingDisplayWidth) - 5.5, indicatorHeight - 5.0)];
	[arrow closePath];
	// Draw
	if (pageOuts) {
		[pageOutColor set];
	}
	else {
		if (darkTheme) {
			[[NSColor darkGrayColor] set];
		}
		else {
			[[pageOutColor colorWithAlphaComponent:0.25] set];
		}
	}
	[arrow fill];

	// Draw the activity count
	NSString *countString = nil;
	if ((pageIns + pageOuts) >= 1000) {
		countString = @"1k+";
	}
	else {
		countString = [NSString stringWithFormat:@"%d", (int)(pageIns + pageOuts)];
	}
	NSAttributedString *renderString = [[NSAttributedString alloc]
		initWithString:countString
			attributes:[NSDictionary dictionaryWithObjectsAndKeys:
										 [NSFont monospacedDigitSystemFontOfSize:9.5
																		  weight:NSFontWeightRegular],
										 NSFontAttributeName,
										 fgMenuThemeColor, NSForegroundColorAttributeName,
										 nil]];
	// Using NSParagraphStyle to right align clipped weird, so do it manually
	// Also draw low to ignore descenders
	NSSize renderSize = [renderString size];
	[renderString drawAtPoint:NSMakePoint(menuWidth - kMemPagingDisplayWidth +
											  round((kMemPagingDisplayWidth - renderSize.width) / 2.0),
										  4.0)]; // Just hardcode the vertical offset
} // renderPageIndicator

///////////////////////////////////////////////////////////////
//
//  Timer callbacks
//
///////////////////////////////////////////////////////////////

- (void)timerFired:(NSTimer *)timer {

	NSDictionary *currentStats = [memStats memStats];
	if (!currentStats)
		return;

	// Add to history (at least one)
	if ([ourPrefs memDisplayMode] == kMemDisplayGraph) {
		if ([memHistory count] >= [ourPrefs memGraphLength]) {
			[memHistory removeObjectsInRange:NSMakeRange(0, [memHistory count] - [ourPrefs memGraphLength] + 1)];
		}
	}
	else {
		[memHistory removeAllObjects];
	}
	[memHistory addObject:currentStats];

	// If the menu is down, update it
	if (self.isMenuVisible) {
		[self updateMenuWhenDown];
	}
	[super timerFired:timer];
} // timerFired

- (void)updateMenuWhenDown {

	NSDictionary *newSwapStats = [memStats swapStats];
	if (newSwapStats) {
		currentSwapStats = newSwapStats;
	}

	// Update the menu content
	[self updateMenuContent];

	// Force the menu to redraw
	LiveUpdateMenu(extraMenu);

} // updateMenuWhenDown

///////////////////////////////////////////////////////////////
//
//  Prefs
//
///////////////////////////////////////////////////////////////

- (void)configFromPrefs:(NSNotification *)notification {
#ifdef ELCAPITAN
	[super configDisplay:kMemMenuBundleID
				fromPrefs:ourPrefs
		withTimerInterval:[ourPrefs memInterval]];
#endif

	// Update prefs
	[ourPrefs syncWithDisk];

	// Handle menubar theme changes
	fgMenuThemeColor = self.menuBarTextColor;

	// Cache colors to skip archive cycle from prefs
	freeColor = [self colorByAdjustingForLightDark:[ourPrefs memFreeColor]];
	usedColor = [self colorByAdjustingForLightDark:[ourPrefs memUsedColor]];
	activeColor = [self colorByAdjustingForLightDark:[ourPrefs memActiveColor]];
	inactiveColor = [self colorByAdjustingForLightDark:[ourPrefs memInactiveColor]];
	wireColor = [self colorByAdjustingForLightDark:[ourPrefs memWireColor]];
	compressedColor = [self colorByAdjustingForLightDark:[ourPrefs memCompressedColor]];
	pageInColor = [self colorByAdjustingForLightDark:[ourPrefs memPageInColor]];
	pageOutColor = [self colorByAdjustingForLightDark:[ourPrefs memPageOutColor]];

	// Since text rendering is so CPU intensive we minimize this by
	// prerendering what we can if we need it
	numberLabelPrerender = nil;
	NSAttributedString *renderUString = [[NSAttributedString alloc]
		initWithString:[[NSBundle bundleForClass:[self class]]
						   localizedStringForKey:kUsedLabel
										   value:nil
										   table:nil]
			attributes:[NSDictionary dictionaryWithObjectsAndKeys:
										 [NSFont monospacedDigitSystemFontOfSize:9.5
																		  weight:NSFontWeightRegular],
										 NSFontAttributeName,
										 usedColor, NSForegroundColorAttributeName,
										 nil]];
	NSAttributedString *renderFString = [[NSAttributedString alloc]
		initWithString:[[NSBundle bundleForClass:[self class]]
						   localizedStringForKey:kFreeLabel
										   value:nil
										   table:nil]
			attributes:[NSDictionary dictionaryWithObjectsAndKeys:
										 [NSFont monospacedDigitSystemFontOfSize:9.5
																		  weight:NSFontWeightRegular],
										 NSFontAttributeName,
										 freeColor, NSForegroundColorAttributeName,
										 nil]];
	if ([renderUString size].width > [renderFString size].width) {
		numberLabelPrerender = [[NSImage alloc] initWithSize:NSMakeSize([renderUString size].width,
																		self.height - 1)];
	}
	else {
		numberLabelPrerender = [[NSImage alloc] initWithSize:NSMakeSize([renderFString size].width,
																		self.height - 1)];
	}
	[numberLabelPrerender lockFocus];
	// No descenders so render both lines lower than normal
	[renderUString drawAtPoint:NSMakePoint(0, floor([numberLabelPrerender size].height / 2.0) - 1)];
	[renderFString drawAtPoint:NSMakePoint(0, -1)];
	[numberLabelPrerender unlockFocus];

	// Figure out the length of "MB" localization
	float mbLength = 0;
	if ([ourPrefs memDisplayMode] == kMemDisplayNumber) {
		NSAttributedString *renderMBString = [[NSAttributedString alloc]
			initWithString:[localizedStrings objectForKey:kMBLabel]
				attributes:[NSDictionary dictionaryWithObjectsAndKeys:
											 [NSFont monospacedDigitSystemFontOfSize:9.5
																			  weight:NSFontWeightRegular],
											 NSFontAttributeName,
											 nil]];
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
			}
			else if ([[[memStats memStats] objectForKey:@"totalmb"] unsignedLongLongValue] >= 1000) {
				menuWidth = kMemNumberDisplayLongWidth + mbLength;
				textWidth = kMemNumberDisplayLongWidth + mbLength;
			}
			else {
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

	// Force initial update
	statusItem.button.image = self.image;
} // configFromPrefs

@end

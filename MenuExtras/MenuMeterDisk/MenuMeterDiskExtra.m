//
//  MenuMeterDiskExtra.m
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

#import "MenuMeterDiskExtra.h"


///////////////////////////////////////////////////////////////
//
//	Private methods
//
///////////////////////////////////////////////////////////////

@interface MenuMeterDiskExtra (PrivateMethods)

// Menu content
- (NSArray *)diskSpaceMenuItemImages:(NSArray *)driveDetails;
// Menu actions
- (void)openOrEjectVolume:(id)sender;
// Prefs
- (void)configFromPrefs:(NSNotification *)notification;

@end


///////////////////////////////////////////////////////////////
//
//	init/unload/dealloc
//
///////////////////////////////////////////////////////////////

@implementation MenuMeterDiskExtra

- init {

    self = [super initWithBundleID:kDiskMenuBundleID];
	if (!self) {
		return nil;
	}
    ourPrefs = [MenuMeterDefaults sharedMenuMeterDefaults];
	if (!ourPrefs) {
		NSLog(@"MenuMeterDisk unable to connect to preferences. Abort.");
		return nil;
	}

	// Create the IO monitor
	diskIOMonitor = [[MenuMeterDiskIO alloc] init];
	// Create the space monitor
	diskSpaceMonitor = [[MenuMeterDiskSpace alloc] init];
	if (!(diskIOMonitor && diskSpaceMonitor)) {
		NSLog(@"MenuMeterDisk unable to load data gatherers. Abort.");
		return nil;
	}

	// Calc disk space base 2 or 10 depending on system version unless the user
	// has forced
	if (![ourPrefs diskSpaceForceBaseTwo]) {
		[diskSpaceMonitor setBaseTen:YES];
	}

	// Setup our menu
	extraMenu = [[NSMenu alloc] initWithTitle:@""];
	if (!extraMenu) {
		return nil;
	}
	// Disable menu autoenabling
	[extraMenu setAutoenablesItems:NO];


	// Register for pref changes
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self
														selector:@selector(configFromPrefs:)
															name:kDiskMenuBundleID
														  object:kPrefChangeNotification];
	// Register for 10.10 theme changes
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self
														selector:@selector(configFromPrefs:)
															name:kAppleInterfaceThemeChangedNotification
														  object:nil];

	// And configure directly from prefs on first load
	[self configFromPrefs:nil];

	// Sanity check image load
	if (!(idleImage && readImage && writeImage && readwriteImage)) {
		NSLog(@"MenuMeterDisk could not load activity images. Abort.");
		return nil;
	}

	// Config initial state
	displayedActivity = kDiskActivityIdle;

    // And hand ourself back to SystemUIServer
	NSLog(@"MenuMeterDisk loaded.");
    return self;

} // initWithBundle

- (void)willUnload {

	// Unregister pref change notifications
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self
															   name:nil
															 object:nil];

	// Let the pref panel know we have been removed
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:kDiskMenuBundleID
																   object:kDiskMenuUnloadNotification];


} // willUnload

 // dealloc

///////////////////////////////////////////////////////////////
//
//	NSMenuExtra view callbacks
//
///////////////////////////////////////////////////////////////

- (NSImage *)image {
    [self setupAppearance];

	// Switch on state
	switch (displayedActivity) {
		case kDiskActivityIdle:
			return idleImage;
			break;
		case kDiskActivityRead:
			return readImage;
			break;
		case kDiskActivityWrite:
			return writeImage;
			break;
		case kDiskActivityReadWrite:
			return readwriteImage;
			break;
		default:
			return idleImage;
	}

} // image

- (NSMenu *)menu {

	// Clear out the menu
	while ([extraMenu numberOfItems]) {
		[extraMenu removeItemAtIndex:0];
	}

	// Get the disk space data
	NSArray *diskSpaceData = [diskSpaceMonitor diskSpaceData];
	if (!diskSpaceData || ![diskSpaceData count]) return extraMenu;

	// Build the menu item images
	NSArray *itemImages = [self diskSpaceMenuItemImages:diskSpaceData];
	if ([itemImages count] != [diskSpaceData count]) return extraMenu;

	// Add our menu item images
	for (int i = 0; i < [itemImages count]; i++) {
		NSMenuItem *item = (NSMenuItem *)[extraMenu addItemWithTitle:@""
															  action:@selector(openOrEjectVolume:)
													   keyEquivalent:@""];
		[item setImage:[itemImages objectAtIndex:i]];
		// Set the represented object to the path (for open/eject)
		[item setRepresentedObject:[[diskSpaceData objectAtIndex:i] objectForKey:@"path"]];
		[item setTarget:self];
	}
    [extraMenu addItem:[NSMenuItem separatorItem]];
    [self addStandardMenuEntriesTo:extraMenu];

	return extraMenu;

} // menu

- (NSArray *)diskSpaceMenuItemImages:(NSArray *)driveDetails {

	// Menu item content is rendered into images render. We do this because
	// it is not possible to subclass NSMenuItemView across all OS versions.
	NSMutableArray *itemImages = [NSMutableArray array];

	// Set up attributes for strings
	NSDictionary *stringAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
										fgMenuThemeColor,
										NSForegroundColorAttributeName,
										[NSFont systemFontOfSize:11.0f],
										NSFontAttributeName,
										nil];

	// Loop the disk info, deciding on text metrics and generating
	// attributed strings
	NSMutableArray	*nameStrings = [NSMutableArray array],
					*detailStrings = [NSMutableArray array],
					*freeStrings = [NSMutableArray array],
					*usedStrings = [NSMutableArray array],
					*totalStrings = [NSMutableArray array];
	double	widestNameText = 0, widestDetailsText = 0,
			widestFreeSpaceText = 0,  widestUsedSpaceText = 0,
			widestTotalSpaceText = 0;
	NSEnumerator *driveDetailEnum = [driveDetails objectEnumerator];
	NSDictionary *driveDetail = nil;
	while ((driveDetail = [driveDetailEnum nextObject])) {
		NSMutableAttributedString *renderString = nil;

		// Name text
		renderString = [[NSMutableAttributedString alloc]
						 initWithString:[driveDetail objectForKey:@"name"]];
		[renderString addAttributes:stringAttributes range:NSMakeRange(0,[renderString length])];
		[nameStrings addObject:renderString];
		if ([renderString size].width > widestNameText) {
			widestNameText = [renderString size].width;
		}

		// Details
		renderString = [[NSMutableAttributedString alloc]
						 initWithString:[NSString stringWithFormat:@"(%@, %@)",
											[driveDetail objectForKey:@"device"],
											[driveDetail objectForKey:@"fstype"]]];
		[renderString addAttributes:stringAttributes range:NSMakeRange(0,[renderString length])];
		[detailStrings addObject:renderString];
		if ([renderString size].width > widestDetailsText) {
			widestDetailsText = [renderString size].width;
		}

		// Now used, free and total
		renderString = [[NSMutableAttributedString alloc]
							initWithString:[driveDetail objectForKey:@"free"]];
		[renderString addAttributes:stringAttributes range:NSMakeRange(0,[renderString length])];
		[freeStrings addObject:renderString];
		if ([renderString size].width > widestFreeSpaceText) {
			widestFreeSpaceText = [renderString size].width;
		}
		renderString = [[NSMutableAttributedString alloc]
							initWithString:[driveDetail objectForKey:@"used"]];
		[renderString addAttributes:stringAttributes range:NSMakeRange(0,[renderString length])];
		[usedStrings addObject:renderString];
		if ([renderString size].width > widestUsedSpaceText) {
			widestUsedSpaceText = [renderString size].width;
		}
		renderString = [[NSMutableAttributedString alloc]
							initWithString:[driveDetail objectForKey:@"total"]];
		[renderString addAttributes:stringAttributes range:NSMakeRange(0,[renderString length])];
		[totalStrings addObject:renderString];
		if ([renderString size].width > widestTotalSpaceText) {
			widestTotalSpaceText = [renderString size].width;
		}

	}

	// Round off the text widths
	widestNameText = ceil(widestNameText);
	widestDetailsText = ceil(widestDetailsText);
	widestFreeSpaceText = ceil(widestFreeSpaceText);
	widestUsedSpaceText = ceil(widestUsedSpaceText);
	widestTotalSpaceText = ceil(widestTotalSpaceText);

	// Decide which is the biggest text, start with assuming that top line
	// (name and details) is widest.
	double finalTextWidth = widestNameText + widestDetailsText + 25;
	if ((widestFreeSpaceText + widestUsedSpaceText + widestTotalSpaceText + 30) > finalTextWidth) {
		finalTextWidth = widestFreeSpaceText + widestUsedSpaceText + widestTotalSpaceText + 30;
	}

	// Loop again, rendering the final image
	for (int i = 0; i < [driveDetails count]; i++) {

		// If we are missing an icon we need an empty image, but we need
		// the icon to decide the menuitem height
		NSImage *volIcon = [[driveDetails objectAtIndex:i] objectForKey:@"icon"];
		if (!volIcon) {
			volIcon = [[NSImage alloc] initWithSize:NSMakeSize(32, 32)];
		}

		// Build the new image
		NSImage *menuItemImage = [[NSImage alloc] initWithSize:NSMakeSize([volIcon size].width + 10 + (float)finalTextWidth,
																		   [volIcon size].height)];
		[menuItemImage lockFocus];
		[volIcon compositeToPoint:NSMakePoint(0, 0) operation:NSCompositeSourceOver];
		[(NSAttributedString *)[nameStrings objectAtIndex:i]
				drawAtPoint:NSMakePoint(ceilf((float)[volIcon size].width) + 10,
										ceilf((float)[volIcon size].height / 2))];
		[(NSAttributedString *)[detailStrings objectAtIndex:i]
				drawAtPoint:NSMakePoint(ceilf((float)[volIcon size].width) + 10 + (float)widestNameText + 15,
										ceilf((float)[volIcon size].height / 2))];
		[(NSAttributedString *)[usedStrings objectAtIndex:i]
				drawAtPoint:NSMakePoint(ceilf((float)[volIcon size].width) + 10, 1)];
		[(NSAttributedString *)[freeStrings objectAtIndex:i]
				drawAtPoint:NSMakePoint(ceilf((float)[volIcon size].width) + 10 + (float)widestUsedSpaceText + 10, 1)];
		[(NSAttributedString *)[totalStrings objectAtIndex:i]
				drawAtPoint:NSMakePoint(ceilf((float)[volIcon size].width) + 10 + (float)widestUsedSpaceText + 10 + (float)widestFreeSpaceText + 10, 1)];
		[menuItemImage unlockFocus];
		[itemImages addObject:menuItemImage];
	}

	return itemImages;

} // diskSpaceMenuItemImages

///////////////////////////////////////////////////////////////
//
//	Timer callback
//
///////////////////////////////////////////////////////////////

- (void)timerFired:(NSTimer *)timer {

	// Have the monitor report state
	DiskIOActivityType activity = [diskIOMonitor diskIOActivity];

	// Only render if the state has changed
	if (activity != displayedActivity) {
		// Store out the new status
		displayedActivity = activity;
	}
	[super timerFired:timer];

} // timerFired

///////////////////////////////////////////////////////////////
//
//	Menu actions
//
///////////////////////////////////////////////////////////////

- (void)openOrEjectVolume:(id)sender {

	// Pressed modifiers
	UInt32 modKeys = GetCurrentKeyModifiers();

	// Decide action
	BOOL eject = ([ourPrefs diskSelectMode] == kDiskSelectModeEject);
	if (modKeys & optionKey) eject = !eject;

	if (eject) {
		BOOL removable = NO;
		if (![[NSWorkspace sharedWorkspace] getFileSystemInfoForPath:[sender representedObject]
														 isRemovable:&removable
														  isWritable:NULL
													   isUnmountable:NULL
														 description:NULL
																type:NULL]) {
			NSLog(@"MenuMeterDisk unable to get filesystem information for \"%@\".", [sender representedObject]);
		}
		// Have to eject/unmount the volume via diskutil because Carbon calls and NSWorkspace
		// both got bizarrely slow in 10.4.x. Wrap in exception handling for NSTask errors,
		// using old-school for 10.2 compatibility.
		NS_DURING
			if (removable) {
				[[NSTask launchedTaskWithLaunchPath:@"/usr/sbin/diskutil"
										 arguments:[NSArray arrayWithObjects:@"eject",
														[sender representedObject],
														nil]] waitUntilExit];
			} else {
				[[NSTask launchedTaskWithLaunchPath:@"/usr/sbin/diskutil"
										 arguments:[NSArray arrayWithObjects:@"unmount",
														[sender representedObject],
														nil]] waitUntilExit];
			}
		NS_HANDLER
			NSLog(@"MenuMeterDisk unable to eject/unmount \"%@\" using diskutil.", [sender representedObject]);
		NS_ENDHANDLER
	} else {
		if (![[NSWorkspace sharedWorkspace] openFile:[sender representedObject]]) {
			NSLog(@"MenuMeterDisk unable to open \"%@\".", [sender representedObject]);
		}
	}

} // openOrEjectVolume

///////////////////////////////////////////////////////////////
//
//	Prefs
//
///////////////////////////////////////////////////////////////

- (void)configFromPrefs:(NSNotification *)notification {
#ifdef ELCAPITAN
    [super configDisplay:kDiskMenuBundleID fromPrefs:ourPrefs withTimerInterval:[ourPrefs diskInterval]];
#endif

	// Update prefs
	[ourPrefs syncWithDisk];

	// Handle menubar theme changes
	fgMenuThemeColor = MenuItemTextColor();
	
	// Decide on image set name prefix
	NSString *imageSetNamePrefix = [kDiskImageSets objectAtIndex:[ourPrefs diskImageset]];
	if (self.isDark) {
		imageSetNamePrefix = [kDiskDarkImageSets objectAtIndex:[ourPrefs diskImageset]];
	}

	// Read/scale the boto disk icon for those styles that need it
	NSImage *bootDiskIcon = [[NSWorkspace sharedWorkspace] iconForFile:@"/"];
	[bootDiskIcon setScalesWhenResized:YES];
	[bootDiskIcon setSize:NSMakeSize(kDiskViewWidth, kDiskViewWidth)];

	// Release current images
	idleImage = nil;
	readImage = nil;
	writeImage = nil;
	readwriteImage = nil;

	// Setup new images as overlays or basic images
    float menubarHeight = [NSApplication sharedApplication].mainMenu.menuBarHeight;
	if ([ourPrefs diskImageset] == kDiskArrowsImageSet) {
		// Small disk arrow is an overlay on the boot disk icon
		idleImage = [[NSImage alloc] initWithSize:NSMakeSize(kDiskViewWidth, menubarHeight)];
		[idleImage lockFocus];
		[bootDiskIcon compositeToPoint:NSMakePoint(0, (menubarHeight - kDiskViewWidth) / 2)
							 operation:NSCompositeSourceOver];
		[idleImage unlockFocus];
		// Read
		readImage = [[NSImage alloc] initWithSize:NSMakeSize(kDiskViewWidth, menubarHeight)];
		[readImage lockFocus];
		[bootDiskIcon compositeToPoint:NSMakePoint(0, (menubarHeight - kDiskViewWidth) / 2)
							 operation:NSCompositeSourceOver];
		[[[NSImage alloc] initWithContentsOfFile:
		   [[NSBundle mainBundle] pathForResource:[imageSetNamePrefix stringByAppendingString:@"Read"]
								   ofType:@"tiff"]]
			compositeToPoint:NSMakePoint(0, 0) operation:NSCompositeSourceOver];
		[readImage unlockFocus];
		// Write
		writeImage = [[NSImage alloc] initWithSize:NSMakeSize(kDiskViewWidth, menubarHeight)];
		[writeImage lockFocus];
		[bootDiskIcon compositeToPoint:NSMakePoint(0, (menubarHeight - kDiskViewWidth) / 2)
							 operation:NSCompositeSourceOver];
		[[[NSImage alloc] initWithContentsOfFile:
			[[NSBundle mainBundle]pathForResource:[imageSetNamePrefix stringByAppendingString:@"Write"]
								   ofType:@"tiff"]]
			compositeToPoint:NSMakePoint(0, 0) operation:NSCompositeSourceOver];
		[writeImage unlockFocus];
		// Read/Write
		readwriteImage = [[NSImage alloc] initWithSize:NSMakeSize(kDiskViewWidth, menubarHeight)];
		[readwriteImage lockFocus];
		[bootDiskIcon compositeToPoint:NSMakePoint(0, (menubarHeight - kDiskViewWidth) / 2)
							 operation:NSCompositeSourceOver];
		[[[NSImage alloc] initWithContentsOfFile:
			[[NSBundle mainBundle]pathForResource:[imageSetNamePrefix stringByAppendingString:@"ReadWrite"]
								   ofType:@"tiff"]]
			compositeToPoint:NSMakePoint(0, 0) operation:NSCompositeSourceOver];
		[readwriteImage unlockFocus];
	} else if ([ourPrefs diskImageset]  == kDiskArrowsLargeImageSet) {
		// Large arrow disk icon overlays based on patches by Mac-arena the Bored Zo
		// (macrulez at softhome.net).
		// Read
		readImage = [[NSImage alloc] initWithSize:NSMakeSize(kDiskViewWidth, menubarHeight)];
		[readImage lockFocus];
		[bootDiskIcon compositeToPoint:NSMakePoint(0, (menubarHeight - kDiskViewWidth) / 2)
							 operation:NSCompositeSourceOver];
		NSBezierPath *readArrowPath = [NSBezierPath bezierPath];
		[readArrowPath moveToPoint:NSMakePoint(0, (menubarHeight / 2) + 1)];
		[readArrowPath lineToPoint:NSMakePoint(kDiskViewWidth, (menubarHeight / 2) + 1)];
		[readArrowPath lineToPoint:NSMakePoint(kDiskViewWidth / 2, (menubarHeight / 2) + 9)];
		[readArrowPath closePath];
		[[NSColor greenColor] set];
		[readArrowPath fill];
		[readImage unlockFocus];
		// Write
		writeImage = [[NSImage alloc] initWithSize:NSMakeSize(kDiskViewWidth, menubarHeight)];
		[writeImage lockFocus];
		[bootDiskIcon compositeToPoint:NSMakePoint(0, (menubarHeight - kDiskViewWidth) / 2)
							 operation:NSCompositeSourceOver];
		NSBezierPath *writeArrowPath = [NSBezierPath bezierPath];
		[writeArrowPath moveToPoint:NSMakePoint(0, (menubarHeight / 2) - 1)];
		[writeArrowPath lineToPoint:NSMakePoint(kDiskViewWidth, (menubarHeight / 2) - 1)];
		[writeArrowPath lineToPoint:NSMakePoint(kDiskViewWidth / 2, (menubarHeight / 2) - 9)];
		[writeArrowPath closePath];
		[[NSColor redColor] set];
		[writeArrowPath fill];
		[writeImage unlockFocus];
		// Idle
		idleImage = [[NSImage alloc] initWithSize:NSMakeSize(kDiskViewWidth, menubarHeight)];
		[idleImage lockFocus];
		[bootDiskIcon compositeToPoint:NSMakePoint(0, (menubarHeight - kDiskViewWidth) / 2)
			operation:NSCompositeSourceOver];
		[idleImage unlockFocus];
		// Read/Write
		readwriteImage = [[NSImage alloc] initWithSize:NSMakeSize(kDiskViewWidth, menubarHeight)];
		[readwriteImage lockFocus];
		[bootDiskIcon compositeToPoint:NSMakePoint(0, (menubarHeight - kDiskViewWidth) / 2)
							 operation:NSCompositeSourceOver];
		[[NSColor greenColor] set];
		[readArrowPath fill];
		[[NSColor redColor] set];
		[writeArrowPath fill];
		[readwriteImage unlockFocus];
	} else {
		// Load the static images
		idleImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle]
						pathForResource:[imageSetNamePrefix stringByAppendingString:@"Idle"] ofType:@"tiff"]];
		readImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle]
						pathForResource:[imageSetNamePrefix stringByAppendingString:@"Read"] ofType:@"tiff"]];
		writeImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle]
						pathForResource:[imageSetNamePrefix stringByAppendingString:@"Write"] ofType:@"tiff"]];
		readwriteImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle]
						pathForResource:[imageSetNamePrefix stringByAppendingString:@"ReadWrite"] ofType:@"tiff"]];
	}

	// Force initial update
	[self timerFired:nil];
} // configFromPrefs

@end

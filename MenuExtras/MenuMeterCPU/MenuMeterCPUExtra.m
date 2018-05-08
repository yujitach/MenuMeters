//
//  MenuMeterCPUExtra.m
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

#import "MenuMeterCPUExtra.h"

///////////////////////////////////////////////////////////////
//
//	Private methods
//
///////////////////////////////////////////////////////////////

@interface MenuMeterCPUExtra (PrivateMethods)

// Image renderers
- (void)renderHistoryGraphIntoImage:(NSImage *)image forProcessor:(uint32_t)processor atOffset:(float)offset;
- (void)renderSinglePercentIntoImage:(NSImage *)image forProcessor:(uint32_t)processor atOffset:(float)offset;
- (void)renderSplitPercentIntoImage:(NSImage *)image forProcessor:(uint32_t)processor atOffset:(float)offset;
- (void)renderThermometerIntoImage:(NSImage *)image forProcessor:(uint32_t)processor atOffset:(float)offset;

// Timer callbacks
- (void)updateMenuWhenDown;
- (void)updatePowerMate;

// Menu actions
- (void)openProcessViewer:(id)sender;
- (void)openActivityMonitor:(id)sender;
- (void)openConsole:(id)sender;

// Prefs
- (void)configFromPrefs:(NSNotification *)notification;

@end


///////////////////////////////////////////////////////////////
//
//	Localized strings
//
///////////////////////////////////////////////////////////////

#define kSingleProcessorTitle				@"Processor:"
#define kMultiProcessorTitle				@"Processors:"
#define kUptimeTitle						@"Uptime:"
#define kTaskThreadTitle					@"Tasks/Threads:"
#define kLoadAverageTitle					@"Load Average (1m, 5m, 15m):"
#define kProcessTitle                       @"Top CPU Intensive Processes:"
#define kOpenProcessViewerTitle				@"Open Process Viewer"
#define kOpenActivityMonitorTitle			@"Open Activity Monitor"
#define kOpenConsoleTitle					@"Open Console"
#define kNoInfoErrorMessage					@"No info available"


///////////////////////////////////////////////////////////////
//
//	init/unload/dealloc
//
///////////////////////////////////////////////////////////////

@implementation MenuMeterCPUExtra

- initWithBundle:(NSBundle *)bundle {

	self = [super initWithBundle:bundle];
	if (!self) {
		return nil;
	}

	// Load our pref bundle, we do this as a bundle because we are a plugin
	// to SystemUIServer and as a result cannot have the same class loaded
	// from every meter. Using a shared bundle each loads fixes this.
    ourPrefs = [MenuMeterDefaults sharedMenuMeterDefaults];
	if (!ourPrefs) {
		NSLog(@"MenuMeterCPU unable to connect to preferences. Abort.");
		return nil;
	}

	// Data gatherers and storage
	cpuInfo = [[MenuMeterCPUStats alloc] init];
    cpuTopProcesses = [[MenuMeterCPUTopProcesses alloc] init];
	uptimeInfo = [[MenuMeterUptime alloc] init];
	loadHistory = [NSMutableArray array];
	if (!(cpuInfo && uptimeInfo && loadHistory && cpuTopProcesses)) {
		NSLog(@"MenuMeterCPU unable to load data gatherers or storage. Abort.");
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

	// Add processor info which never changes
	if ([cpuInfo numberOfCPUs] > 1) {
		menuItem = (NSMenuItem *)[extraMenu addItemWithTitle:[bundle localizedStringForKey:kMultiProcessorTitle value:nil table:nil]
													  action:nil
											   keyEquivalent:@""];
	} else {
		menuItem = (NSMenuItem *)[extraMenu addItemWithTitle:[bundle localizedStringForKey:kSingleProcessorTitle value:nil table:nil]
													  action:nil
											   keyEquivalent:@""];
	}
	[menuItem setEnabled:NO];
	menuItem = (NSMenuItem *)[extraMenu addItemWithTitle:[NSString stringWithFormat:kMenuIndentFormat, [cpuInfo processorDescription]]
												  action:nil
										   keyEquivalent:@""];
	[menuItem setEnabled:NO];

	// Add uptime title and blank for uptime display
	menuItem = (NSMenuItem *)[extraMenu addItemWithTitle:[bundle localizedStringForKey:kUptimeTitle value:nil table:nil]
												  action:nil
										   keyEquivalent:@""];
	[menuItem setEnabled:NO];
	menuItem = (NSMenuItem *)[extraMenu addItemWithTitle:@"" action:nil keyEquivalent:@""];
	[menuItem setEnabled:NO];

	// Add task title and blanks for task display
	menuItem = (NSMenuItem *)[extraMenu addItemWithTitle:[bundle localizedStringForKey:kTaskThreadTitle value:nil table:nil]
												  action:nil
										   keyEquivalent:@""];
	[menuItem setEnabled:NO];
	menuItem = (NSMenuItem *)[extraMenu addItemWithTitle:@"" action:nil keyEquivalent:@""];
	[menuItem setEnabled:NO];

	// Add load title and blanks for load display
	menuItem = (NSMenuItem *)[extraMenu addItemWithTitle:[bundle localizedStringForKey:kLoadAverageTitle value:nil table:nil]
												  action:nil
										   keyEquivalent:@""];
	[menuItem setEnabled:NO];
	menuItem = (NSMenuItem *)[extraMenu addItemWithTitle:@"" action:nil keyEquivalent:@""];
	[menuItem setEnabled:NO];

    // Add top kCPUrocessCountMax most CPU intensive processes
    menuItem = (NSMenuItem *)[extraMenu addItemWithTitle:[bundle localizedStringForKey:kProcessTitle value:nil table:nil]
                                                  action:nil
                                           keyEquivalent:@""];
    [menuItem setEnabled:NO];
    
    // as this list is "static" unfortunately we need all of the kCPUrocessCountMax menu items and hide/show later the un-wanted/wanted ones
    for (NSInteger ndx = 0; ndx < kCPUrocessCountMax; ++ndx) {
        menuItem = (NSMenuItem *)[extraMenu addItemWithTitle:@"" action:nil keyEquivalent:@""];
        [menuItem setEnabled:NO];
    }
    
	// And the "Open Process Viewer"/"Open Activity Monitor" and "Open Console" item
	[extraMenu addItem:[NSMenuItem separatorItem]];
	menuItem = (NSMenuItem *)[extraMenu addItemWithTitle:[bundle localizedStringForKey:kOpenActivityMonitorTitle value:nil table:nil]
												  action:@selector(openActivityMonitor:)
										   keyEquivalent:@""];
	[menuItem setTarget:self];
	menuItem = (NSMenuItem *)[extraMenu addItemWithTitle:[bundle localizedStringForKey:kOpenConsoleTitle value:nil table:nil]
												  action:@selector(openConsole:)
										   keyEquivalent:@""];
	[menuItem setTarget:self];

	// Get our view
	extraView = [[MenuMeterCPUView alloc] initWithFrame:[[self view] frame] menuExtra:self];
	if (!extraView) {
		return nil;
	}
	[self setView:extraView];

	// Register for pref changes
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self
														selector:@selector(configFromPrefs:)
															name:kCPUMenuBundleID
														  object:kPrefChangeNotification];
	// Register for 10.10 theme changes
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self
														selector:@selector(configFromPrefs:)
															name:kAppleInterfaceThemeChangedNotification
														  object:nil];

	// And configure directly from prefs on first load
	[self configFromPrefs:nil];

	// And hand ourself back to SystemUIServer
	NSLog(@"MenuMeterCPU loaded.");
	return self;

} // initWithBundle

- (void)willUnload {

	// Unregister pref change notifications
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self
															   name:nil
															 object:nil];

	// Let the pref panel know we have been removed
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:kCPUMenuBundleID
																   object:kCPUMenuUnloadNotification];

	// Let super do the rest
	[super willUnload];

} // willUnload

 // dealloc

///////////////////////////////////////////////////////////////
//
//	NSMenuExtraView callbacks
//
///////////////////////////////////////////////////////////////

- (NSImage *)image {

	// Image to render into (and return to view)
	NSImage *currentImage = [[NSImage alloc] initWithSize:NSMakeSize((float)menuWidth,
																	  [extraView frame].size.height - 1)];
	if (!currentImage) return nil;

	// Don't render without data
	if (![loadHistory count]) return nil;

	// Loop by processor
	float renderOffset = 0;
	int cpuDisplayModePrefs = [ourPrefs cpuDisplayMode];
	for (uint32_t cpuNum = 0; cpuNum < [cpuInfo numberOfCPUs]; cpuNum++) {

		// Render graph if needed
		if (cpuDisplayModePrefs & kCPUDisplayGraph) {
			[self renderHistoryGraphIntoImage:currentImage forProcessor:cpuNum atOffset:renderOffset];
			// Adjust render offset
			renderOffset += [ourPrefs cpuGraphLength];
		}
		// Render percent if needed
		if (cpuDisplayModePrefs & kCPUDisplayPercent) {
			if ([ourPrefs cpuPercentDisplay] == kCPUPercentDisplaySplit) {
				[self renderSplitPercentIntoImage:currentImage forProcessor:cpuNum atOffset:renderOffset];
			} else {
				[self renderSinglePercentIntoImage:currentImage forProcessor:cpuNum atOffset:renderOffset];
			}
			renderOffset += percentWidth;
		}
		if (cpuDisplayModePrefs & kCPUDisplayThermometer) {
			[self renderThermometerIntoImage:currentImage forProcessor:cpuNum atOffset:renderOffset];
			renderOffset += kCPUThermometerDisplayWidth;
		}
		// At end of each proc adjust spacing
		renderOffset += kCPUDisplayMultiProcGapWidth;

		// If we're averaging all we're done on first iteration
		if ([ourPrefs cpuAvgAllProcs]) break;
	}

	// Send it back for the view to render
	return currentImage;

} // image

- (NSMenu *)menu {

	// Update the various displays starting with uptime
	NSString *title = [NSString stringWithFormat:kMenuIndentFormat, [uptimeInfo uptime]];
	if (title) LiveUpdateMenuItemTitle(extraMenu, kCPUUptimeInfoMenuIndex, title);
    
	// Tasks
	title = [NSString stringWithFormat:kMenuIndentFormat, [cpuInfo currentProcessorTasks]];
	if (title) LiveUpdateMenuItemTitle(extraMenu, kCPUTaskInfoMenuIndex, title);
    
	// Load
	title = [NSString stringWithFormat:kMenuIndentFormat, [cpuInfo loadAverage]];
	if (title) LiveUpdateMenuItemTitle(extraMenu, kCPULoadInfoMenuIndex, title);
    
    // Top CPU intensive processes
    NSArray* processes = ([ourPrefs cpuMaxProcessCount] > 0 ? [cpuTopProcesses runningProcessesByCPUUsage:[ourPrefs cpuMaxProcessCount]] : nil);    
    LiveUpdateMenuItemTitleAndVisibility(extraMenu, kCPUProcessLabelMenuIndex, nil, (processes == nil));
    for (NSInteger ndx = 0; ndx < kCPUrocessCountMax; ++ndx) {
        if (ndx < processes.count) {
            title = [NSString stringWithFormat:kMenuIndentFormat, [NSString stringWithFormat:@"%@ (%.1f%%)", processes[ndx][kProcessListItemProcessNameKey], [processes[ndx][kProcessListItemCPUKey] floatValue]]];
            LiveUpdateMenuItemTitleAndVisibility(extraMenu, kCPUProcessMenuIndex + ndx, title, (title.length == 0));
        }
        else {
            LiveUpdateMenuItemTitleAndVisibility(extraMenu, kCPUProcessMenuIndex + ndx, nil, YES);
        }
    }
    
	// Send the menu back to SystemUIServer
	return extraMenu;

} // menu

///////////////////////////////////////////////////////////////
//
//    NSMenuDelegate
//
///////////////////////////////////////////////////////////////

- (void)menuWillOpen:(NSMenu *)menu {
    
    if ([ourPrefs cpuMaxProcessCount] > 0)
        [cpuTopProcesses startUpdateProcessList];
     
    [super menuWillOpen:menu];
    
} // menuWillOpen:

- (void)menuDidClose:(NSMenu *)menu {

    [cpuTopProcesses stopUpdateProcessList];

    [super menuDidClose:menu];

} // menuDidClose:

///////////////////////////////////////////////////////////////
//
//	Image renderers
//
///////////////////////////////////////////////////////////////

- (void)renderHistoryGraphIntoImage:(NSImage *)image forProcessor:(uint32_t)processor atOffset:(float)offset {

	// Construct paths
	NSBezierPath *systemPath =  [NSBezierPath bezierPath];
	NSBezierPath *userPath =  [NSBezierPath bezierPath];
	if (!(systemPath && userPath)) return;

	// Position for initial offset
	[systemPath moveToPoint:NSMakePoint(offset, 0)];
	[userPath moveToPoint:NSMakePoint(offset, 0)];

	// Loop over pixels in desired width until we're out of data
	int renderPosition = 0;
	float renderHeight = (float)[image size].height - 0.5f;  // Save space for baseline
	int cpuGraphLength = [ourPrefs cpuGraphLength];
	NSUInteger numberOfCPUs = [cpuInfo numberOfCPUs];
	for (renderPosition = 0; renderPosition < cpuGraphLength; renderPosition++) {
		// No data at this position?
		if (renderPosition >= [loadHistory count]) break;

		// Grab data
		NSArray *loadHistoryEntry = [loadHistory objectAtIndex:renderPosition];
		if (!loadHistoryEntry || [loadHistoryEntry count] < numberOfCPUs) {
			// Bad data, just skip
			continue;
		}

		// Get load at this position.
		MenuMeterCPULoad *load = loadHistoryEntry[processor];
		float system = load.system;
		float user = load.user;
		if ([ourPrefs cpuAvgAllProcs]) {
			for (uint32_t cpuNum = 1; cpuNum < numberOfCPUs; cpuNum++) {
				MenuMeterCPULoad *load = loadHistoryEntry[cpuNum];
				system += load.system;
				user += load.user;
			}
			system /= numberOfCPUs;
			user /= numberOfCPUs;
		}
		// Sanity and limit
		if (system < 0) system = 0;
		if (system > 1) system = 1;
		if (user < 0) user = 0;
		if (user > 1) user = 1;

		// Update paths (adding baseline)
		[userPath lineToPoint:NSMakePoint(offset + renderPosition,
										  (((system + user) > 1 ? 1 : (system + user)) * renderHeight) + 0.5f)];
		[systemPath lineToPoint:NSMakePoint(offset + renderPosition,
											(system * renderHeight) + 0.5f)];
	}

	// Return to lower edge (fill will close the graph)
	[userPath lineToPoint:NSMakePoint(offset + renderPosition - 1, 0)];
	[systemPath lineToPoint:NSMakePoint(offset + renderPosition - 1, 0)];

	// Draw
	[image lockFocus];
	[userColor set];
	[userPath fill];
	[systemColor set];
	[systemPath fill];

	// Clean up
	[[NSColor blackColor] set];
	[image unlockFocus];

} // renderHistoryGraphIntoImage:forProcessor:atOffset:

- (void)renderSinglePercentIntoImage:(NSImage *)image forProcessor:(uint32_t)processor atOffset:(float)offset {

	// Current load (if available)
	NSArray *currentLoad = [loadHistory lastObject];
	if (!currentLoad || ([currentLoad count] < [cpuInfo numberOfCPUs])) return;

	MenuMeterCPULoad *load = currentLoad[processor];
	float totalLoad = load.system + load.user;
	if ([ourPrefs cpuAvgAllProcs]) {
		NSUInteger numberOfCPUs = [cpuInfo numberOfCPUs];
		for (uint32_t cpuNum = 1; cpuNum < numberOfCPUs; cpuNum++) {
			MenuMeterCPULoad *load = currentLoad[cpuNum];
			totalLoad += load.user + load.system;
		}
		totalLoad /= numberOfCPUs;
	}
	if (totalLoad > 1) totalLoad = 1;
	if (totalLoad < 0) totalLoad = 0;

	// Get the prerendered text and draw
	NSImage *percentImage = [singlePercentCache objectAtIndex:roundf(totalLoad * 100.0f)];
	if (!percentImage) return;
	[image lockFocus];
	if ([ourPrefs cpuDisplayMode] & kCPUDisplayGraph) {
		// When graphing right align, we had trouble with doing this with NSParagraphStyle, so do it manually
		[percentImage compositeToPoint:NSMakePoint(offset + percentWidth - ceilf((float)[percentImage size].width) - 1,
												   (float)round(([image size].height - [percentImage size].height) / 2))
							 operation:NSCompositeSourceOver];
	} else {
		// Otherwise center
		[percentImage compositeToPoint:NSMakePoint(offset + (float)floor(((percentWidth - [percentImage size].width) / 2)),
												   (float)round(([image size].height - [percentImage size].height) / 2))
							 operation:NSCompositeSourceOver];
	}
	[image unlockFocus];

}  // renderSinglePercentIntoImage:forProcessor:atOffset:

- (void)renderSplitPercentIntoImage:(NSImage *)image forProcessor:(uint32_t)processor atOffset:(float)offset {

	// Current load (if available)
	NSArray *currentLoad = [loadHistory lastObject];
	if (!currentLoad || ([currentLoad count] < [cpuInfo numberOfCPUs])) return;

	MenuMeterCPULoad *load = currentLoad[processor];
	float system = load.system;
	float user = load.user;
	if ([ourPrefs cpuAvgAllProcs]) {
		NSUInteger numberOfCPUs = [cpuInfo numberOfCPUs];
		for (uint32_t cpuNum = 1; cpuNum < numberOfCPUs; cpuNum++) {
			MenuMeterCPULoad *load = currentLoad[cpuNum];
			system += load.system;
			user += load.user;
		}
		system /= numberOfCPUs;
		user /= numberOfCPUs;
	}
	if (system > 1) system = 1;
	if (system < 0) system = 0;
	if (user > 1) user = 1;
	if (user < 0) user = 0;

	// Get the prerendered text and draw
	NSImage *systemImage = [splitSystemPercentCache objectAtIndex:roundf(system * 100.0f)];
	NSImage *userImage = [splitUserPercentCache objectAtIndex:roundf(user * 100.0f)];
	if (!(systemImage && userImage)) return;
	[image lockFocus];
	if ([ourPrefs cpuDisplayMode] & kCPUDisplayGraph) {
		// When graphing right align, we had trouble with doing this with NSParagraphStyle, so do it manually
		[systemImage compositeToPoint:NSMakePoint(offset + percentWidth - [systemImage size].width - 1, 0)
							 operation:NSCompositeSourceOver];
		[userImage compositeToPoint:NSMakePoint(offset + percentWidth - (float)[userImage size].width - 1,
												(float)floor([image size].height / 2))
							operation:NSCompositeSourceOver];
	} else {
		[systemImage compositeToPoint:NSMakePoint(offset + floorf((percentWidth - (float)[systemImage size].width) / 2), 0)
							operation:NSCompositeSourceOver];
		[userImage compositeToPoint:NSMakePoint(offset + floorf((percentWidth - (float)[systemImage size].width) / 2),
												(float)floor([image size].height / 2))
							operation:NSCompositeSourceOver];
	}
	[image unlockFocus];

} // renderSplitPercentIntoImage:forProcessor:atOffset:

- (void)renderThermometerIntoImage:(NSImage *)image forProcessor:(uint32_t)processor atOffset:(float)offset {

	// Current load (if available)
	NSArray *currentLoad = [loadHistory lastObject];
	if (!currentLoad || ([currentLoad count] < [cpuInfo numberOfCPUs])) return;

	MenuMeterCPULoad *load = currentLoad[processor];
	float system = load.system;
	float user = load.user;
	if ([ourPrefs cpuAvgAllProcs]) {
		NSUInteger numberOfCPUs = [cpuInfo numberOfCPUs];
		for (uint32_t cpuNum = 1; cpuNum < numberOfCPUs; cpuNum++) {
			MenuMeterCPULoad *load = currentLoad[cpuNum];
			system += load.system;
			user += load.user;
		}
		system /= numberOfCPUs;
		user /= numberOfCPUs;
	}
	if (system > 1) system = 1;
	if (system < 0) system = 0;
	if (user > 1) user = 1;
	if (user < 0) user = 0;

	// Paths
	float thermometerTotalHeight = (float)[image size].height - 3.0f;
	NSBezierPath *userPath = [NSBezierPath bezierPathWithRect:NSMakeRect(offset + 1.5f, 1.5f, kCPUThermometerDisplayWidth - 3,
																		 thermometerTotalHeight * ((user + system) > 1 ? 1 : (user + system)))];
	NSBezierPath *systemPath = [NSBezierPath bezierPathWithRect:NSMakeRect(offset + 1.5f, 1.5f, kCPUThermometerDisplayWidth - 3,
																		  thermometerTotalHeight * system)];
	NSBezierPath *framePath = [NSBezierPath bezierPathWithRect:NSMakeRect(offset + 1.5f, 1.5f, kCPUThermometerDisplayWidth - 3, thermometerTotalHeight)];

	// Draw
	[image lockFocus];
	[userColor set];
	[userPath fill];
	[systemColor set];
	[systemPath fill];
	[fgMenuThemeColor set];
	[framePath stroke];

	// Reset
	[[NSColor blackColor] set];
	[image unlockFocus];

} // renderThermometerIntoImage:forProcessor:atOffset:

///////////////////////////////////////////////////////////////
//
//	Timer callbacks
//
///////////////////////////////////////////////////////////////

- (void)timerFired:(NSTimer *)timerFired {
	// Get the current load
	NSArray *currentLoad = [cpuInfo currentLoad];
	if (!currentLoad) return;

	// Add to history (at least one)
	if ([ourPrefs cpuDisplayMode] & kCPUDisplayGraph) {
		if ([loadHistory count] >= [ourPrefs cpuGraphLength]) {
			[loadHistory removeObjectsInRange:NSMakeRange(0, [loadHistory count] - [ourPrefs cpuGraphLength] + 1)];
		}
	} else {
		[loadHistory removeAllObjects];
	}
	[loadHistory addObject:currentLoad];

	// If the menu is down force it to update
	if (self.isMenuVisible) {
		[self updateMenuWhenDown];
	}

	// If we're supporting PowerMate do that now
	if ([ourPrefs cpuPowerMate] && powerMate) {
		[self updatePowerMate];
	}
	[super timerFired:timerFired];
} // timerFired

- (void)updateMenuWhenDown {

	// Update content
	[self menu];

	// Force the menu to redraw
	LiveUpdateMenu(extraMenu);

} // updateMenuWhenDown

- (void)updatePowerMate {

	// Current load (if available)
	NSArray *currentLoad = [loadHistory lastObject];
	if (!currentLoad || ([currentLoad count] < [cpuInfo numberOfCPUs])) return;

	double totalLoad = 0;
	NSUInteger numberOfCPUs = [cpuInfo numberOfCPUs];
	for (uint32_t cpuNum = 0; cpuNum < numberOfCPUs; cpuNum++) {
		MenuMeterCPULoad *load = currentLoad[cpuNum];
		totalLoad += load.system + load.user;
	}
	totalLoad /= numberOfCPUs;
	if (totalLoad > 1) totalLoad = 1;
	if (totalLoad < 0) totalLoad = 0;

	if ([ourPrefs cpuPowerMateMode] == kCPUPowerMateGlow) {
		// Ramp to the glow point in half our update time
		[powerMate setGlow:totalLoad rampInterval:[ourPrefs cpuInterval] / 2];
	} else if ([ourPrefs cpuPowerMateMode] == kCPUPowerMatePulse) {
		[powerMate setPulse:totalLoad];
	} else if ([ourPrefs cpuPowerMateMode] == kCPUPowerMateInverseGlow) {
		[powerMate setGlow:(1.0 - totalLoad) rampInterval:[ourPrefs cpuInterval] / 2];
	} else if ([ourPrefs cpuPowerMateMode] == kCPUPowerMateInversePulse) {
		[powerMate setPulse:(1.0 - totalLoad)];
	}

} // updatePowerMate

///////////////////////////////////////////////////////////////
//
//	Menu actions
//
///////////////////////////////////////////////////////////////

- (void)openProcessViewer:(id)sender {

	if (![[NSWorkspace sharedWorkspace] launchApplication:@"Process Viewer.app"]) {
		NSLog(@"MenuMeterCPU unable to launch the Process Viewer.");
	}

} // openProcessViewer

- (void)openActivityMonitor:(id)sender {

	if (![[NSWorkspace sharedWorkspace] launchApplication:@"Activity Monitor.app"]) {
		NSLog(@"MenuMeterCPU unable to launch the Activity Monitor.");
	}

} // openActivityMonitor

- (void)openConsole:(id)sender {

	if (![[NSWorkspace sharedWorkspace] launchApplication:@"Console.app"]) {
		NSLog(@"MenuMeterCPU unable to launch the Console.");
	}

} // openProcessViewer

///////////////////////////////////////////////////////////////
//
//	Prefs
//
///////////////////////////////////////////////////////////////

- (void)configFromPrefs:(NSNotification *)notification {
#ifdef ELCAPITAN
    [super configDisplay:kCPUMenuBundleID fromPrefs:ourPrefs withTimerInterval:[ourPrefs cpuInterval]];
#endif
	// Update prefs
	[ourPrefs syncWithDisk];

	// Handle menubar theme changes
	fgMenuThemeColor = MenuItemTextColor();

	// Cache colors to skip archiver
	userColor = [ourPrefs cpuUserColor];
	systemColor = [ourPrefs cpuSystemColor];

	// It turns out that text drawing is _much_ slower than compositing images together
	// so we render several arrays of images, each representing a different percent value
	// which we can then composite together. Testing showed this to be almost 2x
	// faster than rendering the text every time through.
	singlePercentCache = nil;
	splitUserPercentCache = nil;
	splitSystemPercentCache = nil;

	if (([ourPrefs cpuPercentDisplay] == kCPUPercentDisplayLarge) ||
		([ourPrefs cpuPercentDisplay] == kCPUPercentDisplaySmall)) {

		singlePercentCache = [NSMutableArray array];
		float fontSize = 14;
		if ([ourPrefs cpuPercentDisplay] == kCPUPercentDisplaySmall) {
			fontSize = 11;
		}
		NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
											[NSFont systemFontOfSize:fontSize],
											NSFontAttributeName,
											fgMenuThemeColor,
											NSForegroundColorAttributeName,
											nil];
		for (int i = 0; i <= 100; i++) {
			NSAttributedString *cacheText = [[NSAttributedString alloc]
												initWithString:[NSString stringWithFormat:@"%d%%", i]
													attributes:textAttributes];
			NSImage *cacheImage = [[NSImage alloc] initWithSize:NSMakeSize(ceilf((float)[cacheText size].width),
																			ceilf((float)[cacheText size].height))];
			[cacheImage lockFocus];
			[cacheText drawAtPoint:NSMakePoint(0, 0)];
			[cacheImage unlockFocus];
			[singlePercentCache addObject:cacheImage];
		}
		// Calc the new width
		percentWidth = (float)round([[singlePercentCache lastObject] size].width) + kCPUPercentDisplayBorderWidth;
	} else if ([ourPrefs cpuPercentDisplay] == kCPUPercentDisplaySplit) {
		splitUserPercentCache = [NSMutableArray array];
		NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
											[NSFont systemFontOfSize:9.5f],
											NSFontAttributeName,
											userColor,
											NSForegroundColorAttributeName,
											nil];
		for (int i = 0; i <= 100; i++) {
			NSAttributedString *cacheText = [[NSAttributedString alloc]
												initWithString:[NSString stringWithFormat:@"%d%%", i]
													attributes:textAttributes];
			NSImage *cacheImage = [[NSImage alloc] initWithSize:NSMakeSize(ceilf((float)[cacheText size].width),
																			// No descenders, so render lower
																			[cacheText size].height - 1)];

			[cacheImage lockFocus];
			[cacheText drawAtPoint:NSMakePoint(0, -1)];  // No descenders in our text so render lower
			[cacheImage unlockFocus];
			[splitUserPercentCache addObject:cacheImage];
		}
		splitSystemPercentCache = [NSMutableArray array];
		textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
								[NSFont systemFontOfSize:9.5f],
								NSFontAttributeName,
								systemColor,
								NSForegroundColorAttributeName,
								nil];
		for (int i = 0; i <= 100; i++) {
			NSAttributedString *cacheText = [[NSAttributedString alloc]
											  initWithString:[NSString stringWithFormat:@"%d%%", i]
											  attributes:textAttributes];
			NSImage *cacheImage = [[NSImage alloc] initWithSize:NSMakeSize(ceilf((float)[cacheText size].width),
																			// No descenders, so render lower
																			[cacheText size].height - 1)];

			[cacheImage lockFocus];
			[cacheText drawAtPoint:NSMakePoint(0, -1)];  // No descenders in our text so render lower
			[cacheImage unlockFocus];
			[splitSystemPercentCache addObject:cacheImage];
		}
		// Calc the new text width, both arrays are same font, so use either
		percentWidth = (float)round([[splitSystemPercentCache lastObject] size].width) + kCPUPercentDisplayBorderWidth;
	}

	// Fix our menu size to match our new config
	menuWidth = 0;
	if ([ourPrefs cpuDisplayMode] & kCPUDisplayPercent) {
		menuWidth += (([ourPrefs cpuAvgAllProcs] ? 1 : [cpuInfo numberOfCPUs]) * percentWidth);
	}
	if ([ourPrefs cpuDisplayMode] & kCPUDisplayGraph) {
		menuWidth += (([ourPrefs cpuAvgAllProcs] ? 1 : [cpuInfo numberOfCPUs]) * [ourPrefs cpuGraphLength]);
	}
	if ([ourPrefs cpuDisplayMode] & kCPUDisplayThermometer) {
		menuWidth += (([ourPrefs cpuAvgAllProcs] ? 1 : [cpuInfo numberOfCPUs]) * kCPUThermometerDisplayWidth);
	}
	if (![ourPrefs cpuAvgAllProcs] && ([cpuInfo numberOfCPUs] > 1)) {
		menuWidth += (([cpuInfo numberOfCPUs] - 1) * kCPUDisplayMultiProcGapWidth);
	}

	// Handle PowerMate
	if ([ourPrefs cpuPowerMate]) {
		// Load PowerMate if needed, this grabs control of the PowerMate
		if (!powerMate) {
			powerMate = [[MenuMeterPowerMate alloc] init];
		}
		if (powerMate) {
			// Configure its initial state
			switch ([ourPrefs cpuPowerMateMode]) {
				case kCPUPowerMateGlow:
					[powerMate stopPulse];
					[powerMate setGlow:0];
					break;
				case kCPUPowerMateInverseGlow:
					[powerMate stopPulse];
					[powerMate setGlow:1.0];
					break;
				case kCPUPowerMatePulse:
					[powerMate setGlow:1.0];
					[powerMate setPulse:0];
					break;
				case kCPUPowerMateInversePulse:
					[powerMate setGlow:1.0];
					[powerMate setPulse:1.0];
					break;
			}
		} else {
			NSLog(@"MenuMeterCPU unable to load PowerMate support.");
		}
	} else {
		// Release control if the user wants it for something else
		powerMate = nil;
	}

	// Resize the view
	[extraView setFrameSize:NSMakeSize(menuWidth, [extraView frame].size.height)];
	[self setLength:menuWidth];

	// Force initial update
	[self timerFired:nil];
} // configFromPrefs

@end

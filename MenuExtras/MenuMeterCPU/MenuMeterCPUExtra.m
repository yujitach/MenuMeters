//
//  MenuMeterCPUExtra.m
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

#import "MenuMeterCPUExtra.h"

///////////////////////////////////////////////////////////////
//
//  Private methods
//
///////////////////////////////////////////////////////////////

@interface MenuMeterCPUExtra (PrivateMethods)

// Image renderers
- (void)renderHistoryGraphIntoImage:(NSImage *)image forProcessor:(uint32_t)processor atOffset:(float)offset;
- (void)renderSinglePercentIntoImage:(NSImage *)image forProcessor:(uint32_t)processor atOffset:(float)offset;
- (void)renderSplitPercentIntoImage:(NSImage *)image forProcessor:(uint32_t)processor atOffset:(float)offset;
- (void)renderThermometerIntoImage:(NSImage *)image forProcessor:(uint32_t)processor atOffset:(float)offset;
- (void)renderHorizontalThermometerIntoImage:(NSImage *)image forProcessor:(uint32_t)processor atX:(float)x andY:(float)y withWidth:(float)width andHeight:(float)height;

// Timer callbacks
- (void)updateMenuWhenDown;
- (void)updatePowerMate;

// Menu actions
- (void)openProcessViewer:(id)sender;
- (void)openActivityMonitor:(id)sender;
- (void)openConsole:(id)sender;

// Prefs
- (void)configFromPrefs:(NSNotification *)notification;

// Utilities
- (void)getCPULoadForCPU:(uint32_t)processor
			  atPosition:(NSInteger)position
			returnSystem:(double *)system
			  returnUser:(double *)user;

@end


///////////////////////////////////////////////////////////////
//
//  Localized strings
//
///////////////////////////////////////////////////////////////

#define kSingleProcessorTitle				@"Processor:"
#define kMultiProcessorTitle				@"Processors:"
#define kUptimeTitle						@"Uptime:"
#define kTaskThreadTitle					@"Tasks/Threads:"
#define kLoadAverageTitle					@"Load Average (1m, 5m, 15m):"
#define kProcessTitle						@"Top CPU Intensive Processes:"
#define kOpenProcessViewerTitle				@"Open Process Viewer"
#define kOpenConsoleTitle					@"Open Console"
#define kNoInfoErrorMessage					@"No info available"
#define kCPUPowerLimitStatusTitle			@"CPU power limit:"

///////////////////////////////////////////////////////////////
//
//  init/unload/dealloc
//
///////////////////////////////////////////////////////////////

@implementation MenuMeterCPUExtra
{
	float cpuTemperatureDisplayWidth;
}
- init {

	self = [super initWithBundleID:kCPUMenuBundleID];
	NSBundle*bundle=[NSBundle mainBundle];
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
	if ([cpuInfo numberOfCPUs] != 1) {
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
	menuItem = (NSMenuItem *)[extraMenu addItemWithTitle:[NSString stringWithFormat:kMenuIndentFormat, [cpuInfo coreDescription]]
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

	menuItem = (NSMenuItem *)[extraMenu addItemWithTitle:[bundle localizedStringForKey:kCPUPowerLimitStatusTitle value:nil table:nil]
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
	menuItem = (NSMenuItem *)[extraMenu addItemWithTitle:[bundle localizedStringForKey:kOpenConsoleTitle value:nil table:nil]
												  action:@selector(openConsole:)
										   keyEquivalent:@""];
	[menuItem setTarget:self];
	[self addStandardMenuEntriesTo:extraMenu];
	// Get our view



	// And configure directly from prefs on first load
	[self configFromPrefs:nil];

	// And hand ourself back to SystemUIServer
	NSLog(@"MenuMeterCPU loaded.");
	return self;

} // initWithBundle

// dealloc

///////////////////////////////////////////////////////////////
//
//  NSMenuExtraView callbacks
//
///////////////////////////////////////////////////////////////

- (NSImage *)image {
	[self setupAppearance];
	// Image to render into (and return to view)
	NSImage *currentImage = [[NSImage alloc] initWithSize:NSMakeSize((float)menuWidth,
																	 self.height-1)];
	if (!currentImage) return nil;

	// Don't render without data
	if (![loadHistory count]) return nil;


	uint32_t cpuCount=[cpuInfo numberOfCPUs];
	uint32_t stride=[ourPrefs cpuAvgLowerHalfProcs]?[cpuInfo numberOfCPUs]/[cpuInfo numberOfCores]:1;
	float renderOffset = 0.0f;
	// Horizontal CPU thermometer is handled differently because it has to
	// manage rows and columns in a very different way from normal horizontal
	// layout
	if(![ourPrefs cpuShowTemperature] && [ourPrefs cpuDisplayMode]==0){
		[currentImage lockFocus];
		NSAttributedString *cpuString = [[NSAttributedString alloc]
										 initWithString:@"CPU"
										 attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont monospacedDigitSystemFontOfSize:[NSFont smallSystemFontSize] weight:NSFontWeightRegular],
													 NSFontAttributeName, fgMenuThemeColor, NSForegroundColorAttributeName,
													 nil]];
		[cpuString drawAtPoint:NSMakePoint(
										   kCPULabelOnlyWidth - (float)round([cpuString size].width) - 1,
										   (float)(([currentImage size].height-[cpuString size].height) / 2)+self.baselineOffset
										   )];
		[currentImage unlockFocus];
		return currentImage;
	}
	if ([ourPrefs cpuShowTemperature]) {
		[self renderSingleTemperatureIntoImage:currentImage atOffset:renderOffset];
		renderOffset += cpuTemperatureDisplayWidth;
	}
	if ([ourPrefs cpuDisplayMode] & kCPUDisplayHorizontalThermometer) {
		// Calculate the minimum number of columns that will be needed
		uint32_t rowCount = [ourPrefs cpuHorizontalRows];
		//ceil(A/B) for ints is equal (A+B-1)/B
		uint32_t columnCount = (cpuCount+rowCount-1)/rowCount;
		//((cpuCount - 1) / [ourPrefs cpuHorizontalRows]) + 1;
		// Calculate a column width
		float columnWidth = (menuWidth - 1.0f) / columnCount;
		// Image height
		float imageHeight = (float) ([currentImage size].height);
		// Calculate a thermometer height
		float thermometerHeight = ((imageHeight - 2) / rowCount);
		for (uint32_t cpuNum = 0; cpuNum < cpuCount; cpuNum+=stride) {
			float xOffset = renderOffset + ((cpuNum / rowCount) * columnWidth) + 1.0f;
			float yOffset = (imageHeight -
							 (((cpuNum % rowCount) + 1) * thermometerHeight)) - 1.0f;
			[self renderHorizontalThermometerIntoImage:currentImage forProcessor:cpuNum atX:xOffset andY:yOffset withWidth:columnWidth andHeight:thermometerHeight];
		}
	}
	else {
		// Loop by processor
		int cpuDisplayModePrefs = [ourPrefs cpuDisplayMode];
		for (uint32_t cpuNum = 0; cpuNum < cpuCount; cpuNum+=stride) {

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

	title = [NSString stringWithFormat:kMenuIndentFormat, [cpuInfo cpuPowerLimitStatus]];
	if (title) LiveUpdateMenuItemTitle(extraMenu, kCPUPowerLimitInfoMenuIndex, title);


	// Top CPU intensive processes
	NSArray* processes = ([ourPrefs cpuMaxProcessCount] > 0 ? [cpuTopProcesses runningProcessesByCPUUsage:[ourPrefs cpuMaxProcessCount]] : nil);
	LiveUpdateMenuItemTitleAndVisibility(extraMenu, kCPUProcessLabelMenuIndex, nil, (processes == nil));
	for (NSInteger ndx = 0; ndx < kCPUrocessCountMax; ++ndx) {
		if (ndx < processes.count) {
			NSString*name=processes[ndx][kProcessListItemProcessNameKey];
			float percent=[processes[ndx][kProcessListItemCPUKey] floatValue];
			title = [NSString stringWithFormat:kMenuIndentFormat, [NSString stringWithFormat:@"%@ (%.1f%%)", name,percent ]];
			NSMenuItem*mi=[extraMenu itemAtIndex: kCPUProcessMenuIndex + ndx];
			mi.title=title;
			mi.hidden=title.length==0;

			NSNumber* pid=processes[ndx][kProcessListItemPIDKey];
			NSRunningApplication*app=[NSRunningApplication runningApplicationWithProcessIdentifier:pid.intValue];
			NSImage*icon=app.icon;
			if(!icon){
				static NSImage*defaultIcon=nil;
				if(!defaultIcon){
					defaultIcon=[[NSWorkspace sharedWorkspace] iconForFile:@"/bin/bash"];
				}
				icon=defaultIcon;
			}
			icon.size=NSMakeSize(16, 16);
			mi.image=icon;
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
// NSMenuDelegate
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
//  Image renderers
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
	for (renderPosition = 0; renderPosition < cpuGraphLength; renderPosition++) {
		// No data at this position?
		if (renderPosition >= [loadHistory count]) break;

		// Grab data
		double system=0, user=0;
		[self getCPULoadForCPU:processor atPosition:renderPosition returnSystem:&system returnUser:&user];

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
-(NSAttributedString*)percentStringForLoad:(float)load andColor:(NSColor*)color
{
	float fontSize = self.fontSize;
	NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSFont monospacedDigitSystemFontOfSize:fontSize weight:NSFontWeightRegular],
									NSFontAttributeName,
									color,
									NSForegroundColorAttributeName,
									nil];
	NSAttributedString *cacheText = [[NSAttributedString alloc]
									 initWithString:[NSString stringWithFormat:@"%d%%", (int)roundf(load * 100.0f)]
									 attributes:textAttributes];
	return cacheText;
}
- (void)renderSinglePercentIntoImage:(NSImage *)image forProcessor:(uint32_t)processor atOffset:(float)offset {


	// Current load (if available)
	double system=0,user=0;
	[self getCPULoadForCPU:processor atPosition:-1 returnSystem:&system returnUser:&user];
	float totalLoad = system + user;
	if (totalLoad > 1) totalLoad = 1;
	if (totalLoad < 0) totalLoad = 0;
	if ([ourPrefs cpuSumAllProcsPercent]) {
		totalLoad *= [cpuInfo numberOfCPUs];
	}


	[image lockFocus];
	NSAttributedString*string=[self percentStringForLoad:totalLoad andColor:fgMenuThemeColor];
	[string drawAtPoint:NSMakePoint(offset + percentWidth - ceilf((float)[string size].width) - 1,
									(float)(([image size].height - [string size].height) / 2)+self.baselineOffset)];
	[image unlockFocus];

}  // renderSinglePercentIntoImage:forProcessor:atOffset:

- (void)renderSplitPercentIntoImage:(NSImage *)image forProcessor:(uint32_t)processor atOffset:(float)offset {

	double system, user;
	[self getCPULoadForCPU:processor atPosition:-1 returnSystem:&system returnUser:&user];
	if ((system < 0) || (user < 0)) {
		return;
	}
	if ([ourPrefs cpuSumAllProcsPercent]) {
		system *= [cpuInfo numberOfCPUs];
		user  *= [cpuInfo numberOfCPUs];
	}

	// Get the prerendered text and draw
	NSAttributedString *systemString = [self percentStringForLoad:system andColor:systemColor];
	NSAttributedString *userString = [self percentStringForLoad:user andColor:userColor];
	[image lockFocus];
	[systemString drawAtPoint:NSMakePoint(offset + percentWidth - [systemString size].width - 1, -1)];
	[userString drawAtPoint:NSMakePoint(offset + percentWidth - (float)[userString size].width - 1,
										(float)floor([image size].height / 2)-1)];
	[image unlockFocus];

} // renderSplitPercentIntoImage:forProcessor:atOffset:

-(NSAttributedString*)renderTemperatureStringForString:(NSString *)temperatureString {
	return [[NSAttributedString alloc]
			initWithString:temperatureString
			attributes:[NSDictionary dictionaryWithObjectsAndKeys:
						[NSFont monospacedDigitSystemFontOfSize:self.fontSize weight:NSFontWeightRegular],
						NSFontAttributeName, temperatureColor, NSForegroundColorAttributeName,
						nil]];
}

- (void)renderSingleTemperatureIntoImage:(NSImage *)image atOffset:(float)offset {
	float_t celsius = [cpuInfo cpuProximityTemperature];
	float_t fahrenheit=celsius*1.8+32;
	NSString*temperatureString=@"";
	switch ([ourPrefs cpuTemperatureUnit]){
		case kCPUTemperatureUnitCelsius:
			temperatureString=[NSString stringWithFormat:@"%.1f℃", celsius];
			if(celsius<-100){
				temperatureString=@"??℃";
			}
			break;
		case kCPUTemperatureUnitFahrenheit:
			if (fahrenheit>=100){
				temperatureString=[NSString stringWithFormat:@"%d℉", (int)fahrenheit];
			} else {
				temperatureString=[NSString stringWithFormat:@"%.1f℉", fahrenheit];
			}
			if (celsius<-100){
				temperatureString=@"??℉";
			}
			break;
		default:
			temperatureString=@"???";
	}
	[image lockFocus];
	NSAttributedString *renderTemperatureString = [self renderTemperatureStringForString:temperatureString];
	[renderTemperatureString drawAtPoint:NSMakePoint(
													 cpuTemperatureDisplayWidth - round([renderTemperatureString size].width) - 1,
													 (([image size].height - [renderTemperatureString size].height) / 2 + self.baselineOffset)
													 )];
	[image unlockFocus];
} // renderSingleTemperatureIntoImage:atOffset:

- (void)renderThermometerIntoImage:(NSImage *)image forProcessor:(uint32_t)processor atOffset:(float)offset {

	double system, user;
	[self getCPULoadForCPU:processor atPosition:-1 returnSystem:&system returnUser:&user];
	if ((system < 0) || (user < 0)) {
		return;
	}

	// Paths
	double thermometerTotalHeight = [image size].height - 3.0;
	NSBezierPath *userPath = [NSBezierPath bezierPathWithRect:NSMakeRect(offset + 1.5, 1.5, kCPUThermometerDisplayWidth - 3,
																		 thermometerTotalHeight * ((user + system) > 1 ? 1 : (user + system)))];
	NSBezierPath *systemPath = [NSBezierPath bezierPathWithRect:NSMakeRect(offset + 1.5, 1.5, kCPUThermometerDisplayWidth - 3,
																		   thermometerTotalHeight * system)];
	NSBezierPath *framePath = [NSBezierPath bezierPathWithRect:NSMakeRect(offset + 1.5, 1.5, kCPUThermometerDisplayWidth - 3, thermometerTotalHeight)];

	// Draw
	[image lockFocus];
	[userColor set];
	[userPath fill];
	[systemColor set];
	[systemPath fill];
	[[fgMenuThemeColor colorWithAlphaComponent:kBorderAlpha] set];
	[framePath stroke];

	// Reset
	[[NSColor blackColor] set];
	[image unlockFocus];

} // renderThermometerIntoImage:forProcessor:atOffset:

- (void)renderHorizontalThermometerIntoImage:(NSImage *)image forProcessor:(uint32_t)processor atX:(float)x andY:(float)y withWidth:(float)width andHeight:(float)height {
	double system, user;
	[self getCPULoadForCPU:processor atPosition:-1 returnSystem:&system returnUser:&user];
	if ((system < 0) || (user < 0)) {
		return;
	}

	// Paths
	NSBezierPath *rightCapPath = [NSBezierPath bezierPathWithRect:NSMakeRect((x + width) - 2.0f, y, 1.0f, height - 1.0f)];

	NSBezierPath *userPath = [NSBezierPath bezierPathWithRect:NSMakeRect(x + 1.0f, y, (width - 2.0f) * ((user + system) > 1 ? 1 : (user + system)), height - 1.0f)];

	NSBezierPath *systemPath = [NSBezierPath bezierPathWithRect:NSMakeRect(x + 1.0f, y, (width - 2.0f) * system, height - 1.0f)];

	// Draw
	[image lockFocus];
	[userColor set];
	[userPath fill];
	[systemColor set];
	[systemPath fill];
	[[fgMenuThemeColor colorWithAlphaComponent:kBorderAlpha] set];
	[rightCapPath fill];

	// Reset
	[[NSColor blackColor] set];
	[image unlockFocus];

} // renderHorizontalThermometerIntoImage:forProcessor:atX:andY:withWidth:andHeight:

///////////////////////////////////////////////////////////////
//
//  Timer callbacks
//
///////////////////////////////////////////////////////////////

- (void)timerFired:(NSTimer *)timerFired {
	// Get the current load
	NSArray *currentLoad = [cpuInfo currentLoadBySorting:[ourPrefs cpuSortByUsage]];
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

	int numberOfCPUs = [cpuInfo numberOfCPUs];

	// Current load (if available)
	NSArray *currentLoad = [loadHistory lastObject];
	if (!currentLoad || ([currentLoad count] < numberOfCPUs)) return;

	double totalLoad = 0;
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
//  Menu actions
//
///////////////////////////////////////////////////////////////

- (void)openProcessViewer:(id)sender {

	if (![[NSWorkspace sharedWorkspace] launchApplication:@"Process Viewer.app"]) {
		NSLog(@"MenuMeterCPU unable to launch the Process Viewer.");
	}

} // openProcessViewer


- (void)openConsole:(id)sender {

	if (![[NSWorkspace sharedWorkspace] launchApplication:@"Console.app"]) {
		NSLog(@"MenuMeterCPU unable to launch the Console.");
	}

} // openProcessViewer

///////////////////////////////////////////////////////////////
//
//  Prefs
//
///////////////////////////////////////////////////////////////
-(float)baselineOffset
{
	float offset=1.0f;
	if ([ourPrefs cpuPercentDisplay] == kCPUPercentDisplaySmall) {
		offset=+0.5f;
	}
	if([ourPrefs cpuPercentDisplay] == kCPUPercentDisplaySplit){
		offset = +0.0f;
	}
	return offset;
}
-(float)fontSize
{
	float fontSize=14;
	if ([ourPrefs cpuPercentDisplay] == kCPUPercentDisplaySmall) {
		fontSize = 11;
	}
	if([ourPrefs cpuPercentDisplay] == kCPUPercentDisplaySplit){
		fontSize = 9.5f;
	}
	return fontSize;
}
- (void)configFromPrefs:(NSNotification *)notification {
#ifdef ELCAPITAN
	[super configDisplay:kCPUMenuBundleID fromPrefs:ourPrefs withTimerInterval:[ourPrefs cpuInterval]];
#endif
	// Update prefs
	[ourPrefs syncWithDisk];

	// Handle menubar theme changes
	fgMenuThemeColor = self.menuBarTextColor;

	// Cache colors to skip archiver
	userColor = [self colorByAdjustingForLightDark:[ourPrefs cpuUserColor]];
	systemColor = [self colorByAdjustingForLightDark:[ourPrefs cpuSystemColor]];
	temperatureColor = [self colorByAdjustingForLightDark:[ourPrefs cpuTemperatureColor]];

	int numberOfCPUs = [ourPrefs cpuAvgLowerHalfProcs]?[cpuInfo numberOfCores]:[cpuInfo numberOfCPUs];

	if ([ourPrefs cpuDisplayMode] & kCPUDisplayPercent) {
		// Calc the new width
		NSAttributedString*string=[self percentStringForLoad:[ourPrefs cpuSumAllProcsPercent]?[cpuInfo numberOfCPUs]:1.0f
													andColor:fgMenuThemeColor];
		percentWidth = (float)round([string size].width) + kCPUPercentDisplayBorderWidth;
	}

	// Fix our menu size to match our new config
	menuWidth = 0;
	if ([ourPrefs cpuDisplayMode] & kCPUDisplayHorizontalThermometer) {
		menuWidth = [ourPrefs cpuMenuWidth];
	}
	else {
		if ([ourPrefs cpuDisplayMode] & kCPUDisplayPercent) {
			menuWidth += (([ourPrefs cpuAvgAllProcs] ? 1 : numberOfCPUs) * percentWidth);
		}
		if ([ourPrefs cpuDisplayMode] & kCPUDisplayGraph) {
			menuWidth += (([ourPrefs cpuAvgAllProcs] ? 1 : numberOfCPUs) * [ourPrefs cpuGraphLength]);
		}
		if ([ourPrefs cpuDisplayMode] & kCPUDisplayThermometer) {
			menuWidth += (([ourPrefs cpuAvgAllProcs] ? 1 : numberOfCPUs) * kCPUThermometerDisplayWidth);
		}
		if (![ourPrefs cpuAvgAllProcs] && (numberOfCPUs > 1)) {
			menuWidth += ((numberOfCPUs - 1) * kCPUDisplayMultiProcGapWidth);
		}
	}
	if ([ourPrefs cpuShowTemperature]) {
		cpuTemperatureDisplayWidth=1+[self renderTemperatureStringForString:@"66.6℃"].size.width;
		menuWidth += cpuTemperatureDisplayWidth;
	}
	if(![ourPrefs cpuShowTemperature] && [ourPrefs cpuDisplayMode]==0){
		menuWidth=kCPULabelOnlyWidth;
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


	// Force initial update
	statusItem.button.image=self.image;
} // configFromPrefs

- (void)getCPULoadForCPU:(uint32_t)processor
			  atPosition:(NSInteger)position
			returnSystem:(double *)system
			  returnUser:(double *)user
{
	NSArray *currentLoad = [loadHistory lastObject];
	if(position!=-1){
		currentLoad=[loadHistory objectAtIndex:position];
	}
	if (!currentLoad || ([currentLoad count] < processor)) {
		*system = -1;
		*user = -1;
		return;
	}

	if (![ourPrefs cpuAvgAllProcs]){
		MenuMeterCPULoad*load=currentLoad[processor];
		*system = load.system;
		*user = load.user;
	}else{
		double s=0,u=0;
		int numberOfCPUs = [cpuInfo numberOfCPUs];
		for (uint32_t cpuNum = 0; cpuNum < numberOfCPUs; cpuNum++) {
			MenuMeterCPULoad *load = currentLoad[cpuNum];
			s+=load.system;
			u+=load.user;
		}
		s /= numberOfCPUs;
		u /= numberOfCPUs;
		*system=s;
		*user=u;
	}
	// Sanity and limit
	if (*system < 0) *system = 0;
	if (*system > 1) *system = 1;
	if (*user < 0) *user = 0;
	if (*user > 1) *user = 1;
}
@end

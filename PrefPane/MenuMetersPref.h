//
//  MenuMetersPrefPane.h
//
//	MenuMeters pref panel
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

#import <PreferencePanes/PreferencePanes.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <sys/types.h>
#import <sys/sysctl.h>
#import <unistd.h>
#import "AppleUndocumented.h"
#import "MenuMeters.h"
#import "MenuMeterDefaults.h"
#import "MenuMeterWorkarounds.h"
#import "MenuMeterCPU.h"
#import "MenuMeterDisk.h"
#import "MenuMeterMem.h"
#import "MenuMeterNet.h"
#import "MenuMeterPowerMate.h"


@interface MenuMetersPref : NSPreferencePane {

	// Our preferences
	MenuMeterDefaults				*ourPrefs;
	// System config framework hooks
	SCDynamicStoreRef				scSession;
	CFRunLoopSourceRef				scRunSource;
	// Main controls
	IBOutlet NSTabView				*prefTabs;
	IBOutlet NSTextField			*versionDisplay;
	// CPU pane controlsaverage
	IBOutlet NSButton				*cpuMeterToggle;
	IBOutlet NSPopUpButton			*cpuDisplayMode;
	IBOutlet NSTextField			*cpuIntervalDisplay;
	IBOutlet NSSlider				*cpuInterval;
	IBOutlet NSPopUpButton			*cpuPercentMode;
	IBOutlet NSTextField			*cpuPercentModeLabel;
    IBOutlet NSSlider               *cpuMaxProcessCount;
    IBOutlet NSTextField            *cpuMaxProcessCountCountLabel;
	IBOutlet NSSlider				*cpuGraphWidth;
	IBOutlet NSTextField			*cpuGraphWidthLabel;
	IBOutlet NSSlider				*cpuHorizontalRows;
	IBOutlet NSTextField			*cpuHorizontalRowsLabel;
    IBOutlet NSSlider               *cpuMenuWidth;
	IBOutlet NSTextField			*cpuMenuWidthLabel;
	IBOutlet NSButton				*cpuAvgProcs;
    IBOutlet NSButton               *cpuAvgLowerHalfProcs;
    IBOutlet NSButton               *cpuSortByUsage;
	IBOutlet NSButton				*cpuPowerMate;
	IBOutlet NSPopUpButton			*cpuPowerMateMode;
	IBOutlet NSColorWell			*cpuUserColor;
	IBOutlet NSTextField			*cpuUserColorLabel;
	IBOutlet NSColorWell			*cpuSystemColor;
	IBOutlet NSTextField			*cpuSystemColorLabel;
	// Disk pane controls
	IBOutlet NSButton				*diskMeterToggle;
	IBOutlet NSPopUpButton			*diskImageSet;
	IBOutlet NSTextField			*diskIntervalDisplay;
	IBOutlet NSSlider				*diskInterval;
	IBOutlet NSPopUpButton			*diskSelectMode;
	// Mem pane controls
	IBOutlet NSButton				*memMeterToggle;
	IBOutlet NSPopUpButton			*memDisplayMode;
	IBOutlet NSTextField			*memIntervalDisplay;
	IBOutlet NSSlider				*memInterval;
	IBOutlet NSButton				*memFreeUsedLabeling;
	IBOutlet NSButton				*memPageIndicator;
	IBOutlet NSSlider				*memGraphWidth;
	IBOutlet NSTextField			*memGraphWidthLabel;
	IBOutlet NSTabView				*memColorTab;
	IBOutlet NSColorWell			*memActiveColor;
	IBOutlet NSColorWell			*memInactiveColor;
	IBOutlet NSColorWell			*memWiredColor;
	IBOutlet NSColorWell			*memCompressedColor;
	IBOutlet NSColorWell			*memFreeColor;
	IBOutlet NSColorWell			*memUsedColor;
	IBOutlet NSColorWell			*memPageinColor;
	IBOutlet NSTextField			*memPageinColorLabel;
	IBOutlet NSColorWell			*memPageoutColor;
	IBOutlet NSTextField			*memPageoutColorLabel;
    IBOutlet NSButton               *memPressureMode;
	// Net pane controls
	IBOutlet NSButton				*netMeterToggle;
	IBOutlet NSPopUpButton			*netDisplayMode;
	IBOutlet NSPopUpButton			*netDisplayOrientation;
	IBOutlet NSPopUpButton			*netPreferInterface;
	IBOutlet NSPopUpButton			*netScaleMode;
	IBOutlet NSTextField			*netScaleModeLabel;
	IBOutlet NSPopUpButton			*netScaleCalc;
	IBOutlet NSTextField			*netScaleCalcLabel;
	IBOutlet NSTextField			*netIntervalDisplay;
	IBOutlet NSSlider				*netInterval;
	IBOutlet NSButton				*netThroughputLabeling;
	IBOutlet NSButton				*netThroughput1KBound;
	IBOutlet NSPopUpButton			*netGraphStyle;
	IBOutlet NSTextField			*netGraphStyleLabel;
	IBOutlet NSSlider				*netGraphWidth;
	IBOutlet NSTextField			*netGraphWidthLabel;
	IBOutlet NSColorWell			*netTxColor;
	IBOutlet NSColorWell			*netRxColor;
	IBOutlet NSColorWell			*netInactiveColor;

} // MenuMetersPref

// Pref pane standard methods
- (void)mainViewDidLoad;
- (void)willSelect;
- (void)didUnselect;

// IB Targets
- (IBAction)liveUpdateInterval:(id)sender;
- (IBAction)cpuPrefChange:(id)sender;
- (IBAction)diskPrefChange:(id)sender;
- (IBAction)memPrefChange:(id)sender;
- (IBAction)netPrefChange:(id)sender;

@end

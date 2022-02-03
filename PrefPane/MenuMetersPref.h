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
#import <AppKit/AppKit.h>
#import "MenuMeters.h"
#import "MenuMeterDefaults.h"
#import "MenuMeterWorkarounds.h"
#import "MenuMeterCPU.h"
#import "MenuMeterDisk.h"
#import "MenuMeterMem.h"
#import "MenuMeterNet.h"
#import "MenuMeterPowerMate.h"
#ifdef SPARKLE
#import <Sparkle/Sparkle.h>
#endif

@interface MenuMetersPref :
NSWindowController<NSWindowDelegate, NSToolbarDelegate, NSTabViewDelegate> 
{

	// Our preferences
	MenuMeterDefaults				*ourPrefs;
	// System config framework hooks
	SCDynamicStoreRef				scSession;
	CFRunLoopSourceRef				scRunSource;
	// Main controls
	IBOutlet NSTabView				*prefTabs;
    __unsafe_unretained IBOutlet NSTextView *aboutView;
    // CPU pane controlsaverage
	IBOutlet NSButton				*cpuMeterToggle;
    __weak IBOutlet NSButton *cpuPercentage;
    __weak IBOutlet NSButton *cpuGraph;
    __weak IBOutlet NSButton *cpuThermometer;
    __weak IBOutlet NSButton *cpuHorizontalThermometer;
    
    IBOutlet NSButton               *cpuTemperatureToggle;
    __weak IBOutlet NSPopUpButton *cpuTemperatureUnit;
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
	IBOutlet NSPopUpButton				*cpuMultipleCPU;
	IBOutlet NSButton				*cpuPowerMate;
	IBOutlet NSPopUpButton			*cpuPowerMateMode;
	IBOutlet NSColorWell			*cpuUserColor;
    IBOutlet NSColorWell            *cpuTemperatureColor;
    IBOutlet NSPopUpButton* cpuTemperatureSensor;
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
	IBOutlet NSButton				*netThroughputBits;
	IBOutlet NSPopUpButton			*netGraphStyle;
	IBOutlet NSTextField			*netGraphStyleLabel;
	IBOutlet NSSlider				*netGraphWidth;
	IBOutlet NSTextField			*netGraphWidthLabel;
	IBOutlet NSColorWell			*netTxColor;
	IBOutlet NSColorWell			*netRxColor;
	IBOutlet NSColorWell			*netInactiveColor;
    __weak IBOutlet NSPopUpButton *updateIntervalButton;
    IBOutlet NSView					*sparkleUIContainer;
    BOOL hiddenAlertIsShown;
} // MenuMetersPref

// Pref pane standard methods
- (void)mainViewDidLoad;
- (void)willSelect;
- (void)didUnselect;

#ifdef SPARKLE
-(instancetype)initWithAboutFileName:(NSString*)about andUpdater:(SUUpdater*)updater_;
#else
-(instancetype)initWithAboutFileName:(NSString*)about;
#endif
// IB Targets
-(IBAction)openAbout:(id)sender;
- (IBAction)liveUpdateInterval:(id)sender;
- (IBAction)cpuPrefChange:(id)sender;
- (IBAction)diskPrefChange:(id)sender;
- (IBAction)memPrefChange:(id)sender;
- (IBAction)netPrefChange:(id)sender;

@end

//
//	MenuMeterDefaults.m
//
//	Preference (defaults) file reader/writer
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

#import "MenuMeterDefaults.h"
#import "MenuMeterCPU.h"
#import "MenuMeterMem.h"
#import "MenuMeterDisk.h"
#import "MenuMeterNet.h"


///////////////////////////////////////////////////////////////
//
//	Private
//
///////////////////////////////////////////////////////////////

@interface MenuMeterDefaults (PrivateMethods)

// Prefs version migration
- (void)migratePrefFile;
- (void)migratePrefsForward;

// Datatype read/write
- (double)loadDoublePref:(NSString *)prefName lowBound:(double)lowBound
				highBound:(double)highBound defaultValue:(double)defaultValue;
- (void)saveDoublePref:(NSString *)prefName value:(double)value;
- (int)loadIntPref:(NSString *)prefName lowBound:(int)lowBound
		  highBound:(int)highBound defaultValue:(int)defaultValue;
- (void)saveIntPref:(NSString *)prefName value:(int)value;
- (int)loadBitFlagPref:(NSString *)prefName validFlags:(int)flags
			  zeroValid:(BOOL)zeroValid defaultValue:(int)defaultValue;
- (void)saveBitFlagPref:(NSString *)prefName value:(int)value;
- (BOOL)loadBoolPref:(NSString *)prefName defaultValue:(BOOL)defaultValue;
- (void)saveBoolPref:(NSString *)prefName value:(BOOL)value;
- (NSColor *)loadColorPref:(NSString *)prefName defaultValue:(NSColor *)defaultValue;
- (void)saveColorPref:(NSString *)prefname value:(NSColor *)value;
- (NSString *)loadStringPref:(NSString *)prefName defaultValue:(NSString *)defaultValue;
- (void)saveStringPref:(NSString *)prefName value:(NSString *)value;

@end

///////////////////////////////////////////////////////////////
//
//	init/dealloc
//
///////////////////////////////////////////////////////////////

@implementation MenuMeterDefaults

- (id)init {

	// Allow super to init
	self = [super init];
	if (!self) {
		return nil;
	}

	// Move the pref file if we need to
	[self migratePrefFile];

	// Load pref values
	[self syncWithDisk];

	// Do migration
	[self migratePrefsForward];

	// Send on back
	return self;

} // init

- (void)dealloc {

	// Save back
	[self syncWithDisk];

	// Super do its thing
	[super dealloc];

} // dealloc

///////////////////////////////////////////////////////////////
//
//	Pref read/write
//
///////////////////////////////////////////////////////////////

- (void)syncWithDisk {

	CFPreferencesSynchronize((CFStringRef)kMenuMeterDefaultsDomain,
							 kCFPreferencesCurrentUser, kCFPreferencesAnyHost);

} // syncFromDisk

///////////////////////////////////////////////////////////////
//
//	CPU menu prefs
//
///////////////////////////////////////////////////////////////

- (double)cpuInterval {
	return [self loadDoublePref:kCPUIntervalPref
					   lowBound:kCPUUpdateIntervalMin
					  highBound:kCPUUpdateIntervalMax
				   defaultValue:kCPUUpdateIntervalDefault];
} // cpuInterval

- (int)cpuDisplayMode {
	return [self loadBitFlagPref:kCPUDisplayModePref
					  validFlags:(kCPUDisplayPercent | kCPUDisplayGraph | kCPUDisplayThermometer)
					   zeroValid:NO
					defaultValue:kCPUDisplayDefault];
} // cpuDisplayMode

- (int)cpuPercentDisplay {
	return [self loadIntPref:kCPUPercentDisplayPref
					lowBound:kCPUPercentDisplayLarge
				   highBound:kCPUPercentDisplaySplit
				defaultValue:kCPUPercentDisplayDefault];
} // cpuPercentDisplay

- (int)cpuGraphLength {
	return [self loadIntPref:kCPUGraphLengthPref
					lowBound:kCPUGraphWidthMin
				   highBound:kCPUGraphWidthMax
				defaultValue:kCPUGraphWidthDefault];
} // cpuGraphLength

- (BOOL)cpuAvgAllProcs {
	return [self loadBoolPref:kCPUAvgAllProcsPref defaultValue:kCPUAvgAllProcsDefault];
} // cpuAvgAllProcs

- (BOOL)cpuPowerMate {
	return [self loadBoolPref:kCPUPowerMatePref defaultValue:kCPUPowerMateDefault];
} // cpuPowerMate

- (int)cpuPowerMateMode {
	return [self loadIntPref:kCPUPowerMateMode
					lowBound:kCPUPowerMateGlow
				   highBound:kCPUPowerMateInversePulse
				defaultValue:kCPUPowerMateModeDefault];
} // cpuPowerMateMode

- (NSColor *)cpuSystemColor {
	return [self loadColorPref:kCPUSystemColorPref defaultValue:kCPUSystemColorDefault];
} // cpuSystemColor

- (NSColor *)cpuUserColor {
	return [self loadColorPref:kCPUUserColorPref defaultValue:kCPUUserColorDefault];
} // cpuUserColor

- (void)saveCpuInterval:(double)interval {
	[self saveDoublePref:kCPUIntervalPref value:interval];
} // saveCpuInterval

- (void)saveCpuDisplayMode:(int)mode {
	[self saveIntPref:kCPUDisplayModePref value:mode];
} // saveCpuDisplayMode

- (void)saveCpuPercentDisplay:(int)mode {
	[self saveIntPref:kCPUPercentDisplayPref value:mode];
} // saveCpuPercentSplit

- (void)saveCpuGraphLength:(int)length {
	[self saveIntPref:kCPUGraphLengthPref value:length];
} // saveCpuGraphLength

- (void)saveCpuAvgAllProcs:(BOOL)average {
	[self saveBoolPref:kCPUAvgAllProcsPref value:average];
} // saveCpuAvgAllProcs

- (void)saveCpuPowerMate:(BOOL)active {
	[self saveBoolPref:kCPUPowerMatePref value:active];
} // saveCpuPowerMate

- (void)saveCpuPowerMateMode:(int)mode {
	[self saveIntPref:kCPUPowerMateMode value:mode];
} // saveCpuPowerMateMode

- (void)saveCpuSystemColor:(NSColor *)color {
	[self saveColorPref:kCPUSystemColorPref value:color];
} // saveCpuSystemColor

- (void)saveCpuUserColor:(NSColor *)color {
	[self saveColorPref:kCPUUserColorPref value:color];
} // saveCpuUserColor

///////////////////////////////////////////////////////////////
//
//	Disk menu prefs
//
///////////////////////////////////////////////////////////////

- (double)diskInterval {
	return [self loadDoublePref:kDiskIntervalPref
					   lowBound:kDiskUpdateIntervalMin
					  highBound:kDiskUpdateIntervalMax
				   defaultValue:kDiskUpdateIntervalDefault];
} // diskInterval

- (int)diskImageset {
	return [self loadIntPref:kDiskImageSetPref
					lowBound:kDiskImageSetDefault
				   highBound:((int)[kDiskImageSets count] - 1)
				defaultValue:kDiskImageSetDefault];
} // diskImageset

- (int)diskSelectMode {
	return [self loadIntPref:kDiskSelectModePref
					lowBound:kDiskSelectModeOpen
				   highBound:kDiskSelectModeEject
				defaultValue:kDiskSelectModeDefault];
} // diskSelectMode

- (BOOL)diskSpaceForceBaseTwo {
	return [self loadBoolPref:kDiskSpaceForceBaseTwoPref
				 defaultValue:kDiskSpaceForceBaseTwoDefault];
} // diskSpaceForceBaseTwo

- (void)saveDiskInterval:(double)interval {
	[self saveDoublePref:kDiskIntervalPref value:interval];
} // saveDiskInterval

- (void)saveDiskImageset:(int)imageset {
	[self saveIntPref:kDiskImageSetPref value:imageset];
} // saveDiskImageset

- (void)saveDiskSelectMode:(int)mode {
	[self saveIntPref:kDiskSelectModePref value:mode];
} // saveDiskSelectMode

///////////////////////////////////////////////////////////////
//
//	Mem menu prefs
//
///////////////////////////////////////////////////////////////

- (double)memInterval {
	return [self loadDoublePref:kMemIntervalPref
					   lowBound:kMemUpdateIntervalMin
					  highBound:kMemUpdateIntervalMax
				   defaultValue:kMemUpdateIntervalDefault];
} // memInterval

- (int)memDisplayMode {
	return [self loadIntPref:kMemDisplayModePref
					lowBound:kMemDisplayPie
				   highBound:kMemDisplayNumber
				defaultValue:kMemDisplayDefault];
} // memDisplayMode

- (BOOL)memPageIndicator {
	return [self loadBoolPref:kMemPageIndicatorPref defaultValue:kMemPageIndicatorDefault];
} // memPageIndicator

- (BOOL)memUsedFreeLabel {
	return [self loadBoolPref:kMemUsedFreeLabelPref defaultValue:kMemUsedFreeLabelDefault];
} // memUsedFreeLabel

- (int)memGraphLength {
	return [self loadIntPref:kMemGraphLengthPref
					lowBound:kMemGraphWidthMin
				   highBound:kMemGraphWidthMax
				defaultValue:kMemGraphWidthDefault];
} // memGraphLength

- (NSColor *)memFreeColor {
	return [self loadColorPref:kMemFreeColorPref defaultValue:kMemFreeColorDefault];
} // memFreeColor

- (NSColor *)memUsedColor {
	return [self loadColorPref:kMemUsedColorPref defaultValue:kMemUsedColorDefault];
} // memUsedColor

- (NSColor *)memActiveColor {
	return [self loadColorPref:kMemActiveColorPref defaultValue:kMemActiveColorDefault];
} // memActiveColor

- (NSColor *)memInactiveColor {
	return [self loadColorPref:kMemInactiveColorPref defaultValue:kMemInactiveColorDefault];
} // memInactiveColor

- (NSColor *)memWireColor {
	return [self loadColorPref:kMemWireColorPref defaultValue:kMemWireColorDefault];
} // memWireColor

- (NSColor *)memCompressedColor {
	return [self loadColorPref:kMemCompressedColorPref defaultValue:kMemCompressedColorDefault];
} // memCompressedColor

- (NSColor *)memPageInColor {
	return [self loadColorPref:kMemPageInColorPref defaultValue:kMemPageInColorDefault];
} // memPageinColor

- (NSColor *)memPageOutColor {
	return [self loadColorPref:kMemPageOutColorPref defaultValue:kMemPageOutColorDefault];
} // memPageoutColor

- (void)saveMemInterval:(double)interval {
	[self saveDoublePref:kMemIntervalPref value:interval];
} // saveMemInterval

- (void)saveMemDisplayMode:(int)mode {
	[self saveIntPref:kMemDisplayModePref value:mode];
} // saveMemDisplayMode

- (void)saveMemUsedFreeLabel:(BOOL)label {
	[self saveBoolPref:kMemUsedFreeLabelPref value:label];
} // saveMemUsedFreeLabel

- (void)saveMemPageIndicator:(BOOL)indicator {
	[self saveBoolPref:kMemPageIndicatorPref value:indicator];
} // saveMemPageIndicator

- (void)saveMemGraphLength:(int)length {
	[self saveIntPref:kMemGraphLengthPref value:length];
} // saveMemGraphLength

- (void)saveMemFreeColor:(NSColor *)color {
	[self saveColorPref:kMemFreeColorPref value:color];
} // saveMemFreeColor

- (void)saveMemUsedColor:(NSColor *)color {
	[self saveColorPref:kMemUsedColorPref value:color];
} // saveMemUsedColor

- (void)saveMemActiveColor:(NSColor *)color {
	[self saveColorPref:kMemActiveColorPref value:color];
} // saveMemActiveColor

- (void)saveMemInactiveColor:(NSColor *)color {
	[self saveColorPref:kMemInactiveColorPref value:color];
} // saveMemInactiveColor

- (void)saveMemWireColor:(NSColor *)color {
	[self saveColorPref:kMemWireColorPref value:color];
} // saveMemWireColor

- (void)saveMemCompressedColor:(NSColor *)color {
	[self saveColorPref:kMemCompressedColorPref value:color];
} // saveMemCompressedColor

- (void)saveMemPageInColor:(NSColor *)color {
	[self saveColorPref:kMemPageInColorPref value:color];
} // saveMemPageinColor

- (void)saveMemPageOutColor:(NSColor *)color {
	[self saveColorPref:kMemPageOutColorPref value:color];
} // saveMemPageoutColor

///////////////////////////////////////////////////////////////
//
//	Net menu prefs
//
///////////////////////////////////////////////////////////////

- (double)netInterval {
	return [self loadDoublePref:kNetIntervalPref
					   lowBound:kNetUpdateIntervalMin
					  highBound:kNetUpdateIntervalMax
				   defaultValue:kNetUpdateIntervalDefault];
} // netInterval

- (int)netDisplayMode {
	return [self loadBitFlagPref:kNetDisplayModePref
					  validFlags:(kNetDisplayThroughput | kNetDisplayGraph | kNetDisplayArrows)
					   zeroValid:NO
					defaultValue:kNetDisplayDefault];
} // netDisplayMode

- (int)netDisplayOrientation {
	return [self loadIntPref:kNetDisplayOrientationPref
					lowBound:kNetDisplayOrientTxRx
				   highBound:kNetDisplayOrientRxTx
				defaultValue:kNetDisplayOrientationDefault];
} // netDisplayOrientation

- (int)netScaleMode {
	return [self loadIntPref:kNetScaleModePref
					lowBound:kNetScaleInterfaceSpeed
				   highBound:kNetScalePeakTraffic
				defaultValue:kNetScaleDefault];
} // netScaleMode

- (int)netScaleCalc {
	return [self loadIntPref:kNetScaleCalcPref
					lowBound:kNetScaleCalcLinear
				   highBound:kNetScaleCalcLog
				defaultValue:kNetScaleCalcDefault];
} // netScaleCalc

- (BOOL)netThroughputLabel {
	return [self loadBoolPref:kNetThroughputLabelPref defaultValue:kNetThroughputLabelDefault];
} // netThroughputLabel

- (BOOL)netThroughput1KBound {
	return [self loadBoolPref:kNetThroughput1KBoundPref defaultValue:kNetThroughput1KBoundDefault];
} // netThroughput1KBound

- (int)netGraphStyle {
	return [self loadIntPref:kNetGraphStylePref
					lowBound:kNetGraphStyleStandard
				   highBound:kNetGraphStyleInverseOpposed
				defaultValue:kNetGraphStyleDefault];
} // netGraphStyle

- (int)netGraphLength {
	return [self loadIntPref:kNetGraphLengthPref
					lowBound:kNetGraphWidthMin
				   highBound:kNetGraphWidthMax
				defaultValue:kNetGraphWidthDefault];
} // netGraphLength

- (NSColor *)netTransmitColor {
	return [self loadColorPref:kNetTransmitColorPref defaultValue:kNetTransmitColorDefault];
} // netTransmitColor

- (NSColor *)netReceiveColor {
	return [self loadColorPref:kNetReceiveColorPref defaultValue:kNetReceiveColorDefault];
} // netReceiveColor

- (NSColor *)netInactiveColor {
	return [self loadColorPref:kNetInactiveColorPref defaultValue:kNetInactiveColorDefault];
} // netInactiveColor

- (NSString *)netPreferInterface {
	return [self loadStringPref:kNetPreferInterfacePref defaultValue:kNetPrimaryInterface];
} // netPreferInterface

- (void)saveNetInterval:(double)interval {
	[self saveDoublePref:kNetIntervalPref value:interval];
} // saveNetInterval

- (void)saveNetDisplayMode:(int)mode {
	[self saveIntPref:kNetDisplayModePref value:mode];
} // saveNetDisplayMode

- (void)saveNetDisplayOrientation:(int)orient {
	[self saveIntPref:kNetDisplayOrientationPref value:orient];
} // saveNetDisplayOrientation

- (void)saveNetScaleMode:(int)mode {
	[self saveIntPref:kNetScaleModePref value:mode];
} // saveNetScaleMode

- (void)saveNetScaleCalc:(int)calc {
	[self saveIntPref:kNetScaleCalcPref value:calc];
} // saveNetScaleCalc

- (void)saveNetThroughputLabel:(BOOL)label {
	[self saveBoolPref:kNetThroughputLabelPref value:label];
} // saveNetThroughputLabel

- (void)saveNetThroughput1KBound:(BOOL)label {
	[self saveBoolPref:kNetThroughput1KBoundPref value:label];
} // saveNetThroughput1KBound

- (void)saveNetGraphStyle:(int)style {
	[self saveIntPref:kNetGraphStylePref value:style];
} // saveNetGraphStyle

- (void)saveNetGraphLength:(int)length {
	[self saveIntPref:kNetGraphLengthPref value:length];
} // saveNetGraphLength

- (void)saveNetTransmitColor:(NSColor *)color {
	[self saveColorPref:kNetTransmitColorPref value:color];
} // saveNetTransmitColor

- (void)saveNetReceiveColor:(NSColor *)color {
	[self saveColorPref:kNetReceiveColorPref value:color];
} // saveNetReceiveColor

- (void)saveNetInactiveColor:(NSColor *)color {
	[self saveColorPref:kNetInactiveColorPref value:color];
} // saveNetInactiveColor

- (void)saveNetPreferInterface:(NSString *)interface {
	[self saveStringPref:kNetPreferInterfacePref value:interface];
} // saveNetPreferInterface

///////////////////////////////////////////////////////////////
//
//	Prefs version migration
//
///////////////////////////////////////////////////////////////

- (void)migratePrefFile {

	// Find the user's pref folder
    NSString *prefFolderPath = nil;
	FSRef prefFolderFSRef;
	OSStatus err = FSFindFolder(kUserDomain, kPreferencesFolderType, kDontCreateFolder, &prefFolderFSRef);
	if (err == noErr) {
		CFURLRef prefURL = CFURLCreateFromFSRef(kCFAllocatorSystemDefault, &prefFolderFSRef);
		if (prefURL) {
			prefFolderPath = [(NSURL *)prefURL path];
			CFRelease(prefURL);
		}
	}
	if (!prefFolderPath) {
		return;
	}

	// Can we move the file? Don't overwrite existing new prefs.
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *newPath = [kMenuMeterDefaultsDomain stringByAppendingString:@".plist"];
	NSString *oldPath = [kMenuMeterObsoleteDomain stringByAppendingString:@".plist"];
	if (![fileManager fileExistsAtPath:[prefFolderPath stringByAppendingPathComponent:newPath]] &&
		[fileManager fileExistsAtPath:[prefFolderPath stringByAppendingPathComponent:oldPath]]) {
		// Move the file
		[fileManager movePath:[prefFolderPath stringByAppendingPathComponent:oldPath]
					   toPath:[prefFolderPath stringByAppendingPathComponent:newPath]
					  handler:nil];
	}

} // _migratePrefFile

- (void)migratePrefsForward {

	// Flag set if prefs are changed.
	BOOL didChange = NO;

	// Load current preference version
	NSNumber *prefVersionNum = (NSNumber *)CFPreferencesCopyValue((CFStringRef)kPrefVersionKey,
																  (CFStringRef)kMenuMeterDefaultsDomain,
																  kCFPreferencesCurrentUser,
																  kCFPreferencesAnyHost);
	int prefVersion = -1;  // Use an illegal value
	if (prefVersionNum) {
		prefVersion = [prefVersionNum intValue];
		CFRelease(prefVersionNum);
	}

	// Migrate prefs from versions before we supported pref fields (0.5 -> 0.6)
	if (prefVersion == 0) {
		NSLog(@"MenuMeterDefaults performing preference migration from pref version null to pref version 1");
		didChange = YES;

		// Net preference changed meaning, 0 was valid (arrows only) now
		// arrows are separate pref. We also reordered the flags to fix the menu
		// layout
		NSNumber *netModeNum = (NSNumber *)CFPreferencesCopyValue((CFStringRef)kNetDisplayModePref,
																  (CFStringRef)kMenuMeterDefaultsDomain,
																  kCFPreferencesCurrentUser,
																  kCFPreferencesAnyHost);
		int newValue = 0;
		if (netModeNum) {
			switch ([netModeNum intValue]) {
				case 0:
					newValue = 1;
					break;
				case 1:
					newValue = 3;
					break;
				case 2:
					newValue = 3;
					break;
				case 3:
					newValue = 7;
					break;
				default:
					newValue = 1;
			}
			[self saveIntPref:kNetDisplayModePref value:newValue];
			CFRelease(netModeNum);
		} // end of kNetDisplayModePref migration
	}

	// Migrate prefs from version 0.6 to 0.7
	if (prefVersion == 1) {
		NSLog(@"MenuMeterDefaults performing preference migration from pref version 1 to pref version 2");
		didChange = YES;
		// Percent split pref became percent display mode
		NSNumber *splitNum = (NSNumber *)CFPreferencesCopyValue(CFSTR("kCPUPercentDisplaySplit"),
																  (CFStringRef)kMenuMeterDefaultsDomain,
																  kCFPreferencesCurrentUser,
																  kCFPreferencesAnyHost);
		if (splitNum && [splitNum intValue]) {
			[self saveIntPref:kCPUPercentDisplayPref value:kCPUPercentDisplaySplit];
		} else {
			[self saveIntPref:kCPUPercentDisplayPref value:kCPUPercentDisplaySmall];
		}
		if (splitNum) CFRelease(splitNum);
		// Kill the old
		CFPreferencesSetValue(CFSTR("kCPUPercentDisplaySplit"), NULL,
							  (CFStringRef)kMenuMeterDefaultsDomain,
							  kCFPreferencesCurrentUser,
							  kCFPreferencesAnyHost);
	}

	// Migrate prefs from version 0.7 to 1.0
	if (prefVersion == 2) {
		NSLog(@"MenuMeterDefaults performing preference migration from pref version 2 to pref version 3");
		didChange = YES;

		// Lighten color used for inactive in the mem meter pie display if the user has
		// not already changed it. Have to check this using component ranges due to the perils
		// of float equality.
		NSColor *tempColor = [self memInactiveColor];
		if (([tempColor redComponent] > 0.59) && ([tempColor redComponent] < 0.61) &&
			([tempColor greenComponent] > 0.59) && ([tempColor greenComponent] < 0.61) &&
			([tempColor blueComponent] > 0.59) && ([tempColor blueComponent] < 0.61)) {
			[self saveMemInactiveColor:kMemInactiveColorDefault];
		}

		// Fix the meaning of the Mem menu items
		NSNumber *memModeNum = (NSNumber *)CFPreferencesCopyValue((CFStringRef)kMemDisplayModePref,
																  (CFStringRef)kMenuMeterDefaultsDomain,
																  kCFPreferencesCurrentUser,
																  kCFPreferencesAnyHost);
		if (memModeNum) {
			if ([memModeNum intValue] == 2) {
				[self saveIntPref:kMemDisplayModePref value:3];
			}
			CFRelease(memModeNum);
		}
	}

	// Migrate prefs from version 1.0 to 1.1
	if (prefVersion == 3) {
		NSLog(@"MenuMeterDefaults performing preference migration from pref version 3 to pref version 4");
		didChange = YES;
		// Fix the meaning of the Mem menu items
		NSNumber *memModeNum = (NSNumber *)CFPreferencesCopyValue((CFStringRef)kMemDisplayModePref,
																  (CFStringRef)kMenuMeterDefaultsDomain,
																  kCFPreferencesCurrentUser,
																  kCFPreferencesAnyHost);
		if (memModeNum) {
			if ([memModeNum intValue] == 3) {
				[self saveIntPref:kMemDisplayModePref value:4];
			}
			CFRelease(memModeNum);
		}
	}

	// Migrate prefs from version 1.1/1.1.1 to 1.2
	if (prefVersion == 4) {
		NSLog(@"MenuMeterDefaults performing preference migration from pref version 4 to pref version 5");
		didChange = YES;
		// Clean up bad color prefs
		CFDataRef colorData = CFPreferencesCopyValue(CFSTR("kNetReceiveColorDefault"),
													  (CFStringRef)kMenuMeterDefaultsDomain,
													  kCFPreferencesCurrentUser,
													  kCFPreferencesAnyHost);
		if (colorData) {
			CFPreferencesSetValue((CFStringRef)kNetReceiveColorPref,
								  colorData,
								  (CFStringRef)kMenuMeterDefaultsDomain,
								  kCFPreferencesCurrentUser,
								  kCFPreferencesAnyHost);
			CFPreferencesSetValue(CFSTR("kNetReceiveColorDefault"), NULL,
								  (CFStringRef)kMenuMeterDefaultsDomain,
								  kCFPreferencesCurrentUser,
								  kCFPreferencesAnyHost);
			CFRelease(colorData);
		}
		colorData = CFPreferencesCopyValue(CFSTR("kNetTransmitColorDefault"),
													  (CFStringRef)kMenuMeterDefaultsDomain,
													  kCFPreferencesCurrentUser,
													  kCFPreferencesAnyHost);
		if (colorData) {
			CFPreferencesSetValue((CFStringRef)kNetTransmitColorPref,
								  colorData,
								  (CFStringRef)kMenuMeterDefaultsDomain,
								  kCFPreferencesCurrentUser,
								  kCFPreferencesAnyHost);
			CFPreferencesSetValue(CFSTR("kNetTransmitColorDefault"), NULL,
								  (CFStringRef)kMenuMeterDefaultsDomain,
								  kCFPreferencesCurrentUser,
								  kCFPreferencesAnyHost);
			CFRelease(colorData);
		}
	}

	// Migrate prefs from version from 1.3 to 1.4b1
	if (prefVersion == 5) {
		NSLog(@"MenuMeterDefaults performing preference migration from pref version 5 to pref version 6");
		didChange = YES;
		// Copy mem color to new names
		CFDataRef colorData = CFPreferencesCopyValue(CFSTR("MemPageinColor"),
													 (CFStringRef)kMenuMeterDefaultsDomain,
													 kCFPreferencesCurrentUser,
													 kCFPreferencesAnyHost);
		if (colorData) {
			CFPreferencesSetValue((CFStringRef)kMemPageInColorPref,
								  colorData,
								  (CFStringRef)kMenuMeterDefaultsDomain,
								  kCFPreferencesCurrentUser,
								  kCFPreferencesAnyHost);
			CFPreferencesSetValue(CFSTR("MemPageinColor"), NULL,
								  (CFStringRef)kMenuMeterDefaultsDomain,
								  kCFPreferencesCurrentUser,
								  kCFPreferencesAnyHost);
			CFRelease(colorData);
		}
		colorData = CFPreferencesCopyValue(CFSTR("MemPageoutColor"),
										   (CFStringRef)kMenuMeterDefaultsDomain,
										   kCFPreferencesCurrentUser,
										   kCFPreferencesAnyHost);
		if (colorData) {
			CFPreferencesSetValue((CFStringRef)kMemPageOutColorPref,
								  colorData,
								  (CFStringRef)kMenuMeterDefaultsDomain,
								  kCFPreferencesCurrentUser,
								  kCFPreferencesAnyHost);
			CFPreferencesSetValue(CFSTR("MemPageoutColor"), NULL,
								  (CFStringRef)kMenuMeterDefaultsDomain,
								  kCFPreferencesCurrentUser,
								  kCFPreferencesAnyHost);
			CFRelease(colorData);
		}
		// Delete obsolete prefs
		CFPreferencesSetValue(CFSTR("CPUNiceColor"), NULL,
							  (CFStringRef)kMenuMeterDefaultsDomain,
							  kCFPreferencesCurrentUser,
							  kCFPreferencesAnyHost);
		CFPreferencesSetValue(CFSTR("CPUAntiAlias"), NULL,
							  (CFStringRef)kMenuMeterDefaultsDomain,
							  kCFPreferencesCurrentUser,
							  kCFPreferencesAnyHost);
		CFPreferencesSetValue(CFSTR("MemAntiAlias"), NULL,
							  (CFStringRef)kMenuMeterDefaultsDomain,
							  kCFPreferencesCurrentUser,
							  kCFPreferencesAnyHost);
		CFPreferencesSetValue(CFSTR("NetAntiAlias"), NULL,
							  (CFStringRef)kMenuMeterDefaultsDomain,
							  kCFPreferencesCurrentUser,
							  kCFPreferencesAnyHost);
		CFPreferencesSetValue(CFSTR("NetGraphBaseline"), NULL,
							  (CFStringRef)kMenuMeterDefaultsDomain,
							  kCFPreferencesCurrentUser,
							  kCFPreferencesAnyHost);
	}

	// Migrate prefs from version from 1.4b1
	if (prefVersion == 6) {
		NSLog(@"MenuMeterDefaults performing preference migration from pref version 6 to pref version 7");
		didChange = YES;
		// 1.4b1 had a bug where strings were stored as archived data. Luckily
		// this only affected one pref key.
		CFDataRef preferredArchivedString = CFPreferencesCopyValue((CFStringRef)kNetPreferInterfacePref,
																   (CFStringRef)kMenuMeterDefaultsDomain,
																   kCFPreferencesCurrentUser,
																   kCFPreferencesAnyHost);
		if (preferredArchivedString) {
			if (CFGetTypeID(preferredArchivedString) == CFDataGetTypeID()) {
				NSString *preferredString = [NSUnarchiver unarchiveObjectWithData:(NSData *)preferredArchivedString];
				if (preferredString && [preferredString isKindOfClass:[NSString class]]) {
					CFPreferencesSetValue((CFStringRef)kNetPreferInterfacePref,
										  preferredString,
										  (CFStringRef)kMenuMeterDefaultsDomain,
										  kCFPreferencesCurrentUser,
										  kCFPreferencesAnyHost);
				}
			}
			CFRelease(preferredArchivedString);
		}
	}

	// Move from 7 to 8, no changes here, just skipping because of other conversion
	// bugs from 6 to 7.
	if (prefVersion == 7) {
		NSLog(@"MenuMeterDefaults performing preference migration from pref version 7 to pref version 8");
		didChange = YES;
	}

	// Save migration if needed
	if (didChange) {
		[self saveIntPref:kPrefVersionKey value:kCurrentPrefVersion];
		[self syncWithDisk];
	}

} // _migratePrefsForward

///////////////////////////////////////////////////////////////
//
//	Datatype read/write
//
///////////////////////////////////////////////////////////////

- (double)loadDoublePref:(NSString *)prefName lowBound:(double)lowBound
				highBound:(double)highBound defaultValue:(double)defaultValue {

	double returnVal = defaultValue;
	NSNumber *prefValue = (NSNumber *)CFPreferencesCopyValue((CFStringRef)prefName,
															 (CFStringRef)kMenuMeterDefaultsDomain,
															 kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	if (prefValue && [prefValue isKindOfClass:[NSNumber class]]) {
		returnVal = [prefValue doubleValue];
		// Floating point comparison needs some margin of error. Scale up
		// and truncate
		if ((floor(returnVal * 100) < floor(lowBound * 100)) ||
			(ceil(returnVal * 100) > ceil(highBound * 100))) {
			returnVal = defaultValue;
			[self saveDoublePref:prefName value:returnVal];
		}
	} else {
		[self saveDoublePref:prefName value:returnVal];
	}
	if (prefValue) CFRelease(prefValue);
	return returnVal;

} // _loadDoublePref

- (void)saveDoublePref:(NSString *)prefName value:(double)value {
	CFPreferencesSetValue((CFStringRef)prefName,
						  [NSNumber numberWithDouble:value],
						  (CFStringRef)kMenuMeterDefaultsDomain,
						  kCFPreferencesCurrentUser,
						  kCFPreferencesAnyHost);
} // _saveDoublePref

- (int)loadIntPref:(NSString *)prefName lowBound:(int)lowBound
		  highBound:(int)highBound defaultValue:(int)defaultValue {

	int returnVal = defaultValue;
	NSNumber *prefValue = (NSNumber *)CFPreferencesCopyValue((CFStringRef)prefName,
															 (CFStringRef)kMenuMeterDefaultsDomain,
															 kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	if (prefValue && [prefValue isKindOfClass:[NSNumber class]]) {
		returnVal = [prefValue intValue];
		if ((returnVal < lowBound) || (returnVal > highBound)) {
			returnVal = defaultValue;
			[self saveIntPref:prefName value:returnVal];
		}
	} else {
		[self saveIntPref:prefName value:returnVal];
	}
	if (prefValue) CFRelease(prefValue);
	return returnVal;

} // _loadIntPref

- (void)saveIntPref:(NSString *)prefname value:(int)value {
	CFPreferencesSetValue((CFStringRef)prefname,
						  [NSNumber numberWithInt:value],
						  (CFStringRef)kMenuMeterDefaultsDomain,
						  kCFPreferencesCurrentUser,
						  kCFPreferencesAnyHost);
} // _saveIntPref

- (int)loadBitFlagPref:(NSString *)prefName validFlags:(int)flags
			  zeroValid:(BOOL)zeroValid defaultValue:(int)defaultValue {

	int returnVal = defaultValue;
	NSNumber *prefValue = (NSNumber *)CFPreferencesCopyValue((CFStringRef)prefName,
															 (CFStringRef)kMenuMeterDefaultsDomain,
															 kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	if (prefValue && [prefValue isKindOfClass:[NSNumber class]]) {
		returnVal = [prefValue intValue];
		if (((returnVal | flags) != flags) || (zeroValid && !returnVal)) {
			returnVal = defaultValue;
			[self saveBitFlagPref:prefName value:returnVal];
		}
	} else {
		[self saveBitFlagPref:prefName value:returnVal];
	}
	if (prefValue) CFRelease(prefValue);
	return returnVal;

} // _loadBitFlagPref

- (void)saveBitFlagPref:(NSString *)prefName value:(int)value {
	CFPreferencesSetValue((CFStringRef)prefName,
						  [NSNumber numberWithInt:value],
						  (CFStringRef)kMenuMeterDefaultsDomain,
						  kCFPreferencesCurrentUser,
						  kCFPreferencesAnyHost);
} // _saveBitFlagPref

- (BOOL)loadBoolPref:(NSString *)prefName defaultValue:(BOOL)defaultValue {

	BOOL returnValue = defaultValue;
	NSObject *prefValue = (NSObject *)CFPreferencesCopyValue((CFStringRef)prefName,
															 (CFStringRef)kMenuMeterDefaultsDomain,
															 kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	if (prefValue && [prefValue respondsToSelector:@selector(boolValue)]) {
		returnValue = [(NSNumber *)prefValue boolValue];
	} else {
		[self saveBoolPref:prefName value:defaultValue];
	}
	if (prefValue) CFRelease(prefValue);
	return returnValue;

} // _loadBoolPref

- (void)saveBoolPref:(NSString *)prefName value:(BOOL)value {
	CFPreferencesSetValue((CFStringRef)prefName,
						  [NSNumber numberWithBool:value],
						  (CFStringRef)kMenuMeterDefaultsDomain,
						  kCFPreferencesCurrentUser,
						  kCFPreferencesAnyHost);
} // _saveBoolPref

- (NSColor *)loadColorPref:(NSString *)prefName defaultValue:(NSColor *)defaultValue {

	NSColor *returnValue = nil;
	CFDataRef archivedData = CFPreferencesCopyValue((CFStringRef)prefName,
													(CFStringRef)kMenuMeterDefaultsDomain,
													kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	if (archivedData && (CFGetTypeID(archivedData) == CFDataGetTypeID())) {
		returnValue = [NSUnarchiver unarchiveObjectWithData:(NSData *)archivedData];
		CFRelease(archivedData);
	}
	if (!returnValue) {
		[self saveColorPref:prefName value:defaultValue];
		returnValue = defaultValue;
	}
	return returnValue;

} // _loadColorPref

- (void)saveColorPref:(NSString *)prefName value:(NSColor *)value {
	if (value) {
		CFPreferencesSetValue((CFStringRef)prefName,
							  [NSArchiver archivedDataWithRootObject:value],
							  (CFStringRef)kMenuMeterDefaultsDomain,
							  kCFPreferencesCurrentUser,
							  kCFPreferencesAnyHost);
	}
} // _saveColorPref

- (NSString *)loadStringPref:(NSString *)prefName defaultValue:(NSString *)defaultValue {

	NSString *returnValue = defaultValue;
	CFStringRef prefValue = CFPreferencesCopyValue((CFStringRef)prefName,
												   (CFStringRef)kMenuMeterDefaultsDomain,
												   kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	if (prefValue && (CFGetTypeID(prefValue) == CFStringGetTypeID())) {
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5
		returnValue = NSMakeCollectable(prefValue);
#else
		returnValue = (NSString *)prefValue;
#endif
	} else {
		[self saveStringPref:prefName value:returnValue];
	}
	return [returnValue autorelease];

} // _loadStringPref

- (void)saveStringPref:(NSString *)prefName value:(NSString *)value {
	CFPreferencesSetValue((CFStringRef)prefName,
						  value,
						  (CFStringRef)kMenuMeterDefaultsDomain,
						  kCFPreferencesCurrentUser,
						  kCFPreferencesAnyHost);
} // _saveStringPref

@end

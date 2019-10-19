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
#ifndef ELCAPITAN
- (BOOL)loadBoolPref:(NSString *)prefName defaultValue:(BOOL)defaultValue;
- (void)saveBoolPref:(NSString *)prefName value:(BOOL)value;
#endif
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

+ (MenuMeterDefaults*)sharedMenuMeterDefaults
{
    static MenuMeterDefaults*foo=nil;
    if(!foo){
        foo=[[MenuMeterDefaults alloc] init];
    }
    return foo;
}
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
					  validFlags:(kCPUDisplayPercent | kCPUDisplayGraph | kCPUDisplayThermometer | kCPUDisplayHorizontalThermometer)
					   zeroValid:NO
					defaultValue:kCPUDisplayDefault];
} // cpuDisplayMode

- (int)cpuPercentDisplay {
	return [self loadIntPref:kCPUPercentDisplayPref
					lowBound:kCPUPercentDisplayLarge
				   highBound:kCPUPercentDisplaySplit
				defaultValue:kCPUPercentDisplayDefault];
} // cpuPercentDisplay

- (int)cpuMaxProcessCount {
    return [self loadIntPref:kCPUMaxProcessCountPref
                    lowBound:kCPUProcessCountMin
                   highBound:kCPUrocessCountMax
                defaultValue:kCPUProcessCountDefault];
} // cpuMaxProcessCount

- (int)cpuGraphLength {
	return [self loadIntPref:kCPUGraphLengthPref
					lowBound:kCPUGraphWidthMin
				   highBound:kCPUGraphWidthMax
				defaultValue:kCPUGraphWidthDefault];
} // cpuGraphLength

- (int)cpuHorizontalRows {
    return [self loadIntPref:kCPUHorizontalRowsPref
                    lowBound:kCPUHorizontalRowsMin
                    highBound:kCPUHorizontalRowsMax
                defaultValue:kCPUHorizontalRowsDefault];
} // cpuHorizontalRows

- (int)cpuMenuWidth {
    return [self loadIntPref:kCPUMenuWidthPref
                    lowBound:kCPUMenuWidthMin
                    highBound:kCPUMenuWidthMax
                defaultValue:kCPUMenuWidthDefault];
} // cpuMenuWidth

- (BOOL)cpuAvgAllProcs {
	return [self loadBoolPref:kCPUAvgAllProcsPref defaultValue:kCPUAvgAllProcsDefault];
} // cpuAvgAllProcs

- (BOOL)cpuSumAllProcsPercent {
	return [self loadBoolPref:kCPUSumAllProcsPercentPref defaultValue:kCPUSumAllProcsPercentDefault];
} // cpuSumAllProcsPercent

- (BOOL)cpuAvgLowerHalfProcs {
	return [self loadBoolPref:kCPUAvgLowerHalfProcsPref defaultValue:kCPUAvgLowerHalfProcsDefault];
} // cpuAvgLowerHalfProcs

- (BOOL)cpuSortByUsage {
	return [self loadBoolPref:kCPUSortByUsagePref defaultValue:kCPUSortByUsageDefault];
} // cpuSortByUsage

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

- (BOOL)cpuShowTemperature {
    return [self loadBoolPref:kCPUShowTemperature defaultValue:kCPUShowTemperatureDefault];
}

- (NSColor *)cpuTemperatureColor {
    return [self loadColorPref:kCPUTemperatureColor defaultValue:kCPUTemperatureColorDefault];
} //cpuTemperatureColor

- (void)saveCpuInterval:(double)interval {
	[self saveDoublePref:kCPUIntervalPref value:interval];
} // saveCpuInterval

- (void)saveCpuDisplayMode:(int)mode {
	[self saveIntPref:kCPUDisplayModePref value:mode];
} // saveCpuDisplayMode

- (void)saveCpuPercentDisplay:(int)mode {
	[self saveIntPref:kCPUPercentDisplayPref value:mode];
} // saveCpuPercentSplit

- (void)saveCpuMaxProcessCount:(int)maxCount {
    [self saveIntPref:kCPUMaxProcessCountPref value:maxCount];
} // saveCpuMaxProcessCount

- (void)saveCpuGraphLength:(int)length {
	[self saveIntPref:kCPUGraphLengthPref value:length];
} // saveCpuGraphLength

- (void)saveCpuHorizontalRows:(int)rows {
    [self saveIntPref:kCPUHorizontalRowsPref value:rows];
} // saveCpuHorizontalRows

- (void)saveCpuMenuWidth:(int)rows {
    [self saveIntPref:kCPUMenuWidthPref value:rows];
} // saveCpuMenuWidth

- (void)saveCpuAvgAllProcs:(BOOL)average {
	[self saveBoolPref:kCPUAvgAllProcsPref value:average];
} // saveCpuAvgAllProcs

- (void)saveCpuSumAllProcsPercent:(BOOL)sum {
	[self saveBoolPref:kCPUSumAllProcsPercentPref value:sum];
} // saveCpuSumAllProcsPercent

- (void)saveCpuAvgLowerHalfProcs:(BOOL)average {
	[self saveBoolPref:kCPUAvgLowerHalfProcsPref value:average];
} // saveCpuAvgLowerHalfProcs

- (void)saveCpuSortByUsage:(BOOL)sort {
	[self saveBoolPref:kCPUSortByUsagePref value:sort];
} // saveCpuSortByUsage

- (void)saveCpuPowerMate:(BOOL)active {
	[self saveBoolPref:kCPUPowerMatePref value:active];
} // saveCpuPowerMate

- (void)saveCpuPowerMateMode:(int)mode {
	[self saveIntPref:kCPUPowerMateMode value:mode];
} // saveCpuPowerMateMode

- (void)saveCpuTemperature:(BOOL)show {
    [self saveBoolPref: kCPUShowTemperature value:show];
} // saveCpuTemperature

- (void)saveCpuTemperatureColor:(NSColor *)color {
    [self saveColorPref:kCPUTemperatureColor value:color];
}

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

- (BOOL)memPressure {
  return [self loadBoolPref:kMemPressurePref defaultValue:kMemPressureDefault];
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

- (void)saveMemPressure:(BOOL)label {
  [self saveBoolPref:kMemPressurePref value:label];
} // saveMemPressure

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

- (BOOL)netThroughputBits {
	return [self loadBoolPref:kNetThroughputBitsPref defaultValue:kNetThroughputBitsDefault];
} // netThroughputBits

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

- (void)saveNetThroughputBits:(BOOL)label {
	[self saveBoolPref:kNetThroughputBitsPref value:label];
} // saveNetThroughputBits

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
#ifndef ELCAPITAN
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
		[fileManager moveItemAtPath:[prefFolderPath stringByAppendingPathComponent:oldPath]
					   toPath:[prefFolderPath stringByAppendingPathComponent:newPath]
					  error:nil];
	}
#endif
} // _migratePrefFile

- (void)migratePrefsForward {

	// Flag set if prefs are changed.
	BOOL didChange = NO;

	// Load current preference version
	NSNumber *prefVersionNum = (NSNumber *)CFBridgingRelease(CFPreferencesCopyValue((CFStringRef)kPrefVersionKey,
																  (CFStringRef)kMenuMeterDefaultsDomain,
																  kCFPreferencesCurrentUser,
																  kCFPreferencesAnyHost));
	int prefVersion = -1;  // Use an illegal value
	if (prefVersionNum) {
		prefVersion = [prefVersionNum intValue];
	}

	// Migrate prefs from versions before we supported pref fields (0.5 -> 0.6)
	if (prefVersion == 0) {
		NSLog(@"MenuMeterDefaults performing preference migration from pref version null to pref version 1");
		didChange = YES;

		// Net preference changed meaning, 0 was valid (arrows only) now
		// arrows are separate pref. We also reordered the flags to fix the menu
		// layout
		NSNumber *netModeNum = (NSNumber *)CFBridgingRelease(CFPreferencesCopyValue((CFStringRef)kNetDisplayModePref,
																  (CFStringRef)kMenuMeterDefaultsDomain,
																  kCFPreferencesCurrentUser,
																  kCFPreferencesAnyHost));
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
		} // end of kNetDisplayModePref migration
	}

	// Migrate prefs from version 0.6 to 0.7
	if (prefVersion == 1) {
		NSLog(@"MenuMeterDefaults performing preference migration from pref version 1 to pref version 2");
		didChange = YES;
		// Percent split pref became percent display mode
		NSNumber *splitNum = (NSNumber *)CFBridgingRelease(CFPreferencesCopyValue(CFSTR("kCPUPercentDisplaySplit"),
																  (CFStringRef)kMenuMeterDefaultsDomain,
																  kCFPreferencesCurrentUser,
																  kCFPreferencesAnyHost));
		if (splitNum && [splitNum intValue]) {
			[self saveIntPref:kCPUPercentDisplayPref value:kCPUPercentDisplaySplit];
		} else {
			[self saveIntPref:kCPUPercentDisplayPref value:kCPUPercentDisplaySmall];
		}
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
		NSNumber *memModeNum = (NSNumber *)CFBridgingRelease(CFPreferencesCopyValue((CFStringRef)kMemDisplayModePref,
																  (CFStringRef)kMenuMeterDefaultsDomain,
																  kCFPreferencesCurrentUser,
																  kCFPreferencesAnyHost));
		if (memModeNum) {
			if ([memModeNum intValue] == 2) {
				[self saveIntPref:kMemDisplayModePref value:3];
			}
		}
	}

	// Migrate prefs from version 1.0 to 1.1
	if (prefVersion == 3) {
		NSLog(@"MenuMeterDefaults performing preference migration from pref version 3 to pref version 4");
		didChange = YES;
		// Fix the meaning of the Mem menu items
		NSNumber *memModeNum = (NSNumber *)CFBridgingRelease(CFPreferencesCopyValue((CFStringRef)kMemDisplayModePref,
																  (CFStringRef)kMenuMeterDefaultsDomain,
																  kCFPreferencesCurrentUser,
																  kCFPreferencesAnyHost));
		if (memModeNum) {
			if ([memModeNum intValue] == 3) {
				[self saveIntPref:kMemDisplayModePref value:4];
			}
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
				NSString *preferredString = [NSUnarchiver unarchiveObjectWithData:(__bridge NSData *)preferredArchivedString];
				if (preferredString && [preferredString isKindOfClass:[NSString class]]) {
					CFPreferencesSetValue((CFStringRef)kNetPreferInterfacePref,
										  (CFStringRef)preferredString,
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
	NSNumber *prefValue = (NSNumber *)CFBridgingRelease(CFPreferencesCopyValue((CFStringRef)prefName,
															 (CFStringRef)kMenuMeterDefaultsDomain,
															 kCFPreferencesCurrentUser, kCFPreferencesAnyHost));
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
	return returnVal;

} // _loadDoublePref

- (void)saveDoublePref:(NSString *)prefName value:(double)value {
	CFPreferencesSetValue((CFStringRef)prefName,
						  (__bridge CFPropertyListRef _Nullable)([NSNumber numberWithDouble:value]),
						  (CFStringRef)kMenuMeterDefaultsDomain,
						  kCFPreferencesCurrentUser,
						  kCFPreferencesAnyHost);
} // _saveDoublePref

- (int)loadIntPref:(NSString *)prefName lowBound:(int)lowBound
		  highBound:(int)highBound defaultValue:(int)defaultValue {

	Boolean keyExistsAndHasValidFormat = NO;
	CFIndex returnValue = CFPreferencesGetAppIntegerValue((CFStringRef)prefName,
														  (CFStringRef)kMenuMeterDefaultsDomain,
														  &keyExistsAndHasValidFormat);
	if (!keyExistsAndHasValidFormat) {
		[self saveIntPref:prefName value:defaultValue];
		returnValue = defaultValue;
	}
    if(returnValue > highBound || returnValue < lowBound){
        returnValue = defaultValue;
    }
	return (int) returnValue;

} // _loadIntPref

- (void)saveIntPref:(NSString *)prefname value:(int)value {
	CFPreferencesSetValue((CFStringRef)prefname,
						  (__bridge CFPropertyListRef _Nullable)([NSNumber numberWithInt:value]),
						  (CFStringRef)kMenuMeterDefaultsDomain,
						  kCFPreferencesCurrentUser,
						  kCFPreferencesAnyHost);
} // _saveIntPref

- (int)loadBitFlagPref:(NSString *)prefName validFlags:(int)flags
			  zeroValid:(BOOL)zeroValid defaultValue:(int)defaultValue {

	Boolean keyExistsAndHasValidFormat = NO;
	CFIndex returnValue = CFPreferencesGetAppIntegerValue((CFStringRef)prefName,
														  (CFStringRef)kMenuMeterDefaultsDomain,
														  &keyExistsAndHasValidFormat);
	if (keyExistsAndHasValidFormat) {
		if (((returnValue | flags) != flags) || (zeroValid && !returnValue)) {
			keyExistsAndHasValidFormat = NO;
		}
	}
	
	if (!keyExistsAndHasValidFormat) {
		[self saveIntPref:prefName value:defaultValue];
		returnValue = defaultValue;
	}
	return (int) returnValue;

} // _loadBitFlagPref

- (void)saveBitFlagPref:(NSString *)prefName value:(int)value {
	CFPreferencesSetValue((CFStringRef)prefName,
						  (__bridge CFPropertyListRef _Nullable)([NSNumber numberWithInt:value]),
						  (CFStringRef)kMenuMeterDefaultsDomain,
						  kCFPreferencesCurrentUser,
						  kCFPreferencesAnyHost);
} // _saveBitFlagPref

- (BOOL)loadBoolPref:(NSString *)prefName defaultValue:(BOOL)defaultValue {

	Boolean keyExistsAndHasValidFormat = NO;
	BOOL returnValue = CFPreferencesGetAppBooleanValue((CFStringRef)prefName,
													   (CFStringRef)kMenuMeterDefaultsDomain,
													   &keyExistsAndHasValidFormat);
	if (!keyExistsAndHasValidFormat) {
		[self saveBoolPref:prefName value:defaultValue];
		returnValue = defaultValue;
	}
	return returnValue;

} // _loadBoolPref

- (void)saveBoolPref:(NSString *)prefName value:(BOOL)value {
	CFPreferencesSetValue((CFStringRef)prefName,
						  (__bridge CFPropertyListRef _Nullable)([NSNumber numberWithBool:value]),
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
		returnValue = [NSUnarchiver unarchiveObjectWithData:(__bridge NSData *)archivedData];
	}

    if (!returnValue) {
		[self saveColorPref:prefName value:defaultValue];
		returnValue = defaultValue;
	}

    if (archivedData) {
        CFRelease(archivedData);
    }

    return returnValue;
} // _loadColorPref

- (void)saveColorPref:(NSString *)prefName value:(NSColor *)value {
	if (value) {
		CFPreferencesSetValue((CFStringRef)prefName,
							  (__bridge CFPropertyListRef _Nullable)([NSArchiver archivedDataWithRootObject:value]),
							  (CFStringRef)kMenuMeterDefaultsDomain,
							  kCFPreferencesCurrentUser,
							  kCFPreferencesAnyHost);
	}
} // _saveColorPref

- (NSString *)loadStringPref:(NSString *)prefName defaultValue:(NSString *)defaultValue {

	NSString *returnValue = NULL;
	CFStringRef prefValue = CFPreferencesCopyValue((CFStringRef)prefName,
												   (CFStringRef)kMenuMeterDefaultsDomain,
												   kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    if (prefValue) {
        if (CFGetTypeID(prefValue) == CFStringGetTypeID()) {
            returnValue = (NSString *)CFBridgingRelease(prefValue);
        } else {
            CFBridgingRelease(prefValue);
        }
    }

    if (returnValue == NULL) {
        returnValue = defaultValue;
        [self saveStringPref:prefName value:returnValue];
    }

    return returnValue;

} // _loadStringPref

- (void)saveStringPref:(NSString *)prefName value:(NSString *)value {
	CFPreferencesSetValue((CFStringRef)prefName,
						  (CFStringRef)value,
						  (CFStringRef)kMenuMeterDefaultsDomain,
						  kCFPreferencesCurrentUser,
						  kCFPreferencesAnyHost);
} // _saveStringPref

@end

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


// Datatype read/write
- (double)loadDoublePref:(NSString *)prefName lowBound:(double)lowBound
				highBound:(double)highBound defaultValue:(double)defaultValue;
- (void)saveDoublePref:(NSString *)prefName value:(double)value;
- (int)loadIntPref:(NSString *)prefName lowBound:(int)lowBound
		  highBound:(int)highBound defaultValue:(int)defaultValue;
- (void)saveIntPref:(NSString *)prefName value:(int)value;
- (int)loadBitFlagPref:(NSString *)prefName validFlags:(int)flags
          defaultValue:(int)defaultValue;
- (void)saveBitFlagPref:(NSString *)prefName value:(int)value;
#ifndef ELCAPITAN
- (BOOL)loadBoolPref:(NSString *)prefName defaultValue:(BOOL)defaultValue;
- (void)saveBoolPref:(NSString *)prefName value:(BOOL)value;
#endif
- (NSColor *)loadColorPref:(NSString *)prefName defaultValue:(NSColor *)defaultValue;
- (NSColor *)colorForPref:(NSString *)prefName meter:(NSString *)meter
			defaultValue:(NSColor *)defaultValue monochromeValue:(NSColor *)monochromeValue;
- (void)saveColorPref:(NSString *)prefname value:(NSColor *)value;
- (NSString *)loadStringPref:(NSString *)prefName defaultValue:(NSString *)defaultValue;
- (void)saveStringPref:(NSString *)prefName value:(NSString *)value;
- (BOOL)isCatalinaOrLater;
@end

///////////////////////////////////////////////////////////////
//
//	init/dealloc
//
///////////////////////////////////////////////////////////////

@implementation MenuMeterDefaults
#define kMigratedFromRagingMenaceToYujitach @"migratedFromRagingMenaceToYujitach"
+ (void)movePreferencesIfNecessary
{
    if([[NSUserDefaults standardUserDefaults] boolForKey:kMigratedFromRagingMenaceToYujitach])
        return;
    NSData*data=[NSData dataWithContentsOfFile:[[NSString stringWithFormat:@"~/Library/Preferences/%@.plist", kMenuMeterDefaultsDomain] stringByExpandingTildeInPath]];
    if(data){
        NSError*error=nil;
        NSDictionary*dict=[NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:nil error:&error];
        if(dict){
            NSData*defaultData=[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:kMenuMeterDefaultsDomain ofType:@"plist"]];
            NSDictionary*defaultDict=[NSPropertyListSerialization propertyListWithData:defaultData options:NSPropertyListImmutable format:nil error:nil];
            for(NSString*key in [dict allKeys]){
                NSLog(@"migrating %@", key);
                NSObject*value=[dict objectForKey:key];
                NSObject*defaultValue=[defaultDict objectForKey:key];
                if([value isEqualTo:defaultValue]){
                    NSLog(@"\t%@ has default value; no need to copy",key);
                }else{
                    NSLog(@"\t%@ has non-default value; copying",key);
                    [[NSUserDefaults standardUserDefaults] setObject:[dict objectForKey:key] forKey:key];
                }
            }
        }else{
            NSLog(@"error reading old pref plist: %@",error);
        }
    }
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kMigratedFromRagingMenaceToYujitach];
}
+ (MenuMeterDefaults*)sharedMenuMeterDefaults
{
    static MenuMeterDefaults*foo=nil;
    if(!foo){
        foo=[[MenuMeterDefaults alloc] init];
    }
    return foo;
}
- (int)colorStyleForMeter:(NSString *)meter {
	// Keep the previous app-wide selection until this meter is changed independently.
	int legacyStyle = [self loadIntPref:kMenuMeterColorStylePref
					lowBound:kMenuMeterColorStyleOriginal
			   highBound:kMenuMeterColorStyleCustom
				defaultValue:kMenuMeterColorStyleDefault];
	return [self loadIntPref:[meter stringByAppendingString:@".ColorStyle"]
				   lowBound:kMenuMeterColorStyleOriginal
				  highBound:kMenuMeterColorStyleCustom defaultValue:legacyStyle];
}

- (void)saveColorStyle:(int)style forMeter:(NSString *)meter {
	[self saveIntPref:[meter stringByAppendingString:@".ColorStyle"] value:style];
}

- (NSColor *)colorForPref:(NSString *)prefName meter:(NSString *)meter
			defaultValue:(NSColor *)defaultValue monochromeValue:(NSColor *)monochromeValue {
	int style = [self colorStyleForMeter:meter];
	if (style == kMenuMeterColorStyleCustom) {
		return [self loadColorPref:prefName defaultValue:defaultValue];
	}
	return style == kMenuMeterColorStyleMonochrome ? monochromeValue : defaultValue;
}

- (void)beginCustomColorStyleForMeter:(NSString *)meter {
	if ([self colorStyleForMeter:meter] == kMenuMeterColorStyleCustom) return;

	if ([meter isEqualToString:kCPUMenuBundleID]) {
		[self saveCpuUserColor:[self cpuUserColor]];
		[self saveCpuSystemColor:[self cpuSystemColor]];
		[self saveCpuTemperatureColor:[self cpuTemperatureColor]];
		NSColor *borderColor = [self cpuThermometerBorderColor];
		if (borderColor) {
			[self saveCpuThermometerBorderColor:borderColor];
		} else {
			[[NSUserDefaults standardUserDefaults] removeObjectForKey:kCPUThermometerBorderColorPref];
		}
	} else if ([meter isEqualToString:kMemMenuBundleID]) {
		[self saveMemFreeColor:[self memFreeColor]];
		[self saveMemUsedColor:[self memUsedColor]];
		[self saveMemActiveColor:[self memActiveColor]];
		[self saveMemInactiveColor:[self memInactiveColor]];
		[self saveMemWireColor:[self memWireColor]];
		[self saveMemCompressedColor:[self memCompressedColor]];
		[self saveMemPageInColor:[self memPageInColor]];
		[self saveMemPageOutColor:[self memPageOutColor]];
	} else if ([meter isEqualToString:kNetMenuBundleID]) {
		[self saveNetTransmitColor:[self netTransmitColor]];
		[self saveNetReceiveColor:[self netReceiveColor]];
		[self saveNetInactiveColor:[self netInactiveColor]];
	} else {
		NSLog(@"Cannot edit color scheme for unknown meter: %@", meter);
		return;
	}
	[self saveColorStyle:kMenuMeterColorStyleCustom forMeter:meter];
}

- (id)init {

	// Allow super to init
	self = [super init];
	if (!self) {
		return nil;
	}

	// Send on back
	return self;

} // init

- (void)dealloc {

	// Super do its thing
	[[NSNotificationCenter defaultCenter] removeObserver:self];

} // dealloc

- (BOOL) isCatalinaOrLater {
    static dispatch_once_t once;
    static BOOL isCatalinaOrLater;
    dispatch_once(&once,^{
        if(@available(macOS 10.15, *)){
            isCatalinaOrLater=YES;
        }else{
            isCatalinaOrLater=NO;
        }
    });
    return isCatalinaOrLater;
}

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

- (int)cpuThermometerWidth {
    return [self loadIntPref:kCPUThermometerWidthPref
                    lowBound:kCPUThermometerWidthMin
                   highBound:kCPUThermometerWidthMax
                defaultValue:kCPUThermometerWidthDefault];
} // cpuThermometerWidth

- (int)cpuThermometerGap {
    return [self loadIntPref:kCPUThermometerGapPref
                    lowBound:kCPUThermometerGapMin
                   highBound:kCPUThermometerGapMax
                defaultValue:kCPUThermometerGapDefault];
} // cpuThermometerGap

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
- (int)cpuTemperatureUnit {
    return [self loadIntPref:kCPUTemperatureUnit
                    lowBound:kCPUTemperatureUnitCelsius
                   highBound:kCPUTemperatureUnitFahrenheit
                defaultValue:kCPUTemperatureUnitCelsius];
}
- (NSString*)cpuTemperatureSensor{
    return [self loadStringPref:kCPUTemperatureSensor defaultValue:kCPUTemperatureSensorDefault];
}
-(void)saveCpuTemperatureSensor:(NSString *)name{
    [self saveStringPref:kCPUTemperatureSensor value:name];
}
- (NSColor *)cpuSystemColor {
	return [self colorForPref:kCPUSystemColorPref meter:kCPUMenuBundleID defaultValue:kCPUSystemColorDefault
			 monochromeValue:[NSColor colorWithCalibratedWhite:0.498045 alpha:1.0]];
} // cpuSystemColor

- (NSColor *)cpuUserColor {
	return [self colorForPref:kCPUUserColorPref meter:kCPUMenuBundleID defaultValue:kCPUUserColorDefault monochromeValue:[NSColor whiteColor]];
} // cpuUserColor

- (BOOL)cpuShowTemperature {
    return [self loadBoolPref:kCPUShowTemperature defaultValue:kCPUShowTemperatureDefault];
}

- (NSColor *)cpuTemperatureColor {
	return [self colorForPref:kCPUTemperatureColor meter:kCPUMenuBundleID defaultValue:kCPUTemperatureColorDefault monochromeValue:[NSColor whiteColor]];
} //cpuTemperatureColor

- (NSColor *)cpuThermometerBorderColor {
	return [self colorForPref:kCPUThermometerBorderColorPref meter:kCPUMenuBundleID
			defaultValue:nil monochromeValue:[[NSColor whiteColor] colorWithAlphaComponent:kBorderAlpha]];
}

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

- (void)saveCpuThermometerWidth:(int)width {
    [self saveIntPref:kCPUThermometerWidthPref value:width];
} // saveCpuThermometerWidth

- (void)saveCpuThermometerGap:(int)gap {
    [self saveIntPref:kCPUThermometerGapPref value:gap];
} // saveCpuThermometerGap

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

- (void)saveCpuTemperatureUnit:(int)unit {
    [self saveIntPref:kCPUTemperatureUnit value:unit];
} // saveCpuPowerMateMode

- (void)saveCpuTemperature:(BOOL)show {
    [self saveBoolPref: kCPUShowTemperature value:show];
} // saveCpuTemperature

- (void)saveCpuTemperatureColor:(NSColor *)color {
    [self saveColorPref:kCPUTemperatureColor value:color];
}

- (void)saveCpuThermometerBorderColor:(NSColor *)color {
	[self saveColorPref:kCPUThermometerBorderColorPref value:color];
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

- (int)memDecimals {
	return [self loadIntPref:kMemDecimalsPref
					lowBound:kMenuMeterDecimalsAdaptive
				   highBound:kMenuMeterDecimalsTwo
				defaultValue:kMemDecimalsDefault];
} // memDecimals

- (int)memUnits {
	return [self loadIntPref:kMemUnitsPref
					lowBound:kMemUnitsMB
				   highBound:kMemUnitsAutomatic
				defaultValue:kMemUnitsDefault];
} // memUnits

- (NSColor *)memFreeColor {
	return [self colorForPref:kMemFreeColorPref meter:kMemMenuBundleID defaultValue:kMemFreeColorDefault monochromeValue:[NSColor whiteColor]];
} // memFreeColor

- (NSColor *)memUsedColor {
	return [self colorForPref:kMemUsedColorPref meter:kMemMenuBundleID defaultValue:kMemUsedColorDefault monochromeValue:[NSColor whiteColor]];
} // memUsedColor

- (NSColor *)memActiveColor {
	return [self colorForPref:kMemActiveColorPref meter:kMemMenuBundleID defaultValue:kMemActiveColorDefault
			 monochromeValue:[NSColor colorWithCalibratedWhite:0.812722 alpha:1.0]];
} // memActiveColor

- (NSColor *)memInactiveColor {
	return [self colorForPref:kMemInactiveColorPref meter:kMemMenuBundleID defaultValue:kMemInactiveColorDefault
			 monochromeValue:[NSColor colorWithCalibratedWhite:0.640117 alpha:1.0]];
} // memInactiveColor

- (NSColor *)memWireColor {
	return [self colorForPref:kMemWireColorPref meter:kMemMenuBundleID defaultValue:kMemWireColorDefault
			 monochromeValue:[NSColor colorWithCalibratedWhite:0.343334 alpha:1.0]];
} // memWireColor

- (NSColor *)memCompressedColor {
	return [self colorForPref:kMemCompressedColorPref meter:kMemMenuBundleID defaultValue:kMemCompressedColorDefault
			 monochromeValue:[NSColor colorWithCalibratedWhite:0.102822 alpha:1.0]];
} // memCompressedColor

- (NSColor *)memPageInColor {
	return [self colorForPref:kMemPageInColorPref meter:kMemMenuBundleID defaultValue:kMemPageInColorDefault
			 monochromeValue:[NSColor colorWithCalibratedWhite:0.072070 alpha:1.0]];
} // memPageinColor

- (NSColor *)memPageOutColor {
	return [self colorForPref:kMemPageOutColorPref meter:kMemMenuBundleID defaultValue:kMemPageOutColorDefault
			 monochromeValue:[NSColor colorWithCalibratedWhite:0.211559 alpha:1.0]];
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

- (void)saveMemDecimals:(int)decimals {
	[self saveIntPref:kMemDecimalsPref value:decimals];
} // saveMemDecimals

- (void)saveMemUnits:(int)units {
	[self saveIntPref:kMemUnitsPref value:units];
} // saveMemUnits

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

- (int)netThroughputDecimals {
	return [self loadIntPref:kNetThroughputDecimalsPref
					lowBound:kMenuMeterDecimalsAdaptive
				   highBound:kMenuMeterDecimalsTwo
				defaultValue:kNetThroughputDecimalsDefault];
} // netThroughputDecimals

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
	return [self colorForPref:kNetTransmitColorPref meter:kNetMenuBundleID defaultValue:kNetTransmitColorDefault monochromeValue:[NSColor whiteColor]];
} // netTransmitColor

- (NSColor *)netReceiveColor {
	return [self colorForPref:kNetReceiveColorPref meter:kNetMenuBundleID defaultValue:kNetReceiveColorDefault monochromeValue:[NSColor whiteColor]];
} // netReceiveColor

- (NSColor *)netInactiveColor {
	return [self colorForPref:kNetInactiveColorPref meter:kNetMenuBundleID defaultValue:kNetInactiveColorDefault monochromeValue:[NSColor whiteColor]];
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

- (void)saveNetThroughputDecimals:(int)decimals {
	[self saveIntPref:kNetThroughputDecimalsPref value:decimals];
} // saveNetThroughputDecimals

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
//	Datatype read/write
//
///////////////////////////////////////////////////////////////

- (double)loadDoublePref:(NSString *)prefName lowBound:(double)lowBound
				highBound:(double)highBound defaultValue:(double)defaultValue {

	double returnVal = defaultValue;
    NSNumber *prefValue = [[NSUserDefaults standardUserDefaults] objectForKey:prefName];
	if (prefValue && [prefValue isKindOfClass:[NSNumber class]]) {
		returnVal = [prefValue doubleValue];
		// Floating point comparison needs some margin of error. Scale up
		// and truncate
		if ((floor(returnVal * 100) < floor(lowBound * 100)) ||
			(ceil(returnVal * 100) > ceil(highBound * 100))) {
			returnVal = defaultValue;
			[self saveDoublePref:prefName value:returnVal];
		}
	}
	return returnVal;

} // _loadDoublePref

- (void)saveDoublePref:(NSString *)prefName value:(double)value {
    [[NSUserDefaults standardUserDefaults] setDouble:value forKey:prefName];
} // _saveDoublePref

- (int)loadIntPref:(NSString *)prefName lowBound:(int)lowBound
		  highBound:(int)highBound defaultValue:(int)defaultValue {

    int returnValue=defaultValue;
    if([[NSUserDefaults standardUserDefaults] objectForKey:prefName]){
        returnValue=(int)[[NSUserDefaults standardUserDefaults] integerForKey:prefName];
    }
    if(returnValue > highBound || returnValue < lowBound){
        returnValue = defaultValue;
    }
	return (int) returnValue;

} // _loadIntPref

- (void)saveIntPref:(NSString *)prefname value:(int)value {
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:prefname];
} // _saveIntPref

- (int)loadBitFlagPref:(NSString *)prefName validFlags:(int)flags defaultValue:(int)defaultValue {

    if([[NSUserDefaults standardUserDefaults] objectForKey:prefName]){
        int returnValue=(int)[[NSUserDefaults standardUserDefaults] integerForKey:prefName];
        if (((returnValue | flags) == flags)) {
            return returnValue;
        }
    }
	return defaultValue;

} // _loadBitFlagPref

- (void)saveBitFlagPref:(NSString *)prefName value:(int)value {
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:prefName];
} // _saveBitFlagPref

- (BOOL)loadBoolPref:(NSString *)prefName defaultValue:(BOOL)defaultValue {

    if([[NSUserDefaults standardUserDefaults] objectForKey:prefName]){
        return [[NSUserDefaults standardUserDefaults] boolForKey:prefName];
    }
    return defaultValue;
} // _loadBoolPref

- (void)saveBoolPref:(NSString *)prefName value:(BOOL)value {
    [[NSUserDefaults standardUserDefaults] setBool:value forKey:prefName];
} // _saveBoolPref

- (NSColor *)loadColorPref:(NSString *)prefName defaultValue:(NSColor *)defaultValue {

    NSData* data = [[NSUserDefaults standardUserDefaults] objectForKey:prefName];
    if(data){
        NSColor*color=[NSUnarchiver unarchiveObjectWithData:data];
        if(color){
            return color;
        }
	}
    return defaultValue;
} // _loadColorPref

- (void)saveColorPref:(NSString *)prefName value:(NSColor *)value {
	if (value) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSArchiver archivedDataWithRootObject:value] forKey:prefName];
	}
} // _saveColorPref

- (NSString *)loadStringPref:(NSString *)prefName defaultValue:(NSString *)defaultValue {

    NSString*s=[[NSUserDefaults standardUserDefaults] objectForKey:prefName];
    if(s){
        return s;
    }
    return defaultValue;
} // _loadStringPref

- (void)saveStringPref:(NSString *)prefName value:(NSString *)value {
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:prefName];
} // _saveStringPref

@end

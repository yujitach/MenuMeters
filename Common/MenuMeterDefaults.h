//
//	MenuMeterDefaults.h
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

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#import "MenuMeters.h"

@interface MenuMeterDefaults : NSObject

#ifdef ELCAPITAN
- (BOOL)loadBoolPref:(NSString *)prefName defaultValue:(BOOL)defaultValue;
- (void)saveBoolPref:(NSString *)prefName value:(BOOL)value;
#endif

+ (MenuMeterDefaults*)sharedMenuMeterDefaults;

// Pref read/write
- (void)syncWithDisk;

// CPU menu prefs
- (double)cpuInterval;
- (int)cpuDisplayMode;
- (int)cpuPercentDisplay;
- (int)cpuMaxProcessCount;
- (int)cpuGraphLength;
- (int)cpuHorizontalRows;
- (int)cpuMenuWidth;
- (BOOL)cpuAvgAllProcs;
- (BOOL)cpuAvgLowerHalfProcs;
- (BOOL)cpuSortByUsage;
- (BOOL)cpuPowerMate;
- (int)cpuPowerMateMode;
- (NSColor *)cpuSystemColor;
- (NSColor *)cpuUserColor;
- (void)saveCpuInterval:(double)interval;
- (void)saveCpuDisplayMode:(int)mode;
- (void)saveCpuPercentDisplay:(int)mode;
- (void)saveCpuMaxProcessCount:(int)maxCount;
- (void)saveCpuGraphLength:(int)length;
- (void)saveCpuHorizontalRows:(int)rows;
- (void)saveCpuMenuWidth:(int)width;
- (void)saveCpuAvgAllProcs:(BOOL)average;
- (void)saveCpuAvgLowerHalfProcs:(BOOL)average;
- (void)saveCpuSortByUsage:(BOOL)sort;
- (void)saveCpuPowerMate:(BOOL)active;
- (void)saveCpuPowerMateMode:(int)mode;
- (void)saveCpuSystemColor:(NSColor *)color;
- (void)saveCpuUserColor:(NSColor *)color;

// Disk menu prefs
- (double)diskInterval;
- (int)diskImageset;
- (int)diskSelectMode;
- (BOOL)diskSpaceForceBaseTwo;
- (void)saveDiskInterval:(double)interval;
- (void)saveDiskImageset:(int)imageset;
- (void)saveDiskSelectMode:(int)mode;

// Mem menu prefs
- (double)memInterval;
- (int)memDisplayMode;
- (BOOL)memUsedFreeLabel;
- (int)memGraphLength;
- (BOOL)memPageIndicator;
- (BOOL)memPressure;
- (NSColor *)memFreeColor;
- (NSColor *)memUsedColor;
- (NSColor *)memActiveColor;
- (NSColor *)memInactiveColor;
- (NSColor *)memWireColor;
- (NSColor *)memCompressedColor;
- (NSColor *)memPageInColor;
- (NSColor *)memPageOutColor;
- (void)saveMemInterval:(double)interval;
- (void)saveMemDisplayMode:(int)mode;
- (void)saveMemPageIndicator:(BOOL)indicator;
- (void)saveMemUsedFreeLabel:(BOOL)label;
- (void)saveMemPressure:(BOOL)label;
- (void)saveMemGraphLength:(int)length;
- (void)saveMemFreeColor:(NSColor *)color;
- (void)saveMemUsedColor:(NSColor *)color;
- (void)saveMemActiveColor:(NSColor *)color;
- (void)saveMemInactiveColor:(NSColor *)color;
- (void)saveMemWireColor:(NSColor *)color;
- (void)saveMemCompressedColor:(NSColor *)color;
- (void)saveMemPageInColor:(NSColor *)color;
- (void)saveMemPageOutColor:(NSColor *)color;

// Net menu prefs
- (double)netInterval;
- (int)netDisplayMode;
- (int)netDisplayOrientation;
- (int)netScaleMode;
- (int)netScaleCalc;
- (BOOL)netThroughputLabel;
- (BOOL)netThroughput1KBound;
- (int)netGraphStyle;
- (int)netGraphLength;
- (NSColor *)netTransmitColor;
- (NSColor *)netReceiveColor;
- (NSColor *)netInactiveColor;
- (NSString *)netPreferInterface;
- (void)saveNetInterval:(double)interval;
- (void)saveNetDisplayMode:(int)mode;
- (void)saveNetDisplayOrientation:(int)orient;
- (void)saveNetScaleMode:(int)mode;
- (void)saveNetScaleCalc:(int)calc;
- (void)saveNetThroughputLabel:(BOOL)label;
- (void)saveNetThroughput1KBound:(BOOL)bound;
- (void)saveNetGraphStyle:(int)style;
- (void)saveNetGraphLength:(int)length;
- (void)saveNetTransmitColor:(NSColor *)color;
- (void)saveNetReceiveColor:(NSColor *)color;
- (void)saveNetInactiveColor:(NSColor *)color;
- (void)saveNetPreferInterface:(NSString *)interface;

@end

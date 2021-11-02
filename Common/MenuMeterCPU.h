//
//  MenuMeterCPU.h
//
//  Constants and other definitions for the CPU Meter
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

///////////////////////////////////////////////////////////////
//
//  Constants
//
///////////////////////////////////////////////////////////////

// Widths of the various displays
#define kCPUPercentDisplayBorderWidth 2
#define kCPUThermometerDisplayWidth 11.0f
#define kCPUDisplayMultiProcGapWidth 5
#define kCPULabelOnlyWidth 25

// Menu item indexes
#define kCPUUptimeInfoMenuIndex 4
#define kCPUTaskInfoMenuIndex 6
#define kCPULoadInfoMenuIndex 8
#define kCPUPowerLimitInfoMenuIndex 10
#define kCPUProcessLabelMenuIndex 11
#define kCPUProcessMenuIndex (kCPUProcessLabelMenuIndex + 1)

///////////////////////////////////////////////////////////////
//
//  Preference information
//
///////////////////////////////////////////////////////////////

// Pref dictionary keys
extern NSString *kCPUIntervalPref;
extern NSString *kCPUDisplayModePref;
extern NSString *kCPUPercentDisplayPref;
extern NSString *kCPUMaxProcessCountPref;
extern NSString *kCPUGraphLengthPref;
extern NSString *kCPUHorizontalRowsPref;
extern NSString *kCPUMenuWidthPref;
extern NSString *kCPUAvgAllProcsPref;
extern NSString *kCPUSumAllProcsPercentPref;
// Note that "Lower Half" is now reused to show only physical cores
extern NSString *kCPUAvgLowerHalfProcsPref;
extern NSString *kCPUSortByUsagePref;
extern NSString *kCPUSystemColorPref;
extern NSString *kCPUUserColorPref;
extern NSString *kCPUPowerMatePref;
extern NSString *kCPUPowerMateMode;
extern NSString *kCPUShowTemperature;
extern NSString *kCPUTemperatureColor;
extern NSString *kCPUTemperatureSensor;
extern NSString *kCPUTemperatureSensorDefault;
extern NSString *kCPUTemperatureUnit;
#define kCPUTemperatureUnitCelsius 0
#define kCPUTemperatureUnitFahrenheit 1
// Display modes
enum {
	kCPUDisplayPercent = 1,
	kCPUDisplayGraph = 2,
	kCPUDisplayThermometer = 4,
	kCPUDisplayHorizontalThermometer = 8
};
#define kCPUDisplayDefault kCPUDisplayPercent

// Percent display modes
enum {
	kCPUPercentDisplayLarge = 0,
	kCPUPercentDisplaySmall,
	kCPUPercentDisplaySplit
};
#define kCPUPercentDisplayDefault kCPUPercentDisplaySmall

// Process info
#define kCPUProcessCountMin 0
#define kCPUrocessCountMax 25
#define kCPUProcessCountDefault 5

// PowerMate modes
enum {
	kCPUPowerMateGlow = 0,
	kCPUPowerMatePulse,
	kCPUPowerMateInverseGlow,
	kCPUPowerMateInversePulse
};
#define kCPUPowerMateModeDefault kCPUPowerMateGlow

// Timer
#define kCPUUpdateIntervalMin 0.5
#define kCPUUpdateIntervalMax 10.0
#define kCPUUpdateIntervalDefault 1.0

// Graph display
#define kCPUGraphWidthMin 11
#define kCPUGraphWidthMax 88
#define kCPUGraphWidthDefault 33

// Thermometer display
#define kCPUHorizontalRowsMin 1
#define kCPUHorizontalRowsMax 8
#define kCPUHorizontalRowsDefault 2

// Menu width
#define kCPUMenuWidthMin 60
#define kCPUMenuWidthMax 400
#define kCPUMenuWidthDefault 120

// Multiproc averaging
#define kCPUAvgAllProcsDefault NO

// Multiproc sum percentage
#define kCPUSumAllProcsPercentDefault NO

// Least-utilized half of procs averaging
#define kCPUAvgLowerHalfProcsDefault NO

// Sorting by usage
#define kCPUSortByUsageDefault NO

// PowerMate
#define kCPUPowerMateDefault NO

// Show CPU temperature
#define kCPUShowTemperatureDefault YES

// Colors
// Maraschino
#define kCPUSystemColorDefault [NSColor systemRedColor]
// Midnight blue
#define kCPUUserColorDefault [NSColor systemBlueColor]
// Orange
#define kCPUTemperatureColorDefault [NSColor systemOrangeColor]

//
//  MenuMeterCPU.h
//
// 	Constants and other definitions for the CPU Meter
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

///////////////////////////////////////////////////////////////
//
//	Constants
//
///////////////////////////////////////////////////////////////

// Widths of the various displays
#define kCPUPercentDisplayBorderWidth		2
#define kCPUThermometerDisplayWidth			10
#define kCPUDisplayMultiProcGapWidth		5

// Menu item indexes
#define kCPUUptimeInfoMenuIndex				3
#define kCPUTaskInfoMenuIndex				5
#define kCPULoadInfoMenuIndex				7

///////////////////////////////////////////////////////////////
//
//	Preference information
//
///////////////////////////////////////////////////////////////

// Pref dictionary keys
#define kCPUIntervalPref					@"CPUInterval"
#define kCPUDisplayModePref					@"CPUDisplayMode"
#define kCPUPercentDisplayPref				@"CPUPercentDisplayMode"
#define kCPUGraphLengthPref					@"CPUGraphLength"
#define kCPUAvgAllProcsPref					@"CPUAverageMultiProcs"
#define kCPUSystemColorPref					@"CPUSystemColor"
#define kCPUUserColorPref					@"CPUUserColor"
#define kCPUPowerMatePref					@"CPUPowerMate"
#define kCPUPowerMateMode					@"CPUPowerMateMode"

// Display modes
enum {
	kCPUDisplayPercent						= 1,
	kCPUDisplayGraph						= 2,
	kCPUDisplayThermometer					= 4
};
#define kCPUDisplayDefault					kCPUDisplayPercent

// Percent display modes
enum {
	kCPUPercentDisplayLarge					= 0,
	kCPUPercentDisplaySmall,
	kCPUPercentDisplaySplit
};
#define kCPUPercentDisplayDefault			kCPUPercentDisplaySmall

// PowerMate modes
enum {
	kCPUPowerMateGlow						= 0,
	kCPUPowerMatePulse,
	kCPUPowerMateInverseGlow,
	kCPUPowerMateInversePulse
};
#define kCPUPowerMateModeDefault			kCPUPowerMateGlow

// Timer
#define kCPUUpdateIntervalMin				0.5f
#define kCPUUpdateIntervalMax				10.0f
#define kCPUUpdateIntervalDefault			1.0f

// Graph display
#define kCPUGraphWidthMin					11
#define kCPUGraphWidthMax					88
#define kCPUGraphWidthDefault				33

// Multiproc averaging
#define kCPUAvgAllProcsDefault				NO

// PowerMate
#define kCPUPowerMateDefault				NO

// Colors
											// Maraschino
#define kCPUSystemColorDefault				[NSColor colorWithDeviceRed:1.0f green:0.0f blue:0.0f alpha:1.0f]
											// Midnight blue
#define kCPUUserColorDefault				[NSColor colorWithDeviceRed:0.0f green:0.0f blue:0.5f alpha:1.0f]






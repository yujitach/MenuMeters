//
//  MenuMeterMem.h
//
//  Constants and other definitions for the Memory Meter
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
#define kMemPieDisplayWidth					17.0
#define kMemNumberDisplayShortWidth			20.0
#define kMemNumberDisplayLongWidth			26.0
#define kMemNumberDisplayExtraLongWidth		34.0
#define kMemThermometerDisplayWidth			11.0
#define kMemPagingDisplayWidth				17.0
#define kMemPagingDisplayGapWidth			4.0

// Menu item indexes
#define kMemUsageInfoMenuIndex				1
#define kMemActiveWiredInfoMenuIndex		3
#define kMemInactiveFreeInfoMenuIndex		4
#define kMemCompressedInfoMenuIndex			5
#define kMemVMPageInfoMenuIndex				7
#define kMemVMCacheInfoMenuIndex			8
#define kMemVMFaultInfoMenuIndex			9
#define kMemMemPressureInfoMenuIndex		11
#define kMemSwapCountInfoMenuIndex			13
#define kMemSwapMaxCountInfoMenuIndex		14
#define kMemSwapSizeInfoMenuIndex			15

///////////////////////////////////////////////////////////////
//
//  Preference information
//
///////////////////////////////////////////////////////////////

// Pref dictionary keys
#define kMemIntervalPref					@"MemInterval"
#define kMemDisplayModePref					@"MemDisplayMode"
#define kMemUsedFreeLabelPref				@"MemUsedFreeLabel"
#define kMemPressurePref					@"MemPressure"
#define kMemPageIndicatorPref				@"MemPagingIndicator"
#define kMemGraphLengthPref					@"MemGraphLength"
#define kMemFreeColorPref					@"MemFreeColor"
#define kMemUsedColorPref					@"MemUsedColor"
#define kMemActiveColorPref					@"MemActiveColor"
#define kMemInactiveColorPref				@"MemInactiveColor"
#define kMemWireColorPref					@"MemWireColor"
#define kMemCompressedColorPref				@"MemCompressedColor"
#define kMemPageInColorPref					@"MemPageInColor"
#define kMemPageOutColorPref				@"MemPageOutColor"

// Display modes
enum {
	kMemDisplayPie							= 1,
	kMemDisplayBar,
	kMemDisplayGraph,
	kMemDisplayNumber
};
#define kMemDisplayDefault					kMemDisplayPie

// Used/Free label
#define kMemUsedFreeLabelDefault			YES

#define kMemPressureDefault					NO

// Page indicator
#define kMemPageIndicatorDefault			NO

// Timer
#define kMemUpdateIntervalMin				1.0
#define kMemUpdateIntervalMax				60.0
#define kMemUpdateIntervalDefault			10.0

// Graph display
#define kMemGraphWidthMin					11
#define kMemGraphWidthMax					88
#define kMemGraphWidthDefault				33

// Colors
											// Clover
#define kMemFreeColorDefault				[NSColor colorWithDeviceRed:0.0 green:0.5 blue:0.0 alpha:1.0]
											// Cayenne
#define kMemUsedColorDefault				[NSColor colorWithDeviceRed:0.5 green:0.0 blue:0.0 alpha:1.0]
											// Lime
#define kMemActiveColorDefault				[NSColor colorWithDeviceRed:0.5 green:1.0 blue:0.0 alpha:1.0]
											// Color between Aluminum and Magnesium
											// (used to be Alumnium, but that was a bit dark)
#define kMemInactiveColorDefault			[NSColor colorWithDeviceRed:0.7 green:0.7 blue:0.7 alpha:1.0]
											// Orchid
#define kMemWireColorDefault				[NSColor colorWithDeviceRed:0.4 green:0.4 blue:1.0 alpha:1.0]
											// Maroon
#define kMemCompressedColorDefault			[NSColor colorWithDeviceRed:0.5 green:0.0 blue:0.25 alpha:1.0]
											// Blue
#define kMemPageInColorDefault				[NSColor blueColor]
											// Red
#define kMemPageOutColorDefault				[NSColor redColor]
											// Black
#define kMemPageRateColorDefault			[NSColor blackColor]



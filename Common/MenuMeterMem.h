//
//  MenuMeterMem.h
//
// 	Constants and other definitions for the Memory Meter
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
#define kMemPieDisplayWidth					17.0f
#define kMemNumberDisplayShortWidth			20.0f
#define kMemNumberDisplayLongWidth			26.0f
#define kMemNumberDisplayExtraLongWidth		34.0f
#define kMemThermometerDisplayWidth			11.0f
#define kMemPagingDisplayWidth				17.0f
#define kMemPagingDisplayGapWidth			4.0f

// Menu item indexes
#define kMemUsageInfoMenuIndex				1
#define kMemActiveWiredInfoMenuIndex		3
#define kMemInactiveFreeInfoMenuIndex		4
#define kMemCompressedInfoMenuIndex			5
#define kMemVMPageInfoMenuIndex				7
#define kMemVMCacheInfoMenuIndex			8
#define kMemVMFaultInfoMenuIndex			9
#define kMemSwapCountInfoMenuIndex			11
#define kMemSwapMaxCountInfoMenuIndex		12
#define kMemSwapSizeInfoMenuIndex			13

///////////////////////////////////////////////////////////////
//
//	Preference information
//
///////////////////////////////////////////////////////////////

// Pref dictionary keys
#define kMemIntervalPref					@"MemInterval"
#define kMemDisplayModePref					@"MemDisplayMode"
#define kMemUsedFreeLabelPref				@"MemUsedFreeLabel"
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
#define kMemFreeColorDefault				[NSColor colorWithDeviceRed:0.0f green:0.5f blue:0.0f alpha:1.0f]
											// Cayenne
#define kMemUsedColorDefault				[NSColor colorWithDeviceRed:0.5f green:0.0f blue:0.0f alpha:1.0f]
											// Lime
#define kMemActiveColorDefault				[NSColor colorWithDeviceRed:0.5f green:1.0f blue:0.0f alpha:1.0f]
											// Color between Aluminum and Magnesium
											// (used to be Alumnium, but that was a bit dark)
#define kMemInactiveColorDefault			[NSColor colorWithDeviceRed:0.7f green:0.7f blue:0.7f alpha:1.0f]
											// Orchid
#define kMemWireColorDefault				[NSColor colorWithDeviceRed:0.4f green:0.4f blue:1.0f alpha:1.0f]
											// Maroon
#define kMemCompressedColorDefault			[NSColor colorWithDeviceRed:0.5f green:0.0f blue:0.25f alpha:1.0f]
											// Blue
#define kMemPageInColorDefault				[NSColor blueColor]
											// Red
#define kMemPageOutColorDefault				[NSColor redColor]
											// Black
#define kMemPageRateColorDefault			[NSColor blackColor]



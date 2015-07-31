//
//  MenuMeterDisk.h
//
// 	Constants and other definitions for the Disk Meter
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

typedef enum {
	kDiskActivityIdle 			= 0,
	kDiskActivityRead,
	kDiskActivityWrite,
	kDiskActivityReadWrite
} DiskIOActivityType;

///////////////////////////////////////////////////////////////
//
//	Preference information
//
///////////////////////////////////////////////////////////////

// Pref dictionary keys
#define kDiskIntervalPref				@"DiskInterval"
#define kDiskImageSetPref				@"DiskImageSet"
#define kDiskSelectModePref				@"DiskSelectMode"

// Hidden pref keys
#define kDiskSpaceForceBaseTwoPref		@"DiskSpaceForceBaseTwo"

// Timer
#define kDiskUpdateIntervalMin			0.1f
#define kDiskUpdateIntervalMax			5.0f
#define kDiskUpdateIntervalDefault		0.3f

// Image sets
#define kDiskImageSets					[NSArray arrayWithObjects: @"Color Arrows", @"Arrows", \
											@"Lights", @"Aqua Lights", @"Disk Arrows", \
											@"Disk Arrows (large)", nil]
#define kDiskDarkImageSets				[NSArray arrayWithObjects: @"Dark Color Arrows", @"Dark Arrows", \
											@"Lights", @"Aqua Lights", @"Disk Arrows", \
											@"Disk Arrows (large)", nil]
#define kDiskImageSetDefault			0
#define kDiskArrowsImageSet				4
#define kDiskArrowsLargeImageSet		5

// Select mode constants
enum {
	kDiskSelectModeOpen					= 0,
	kDiskSelectModeEject
};
#define kDiskSelectModeDefault			kDiskSelectModeOpen

// Hidden pref defaults
#define kDiskSpaceForceBaseTwoDefault	NO

// View width, also menubar disk icon image width/height
#define kDiskViewWidth					16





//
//  MenuMeterMemExtra.h
//
//	Menu Extra implementation
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
#import "AppleUndocumented.h"
#import "MenuMeters.h"
#import "MenuMeterDefaults.h"
#import "MenuMeterMem.h"
#import "MenuMeterMemView.h"
#import "MenuMeterMemStats.h"
#import "MenuMeterWorkarounds.h"


@interface MenuMeterMemExtra : NSMenuExtra  {

	// Menu Extra necessities
	NSMenu 							*extraMenu;
    MenuMeterMemView 				*extraView;
	// Is this Panther? Tiger?
	BOOL							isPantherOrLater, isTigerOrLater;
	// The timer
	NSTimer							*updateTimer;
	// Pref object
	MenuMeterDefaults				*ourPrefs;
	// Info gathers
	MenuMeterMemStats				*memStats;
	// Localized strings
	NSDictionary					*localizedStrings;
	// Formatters for numbers so we get localization correctly
	NSNumberFormatter				*memFloatMBFormatter,
									*memIntMBFormatter,
									*prettyIntFormatter,
									*percentFormatter;
	// Colors
	NSColor							*freeColor, *usedColor,
									*activeColor, *inactiveColor, *wireColor, *compressedColor,
									*pageInColor, *pageOutColor;
	// Image cache for numbers label
	NSImage							*numberLabelPrerender;
	// Width of the menu item
	float							menuWidth;
	// Width of the text display
	float							textWidth;
	// History data
	NSMutableArray					*memHistory;
	NSDictionary					*currentSwapStats;
	// Theme support
	NSColor							*fgMenuThemeColor;

} // MenuMeterMemExtra

@end

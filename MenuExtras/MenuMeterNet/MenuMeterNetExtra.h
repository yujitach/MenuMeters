//
//  MenuMeterNetExtra.h
//
//  Menu Extra implementation
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

#import "MenuMeterDefaults.h"
#import "MenuMeterNet.h"
#import "MenuMeterNetConfig.h"
#import "MenuMeterNetPPP.h"
#import "MenuMeterNetStats.h"
#import "MenuMeterWorkarounds.h"
#import "MenuMeters.h"
#import <Carbon/Carbon.h>
#import <Cocoa/Cocoa.h>

@interface MenuMeterNetExtra : NSMenuExtra {

	// Menu Extra necessities
	NSMenu *extraMenu;
	// Pref object
	MenuMeterDefaults *ourPrefs;
	// Info gatherers/controllers
	MenuMeterNetConfig *netConfig;
	MenuMeterNetStats *netStats;
	MenuMeterNetPPP *pppControl;
	// Formatters for localization
	NSNumberFormatter *bytesFormatter, *prettyIntFormatter;
	// Cached colors
	NSColor *txColor, *rxColor, *inactiveColor;
	// Cached bezier paths
	NSBezierPath *upArrow, *downArrow;
	// Cached prerendered text
	NSImage *throughputLabel, *inactiveThroughputLabel;
	// The length of the menu item
	float menuWidth;
	// Historical data samples and current interface config
	NSDate *lastSampleDate;
	NSMutableArray *netHistoryData, *netHistoryIntervals;
	NSDictionary *preferredInterfaceConfig;
	// Cached dictionary of menu items that can be updated
	NSMutableDictionary *updateMenuItems;
	NSFont *throughputFont;
	BOOL tallMenuBar;

} // MenuMeterNetExtra

@end

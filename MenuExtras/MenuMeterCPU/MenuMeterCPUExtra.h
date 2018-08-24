//
//  MenuMeterCPUExtra.h
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
#import "MenuMeterCPU.h"
#import "MenuMeterCPUView.h"
#import "MenuMeterCPUStats.h"
#import "MenuMeterCPUTopProcesses.h"
#import "MenuMeterUptime.h"
#import "MenuMeterPowerMate.h"
#import "MenuMeterWorkarounds.h"


@interface MenuMeterCPUExtra : NSMenuExtra {

	// Menu Extra necessities
	NSMenu 							*extraMenu;
    MenuMeterCPUView 				*extraView;
	// Prefs object
	MenuMeterDefaults				*ourPrefs;
	// Info gatherers
	MenuMeterCPUStats				*cpuInfo;
    MenuMeterCPUTopProcesses        *cpuTopProcesses;
	MenuMeterUptime					*uptimeInfo;
	// PowerMate support
	MenuMeterPowerMate				*powerMate;
	// The length of the menu item
	float							menuWidth;
	// Prerendered percentage text displays and their calculated width
	float							percentWidth;
	NSMutableArray					*singlePercentCache,
									*splitUserPercentCache,
									*splitSystemPercentCache;
	// Historical data samples
	NSMutableArray					*loadHistory;
	// Cached colors and theme support
	NSColor							*userColor,
									*systemColor,
									*fgMenuThemeColor;

} // MenuMeterCPUExtra

@end

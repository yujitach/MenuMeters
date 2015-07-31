//
//  MenuMeterMemStats.h
//
// 	Reader object for VM info
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
#import <dlfcn.h>
#import <mach/mach.h>
#import <mach/mach_error.h>
#import <sys/sysctl.h>
#import <unistd.h>
#import "MenuMeterWorkarounds.h"


@interface MenuMeterMemStats : NSObject {

	// Mach host
	mach_port_t				selfHost;
	// Total RAM
	uint64_t				totalRAM;
	// Tiger or later?
	BOOL					isTigerOrLater;
	// Mavericks or later?
	BOOL					isMavericksOrLater;
	// Path to swap
	NSString				*swapPath;
	// Swap name prefix
	NSString				*swapPrefix;
	// Max swap count
	uint32_t				peakSwapFiles;
	// Last paging counts
	uint64_t				lastPageIn, lastPageOut;

} // MenuMeterMemStats

// Mem usage info
- (NSDictionary *)memStats;
- (NSDictionary *)swapStats;

@end

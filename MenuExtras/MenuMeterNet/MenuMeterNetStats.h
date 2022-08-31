//
//  MenuMeterNetStats.h
//
// 	Reader object for network throughput info
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

#import <Foundation/Foundation.h>
#import <sys/types.h>
#import <sys/sysctl.h>
#import <sys/socket.h>
#import <net/if.h>
#import <net/if_dl.h>
#import <net/if_var.h>
#import <net/route.h>
#import <limits.h>
#import "MenuMeterNetPPP.h"

@interface MenuMeterNetStats : NSObject {

	// Old data for containing prior reads
	NSMutableDictionary		*lastData;
	// Buffer we keep around
	size_t					sysctlBufferSize;
	uint8_t					*sysctlBuffer;
	// PPP data
	MenuMeterNetPPP			*pppGatherer;

} // MenuMeterNetStats

// Net usage info
- (NSDictionary *)netStatsForInterval:(NSTimeInterval)sampleInterval;
- (void)resetStatsForInterfaceName:(NSString*)interfaceName;
@end

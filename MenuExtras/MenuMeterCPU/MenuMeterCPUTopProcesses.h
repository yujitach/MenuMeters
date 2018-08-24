//
//  MenuMeterCPUTopProcesses.h
//
//  Reader object for top CPU hogging process list
//
//	Copyright (c) 2018 Hofi
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

extern NSString* const kProcessListItemPIDKey;
extern NSString* const kProcessListItemProcessNameKey;
extern NSString* const kProcessListItemProcessPathKey;
extern NSString* const kProcessListItemUserIDKey;
extern NSString* const kProcessListItemUserNameKey;
extern NSString* const kProcessListItemCPUKey;

@interface MenuMeterCPUTopProcesses : NSObject

// Basic process info for the top maxItem most CPU hugging processes
- (NSArray *)runningProcessesByCPUUsage:(NSUInteger)maxItem;

- (void)startUpdateProcessList;
- (void)stopUpdateProcessList;

@end

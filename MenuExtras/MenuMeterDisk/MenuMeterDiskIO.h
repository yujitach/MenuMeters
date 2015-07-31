//
//  MenuMeterDiskIO.h
//
// 	Reader object for disk IO statistics
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
#import <sys/param.h>
#import <sys/mount.h>
#import <IOKit/IOKitLib.h>
#import <IOKit/storage/IOBlockStorageDriver.h>
#import "MenuMeters.h"
#import "MenuMeterDisk.h"


@interface MenuMeterDiskIO : NSObject {

	// IOKit connection
	mach_port_t        		masterPort;
	IONotificationPortRef	notifyPort;
	CFRunLoopSourceRef		notifyRunSource;
	io_iterator_t			blockDevicePublishedIterator,
							blockDeviceTerminatedIterator,
							blockDeviceIterator;
	// Tracking values
	uint64_t				previousTotalRead, previousTotalWrite;

} // MenuMeterDiskIO

// Disk activity info
- (DiskIOActivityType)diskIOActivity;

@end

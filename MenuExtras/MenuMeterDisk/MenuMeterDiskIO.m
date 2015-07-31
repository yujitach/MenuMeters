//
//  MenuMeterDiskIO.m
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

#import "MenuMeterDiskIO.h"
#import <mach/mach_port.h>


///////////////////////////////////////////////////////////////
//
//	Private methods and constants
//
///////////////////////////////////////////////////////////////

@interface MenuMeterDiskIO (PrivateMethods)
-(void)blockDeviceChanged:(io_iterator_t)iterator;
@end

///////////////////////////////////////////////////////////////
//
//	IOKit notification callbacks
//
///////////////////////////////////////////////////////////////

static void BlockDeviceChanged(void *ref, io_iterator_t iterator) {

	if (ref) [(MenuMeterDiskIO *)ref blockDeviceChanged:iterator];

} // BlockDeviceChanged


///////////////////////////////////////////////////////////////
//
//	init/dealloc
//
///////////////////////////////////////////////////////////////

@implementation MenuMeterDiskIO

- (id)init {

	self = [super init];
	if (!self) {
		return nil;
	}

	// Connect to IOKit and setup our notification source
	kern_return_t err = IOMasterPort(MACH_PORT_NULL, &masterPort);
	if ((err != KERN_SUCCESS) || !masterPort) {
		[self release];
		return nil;
	}
	notifyPort = IONotificationPortCreate(masterPort);
	if (!notifyPort) {
		[self release];
		return nil;
	}
	notifyRunSource = IONotificationPortGetRunLoopSource(notifyPort);
	if (!notifyRunSource) {
		[self release];
		return nil;
	}
	CFRunLoopAddSource(CFRunLoopGetCurrent(), notifyRunSource, kCFRunLoopDefaultMode);

	// Install notifications for block storage devices
	err = IOServiceAddMatchingNotification(notifyPort,  kIOPublishNotification,
										   IOServiceMatching(kIOBlockStorageDriverClass),
										   BlockDeviceChanged, self, &blockDevicePublishedIterator);
	if (err != KERN_SUCCESS) {
		[self release];
		return nil;
	}
	err = IOServiceAddMatchingNotification(notifyPort, kIOTerminatedNotification,
										   IOServiceMatching(kIOBlockStorageDriverClass),
										   BlockDeviceChanged, self, &blockDeviceTerminatedIterator);
	if (err != KERN_SUCCESS) {
		[self release];
		return nil;
	}

	// Pump both iterators
	BlockDeviceChanged(self, blockDevicePublishedIterator);
	BlockDeviceChanged(self, blockDeviceTerminatedIterator);

	// Seed our data
	[self diskIOActivity];

	return self;

} // init

- (void)dealloc {

	if (blockDeviceIterator) IOObjectRelease(blockDeviceIterator);
	if (blockDevicePublishedIterator) IOObjectRelease(blockDevicePublishedIterator);
	if (blockDeviceTerminatedIterator) IOObjectRelease(blockDeviceTerminatedIterator);
	if (notifyRunSource) {
		CFRunLoopRemoveSource(CFRunLoopGetCurrent(), notifyRunSource, kCFRunLoopDefaultMode);
	}
	if (notifyPort) IONotificationPortDestroy(notifyPort);
	if (masterPort) mach_port_deallocate(mach_task_self(), masterPort);
	[super dealloc];

} // dealloc

///////////////////////////////////////////////////////////////
//
//	Disk activity
//
///////////////////////////////////////////////////////////////

- (DiskIOActivityType)diskIOActivity {

	// Check that the iterator is still good, if not get a new one
	if (!blockDeviceIterator) {
		kern_return_t err = IOServiceGetMatchingServices(masterPort,
														 IOServiceMatching(kIOBlockStorageDriverClass),
														 &blockDeviceIterator);
		if (err != KERN_SUCCESS) {
			return kDiskActivityIdle;  // Best we can do
		}
	}

	// Iterate the device list from IOKit and figure out if we're reading
	// or writing
	io_registry_entry_t driveEntry = MACH_PORT_NULL;
	uint64_t totalRead = 0, totalWrite = 0;
	while ((driveEntry = IOIteratorNext(blockDeviceIterator))) {

 		// Get the statistics for this drive
		CFDictionaryRef statistics = IORegistryEntryCreateCFProperty(driveEntry,
																	 CFSTR(kIOBlockStorageDriverStatisticsKey),
																	 kCFAllocatorDefault,
																	 kNilOptions);
		// If we got the statistics block for this device then we can add it to our totals
		if (statistics) {
			// Get total bytes read
			NSNumber *statNumber = (NSNumber *)[(NSDictionary *)statistics objectForKey:
													(NSString *)CFSTR(kIOBlockStorageDriverStatisticsBytesReadKey)];
			if (statNumber) {
				totalRead += [statNumber unsignedLongLongValue];
			}
			// Bytes written
			statNumber = (NSNumber *)[(NSDictionary *)statistics objectForKey:
													(NSString *)CFSTR(kIOBlockStorageDriverStatisticsBytesWrittenKey)];
			if (statNumber) {
				totalWrite += [statNumber unsignedLongLongValue];
			}
			// Release
			CFRelease(statistics);
		} // end of statistics read

		// Release the drive
		if (driveEntry) {
			IOObjectRelease(driveEntry);
		}

	} // end of IOKit drive iteration

	// Reset our drive list
	IOIteratorReset(blockDeviceIterator);

	// Once we have totals all we care is if they changed. Calculating actualy
	// delta isn't important, since unmounts and overflows will change the
	// values. We're basically assuming that unmount == read/write, but
	// close enough.
	DiskIOActivityType activity = kDiskActivityIdle;
	if ((totalRead != previousTotalRead) && (totalWrite != previousTotalWrite)) {
		activity = kDiskActivityReadWrite;
	} else if (totalRead != previousTotalRead) {
		activity = kDiskActivityRead;
	} else if (totalWrite != previousTotalWrite) {
		activity = kDiskActivityWrite;
	}
	previousTotalRead = totalRead;
	previousTotalWrite = totalWrite;
	return activity;

} // diskIOActivity

///////////////////////////////////////////////////////////////
//
//	Device state changes
//
///////////////////////////////////////////////////////////////

-(void)blockDeviceChanged:(io_iterator_t)iterator {

	// Remove the current drive iterator, forcing its recreation later
	if (blockDeviceIterator) IOObjectRelease(blockDeviceIterator);
	blockDeviceIterator = MACH_PORT_NULL;

	// Drain the iterator
	io_service_t someDevice = IOIteratorNext(iterator);
	while (someDevice) {
		IOObjectRelease(someDevice);
		someDevice = IOIteratorNext(iterator);
	}

} // _blockDeviceChanged:

@end

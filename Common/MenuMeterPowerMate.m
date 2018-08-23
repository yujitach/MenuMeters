//
//  MenuMeterPowerMate.m
//
//	PowerMate support
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

#import "MenuMeterPowerMate.h"
#import <mach/mach_port.h>


///////////////////////////////////////////////////////////////
//
//	Private methods and constants
//
///////////////////////////////////////////////////////////////

@interface MenuMeterPowerMate (PrivateMethods)
-(void)glowRamp:(NSTimer *)timer;
-(void)deviceMatched:(io_iterator_t)iterator;
-(void)deviceTerminated:(io_iterator_t)iterator;
@end

#define kGlowRampInterval 0.05


///////////////////////////////////////////////////////////////
//
//	IOKit notification callbacks
//
///////////////////////////////////////////////////////////////

static void DeviceMatched(void *ref, io_iterator_t iterator) {

	if (ref) [(__bridge MenuMeterPowerMate *)ref deviceMatched:iterator];

} // DeviceMatched

static void DeviceTerminated(void *ref, io_iterator_t iterator) {

	if (ref) [(__bridge MenuMeterPowerMate *)ref deviceTerminated:iterator];

} // DeviceTerminated


///////////////////////////////////////////////////////////////
//
//	init/dealloc
//
///////////////////////////////////////////////////////////////

@implementation MenuMeterPowerMate

+ (BOOL)powermateAttached {

	// Check for device
	mach_port_t	localMasterPort = 0;
	kern_return_t err = IOMasterPort(MACH_PORT_NULL, &localMasterPort);
	if ((err != KERN_SUCCESS) || !localMasterPort) return NO;

	// Construct a matching dict
	CFMutableDictionaryRef matchingDict = IOServiceMatching("IOUSBDevice");
	if (!matchingDict) {
		mach_port_deallocate(mach_task_self(), localMasterPort);
		return NO;
	}
	// ID info here from Griffin sample code. Keep this pure CF so GC behavior
	// is clear.
	SInt32 vendorID = 0x077d, productID = 0x0410;
	CFNumberRef vendorIDNum = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &vendorID);
	CFNumberRef productIDNum = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &productID);
	CFDictionarySetValue(matchingDict, CFSTR(kUSBVendorID), vendorIDNum);
	CFDictionarySetValue(matchingDict, CFSTR(kUSBProductID), productIDNum);
	CFRelease(vendorIDNum);
	CFRelease(productIDNum);

	// Device service? Reference is stolen.
	io_service_t powermateService = IOServiceGetMatchingService(localMasterPort, matchingDict);
	BOOL deviceAttached = NO;
	if (powermateService) {
		deviceAttached = YES;
	}

	// Clean up
	IOObjectRelease(powermateService);
	mach_port_deallocate(mach_task_self(), localMasterPort);

	return deviceAttached;

} // powermateAttached

- (id)init {

	self = [super init];
	if (!self) {
		return nil;
	}

	// Connect to IOKit and setup our notification source
	kern_return_t err = IOMasterPort(MACH_PORT_NULL, &masterPort);
	if ((err != KERN_SUCCESS) || !masterPort) {
		return nil;
	}
	notifyPort = IONotificationPortCreate(masterPort);
	if (!notifyPort) {
		return nil;
	}
	notifyRunSource = IONotificationPortGetRunLoopSource(notifyPort);
	if (!notifyRunSource) {
		return nil;
	}
	CFRunLoopAddSource(CFRunLoopGetCurrent(), notifyRunSource, kCFRunLoopDefaultMode);

	// Construct a matching dict
	CFMutableDictionaryRef matchingDict = IOServiceMatching("IOUSBDevice");
	if (!matchingDict) {
		return nil;
	}
	// ID info here from Griffin sample code. Keep this pure CF so GC behavior
	// is clear.
	SInt32 vendorID = 0x077d, productID = 0x0410;
	CFNumberRef vendorIDNum = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &vendorID);
	CFNumberRef productIDNum = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &productID);
	CFDictionarySetValue(matchingDict, CFSTR(kUSBVendorID), vendorIDNum);
	CFDictionarySetValue(matchingDict, CFSTR(kUSBProductID), productIDNum);
	CFRelease(vendorIDNum);
	CFRelease(productIDNum);

	// IOServiceAddMatchingNotification() consumes a reference so make a copy
	CFMutableDictionaryRef terminatedDict = CFDictionaryCreateMutableCopy(kCFAllocatorDefault, 0, matchingDict);
	if (!terminatedDict) {
		CFRelease(matchingDict);
		return nil;
	}

	// Install notifications for Powermate devices
	err = IOServiceAddMatchingNotification(notifyPort,
                                           kIOMatchedNotification,
										   matchingDict,
										   DeviceMatched,
                                           (__bridge void *)(self), &deviceMatchedIterator);
	if (err != KERN_SUCCESS) {
        CFRelease(terminatedDict);

		return nil;
	}

    err = IOServiceAddMatchingNotification(notifyPort,
                                           kIOTerminatedNotification,
										   terminatedDict,
										   DeviceTerminated,
                                           (__bridge void *)(self), &deviceTerminatedIterator);
	if (err != KERN_SUCCESS) {
		return nil;
	}

	// Pump the iterators and trigger first matching if the device is already
	// present. Run termnated first so that matched iterator leaves us
	// in correct state.
	DeviceTerminated((__bridge void *)(self), deviceTerminatedIterator);
	DeviceMatched((__bridge void *)(self), deviceMatchedIterator);

	return self;
} // init

- (void)dealloc {

	[rampTimer invalidate];  // Runloop releases
	if (deviceInterface) (*deviceInterface)->Release(deviceInterface);
	if (deviceMatchedIterator) IOObjectRelease(deviceMatchedIterator);
	if (deviceTerminatedIterator) IOObjectRelease(deviceTerminatedIterator);
	if (notifyRunSource) {
		CFRunLoopRemoveSource(CFRunLoopGetCurrent(), notifyRunSource, kCFRunLoopDefaultMode);
	}
	if (notifyPort) IONotificationPortDestroy(notifyPort);
	if (masterPort) mach_port_deallocate(mach_task_self(), masterPort);

} // dealloc

///////////////////////////////////////////////////////////////
//
//	Public interface
//
///////////////////////////////////////////////////////////////

- (void)setGlow:(double)level {

	// Cancel any running timer
	[rampTimer invalidate];
	rampTimer = nil;

	if (!(devicePresent && deviceInterface)) return;

	// Sanity
	if (level > 1.0) level = 1.0;
	if (level < 0) level = 0;

	// Clear pulsing
	[self stopPulse];

	// Store and clear ramp
	lastGlowLevel = level;
	targetGlowLevel =level;
	rampGlowStep = 0;

	// Only 128 levels of glow
	UInt16 targetGlow = 128 * level;
	if (targetGlow > 128) targetGlow = 128;

	IOUSBDevRequest	usbRequest;
	usbRequest.bmRequestType = 0x41;
	usbRequest.bRequest = 0x01;
	usbRequest.wValue = 0x01;
	usbRequest.wIndex = targetGlow;
	usbRequest.wLength = 0;
	usbRequest.pData = NULL;
	(*deviceInterface)->DeviceRequest(deviceInterface, &usbRequest);

} // setGlow:

- (void)setGlow:(double)level rampInterval:(NSTimeInterval)interval {

	// Cancel any running timer
	[rampTimer invalidate];
	rampTimer = nil;

	if (!(devicePresent && deviceInterface)) return;

	// Sanity
	if (level > 1.0) level = 1.0;
	if (level < 0) level = 0;

	// Clear pulsing
	[self stopPulse];

	// We tick every kGlowRampInterval seconds, is the interval too short?
	if (interval <= kGlowRampInterval) [self setGlow:level];

	// Calc steps. We're happy with steps that are actually finer
	// than the device can handle.
	double step = (level - lastGlowLevel) / (interval / kGlowRampInterval);

	// Schedule a timer and set our details. We could pass this inside
	// the timer, but with only one timer its not needed.
	rampGlowStep = step;
	targetGlowLevel = level;
	rampTimer = [NSTimer scheduledTimerWithTimeInterval:kGlowRampInterval
												 target:self
											   selector:@selector(glowRamp:)
											   userInfo:nil
												repeats:YES];
	// Start stepping before the timer fires
	[self glowRamp:rampTimer];

} // setGlow:rampInterval:

- (void)setPulse:(double)rate {

	if (!(devicePresent && deviceInterface)) return;

	// Sanity
	if (rate > 1.0) rate = 1.0;
	if (rate < 0) rate = 0;

	// Turn on pulsing on
	IOUSBDevRequest	usbRequest;
	usbRequest.bmRequestType = 0x41;
	usbRequest.bRequest = 0x01;
	usbRequest.wValue = 0x03;
	usbRequest.wIndex = 0x01;
	usbRequest.wLength = 0;
	usbRequest.pData = NULL;
	(*deviceInterface)->DeviceRequest(deviceInterface, &usbRequest);

	// There are multiple pulse tables, I can't really see much difference.
	// Table 1 looks good.
	usbRequest.wValue = 0x0104;

	// Pulse rate is weird, dividing or multiplying by 0xFF gives
	// too wide a range (device just flickers). Restrict to just 24 positions,
	// not centered on the default rate
	uint8_t pulseRate = 24 * rate;
	if (pulseRate > 2) {
		usbRequest.wIndex = 0x02 | (pulseRate << 8);
	} else if (pulseRate == 2) {
		usbRequest.wIndex = 0x0001;
	} else {
		usbRequest.wIndex = (2 - pulseRate) << 8;
	}
	(*deviceInterface)->DeviceRequest(deviceInterface, &usbRequest);

} // setPulse:

- (void)stopPulse {

	if (!(devicePresent && deviceInterface)) return;
	IOUSBDevRequest	usbRequest;
	usbRequest.bmRequestType = 0x41;
	usbRequest.bRequest = 0x01;
	usbRequest.wValue = 0x03;
	usbRequest.wIndex = 0x00;
	usbRequest.wLength = 0;
	usbRequest.pData = NULL;
	(*deviceInterface)->DeviceRequest(deviceInterface, &usbRequest);

} // stopPulse

///////////////////////////////////////////////////////////////
//
//	Timer callback
//
///////////////////////////////////////////////////////////////

-(void)glowRamp:(NSTimer *)timer {

	// Sanity checks
	if (!(devicePresent && deviceInterface)) {
		[rampTimer invalidate];
		rampTimer = nil;
		return;
	}

	// Calc next level
	double newLevel = lastGlowLevel + rampGlowStep;
	if (newLevel > 1.0) newLevel = 1.0;
	if (newLevel < 0) newLevel = 0;

	// If we've met the target return to the normal code path
	if (rampGlowStep > 0) {
		if (newLevel > targetGlowLevel) {
			[self setGlow:targetGlowLevel];  // Cancels timer
			return;
		}
	} else {
		if (newLevel < targetGlowLevel) {
			[self setGlow:targetGlowLevel];  // Cancels timer
			return;
		}
	}

	// Intermediate level set from here
	// Only 128 levels of glow
	UInt16 targetGlow = 128 * newLevel;
	if (targetGlow > 128) targetGlow = 128;

	IOUSBDevRequest	usbRequest;
	usbRequest.bmRequestType = 0x41;
	usbRequest.bRequest = 0x01;
	usbRequest.wValue = 0x01;
	usbRequest.wIndex = targetGlow;
	usbRequest.wLength = 0;
	usbRequest.pData = NULL;
	(*deviceInterface)->DeviceRequest(deviceInterface, &usbRequest);

	lastGlowLevel = newLevel;

} // glowRamp:

///////////////////////////////////////////////////////////////
//
//	Device state changes
//
///////////////////////////////////////////////////////////////

-(void)deviceMatched:(io_iterator_t)iterator {

	io_service_t pmDevice = IOIteratorNext(iterator);
	if (!pmDevice) return;

	// Drain the iterator
	io_service_t otherDevice = IOIteratorNext(iterator);
	while (otherDevice) {
		IOObjectRelease(otherDevice);
		otherDevice = IOIteratorNext(iterator);
	}

	// At least one device matched (we make no attempt to handle multiple devices).
	if (devicePresent || deviceInterface) {
		IOObjectRelease(pmDevice);
		return;
	}

	IOCFPlugInInterface **plugInInterface = NULL;
	SInt32 score = 0;
	kern_return_t createErr = IOCreatePlugInInterfaceForService(pmDevice,
																kIOUSBDeviceUserClientTypeID,
																kIOCFPlugInInterfaceID,
																&plugInInterface, &score);
	if ((createErr != KERN_SUCCESS) || !plugInInterface) {
		IOObjectRelease(pmDevice);
		return;
	}
	HRESULT queryErr = (*plugInInterface)->QueryInterface(plugInInterface,
														  CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID),
														  (LPVOID)&deviceInterface);
	IODestroyPlugInInterface(plugInInterface);
	if (queryErr || !deviceInterface) {
		IOObjectRelease(pmDevice);
		return;
	}
	IOReturn openErr = (*deviceInterface)->USBDeviceOpen(deviceInterface);
	if (openErr != kIOReturnSuccess) {
		(*deviceInterface)->Release(deviceInterface);
		deviceInterface = NULL;
		IOObjectRelease(pmDevice);
		return;
	}

	// We have a device
	devicePresent = YES;

} // _deviceMatched:

-(void)deviceTerminated:(io_iterator_t)iterator {

	// Assume any termination is our device (again, no attempt to handle
	// multiple devices)
	if (deviceInterface) (*deviceInterface)->Release(deviceInterface);
	deviceInterface = NULL;
	devicePresent = NO;

	// Drain the iterator
	io_service_t someDevice = IOIteratorNext(iterator);
	while (someDevice) {
		IOObjectRelease(someDevice);
		someDevice = IOIteratorNext(iterator);
	}

} // deviceTerminated:

@end

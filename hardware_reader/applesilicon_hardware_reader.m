//
//  applesilicon_hardware_reader.m
//  MenuMeters
//
//  Created by Yuji on 1/25/21.
//

#import "applesilicon_hardware_reader.h"
#import <Foundation/Foundation.h>

// This code is based on https://github.com/fermion-star/apple_sensors/blob/master/temp_sensor.m
// which was in turn based on https://github.com/freedomtan/sensors/blob/master/sensors/sensors.m
// whose detail can be found in https://www2.slideshare.net/kstan2/exploring-thermal-related-stuff-in-idevices-using-opensource-tool

#include <IOKit/hidsystem/IOHIDEventSystemClient.h>

// Declarations from other IOKit source code

typedef struct __IOHIDEvent *IOHIDEventRef;
typedef struct __IOHIDServiceClient *IOHIDServiceClientRef;
#ifdef __LP64__
typedef double IOHIDFloat;
#else
typedef float IOHIDFloat;
#endif

IOHIDEventSystemClientRef IOHIDEventSystemClientCreate(CFAllocatorRef allocator);
int IOHIDEventSystemClientSetMatching(IOHIDEventSystemClientRef client, CFDictionaryRef match);
int IOHIDEventSystemClientSetMatchingMultiple(IOHIDEventSystemClientRef client, CFArrayRef match);
IOHIDEventRef IOHIDServiceClientCopyEvent(IOHIDServiceClientRef, int64_t, int32_t, int64_t);
CFTypeRef _Nullable IOHIDServiceClientCopyProperty(IOHIDServiceClientRef service, CFStringRef key);
IOHIDFloat IOHIDEventGetFloatValue(IOHIDEventRef event, int32_t field);

// extern uint64_t my_mhz(void);
// extern void mybat(void);
//   Primary Usage Page:
//     kHIDPage_AppleVendor                        = 0xff00,
//     kHIDPage_AppleVendorTemperatureSensor       = 0xff05,
//     kHIDPage_AppleVendorPowerSensor             = 0xff08,
//
//   Primary Usage:
//     kHIDUsage_AppleVendor_TemperatureSensor     = 0x0005,
//     kHIDUsage_AppleVendorPowerSensor_Current    = 0x0002,
//     kHIDUsage_AppleVendorPowerSensor_Voltage    = 0x0003,
//  See IOHIDFamily/AppleHIDUsageTables.h for more information
//  https://opensource.apple.com/source/IOHIDFamily/IOHIDFamily-701.60.2/IOHIDFamily/AppleHIDUsageTables.h.auto.html

#define IOHIDEventFieldBase(type) (type << 16)
#define kIOHIDEventTypeTemperature 15
#define kIOHIDEventTypePower 25

NSDictionary *AppleSiliconTemperatureDictionary(void) {
	NSDictionary *thermalSensors = @{@"PrimaryUsagePage": @(0xff00),
	 								 @"PrimaryUsage": @(5)};

	IOHIDEventSystemClientRef system = IOHIDEventSystemClientCreate(kCFAllocatorDefault); // in CFBase.h = NULL
	// ... this is the same as using kCFAllocatorDefault or the return value from CFAllocatorGetDefault()
	IOHIDEventSystemClientSetMatching(system, (__bridge CFDictionaryRef)thermalSensors);
	CFArrayRef matchingsrvs = IOHIDEventSystemClientCopyServices(system); // matchingsrvs = matching services

	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	long count = CFArrayGetCount(matchingsrvs);
	for (int i = 0; i < count; i++) {
		IOHIDServiceClientRef sc = (IOHIDServiceClientRef)CFArrayGetValueAtIndex(matchingsrvs, i);
		NSString *name = CFBridgingRelease(IOHIDServiceClientCopyProperty(sc, CFSTR("Product"))); // here we use ...CopyProperty
		IOHIDEventRef event = IOHIDServiceClientCopyEvent(sc, kIOHIDEventTypeTemperature, 0, 0);  // here we use ...CopyEvent
		if (name && event) {
			double temp = IOHIDEventGetFloatValue(event, IOHIDEventFieldBase(kIOHIDEventTypeTemperature));
			dict[name] = @(temp);
		}
		if (event) {
			CFRelease(event);
		}
	}

	CFRelease(matchingsrvs);
	CFRelease(system);

	return dict;
}

float AppleSiliconTemperatureForName(NSString *productName) {

	NSDictionary *thermalSensors = @{@"PrimaryUsagePage": @(0xff00),
									 @"PrimaryUsage": @(5)};

	IOHIDEventSystemClientRef system = IOHIDEventSystemClientCreate(kCFAllocatorDefault); // in CFBase.h = NULL
	// ... this is the same as using kCFAllocatorDefault or the return value from CFAllocatorGetDefault()
	IOHIDEventSystemClientSetMatching(system, (__bridge CFDictionaryRef)thermalSensors);
	CFArrayRef matchingsrvs = IOHIDEventSystemClientCopyServices(system); // matchingsrvs = matching services

	long count = CFArrayGetCount(matchingsrvs);
	float temp = 0;
	for (int i = 0; i < count; i++) {
		IOHIDServiceClientRef sc = (IOHIDServiceClientRef)CFArrayGetValueAtIndex(matchingsrvs, i);
		NSString *name = CFBridgingRelease(IOHIDServiceClientCopyProperty(sc, CFSTR("Product"))); // here we use ...CopyProperty
		if ([productName isEqualToString:name]) {
			IOHIDEventRef event = IOHIDServiceClientCopyEvent(sc, kIOHIDEventTypeTemperature, 0, 0); // here we use ...CopyEvent
			if (event) {
				temp = IOHIDEventGetFloatValue(event, IOHIDEventFieldBase(kIOHIDEventTypeTemperature));
				CFRelease(event);
				break;
			}
		}
	}
	CFRelease(matchingsrvs);
	CFRelease(system);

	return temp;
}

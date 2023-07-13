//
//  applesilicon_hardware_reader.m
//  MenuMeters
//
//  Created by Yuji on 1/25/21.
//

#import <Foundation/Foundation.h>
#import "applesilicon_hardware_reader.h"

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
IOHIDEventRef IOHIDServiceClientCopyEvent(IOHIDServiceClientRef, int64_t , int32_t, int64_t);
CFTypeRef _Nullable IOHIDServiceClientCopyProperty(IOHIDServiceClientRef service, CFStringRef key);
IOHIDFloat IOHIDEventGetFloatValue(IOHIDEventRef event, int32_t field);

//extern uint64_t my_mhz(void);
//extern void mybat(void);
    //  Primary Usage Page:
    //    kHIDPage_AppleVendor                        = 0xff00,
    //    kHIDPage_AppleVendorTemperatureSensor       = 0xff05,
    //    kHIDPage_AppleVendorPowerSensor             = 0xff08,
    //
    //  Primary Usage:
    //    kHIDUsage_AppleVendor_TemperatureSensor     = 0x0005,
    //    kHIDUsage_AppleVendorPowerSensor_Current    = 0x0002,
    //    kHIDUsage_AppleVendorPowerSensor_Voltage    = 0x0003,
    // See IOHIDFamily/AppleHIDUsageTables.h for more information
    // https://opensource.apple.com/source/IOHIDFamily/IOHIDFamily-701.60.2/IOHIDFamily/AppleHIDUsageTables.h.auto.html


#define IOHIDEventFieldBase(type)   (type << 16)
#define kIOHIDEventTypeTemperature  15
#define kIOHIDEventTypePower        25

static dispatch_once_t once=0;
static IOHIDEventSystemClientRef eventSystem;

static void initEventSystem(void){
    dispatch_once(&once,^{
        eventSystem = IOHIDEventSystemClientCreate(kCFAllocatorDefault); // in CFBase.h = NULL
    });
}

NSArray*AppleSiliconTemperatureSensorNames(void)
{
    initEventSystem();
    
    NSDictionary*thermalSensors=@{@"PrimaryUsagePage":@(0xff00),@"PrimaryUsage":@(5)};

   
    // ... this is the same as using kCFAllocatorDefault or the return value from CFAllocatorGetDefault()
    IOHIDEventSystemClientSetMatching(eventSystem, (__bridge CFDictionaryRef)thermalSensors);
    NSArray* matchingsrvs = CFBridgingRelease(IOHIDEventSystemClientCopyServices(eventSystem)); // matchingsrvs = matching services


    NSMutableArray*array=[NSMutableArray array];
    for (NSObject* scx in matchingsrvs) {
        IOHIDServiceClientRef sc = (__bridge IOHIDServiceClientRef)scx;
        NSString* name = CFBridgingRelease(IOHIDServiceClientCopyProperty(sc, CFSTR("Product"))); // here we use ...CopyProperty
        if (name) {
            [array addObject:name];
        }
    }
    
    
    return array;
    
}

float AppleSiliconTemperatureForName(NSString *productName) {
    initEventSystem();

	NSDictionary *thermalSensors = @{@"PrimaryUsagePage": @(0xff00),
									  @"PrimaryUsage": @(5),
                                      @"Product":productName};
	// ... this is the same as using kCFAllocatorDefault or the return value from CFAllocatorGetDefault()
	IOHIDEventSystemClientSetMatching(eventSystem, (__bridge CFDictionaryRef)thermalSensors);
    NSArray* matchingsrvs = CFBridgingRelease(IOHIDEventSystemClientCopyServices(eventSystem)); // matchingsrvs = matching services
    float temp=-273.15F;
    if(matchingsrvs){
        if([matchingsrvs count]>0){
            IOHIDServiceClientRef sc = (__bridge IOHIDServiceClientRef)matchingsrvs[0];
            IOHIDEventRef event = IOHIDServiceClientCopyEvent(sc, kIOHIDEventTypeTemperature, 0, 0); // here we use ...CopyEvent
            if (event) {
                temp = IOHIDEventGetFloatValue(event, IOHIDEventFieldBase(kIOHIDEventTypeTemperature));
                CFRelease(event);
            }
        }
    }

	return temp;
}

//
//  applesilicon_hardware_reader.m
//  MenuMeters
//
//  Created by Yuji on 1/25/21.
//
//  Changed 2026-10-27 by Joe Moreno: initEventSystem declared with (void),
//  so the project builds with Xcode 27, and freedomtan's notice restored
//  below.
//

#import <Foundation/Foundation.h>
#import "applesilicon_hardware_reader.h"

// This code is based on https://github.com/fermion-star/apple_sensors/blob/master/temp_sensor.m
// which was in turn based on https://github.com/freedomtan/sensors/blob/master/sensors/sensors.m
// whose detail can be found in https://www2.slideshare.net/kstan2/exploring-thermal-related-stuff-in-idevices-using-opensource-tool
// freedomtan's code is under the BSD 3-Clause License, which temp_sensor.m
// carried as "the original code's license":
//
// BSD 3-Clause License
//
// Copyright (c) 2016-2018, "freedom" Koan-Sin Tan
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice, this
//   list of conditions and the following disclaimer.
//
// * Redistributions in binary form must reproduce the above copyright notice,
//   this list of conditions and the following disclaimer in the documentation
//   and/or other materials provided with the distribution.
//
// * Neither the name of the copyright holder nor the names of its
//   contributors may be used to endorse or promote products derived from
//   this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


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

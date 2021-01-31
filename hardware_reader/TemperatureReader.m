//
//  TemperatureReader.m
//  MenuMeters
//
//  Created by Yuji on 1/31/21.
//

#import "TemperatureReader.h"
#if TARGET_CPU_X86_64
#import "smc_reader.h"
#elif TARGET_CPU_ARM64
#import "applesilicon_hardware_reader.h"
#endif

@implementation TemperatureReader
+(NSArray*)sensorNames
{
#if TARGET_CPU_X86_64
    return nil;
#elif TARGET_CPU_ARM64
    return [[AppleSiliconTemperatureDictionary() allKeys] sortedArrayUsingSelector:@selector(compare:)];
#endif
}
+(NSString*)defaultSensor
{
#if TARGET_CPU_X86_64
    return @"";
#elif TARGET_CPU_ARM64
    return @"SOC MTR Temp Sensor0";
#endif
}
+(float)temperatureOfSensorWithName:(NSString*)name
{
#if TARGET_CPU_X86_64
    return 0;
#elif TARGET_CPU_ARM64
    return [(NSNumber*)AppleSiliconTemperatureDictionary()[name] floatValue];
#endif
}
@end



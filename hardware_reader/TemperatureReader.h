//
//  TemperatureReader.h
//  MenuMeters
//
//  Created by Yuji on 1/31/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TemperatureReader : NSObject

+ (NSArray *)sensorNames;

+ (NSString *)defaultSensor;

+ (NSString *)displayNameForSensor:(NSString *)name;

+ (float)temperatureOfSensorWithName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END

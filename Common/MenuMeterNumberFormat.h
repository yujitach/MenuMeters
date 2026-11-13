//
//	MenuMeterNumberFormat.h
//
//	Locale-aware number formatting shared by the meters
//
// 	This file is part of MenuMeters.
//
// 	MenuMeters is free software; you can redistribute it and/or modify
// 	it under the terms of the GNU General Public License version 2 as
//  published by the Free Software Foundation.
//

#import <Foundation/Foundation.h>

// Decimal place modes (matches popup order in the pref pane)
enum {
	kMenuMeterDecimalsAdaptive		= 0,
	kMenuMeterDecimalsZero,
	kMenuMeterDecimalsOne,
	kMenuMeterDecimalsTwo
};

@interface MenuMeterNumberFormat : NSObject

// Values >= 1000 never get decimals; adaptive: >= 100 none, >= 10 one, else two
+ (NSUInteger)decimalsForValue:(double)value mode:(int)mode;

// "<value> <unit>" using the user's locale
+ (NSString *)stringForValue:(double)value decimals:(NSUInteger)decimals unit:(NSString *)unit;
+ (NSString *)stringForValue:(double)value mode:(int)mode unit:(NSString *)unit;

// Scales value down by base until it fits the largest suitable unit, then formats it
+ (NSString *)scaledStringForValue:(double)value base:(double)base units:(NSArray *)units mode:(int)mode;

@end

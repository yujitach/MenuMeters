//
//	MenuMeterNumberFormat.m
//
//	Locale-aware number formatting shared by the meters
//
// 	This file is part of MenuMeters.
//
// 	MenuMeters is free software; you can redistribute it and/or modify
// 	it under the terms of the GNU General Public License version 2 as
//  published by the Free Software Foundation.
//

#import "MenuMeterNumberFormat.h"

@implementation MenuMeterNumberFormat

+ (NSNumberFormatter *)formatter {

	static NSNumberFormatter *formatter = nil;
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		formatter = [[NSNumberFormatter alloc] init];
		[formatter setNumberStyle:NSNumberFormatterDecimalStyle];
		[formatter setLocale:[NSLocale autoupdatingCurrentLocale]];
		[formatter setUsesGroupingSeparator:YES];
		[formatter setRoundingMode:NSNumberFormatterRoundHalfUp];
	});
	return formatter;

} // formatter

+ (NSUInteger)decimalsForValue:(double)value mode:(int)mode {

	if (value >= 1000) return 0;
	switch (mode) {
		case kMenuMeterDecimalsZero:
			return 0;
		case kMenuMeterDecimalsTwo:
			return 2;
		case kMenuMeterDecimalsAdaptive:
			return (value >= 100) ? 0 : ((value >= 10) ? 1 : 2);
		default:
			return 1;
	}

} // decimalsForValue:mode:

+ (NSString *)stringForValue:(double)value decimals:(NSUInteger)decimals unit:(NSString *)unit {

	NSNumberFormatter *formatter = [self formatter];
	@synchronized (formatter) {
		[formatter setMinimumFractionDigits:decimals];
		[formatter setMaximumFractionDigits:decimals];
		return [NSString stringWithFormat:@"%@ %@",
				[formatter stringFromNumber:[NSNumber numberWithDouble:value]], unit];
	}

} // stringForValue:decimals:unit:

+ (NSString *)stringForValue:(double)value mode:(int)mode unit:(NSString *)unit {

	return [self stringForValue:value decimals:[self decimalsForValue:value mode:mode] unit:unit];

} // stringForValue:mode:unit:

+ (NSString *)scaledStringForValue:(double)value base:(double)base units:(NSArray *)units mode:(int)mode {

	NSUInteger unitIndex = 0;
	while ((value >= base) && (unitIndex + 1 < [units count])) {
		value /= base;
		unitIndex++;
	}
	return [self stringForValue:value mode:mode unit:[units objectAtIndex:unitIndex]];

} // scaledStringForValue:base:units:mode:

@end

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
#import <math.h>

const NSUInteger kMenuMeterDecimalBase = 1000;
const NSUInteger kMenuMeterBinaryBase = 1024;

static const double kAdaptiveIntegerThreshold = 100.0;
static const double kAdaptiveSingleDecimalThreshold = 10.0;
static const double kTwoDecimalWidthProbeOffset = 0.01;
static const double kSingleDigitWidthProbeOffset = 0.001;

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

	if (value >= kMenuMeterDecimalBase) return 0;
	switch (mode) {
		case kMenuMeterDecimalsZero:
			return 0;
		case kMenuMeterDecimalsTwo:
			return 2;
		case kMenuMeterDecimalsAdaptive:
			return (value >= kAdaptiveIntegerThreshold) ? 0 : ((value >= kAdaptiveSingleDecimalThreshold) ? 1 : 2);
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

+ (NSString *)scaledStringForValue:(double)value base:(double)base units:(NSArray<NSString *> *)units mode:(int)mode {

	if (!isfinite(value) || value < 0 || !isfinite(base) || base <= 1 || ![units count]) {
		[NSException raise:NSInvalidArgumentException
					format:@"Number scaling requires a finite nonnegative value, a finite base > 1, and at least one unit."];
	}
	NSArray<NSString *> *unitLabels = [units copy];
	for (id unit in unitLabels) {
		if (![unit isKindOfClass:[NSString class]] || ![unit length]) {
			[NSException raise:NSInvalidArgumentException format:@"Number scaling requires nonempty string units."];
		}
	}
	NSEnumerator<NSString *> *unitEnumerator = [unitLabels objectEnumerator];
	NSString *unit = [unitEnumerator nextObject];
	NSString *nextUnit = nil;
	while ((value >= base) && (nextUnit = [unitEnumerator nextObject])) {
		value /= base;
		unit = nextUnit;
	}
	return [self stringForValue:value mode:mode unit:unit];

} // scaledStringForValue:base:units:mode:

+ (NSArray<NSNumber *> *)displayWidthSamplesForBase:(double)base {
	if (!isfinite(base) || base <= 1) {
		[NSException raise:NSInvalidArgumentException format:@"Display width sampling requires a finite base > 1."];
	}
	return @[@(base - kTwoDecimalWidthProbeOffset),
			 @(kMenuMeterDecimalBase - kTwoDecimalWidthProbeOffset),
			 @(kAdaptiveIntegerThreshold - kTwoDecimalWidthProbeOffset),
			 @(kAdaptiveSingleDecimalThreshold - kSingleDigitWidthProbeOffset)];
}

@end

//
//  MenuMeterUptime.m
//
// 	Reader object for uptime
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

#import "MenuMeterUptime.h"
#import <sys/types.h>
#import <sys/sysctl.h>


///////////////////////////////////////////////////////////////
//
//	Localized strings
//
///////////////////////////////////////////////////////////////

#define kUptimeUnavailable			@"Unavailable"
#define kUptimeZeroDayFormat		@"%02ld:%02ld:%02ld"
#define kUptimeOneDayFormat			@"%ld day %02ld:%02ld:%02ld"
#define kUptimeMultiDayFormat		@"%ld days %02ld:%02ld:%02ld"


///////////////////////////////////////////////////////////////
//
//	init/dealloc
//
///////////////////////////////////////////////////////////////

@implementation MenuMeterUptime

- (id)init {

	// Allow super to init
	self = [super init];
	if (!self) {
		return nil;
	}

	// Set up localized strings
	NSBundle *selfBundle = [NSBundle bundleForClass:[self class]];
	if (!selfBundle) {
		[self release];
		return nil;
	}
	localizedStrings = [[NSDictionary dictionaryWithObjectsAndKeys:
							[selfBundle localizedStringForKey:kUptimeUnavailable value:nil table:nil],
							kUptimeUnavailable,
							[selfBundle localizedStringForKey:kUptimeMultiDayFormat value:nil table:nil],
							kUptimeMultiDayFormat,
							[selfBundle localizedStringForKey:kUptimeOneDayFormat value:nil table:nil],
							kUptimeOneDayFormat,
							[selfBundle localizedStringForKey:kUptimeZeroDayFormat value:nil table:nil],
							kUptimeZeroDayFormat,
							nil
						] retain];
	if (!localizedStrings) {
		[self release];
		return nil;
	}

	// Send on back
	return self;

} // init

- (void)dealloc {

	[localizedStrings release];
	[super dealloc];

} // dealloc

///////////////////////////////////////////////////////////////
//
//	Uptime info
//
///////////////////////////////////////////////////////////////

- (NSString *)uptime {

	// Current time
	time_t now = time(NULL);

	// Boot time
	struct timeval bootTime;
	int mib[2] = { CTL_KERN, KERN_BOOTTIME };
	size_t bootTimeSize = sizeof(bootTime);
	if (sysctl(mib, 2, &bootTime, &bootTimeSize, NULL, 0)) {
		return [localizedStrings objectForKey:kUptimeZeroDayFormat];
	}

	// Calculate the uptime
	time_t uptime = now - bootTime.tv_sec;

	// Get our pretty string
	time_t days = uptime / (24 * 60 * 60);
	uptime %= (24 * 60 * 60);
	time_t hours = uptime / (60 * 60);
	uptime %= (60 * 60);
	time_t minutes = uptime / 60;
	uptime %= 60;
	time_t seconds = uptime;
	NSString *uptimeDesc = nil;
	if (days > 1) {
		uptimeDesc = [NSString stringWithFormat:[localizedStrings objectForKey:kUptimeMultiDayFormat],
						days, hours, minutes, seconds];
	} else if (days == 1) {
		uptimeDesc = [NSString stringWithFormat:[localizedStrings objectForKey:kUptimeOneDayFormat],
						days, hours, minutes, seconds];
	} else {
		uptimeDesc = [NSString stringWithFormat:[localizedStrings objectForKey:kUptimeZeroDayFormat],
						hours, minutes, seconds];
	}

	// Send the string back
	return uptimeDesc;

} // uptime

@end

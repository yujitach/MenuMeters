//
//  MenuMeterPowerMate.h
//
//	PowerMate support, based on sample code from Griffin
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

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#import <IOKit/usb/IOUSBLib.h>
#import <IOKit/IOCFPlugIn.h>

@interface MenuMeterPowerMate : NSObject {

	// IOKit connection
	mach_port_t					masterPort;
	IONotificationPortRef		notifyPort;
	CFRunLoopSourceRef			notifyRunSource;
	io_iterator_t				deviceMatchedIterator,
								deviceTerminatedIterator;
	// Connected PowerMate state
	BOOL						devicePresent;
	IOUSBDeviceInterface		**deviceInterface;
	// Glow ramping
	double						lastGlowLevel,
								targetGlowLevel,
								rampGlowStep;
	NSTimer						*rampTimer;

} // MenuMeterPowerMate

+ (BOOL)powermateAttached;
- (void)setGlow:(double)level;
- (void)setGlow:(double)level rampInterval:(NSTimeInterval)interval;
- (void)setPulse:(double)rate;
- (void)stopPulse;

@end

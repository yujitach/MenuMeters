//
//  MenuMeterMemView.m
//
//	NSView for the menu extra
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

#import "MenuMeterMemView.h"

@implementation MenuMeterMemView

///////////////////////////////////////////////////////////////
//
//	init/dealloc
//
///////////////////////////////////////////////////////////////

- initWithFrame:(NSRect)rect menuExtra:extra {

	// Use NSView initializer, not our undoc superclass
	self = [super initWithFrame:rect];
	if (!self) {
		return nil;
	}
	memMenuExtra = extra;
    return self;

} // initWithFrame

- (void)dealloc {

    [super dealloc];

} // dealloc


///////////////////////////////////////////////////////////////
//
//	View commands
//
///////////////////////////////////////////////////////////////

- (void)drawRect:(NSRect)rect {

	// Following our superclass API, get an image from the extra and draw it
	// on the extra's behalf.
	NSImage *image = [memMenuExtra image];
    if (image) {
		// Live updating even when menu is down handled by making the extra
		// draw the background if needed.
		if ([memMenuExtra isMenuDown] || 
			([memMenuExtra respondsToSelector:@selector(isMenuDownForAX)] && [memMenuExtra isMenuDownForAX])) {
			[memMenuExtra drawMenuBackground:YES];
		}
		// Mem extra image is is height - 1 to skip edge of menubar
		[image compositeToPoint:NSMakePoint(0, 1) operation:NSCompositeSourceOver];
	}

} // drawRect

@end

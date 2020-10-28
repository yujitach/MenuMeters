//
//  MenuMeterWorkarounds.h
//
//	Various workarounds for old OS bugs that may not be applicable
//  (or compilable) on newer OS versions. To prevent conflicts
//  everything here is __private_extern__.
//
//	Copyright (c) 2009-2014 Alex Harper
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

// OS version info
__private_extern__ BOOL OSIsJaguarOrLater(void);
__private_extern__ BOOL OSIsPantherOrLater(void);
__private_extern__ BOOL OSIsTigerOrLater(void);
__private_extern__ BOOL OSIsLeopardOrLater(void);
__private_extern__ BOOL OSIsSnowLeopardOrLater(void);
__private_extern__ BOOL OSIsMavericksOrLater(void);

// Menu live updating (CFIndex is right-sized everywhere)
__private_extern__ void LiveUpdateMenuItemTitleAndVisibility(NSMenu *, CFIndex, NSString *, BOOL);
__private_extern__ void LiveUpdateMenuItemTitle(NSMenu *, CFIndex, NSString *);
__private_extern__ void LiveUpdateMenu(NSMenu *);


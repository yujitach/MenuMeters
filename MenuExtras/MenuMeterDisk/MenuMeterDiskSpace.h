//
//  MenuMeterDiskSpace.h
//
// 	Reader object for disk space statistics
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
#import <sys/param.h>
#import <sys/mount.h>
#import <sys/stat.h>
#import <string.h>


@interface MenuMeterDiskSpace : NSObject {

	// Cache for the localized strings
	NSDictionary		*localizedStrings;
	// NSFormatter for disk space localization
	NSNumberFormatter	*spaceFormatter;
	BOOL				useBaseTen;

} // MenuMeterDiskSpace

// Disk space info
- (NSMutableArray *)diskSpaceData;
- (void)setBaseTen:(BOOL)baseTen;

@end

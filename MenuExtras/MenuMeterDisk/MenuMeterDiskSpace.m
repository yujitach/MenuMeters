//
//  MenuMeterDiskSpace.m
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

#import "MenuMeterDiskSpace.h"
#import "MenuMeterNumberFormat.h"


///////////////////////////////////////////////////////////////
//
//	Private methods and functions
//
///////////////////////////////////////////////////////////////

@interface MenuMeterDiskSpace (PrivateMethods)
- (NSString *)spaceString:(double)space;
@end


static NSComparisonResult SortDiskEntryByDeviceString(NSDictionary *a, NSDictionary *b, void *context) {

	return [(NSString *)[a objectForKey:@"device"] compare:[b objectForKey:@"device"]];

} // SortDiskEntryByDeviceString


///////////////////////////////////////////////////////////////
//
//	Localized strings
//
///////////////////////////////////////////////////////////////

#define	kUsedSpaceFormat		@"%@ Used"
#define	kFreeSpaceFormat		@"%@ Free"
#define	kTotalSpaceFormat		@"%@ Total"
#define kKBLabel				@"KB"
#define kMBLabel				@"MB"
#define kGBLabel				@"GB"


@implementation MenuMeterDiskSpace

///////////////////////////////////////////////////////////////
//
//	Disk space info
//
///////////////////////////////////////////////////////////////

- (NSMutableArray *)diskSpaceData {

	// Grab the current mount list. Early versions used NSWorkspace but the
	// results were remarkably inaccurate. Bugs that may have been subsequently
	// fixed in new OS versions, but this code works (and we want to remain as
	// backwards compatible as possible)
	// Really this whole thing should be rewritten using DiskArbitration, but
	// that would force too new an OS version.
	struct statfs *mountInfo;
	int mountCount = getmntinfo(&mountInfo, MNT_WAIT);

	// Loop the local mounts
	NSMutableArray *diskSpaceDetails = [NSMutableArray array];
	for (int i = 0; i < mountCount; i++) {
		// We only view local volumes, which isn't easy (are FUSE volumes local?)
		// Just look at filesystem type.
		if(!strcmp(mountInfo[i].f_fstypename, "hfs") ||
                   !strcmp(mountInfo[i].f_fstypename, "apfs") ||
			!strcmp(mountInfo[i].f_fstypename, "ufs") ||
			!strcmp(mountInfo[i].f_fstypename, "msdos") ||
			!strcmp(mountInfo[i].f_fstypename, "exfat") ||
			!strcmp(mountInfo[i].f_fstypename, "ntfs") ||
			!strcmp(mountInfo[i].f_fstypename, "cd9660") ||
			!strcmp(mountInfo[i].f_fstypename, "cddafs") ||
			!strcmp(mountInfo[i].f_fstypename, "udf")) {

			// Build the dictionary, start with 6 items (name, path, icon, free, used, total)
			NSMutableDictionary *diskStats = [NSMutableDictionary dictionary];

			// Build a NSString from the path
			NSString *mountPath = [[NSFileManager defaultManager]
									stringWithFileSystemRepresentation:mountInfo[i].f_mntonname
									length:strlen(mountInfo[i].f_mntonname)];

			// NSFileManger used to report stale volume names and many other
			// bugs. Again, probably fixed in new OS versions, but stick with
			// what works. Filesystem Carbon calls are available in x86_64,
			// so we're fine with this.
			FSRef pathRef;
			OSStatus err = FSPathMakeRef((UInt8 *)[mountPath fileSystemRepresentation], &pathRef, NULL);
			if (err != noErr) {
				continue;
			}
			// Get catalog info
			FSCatalogInfo catInfo;
			err = FSGetCatalogInfo(&pathRef, kFSCatInfoVolume, &catInfo, NULL, NULL, NULL);
			if (err != noErr) {
				continue;
			}
			// Get volume info
			FSVolumeInfo volInfo;
			HFSUniStr255 volumeName;
			err = FSGetVolumeInfo(catInfo.volume, 0, NULL, kFSVolInfoNone, &volInfo, &volumeName, NULL);
			if (err != noErr) {
				continue;
			}

			// Store the name and path from the workspace
			[diskStats setObject:[NSString stringWithCharacters:volumeName.unicode length:volumeName.length]
						  forKey:@"name"];
			[diskStats setObject:mountPath forKey:@"path"];

			// Store the icon
			NSImage *volIcon = [[NSWorkspace sharedWorkspace] iconForFile:mountPath];
			if (volIcon) {
				[diskStats setObject:volIcon forKey:@"icon"];
			}

			// Other random details (these strings aren't UTF-8 but that's still
			// the safest choice).
			[diskStats setObject:[NSString stringWithUTF8String:mountInfo[i].f_fstypename]
						  forKey:@"fstype"];
			[diskStats setObject:[NSString stringWithUTF8String:mountInfo[i].f_mntfromname]
						  forKey:@"device"];

			// Store
			[diskStats setObject:[NSString stringWithFormat:[localizedStrings objectForKey:kTotalSpaceFormat],
									[self spaceString:((double)mountInfo[i].f_blocks * (double)mountInfo[i].f_bsize)]]
						  forKey:@"total"];
			[diskStats setObject:[NSString stringWithFormat:[localizedStrings objectForKey:kFreeSpaceFormat],
									[self spaceString:((double)mountInfo[i].f_bavail * (double)mountInfo[i].f_bsize)]]
						  forKey:@"free"];
			[diskStats setObject:[NSString stringWithFormat:[localizedStrings objectForKey:kUsedSpaceFormat],
									[self spaceString:(((double)mountInfo[i].f_blocks -
														(double)mountInfo[i].f_bavail) * (double)mountInfo[i].f_bsize)]]
						  forKey:@"used"];
			// Store the data into the array
			[diskSpaceDetails addObject:diskStats];

 		} // end of filesystem type check
	} // end of mount loop

	// Sort by device, this matches most users expectations best
	[diskSpaceDetails sortUsingFunction:&SortDiskEntryByDeviceString context:NULL];

	// Send the array of dicts on back
	return diskSpaceDetails;

} // diskSpaceData

- (void)setBaseTen:(BOOL)baseTen {

	useBaseTen = baseTen;

} // setBaseTen

///////////////////////////////////////////////////////////////
//
//	Utility
//
///////////////////////////////////////////////////////////////

- (NSString *)spaceString:(double)space {

	double base = useBaseTen ? 1000.0 : 1024.0;
	NSArray *units = @[[localizedStrings objectForKey:kKBLabel],
					   [localizedStrings objectForKey:kMBLabel],
					   [localizedStrings objectForKey:kGBLabel]];
	return [MenuMeterNumberFormat scaledStringForValue:space / base
												base:base
											   units:units
												mode:kMenuMeterDecimalsAdaptive];

} // spaceString

@end

//
//	Installer.h
//
//	Installer defines
//
//	Copyright (c) 2003-2014 Alex Harper
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

// Logging (here so I can cut and paste code between this and my other
// project installers)
#import <Foundation/NSDebug.h>
#define LOG(args...)			NSLog(args)
#define LOGERROR(args...)		NSLog(args)
#define LOGDEBUG(args...)		if (NSDebugEnabled) { NSLog(args); }

// OS version
#define kSupportedOS			0x1020

// Installation paths
#define kLibraryPrefPanePath	@"/Library/PreferencePanes"
#define kUserPrefPanePath		[@"~/Library/PreferencePanes/" stringByExpandingTildeInPath]

// Installation items
#define kPrefPaneName			@"MenuMeters.prefPane"

// Cache files
#define kSystemPrefCacheFile	[@"~/Library/Caches/com.apple.preferencepanes.cache" stringByExpandingTildeInPath]

// Installation type
enum {
	kNotInstalled				= 0,
	kLibraryInstall,
	kUserInstall
};

// Installer tool return codes
enum {
	kInstallToolSuccess			= 0,
	kInstallToolFail
};

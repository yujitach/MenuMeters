//
//	MenuMeters.h
//
//	Shared defines for the entire project
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

///////////////////////////////////////////////////////////////
//
//	Bundle information
//
///////////////////////////////////////////////////////////////

// Bundle directory name of the preferences bundle
#define kPrefBundleName					@"MenuMeterDefaults.bundle"

// Bundle ID for the CPU menu extra
#define kCPUMenuBundleID				@"com.ragingmenace.MenuMeterCPU"

// Bundle ID for the Disk menu extra
#define kDiskMenuBundleID				@"com.ragingmenace.MenuMeterDisk"

// Bundle ID for the Memory menu extra
#define kMemMenuBundleID				@"com.ragingmenace.MenuMeterMem"

// Bundle ID for the Net menu extra
#define kNetMenuBundleID				@"com.ragingmenace.MenuMeterNet"

// Bundle information for the pref pane
#define kPrefPaneBundleID				@"com.ragingmenace.MenuMeters"

///////////////////////////////////////////////////////////////
//
//	Preference information
//
///////////////////////////////////////////////////////////////

// Since all our bundles share a single pref file we don't use the default
// suite (which would be based on our bundle) and instead we load a different
// domain
#define kMenuMeterDefaultsDomain		@"com.ragingmenace.MenuMeters"

// Old name we no longer use
#define kMenuMeterObsoleteDomain		@"MenuMeters"

// Pref versioning
#define	kPrefVersionKey					@"MenuMeterPrefVersion"
#define	kCurrentPrefVersion				8

///////////////////////////////////////////////////////////////
//
//	Notifications
//
///////////////////////////////////////////////////////////////

// Preferences were changed
#define kPrefChangeNotification			@"prefChange"

// Extras unload
#define kCPUMenuUnloadNotification		@"cpuMenuUnload"
#define kDiskMenuUnloadNotification		@"diskMenuUnload"
#define kMemMenuUnloadNotification		@"memMenuUnload"
#define kNetMenuUnloadNotification		@"netMenuUnload"

///////////////////////////////////////////////////////////////
//
//	String formats
//
///////////////////////////////////////////////////////////////

#define kMenuIndentFormat				@"    %@"
#define kMenuDoubleIndentFormat			@"        %@"
#define kMenuTripleIndentFormat			@"            %@"



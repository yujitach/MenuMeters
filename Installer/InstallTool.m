//
//  InstallTool.m
//
//	Foundation tool that handles installation, not elegant, but it works
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

#import <Foundation/Foundation.h>
#import <sys/param.h>
#import <mach-o/dyld.h>
#import <unistd.h>
#import "Installer.h"

///////////////////////////////////////////////////////////////
//
//	Globals
//
///////////////////////////////////////////////////////////////

NSFileManager		*fileMan = nil;
NSString			*toolPath = nil;

///////////////////////////////////////////////////////////////
//
//	Install actions
//
///////////////////////////////////////////////////////////////

BOOL uninstallLibraryPrefPane(void) {

	// Main library
	if ([fileMan fileExistsAtPath:[kLibraryPrefPanePath stringByAppendingPathComponent:kPrefPaneName]]) {
		LOGDEBUG(@"InstallTool: PrefPane uninstall found target file in main Library.");
		if ([fileMan removeFileAtPath:[kLibraryPrefPanePath stringByAppendingPathComponent:kPrefPaneName] handler:nil]) {
			LOGDEBUG(@"InstallTool: PrefPane uninstalled from main Library.");
			return YES;
		} else {
			LOGERROR(@"InstallTool error: PrefPane uninstall from main Library failed.");
			return NO;
		}
	} else {
		LOGDEBUG(@"InstallTool: PrefPane uninstall did not find target file in main Library.");
		return YES;
	}

} // uninstallLibraryPrefPane

BOOL uninstallUserPrefPane(void) {

	// User library
	if ([fileMan fileExistsAtPath:[kUserPrefPanePath stringByAppendingPathComponent:kPrefPaneName]]) {
		LOGDEBUG(@"InstallTool: PrefPane uninstall found target file in user's Library.");
		if ([fileMan removeFileAtPath:[kUserPrefPanePath stringByAppendingPathComponent:kPrefPaneName] handler:nil]) {
			LOGDEBUG(@"InstallTool: PrefPane uninstalled from user's Library.");
			return YES;
		} else {
			LOGERROR(@"InstallTool error: PrefPane uninstall from user's Library failed.");
			return NO;
		}
	} else {
		LOGDEBUG(@"InstallTool: PrefPane uninstall did not find target file in user's Library.");
		return YES;
	}

} // uninstallPrefPane

BOOL installLibraryPrefPane(void) {

	// Can we find our pieces?
	if (![fileMan fileExistsAtPath:[toolPath stringByAppendingPathComponent:kPrefPaneName]]) {
		LOGERROR(@"InstallTool error: PrefPane install could not find source file \"%@\".",
				 [toolPath stringByAppendingPathComponent:kPrefPaneName]);
		return NO;
	}

	// Uninstall any current version
	if ([fileMan fileExistsAtPath:[kLibraryPrefPanePath stringByAppendingPathComponent:kPrefPaneName]]) {
		LOGDEBUG(@"InstallTool: PrefPane install found prior Library install.");
		if (!uninstallLibraryPrefPane()) {
			LOGERROR(@"InstallTool error: PrefPane install had failure uninstalling prior Library PrefPane.");
			return NO;
		}
	}

	// Create the target dir if needed
	if (![fileMan fileExistsAtPath:kLibraryPrefPanePath]) {
		LOGDEBUG(@"InstallTool: PrefPane install must create \"%@\".", kLibraryPrefPanePath);
		if (![fileMan createDirectoryAtPath:kLibraryPrefPanePath
								 attributes:[NSDictionary dictionaryWithObjectsAndKeys:
												@"root",
												NSFileOwnerAccountName,
												@"admin",
												NSFileGroupOwnerAccountName,
												[NSNumber numberWithUnsignedInt:0777],
												NSFilePosixPermissions,
												nil]]) {
			LOGERROR(@"InstallTool error: PrefPane install unable to create \"%@\".", kLibraryPrefPanePath);
			return NO;
		}
	}
	if(![fileMan copyPath:[toolPath stringByAppendingPathComponent:kPrefPaneName]
				   toPath:[kLibraryPrefPanePath stringByAppendingPathComponent:kPrefPaneName] handler:nil]) {
		LOGERROR(@"InstallTool error: Library PrefPane installation failed.");
		return NO;
	}
	if (![fileMan changeFileAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
											@"root",
											NSFileOwnerAccountName,
											@"admin",
											NSFileGroupOwnerAccountName,
											[NSNumber numberWithUnsignedInt:0775],
											NSFilePosixPermissions,
											nil]
								atPath:[kLibraryPrefPanePath stringByAppendingPathComponent:kPrefPaneName]]) {
		LOGERROR(@"InstallTool error: Library PrefPane top level attribute change failed.");
		return NO;
	}
	NSDirectoryEnumerator *dirEnum = [fileMan enumeratorAtPath:[kLibraryPrefPanePath stringByAppendingPathComponent:kPrefPaneName]];
	if (!dirEnum) {
		LOGERROR(@"InstallTool error: Library PrefPane enumerator failed.");
		return NO;
	}
	NSString *subPath = nil;
	while ((subPath = [dirEnum nextObject])) {
		if (![fileMan changeFileAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
												@"root",
												NSFileOwnerAccountName,
												@"admin",
												NSFileGroupOwnerAccountName,
												[NSNumber numberWithUnsignedInt:0775],
												NSFilePosixPermissions,
												nil]
									atPath:[[kLibraryPrefPanePath stringByAppendingPathComponent:kPrefPaneName]
												stringByAppendingPathComponent:subPath]]) {
			LOGERROR(@"InstallTool error: Library PrefPane attribute change failed for subitem \"%@\".", subPath);
			return NO;
		}
	}

	LOGDEBUG(@"InstallTool: Library PrefPane installed.");
	return YES;

} // installLibraryPrefPane

BOOL installUserPrefPane(void) {

	// Can we find our pieces?
	if (![fileMan fileExistsAtPath:[toolPath stringByAppendingPathComponent:kPrefPaneName]]) {
		LOGERROR(@"InstallTool error: PrefPane install could not find source file \"%@\".",
				 [toolPath stringByAppendingPathComponent:kPrefPaneName]);
		return NO;
	}

	// Uninstall any current version
	if ([fileMan fileExistsAtPath:[kUserPrefPanePath stringByAppendingPathComponent:kPrefPaneName]]) {
		LOGDEBUG(@"InstallTool: PrefPane install found prior user install.");
		if (!uninstallUserPrefPane()) {
			LOGERROR(@"InstallTool error: PrefPane install had failure uninstalling prior user PrefPane.");
			return NO;
		}
	}

	// Create the target dir if needed
	if (![fileMan fileExistsAtPath:kUserPrefPanePath]) {
		LOGDEBUG(@"InstallTool: PrefPane install must create \"%@\".", kUserPrefPanePath);
		if (![fileMan createDirectoryAtPath:kUserPrefPanePath
								 attributes:[NSDictionary dictionaryWithObjectsAndKeys:
												[NSNumber numberWithUnsignedInt:0755],
												NSFilePosixPermissions,
												nil]]) {
			LOGERROR(@"InstallTool error: PrefPane install unable to create \"%@\".", kUserPrefPanePath);
			return NO;
		}
	}
	if(![fileMan copyPath:[toolPath stringByAppendingPathComponent:kPrefPaneName]
				   toPath:[kUserPrefPanePath stringByAppendingPathComponent:kPrefPaneName] handler:nil]) {
		LOGERROR(@"InstallTool error: user PrefPane installation failed.");
		return NO;
	}
	if (![fileMan changeFileAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
											[NSNumber numberWithUnsignedInt:0755],
											NSFilePosixPermissions,
											nil]
								atPath:[kUserPrefPanePath stringByAppendingPathComponent:kPrefPaneName]]) {
		LOGERROR(@"InstallTool error: user PrefPane top level attribute change failed.");
		return NO;
	}
	NSDirectoryEnumerator *dirEnum = [fileMan enumeratorAtPath:[kUserPrefPanePath stringByAppendingPathComponent:kPrefPaneName]];
	if (!dirEnum) {
		LOGERROR(@"InstallTool error: user PrefPane enumerator failed.");
		return NO;
	}
	NSString *subPath = nil;
	while ((subPath = [dirEnum nextObject])) {
		if (![fileMan changeFileAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
												[NSNumber numberWithUnsignedInt:0755],
												NSFilePosixPermissions,
												nil]
									atPath:[[kUserPrefPanePath stringByAppendingPathComponent:kPrefPaneName]
												stringByAppendingPathComponent:subPath]]) {
			LOGERROR(@"InstallTool error: user PrefPane attribute change failed for subitem \"%@\".", subPath);
			return NO;
		}
	}

	LOGDEBUG(@"InstallTool: user PrefPane installed.");
	return YES;

} // installUserPrefPane

///////////////////////////////////////////////////////////////
//
//	Return status
//
///////////////////////////////////////////////////////////////

void installSuccess(void) {

	int result = kInstallToolSuccess;
	fwrite(&result, sizeof(int), 1, stdout);
	fflush(stdout);

} // installSuccess

void installFailure(void) {

	int	result = kInstallToolFail;
	fwrite(&result, sizeof(int), 1, stdout);
	fflush(stdout);

} // installFailure

///////////////////////////////////////////////////////////////
//
//	Main
//
///////////////////////////////////////////////////////////////

int main (int argc, const char *argv[]) {

	// Keep a local pool
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	// Pathing
	char *path = NULL;
	uint32_t pathSize = MAXPATHLEN;
	if (!(path = malloc(pathSize))) {
		LOGERROR(@"InstallTool error: Cannot allocate a path buffer.");
		[pool release];
		installFailure();
		return kInstallToolFail;
	}
	if (_NSGetExecutablePath(path, &pathSize) == -1) {
		LOGERROR(@"InstallTool error: _NSGetExecutablePath failed.");
		free(path);
		[pool release];
		installFailure();
		return kInstallToolFail;
	}

	// File manager
	fileMan = [NSFileManager defaultManager];
	if (!fileMan) {
		LOGERROR(@"InstallTool error: No default file manager.");
		[pool release];
		installFailure();
		return kInstallToolFail;
	}

	// Store tool path
	toolPath = [[[fileMan stringWithFileSystemRepresentation:path length:strlen(path)]
					stringByStandardizingPath] stringByDeletingLastPathComponent];
	free(path);
	if (!toolPath) {
		LOGERROR(@"InstallTool error: Cannot find our path.");
		[pool release];
		installFailure();
		return kInstallToolFail;
	} else {
		LOGDEBUG(@"InstallTool: Path \"%@\".", toolPath);
	}

	// Args
	if (argc != 2) {
		LOGERROR(@"InstallTool error: Called with wrong number of arguments.");
		[pool release];
		installFailure();
		return kInstallToolFail;
	}

	// Do the install
	if (!strcmp(argv[1], "--installlibrary")) {
		if (installLibraryPrefPane()) {
			[pool release];
			installSuccess();
			return kInstallToolSuccess;
		} else {
			[pool release];
			installFailure();
			return kInstallToolFail;
		}
	} else if (!strcmp(argv[1], "--installuser")) {
		if (installUserPrefPane()) {
			[pool release];
			installSuccess();
			return kInstallToolSuccess;
		} else {
			[pool release];
			installFailure();
			return kInstallToolFail;
		}
	} else if (!strcmp(argv[1], "--uninstalllibrary")) {
		if (uninstallLibraryPrefPane()) {
			[pool release];
			installSuccess();
			return kInstallToolSuccess;
		} else {
			[pool release];
			installFailure();
			return kInstallToolFail;
		}
	} else if (!strcmp(argv[1], "--uninstalluser")) {
		if (uninstallUserPrefPane()) {
			[pool release];
			installSuccess();
			return kInstallToolSuccess;
		} else {
			[pool release];
			installFailure();
			return kInstallToolFail;
		}
	}
	else {
		LOGERROR(@"InstallTool error: Unknown command \"%s\".", argv[1]);
		[pool release];
		installFailure();
		return kInstallToolFail;
	}

	// Fall through, never get here
	[pool release];
	installFailure();
	return kInstallToolFail;

} // main

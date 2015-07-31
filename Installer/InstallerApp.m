//
//	InstallerApp.m
//
//	Installer application
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

#import "InstallerApp.h"

///////////////////////////////////////////////////////////////
//
//	Private methods and constants
//
///////////////////////////////////////////////////////////////

@interface InstallerApp (PrivateMethods)

// Button actions
- (void)doInstall:(id)sender;
- (void)doUninstall:(id)sender;
- (void)quitInstaller:(id)sender;

// Sheet
- (void)installSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

// Installation checks
- (BOOL)uninstallAvailable;
- (int)packageInstalled;

// Installation
- (BOOL)normalInstall:(NSString *)command;
- (BOOL)authenticatedInstall:(NSString *)command;
- (void)unloadMenuExtras;
- (void)killSysPrefsCache;

// Version info
- (NSString *)installVersion;

@end

// Tab items in installer
enum {
	kInstallTab						= 0,
	kUpdateTab
};


///////////////////////////////////////////////////////////////
//
//	Localized strings
//
///////////////////////////////////////////////////////////////

#define kUpdateTitle				@"Update"
#define kWindowTitleFormat			@"%@ Installation"
#define kUnsupportedOSErrorTitle 	@"Unsupported Mac OS X version"
#define kUnsupportedOSError		 	@"MenuMeters can only be installed on Mac OS X 10.2 or later."
#define kInstallSuccessTitle		@"Installation Successful"
#define kInstallSuccessMessage		@"MenuMeters was installed successfully. Open your System Preferences to start using MenuMeters."
#define kUpdateSuccessTitle			@"Update Successful"
#define kUpdateSuccessMessage		@"MenuMeters was updated successfully. You must logout and relogin to use the new version of MenuMeters."
#define kInstallFailureTitle		@"Installation Failure"
#define kInstallFailureMessage		@"MenuMeters could not be installed. Please see the Console log for errors."
#define kUninstallSuccessTitle		@"Uninstall Successful"
#define kUninstallSuccessMessage 	@"MenuMeters has been removed. You must logout to complete the uninstall."
#define kUninstallFailureTitle		@"Uninstall Error"
#define kUninstallFailureMessage	@"MenuMeters could not be removed. Please see the Console log for errors."


@implementation InstallerApp

///////////////////////////////////////////////////////////////
//
//	NSApp stuff
//
///////////////////////////////////////////////////////////////

- (void)awakeFromNib {

	// Update the window title
	if ([self installVersion]) {
		[installWindow setTitle:
			[NSString stringWithFormat:
				[[NSBundle mainBundle] localizedStringForKey:kWindowTitleFormat value:nil table:nil],
					[self installVersion]]];
	}

	// Hide the tabs. We do this programatically instead
	// of in Interface Builder to make the tabs more obvious to localizers
	[installOrUpdate setTabViewType:NSNoTabsBezelBorder];

	// Change control state on for installation status
	if (![self uninstallAvailable]) {
		[uninstallButton setEnabled:NO];
	}
	int installState = [self packageInstalled];
	if (installState) {
		// Not an install, its an update
		[installButton setTitle:[[NSBundle mainBundle] localizedStringForKey:kUpdateTitle value:nil table:nil]];
		// Switch to the update tab.
		[installOrUpdate selectTabViewItemAtIndex:kUpdateTab];
	} else {
		// New install, configure tab
		[installOrUpdate selectTabViewItemAtIndex:kInstallTab];
	}

	// Center our window
	[installWindow center];
	// Front
	[installWindow makeKeyAndOrderFront:self];

	// Check for unsupported OS
	if (!OSIsJaguarOrLater()) {
		NSBeginCriticalAlertSheet(
			// Title
			[[NSBundle mainBundle] localizedStringForKey:kUnsupportedOSErrorTitle value:nil table:nil],
			// Default button
			nil,
			// Alternate button
			nil,
			// Other button
			nil,
			// Window
			installWindow,
			// Delegate
			nil,
			// end elector
			nil,
			// dismiss selector
			nil,
			// context
			nil,
			// msg
			[[NSBundle mainBundle] localizedStringForKey:kUnsupportedOSError value:nil table:nil]);
		// Disable install
		[installButton setEnabled:NO];
	}

} // awakeFromNib

///////////////////////////////////////////////////////////////
//
//	Button actions
//
///////////////////////////////////////////////////////////////

- (void)doInstall:(id)sender {

	// Show the panel
	[NSApp beginSheet:installProgressPanel modalForWindow:installWindow
		modalDelegate:nil didEndSelector:nil contextInfo:nil];

	// Spin
	[installProgress startAnimation:self];

	// Install or update
	BOOL installSuccess = NO;
	int	isUpdate = [self packageInstalled];
	if (isUpdate != kNotInstalled) {
		if (isUpdate == kUserInstall) {
			installSuccess = [self normalInstall:@"--installuser"];
		} else if (isUpdate == kLibraryInstall) {
			installSuccess = [self authenticatedInstall:@"--installlibrary"];
		} else {
			LOGERROR(@"Installer error: Update location could not be determined.");
			installSuccess = NO;
		}
	} else {
		if ([installLocationCurrentUser intValue]) {
			installSuccess = [self normalInstall:@"--installuser"];
		} else if ([installLocationAllUser intValue]) {
			installSuccess = [self authenticatedInstall:@"--installlibrary"];
		} else {
			LOGERROR(@"Installer error: Install location radio button state not understood.");
			installSuccess = NO;
		}
	}
	[self killSysPrefsCache];

	// Bring our window back to front (after authentication dialog)
	[installWindow makeKeyAndOrderFront:self];

	// Stop spin
	[installProgress stopAnimation:self];

	// Stop sheet
	[NSApp endSheet:installProgressPanel];
	[installProgressPanel orderOut:self];

	// Prompt
	if (installSuccess && [self packageInstalled]) {
		if (isUpdate) {
			NSBeginAlertSheet(
				// Title
				[[NSBundle mainBundle] localizedStringForKey:kUpdateSuccessTitle value:nil table:nil],
				// Default button
				nil,
				// Alternate button
				nil,
				// Other button
				nil,
				// Window
				installWindow,
				// Delegate
				self,
				// end elector
				@selector(installSheetDidEnd:returnCode:contextInfo:),
				// dismiss selector
				nil,
				// context
				nil,
				// msg
				[[NSBundle mainBundle]
					localizedStringForKey:kUpdateSuccessMessage
					value:nil table:nil]);
		} else {
			NSBeginAlertSheet(
				// Title
				[[NSBundle mainBundle] localizedStringForKey:kInstallSuccessTitle value:nil table:nil],
				// Default button
				nil,
				// Alternate button
				nil,
				// Other button
				nil,
				// Window
				installWindow,
				// Delegate
				self,
				// end elector
				@selector(installSheetDidEnd:returnCode:contextInfo:),
				// dismiss selector
				nil,
				// context
				nil,
				// msg
				[[NSBundle mainBundle]
					localizedStringForKey:kInstallSuccessMessage
					value:nil table:nil]);
		}
	} else {
		NSBeginCriticalAlertSheet(
			// Title
			[[NSBundle mainBundle] localizedStringForKey:kInstallFailureTitle value:nil table:nil],
			// Default button
			nil,
			// Alternate button
			nil,
			// Other button
			nil,
			// Window
			installWindow,
			// Delegate
			self,
			// end elector
			@selector(installSheetDidEnd:returnCode:contextInfo:),
			// dismiss selector
			nil,
			// context
			nil,
			// msg
			[[NSBundle mainBundle]
				localizedStringForKey:kInstallFailureMessage
				value:nil table:nil]);
	}

} // doInstall

- (void)doUninstall:(id)sender {

	// Show the panel
	[NSApp beginSheet:installProgressPanel modalForWindow:installWindow
		modalDelegate:nil didEndSelector:nil contextInfo:nil];
	// Spin
	[installProgress startAnimation:self];

	// Uninstall
	int uninstallType = [self packageInstalled];
	BOOL uninstallSuccess = NO;
	[self unloadMenuExtras];
	if (uninstallType == kUserInstall) {
		uninstallSuccess = [self normalInstall:@"--uninstalluser"];
	} else if (uninstallType == kLibraryInstall) {
		uninstallSuccess = [self authenticatedInstall:@"--uninstalllibrary"];
	} else {
		LOGERROR(@"Installer error: Uninstall location could not be determined.");
		uninstallSuccess = NO;
	}
	[self killSysPrefsCache];

	// Bring back to front
	[installWindow makeKeyAndOrderFront:self];

	// Stop spin
	[installProgress stopAnimation:self];
	// Stop sheet
	[NSApp endSheet:installProgressPanel];
	[installProgressPanel orderOut:self];

	// Prompt
	if (uninstallSuccess && ![self packageInstalled]) {
		NSBeginAlertSheet(
			// Title
			[[NSBundle mainBundle] localizedStringForKey:kUninstallSuccessTitle value:nil table:nil],
			// Default button
			nil,
			// Alternate button
			nil,
			// Other button
			nil,
			// Window
			installWindow,
			// Delegate
			self,
			// end elector
			@selector(installSheetDidEnd:returnCode:contextInfo:),
			// dismiss selector
			nil,
			// context
			nil,
			// msg
			[[NSBundle mainBundle]
				localizedStringForKey:kUninstallSuccessMessage
				value:nil table:nil]);
	} else {
		NSBeginCriticalAlertSheet(
			// Title
			[[NSBundle mainBundle] localizedStringForKey:kUninstallFailureTitle value:nil table:nil],
			// Default button
			nil,
			// Alternate button
			nil,
			// Other button
			nil,
			// Window
			installWindow,
			// Delegate
			self,
			// end elector
			@selector(installSheetDidEnd:returnCode:contextInfo:),
			// dismiss selector
			nil,
			// context
			nil,
			// msg
			[[NSBundle mainBundle]
				localizedStringForKey:kUninstallFailureMessage
				value:nil table:nil]);
	}

} // doUninstall

- (void)quitInstaller:(id)sender {

	// Just quit
	[NSApp terminate:self];

} // quitInstaller

///////////////////////////////////////////////////////////////
//
//	Sheet
//
///////////////////////////////////////////////////////////////

- (void)installSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {

	// After install quit
	[NSApp terminate:self];

} // installSheetDidEnd

///////////////////////////////////////////////////////////////
//
//	Installation checks
//
///////////////////////////////////////////////////////////////

- (BOOL)uninstallAvailable {

	// For MenuMeters uninstall just implies installed
	return ([self packageInstalled] ? YES : NO);

} // uninstallAvailable

- (int)packageInstalled {

	if ([[NSFileManager defaultManager] fileExistsAtPath:[kLibraryPrefPanePath stringByAppendingPathComponent:kPrefPaneName]]) {
		return kLibraryInstall;
	}
	if ([[NSFileManager defaultManager] fileExistsAtPath:[kUserPrefPanePath stringByAppendingPathComponent:kPrefPaneName]]) {
		return kUserInstall;
	}
	return kNotInstalled;

} // packageInstalled

///////////////////////////////////////////////////////////////
//
//	Installation
//
///////////////////////////////////////////////////////////////

- (BOOL)normalInstall:(NSString *)command {

	// Make sure we can find our tool
	NSString *toolPath = [[NSBundle mainBundle] pathForResource:@"InstallTool" ofType:@""];
	if (!toolPath) {
		LOGERROR(@"Installer error: Unable to find the installation tool.");
		return NO;
	}

	// Run the tool
	NSTask *installTask = [[[NSTask alloc] init] autorelease];
	[installTask setLaunchPath:toolPath];
	[installTask setArguments:[NSArray arrayWithObjects:command, nil]];
	[installTask launch];
	[installTask waitUntilExit];
	if ([installTask terminationStatus] != kInstallToolSuccess) {
		return NO;
	} else {
		return YES;
	}

} // normalInstall

- (BOOL)authenticatedInstall:(NSString *)command {

	// Make sure we can find our tool
	NSString *toolPath = [[NSBundle mainBundle] pathForResource:@"InstallTool" ofType:@""];
	if (!toolPath) {
		LOGERROR(@"Installer error: Unable to find the installation tool.");
		return NO;
	}

	// Get authorization
    AuthorizationFlags authFlags = kAuthorizationFlagDefaults;
	AuthorizationRef auth = NULL;
	OSStatus err = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, authFlags, &auth);
	if (err != errAuthorizationSuccess) {
		LOGERROR(@"Installer error: Unable to create an AuthorizationRef.");
		return NO;
	}

	AuthorizationItem authItem = { kAuthorizationRightExecute, 0, NULL, 0 };
	AuthorizationRights	authRights = { 1, &authItem };
	authFlags = kAuthorizationFlagDefaults | kAuthorizationFlagInteractionAllowed |
	kAuthorizationFlagPreAuthorize | kAuthorizationFlagExtendRights;
	err = AuthorizationCopyRights(auth, &authRights, NULL, authFlags, NULL);
	if (err != errAuthorizationSuccess) {
		AuthorizationFree(auth, kAuthorizationFlagDefaults);
		LOGERROR(@"Installer error: Unable to obtain authorization rights.");
		return NO;
	}

	// Execute
	char *execArgs[2];
	execArgs[0] = (char *)[command UTF8String];
	execArgs[1] = NULL;  // Terminate array

	authFlags = kAuthorizationFlagDefaults;
	FILE *outputPipe = NULL;
	err = AuthorizationExecuteWithPrivileges(auth, [toolPath fileSystemRepresentation], authFlags, execArgs, &outputPipe);
	if (err != errAuthorizationSuccess) {
		AuthorizationFree(auth, kAuthorizationFlagDefaults);
		LOGERROR(@"Installer error: Unable to execute installer tool. Error: %d", err);
		return NO;
	}
	// This blocks till the tool returns status
	int	terminationStatus = 0;
	fread(&terminationStatus, sizeof(terminationStatus), 1, outputPipe);

	// Release authorization
	AuthorizationFree(auth, kAuthorizationFlagDefaults);

	if (terminationStatus != kInstallToolSuccess) {
		return NO;
	} else {
		return YES;
	}

} // authenticatedInstall

- (void)unloadMenuExtras {

	// Kill loaded extras
	void *anExtra = NULL;
	if ((CoreMenuExtraGetMenuExtra((CFStringRef)kCPUMenuBundleID, &anExtra) == 0) && anExtra) {
		CoreMenuExtraRemoveMenuExtra(anExtra, 0);
	}
	if ((CoreMenuExtraGetMenuExtra((CFStringRef)kDiskMenuBundleID, &anExtra) == 0) && anExtra) {
		CoreMenuExtraRemoveMenuExtra(anExtra, 0);
	}
	if ((CoreMenuExtraGetMenuExtra((CFStringRef)kMemMenuBundleID, &anExtra) == 0) && anExtra) {
		CoreMenuExtraRemoveMenuExtra(anExtra, 0);
	}
	if ((CoreMenuExtraGetMenuExtra((CFStringRef)kNetMenuBundleID, &anExtra) == 0) && anExtra) {
		CoreMenuExtraRemoveMenuExtra(anExtra, 0);
	}

} // unloadMenuExtras

- (void)killSysPrefsCache {

	if ([[NSFileManager defaultManager] fileExistsAtPath:kSystemPrefCacheFile]) {
		if (![[NSFileManager defaultManager] removeFileAtPath:kSystemPrefCacheFile handler:nil]) {
			LOGERROR(@"Installer error: Unable to remove system preferences cache file.");
		}
	}

} // killSysPrefsCache

///////////////////////////////////////////////////////////////
//
//	Version info
//
///////////////////////////////////////////////////////////////

- (NSString *)installVersion {

	return [[[NSBundle bundleWithPath: [[NSBundle mainBundle] pathForResource:kPrefPaneName ofType:@""]]
				infoDictionary] objectForKey:@"CFBundleShortVersionString"];

} // installVersion

@end

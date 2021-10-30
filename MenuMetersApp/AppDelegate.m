//
//  AppDelegate.m
//  MenuMetersApp
//
//  Created by Yuji on 2015/07/30.
//
//

#import "AppDelegate.h"
#import "MenuMeterCPUExtra.h"
#import "MenuMeterDiskExtra.h"
#import "MenuMeterMemExtra.h"
#import "MenuMeterNetExtra.h"
#import "MenuMetersPref.h"
#ifdef SPARKLE
#import <Sparkle/Sparkle.h>
#endif

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate
{
	MenuMeterCPUExtra*cpuExtra;
	MenuMeterDiskExtra*diskExtra;
	MenuMeterNetExtra*netExtra;
	MenuMeterMemExtra*memExtra;
	MenuMetersPref*pref;
#ifdef SPARKLE
	SUUpdater*updater;
#endif
	NSTimer*timer;
}

-(IBAction)checkForUpdates:(id)sender
{
#ifdef SPARKLE
	[updater checkForUpdates:sender];
#endif
}

-(void)killOlderInstances{
	NSString*thisVersion=NSBundle.mainBundle.infoDictionary[@"CFBundleVersion"];
	for(NSRunningApplication* x in [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.yujitach.MenuMeters"]){
		if([x isEqualTo:NSRunningApplication.currentApplication]){
			continue;
		}
		NSBundle*b=[NSBundle bundleWithURL:x.bundleURL];
		NSString*version=b.infoDictionary[@"CFBundleVersion"];
#ifdef SPARKLE
		NSComparisonResult r=[[SUStandardVersionComparator defaultComparator] compareVersion:version toVersion:thisVersion];
#else
		NSComparisonResult r=[version compare:thisVersion options:NSNumericSearch];
#endif
		NSLog(@"vers: running is %@, ours is %@, compare result was %ld", version, thisVersion, r);
		if(r!=NSOrderedDescending){
			NSLog(@"version %@ already running, which is equal or older than this binary %@. Going to kill it.",version,thisVersion);
			[x terminate];
		}
	}
}
- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
	[MenuMeterDefaults movePreferencesIfNecessary];
}
#define WELCOME @"v2.0.8alert"
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application
	[NSColor setIgnoresAlpha:NO];
	if([self isRunningOnReadOnlyVolume]){
		[self alertConcerningAppTranslocation];
	}
	[self killOlderInstances];
#ifdef SPARKLE
	updater=[SUUpdater sharedUpdater];
	updater.feedURL=[NSURL URLWithString:@"https://member.ipmu.jp/yuji.tachikawa/MenuMetersElCapitan/MenuMeters-Update.xml"];
	pref=[[MenuMetersPref alloc] initWithAboutFileName:WELCOME andUpdater:updater];
#else
	pref=[[MenuMetersPref alloc] initWithAboutFileName:WELCOME];
#endif
	NSString*key=[WELCOME stringByAppendingString:@"Presented"];
	if(![[NSUserDefaults standardUserDefaults] boolForKey:key]){
		[pref openAbout:WELCOME];
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:key];
	}
	// init of extras were moved to the last step.
	// It is because init of extras can raise exceptions when I introduce bugs.
	// If extras are init'ed first, neither the updater nor the pref pane is init'ed,
	// which is even worse.
	// When extras are inited last, at least the updater and the pref pane are live.
	cpuExtra=[[MenuMeterCPUExtra alloc] init];
	diskExtra=[[MenuMeterDiskExtra alloc] init];
	netExtra=[[MenuMeterNetExtra alloc] init];
	memExtra=[[MenuMeterMemExtra alloc] init];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Insert code here to tear down your application
}


- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag
{
	[NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
	[pref.window makeKeyAndOrderFront:sender];
	return YES;
}


- (BOOL)isRunningOnReadOnlyVolume {
	// taken from https://github.com/Squirrel/Squirrel.Mac/pull/186/files
	struct statfs statfsInfo;
	NSURL *bundleURL = NSRunningApplication.currentApplication.bundleURL;
	int result = statfs(bundleURL.fileSystemRepresentation, &statfsInfo);
	if (result == 0) {
		return (statfsInfo.f_flags & MNT_RDONLY) != 0;
	} else {
		// If we can't even check if the volume is read-only, assume it is.
		return YES;
	}
}

-(void)alertConcerningAppTranslocation{
	NSAlert*alert=[[NSAlert alloc] init];
	alert.messageText=@"Please move the app after downloading it";
	[alert addButtonWithTitle:@"OK, I quit the app and move it"];
	alert.informativeText=@"Please move the app to, say, /Applications, using your mouse/trackpad, not from the command line. \n\nApple decided that they don't allow the app to auto-update otherwise. \n\nI am sorry for the inconvenience.";
	[alert runModal];
	[NSApp terminate:nil];
}

@end

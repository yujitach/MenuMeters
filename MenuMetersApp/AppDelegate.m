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
#ifdef OUTOFPREFPANE
#import <Sparkle/Sparkle.h>
#import "MessageViewerController.h"
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
#ifdef OUTOFPREFPANE
    MenuMetersPref*pref;
    SUUpdater*updater;
    MessageViewerController*messageViewerController;
#endif
    NSTimer*timer;
}

-(IBAction)checkForUpdates:(id)sender
{
#ifdef OUTOFPREFPANE
    [updater checkForUpdates:sender];
#endif
}
#define WELCOME @"v2.0.3alert"
-(IBAction)showMessage:(id)sender
{
    if(!messageViewerController){
        messageViewerController=[[MessageViewerController alloc] initWithRTF:[[NSBundle mainBundle] pathForResource:WELCOME ofType:@"rtf"]];
    }
    [messageViewerController showWindow:sender];
}
-(IBAction)showWelcome:(id)sender
{
    NSString*key=[WELCOME stringByAppendingString:@"Shown"];
    if(![[NSUserDefaults standardUserDefaults] boolForKey:key]){
        [self showMessage:sender];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:key];
    }
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    cpuExtra=[[MenuMeterCPUExtra alloc] initWithBundle:[NSBundle mainBundle]];
    
    diskExtra=[[MenuMeterDiskExtra alloc] initWithBundle:[NSBundle mainBundle]];

    netExtra=[[MenuMeterNetExtra alloc] initWithBundle:[NSBundle mainBundle]];

    memExtra=[[MenuMeterMemExtra alloc] initWithBundle:[NSBundle mainBundle]];
    
#ifdef OUTOFPREFPANE
    pref=[[MenuMetersPref alloc] init];
    if([self isRunningOnReadOnlyVolume]){
        [self alertConcerningAppTranslocation];
    }
    updater=[SUUpdater sharedUpdater];
    updater.feedURL=[NSURL URLWithString:@"https://member.ipmu.jp/yuji.tachikawa/MenuMetersElCapitan/MenuMeters-Update.xml"];
    [self showWelcome:self];
    if(![pref noMenuMeterLoaded]){
        [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
    }
#endif
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


#ifdef OUTOFPREFPANE

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

#endif
@end

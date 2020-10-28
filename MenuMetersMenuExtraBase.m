//
//  NSMenuExtraBase.m
//  MenuMeters
//
//  Created by Yuji on 2015/08/01.
//
//

#import "MenuMetersMenuExtraBase.h"
#import "MenuMeterWorkarounds.h"

#import "MenuMeterCPUExtra.h"
#import "MenuMeterDiskExtra.h"
#import "MenuMeterMemExtra.h"
#import "MenuMeterNetExtra.h"

#define kAppleInterfaceThemeChangedNotification        @"AppleInterfaceThemeChangedNotification"

@implementation MenuMetersMenuExtraBase
-(NSColor*)colorByAdjustingForLightDark:(NSColor*)c
{
    return [c blendedColorWithFraction:[[NSUserDefaults standardUserDefaults] floatForKey:@"tintPercentage"]/100  ofColor:self.isDark?[NSColor whiteColor]:[NSColor blackColor]];
}
-(instancetype)initWithBundleID:(NSString*)bundleID
{
    self=[super init];
    self.bundleID=bundleID;
    // Register for pref changes
    [[NSNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(configFromPrefs:)
                                                            name:self.bundleID
                                                          object:kPrefChangeNotification];
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"tintPercentage" options:NSKeyValueObservingOptionNew context:nil];
    if(@available(macOS 10.14,*)){
    }else{
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                            selector:@selector(configFromPrefs:)
                                                                name:kAppleInterfaceThemeChangedNotification
                                                              object:nil];
    }
    return self;
}
-(void)configFromPrefs:(NSNotification *)notification
{
    NSLog(@"shouldn't happen");
    abort();
}
-(NSMenu*)menu
{
    NSLog(@"shouldn't happen");
    abort();
}
-(NSImage*)image
{
    NSLog(@"shouldn't happen");
    abort();
}
-(void)timerFired:(id)notused
{
    statusItem.button.image=self.image;
/*    NSImage*image=self.image;
    NSImage*canvas=[NSImage imageWithSize:image.size flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
        [[[NSColor systemGrayColor] colorWithAlphaComponent:.3] setFill];
        [NSBezierPath fillRect:(CGRect) {.size = image.size}];
        [image drawAtPoint:CGPointZero fromRect:(CGRect) {.size = image.size} operation:NSCompositeSourceOver fraction:1.0];
        return YES;
    }];
    statusItem.button.image=canvas;*/
}
-(void)timerXired:(id)notused
{
    NSImage *oldCanvas = statusItem.button.image;
    NSImage *canvas = oldCanvas;
    NSImage *image = self.image;
    NSSize imageSize = image.size;
    NSSize oldImageSize = canvas.size;
    if (imageSize.width != oldImageSize.width || imageSize.height != oldImageSize.height) {
        canvas = [[NSImage alloc] initWithSize:imageSize];
    }
    
    [canvas lockFocus];
    [image drawAtPoint:CGPointZero fromRect:(CGRect) {.size = image.size} operation:NSCompositeCopy fraction:1.0];
    [canvas unlockFocus];
    
    if (canvas != oldCanvas) {
        statusItem.button.image = canvas;
    } else {
        [statusItem.button displayRectIgnoringOpacity:statusItem.button.bounds];
    }
}
- (void)configDisplay:(NSString*)bundleID fromPrefs:(MenuMeterDefaults*)ourPrefs withTimerInterval:(NSTimeInterval)interval
{
    if([ourPrefs loadBoolPref:bundleID defaultValue:YES]){
        if(!statusItem){
            statusItem=[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
            if(@available(macOS 10.12,*)){
//                statusItem.autosaveName=self.bundleID;
                statusItem.behavior=NSStatusItemBehaviorRemovalAllowed;
                [statusItem addObserver:self forKeyPath:@"visible" options:NSKeyValueObservingOptionNew context:nil];
            }
            statusItem.menu = self.menu;
            statusItem.menu.delegate = self;
            [statusItem.button addObserver:self forKeyPath:@"effectiveAppearance" options:NSKeyValueObservingOptionNew context:nil];
        }
        [updateTimer invalidate];
        updateTimer=[NSTimer timerWithTimeInterval:interval target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
        [updateTimer setTolerance:.2*interval];
        [[NSRunLoop currentRunLoop] addTimer:updateTimer forMode:NSRunLoopCommonModes];
    }else if(![ourPrefs loadBoolPref:bundleID defaultValue:YES] && statusItem){
        [self removeStatusItem];
    }
}
-(void)removeStatusItem
{
    [updateTimer invalidate];
    [[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
    statusItem=nil;
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"menuExtraUnloaded" object:self.bundleID]];
}
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if(object==statusItem.button && [keyPath isEqualToString:@"effectiveAppearance"]){
        [self configFromPrefs:nil];
    }

    if(@available(macOS 10.12,*)){
        if(object==statusItem && [keyPath isEqualToString:@"visible"]){
            if(!statusItem.visible){
                [self removeStatusItem];
            }
        }
    }
    if([keyPath isEqualToString:@"tintPercentage"]){
        [self configFromPrefs:nil];
    }
}
- (void)openMenuMetersPref:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"openPref" object:self]];
}
- (void)openActivityMonitor:(id)sender {

    if (![[NSWorkspace sharedWorkspace] launchApplication:@"Activity Monitor.app"]) {
        NSLog(@"MenuMeter unable to launch the Activity Monitor.");
    }
    BOOL x=[[NSUserDefaults standardUserDefaults] boolForKey:@"activityMonitorOpenSpecificPanes"];
    if(!x)
        return;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(),^{
        if(@available(macOS 10.15,*)){
            int tab=1;
            if([self isKindOfClass:[MenuMeterCPUExtra class]]){
                tab=1;
            }
            if([self isKindOfClass:[MenuMeterDiskExtra class]]){
                tab=4;
            }
            if([self isKindOfClass:[MenuMeterMemExtra class]]){
                tab=2;
            }
            if([self isKindOfClass:[MenuMeterNetExtra class]]){
                tab=5;
            }
            NSString*source=[NSString stringWithFormat:@"tell application \"System Events\" to tell process \"Activity Monitor\" to click radio button %@ of radio group 1 of group 2 of toolbar of window 1", @(tab)];
            NSAppleScript*script=[[NSAppleScript alloc] initWithSource:source];
            NSDictionary* errorDict=nil;
            [script executeAndReturnError:&errorDict];
            if(errorDict){
                NSLog(@"%@",errorDict);
            }
        }
    });
} // openActivityMonitor
- (void)addStandardMenuEntriesTo:(NSMenu*)extraMenu
{
    NSMenuItem* menuItem = (NSMenuItem *)[extraMenu addItemWithTitle:NSLocalizedString(kOpenActivityMonitorTitle, kOpenActivityMonitorTitle)
                                                              action:@selector(openActivityMonitor:)
                                                       keyEquivalent:@""];
    [menuItem setTarget:self];
    menuItem = (NSMenuItem *)[extraMenu addItemWithTitle:NSLocalizedString(kOpenMenuMetersPref, kOpenMenuMetersPref)
                                                  action:@selector(openMenuMetersPref:)
                                           keyEquivalent:@""];
    [menuItem setTarget:self];

}
-(BOOL)isDark
{
    if(@available(macOS 10.14,*)){
        // https://github.com/ruiaureliano/macOS-Appearance/blob/master/Appearance/Source/AppDelegate.swift
        return [statusItem.button.effectiveAppearance.name containsString:@"ark"];
    }else{
        // https://stackoverflow.com/questions/25207077/how-to-detect-if-os-x-is-in-dark-mode
        // On 10.10 there is no documented API for theme, so we'll guess a couple of different ways.
        BOOL isDark = NO;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults synchronize];
        NSString *interfaceStyle = [defaults stringForKey:@"AppleInterfaceStyle"];
        if (interfaceStyle && [interfaceStyle isEqualToString:@"Dark"]) {
            isDark = YES;
        }
        return isDark;
    }
}
-(NSColor*)menuBarTextColor
{
    if(@available(macOS 10.14,*)){
        return [NSColor labelColor];
    }
    if (self.isDark){
        return [NSColor whiteColor];
    }
    return [NSColor blackColor];
}
- (void)setupAppearance {
    if(@available(macOS 10.14,*)){
        [NSAppearance setCurrentAppearance:statusItem.button.effectiveAppearance];
    }
}
#pragma mark NSMenuDelegate
- (void)menuNeedsUpdate:(NSMenu*)menu {
    statusItem.menu = self.menu;
    statusItem.menu.delegate = self;
}
- (void)menuWillOpen:(NSMenu*)menu {
    _isMenuVisible = YES;
}
- (void)menuDidClose:(NSMenu*)menu {
    _isMenuVisible = NO;
}

@end

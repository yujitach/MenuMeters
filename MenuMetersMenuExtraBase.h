//
//  NSMenuExtraBase.h
//  MenuMeters
//
//  Created by Yuji on 2015/08/01.
//
//

#import <Foundation/Foundation.h>
@class MenuMeterDefaults;

@interface MenuMetersMenuExtraBase : NSObject <NSMenuDelegate>
{
    NSStatusItem* statusItem;
    NSTimer* updateTimer;
}
-(NSColor*)colorByAdjustingForLightDark:(NSColor*)c;
- (NSImage*)image;
- (NSMenu*)menu;
- (void)configDisplay:(NSString*)bundleID fromPrefs:(MenuMeterDefaults*)ourPrefs withTimerInterval:(NSTimeInterval)interval;
- (void)configFromPrefs:(NSNotification*)notification;
- (void)timerFired:(id)timer;
- (void)openMenuMetersPref:(id)sender;
- (void)openActivityMonitor:(id)sender;
- (void)addStandardMenuEntriesTo:(NSMenu*)extraMenu;
- (void)setupAppearance;
- (BOOL)isDark;
- (CGFloat)height;
-(NSColor*)menuBarTextColor;
-(instancetype)initWithBundleID:(NSString*)bundleID;
@property(nonatomic, readonly) BOOL isMenuVisible;
@property(nonatomic, retain) NSString*bundleID;
@end

#define NSMenuExtra MenuMetersMenuExtraBase
#define kOpenMenuMetersPref                 @"Open MenuMeters preferences"
#define kOpenActivityMonitorTitle            @"Open Activity Monitor"


//
//  NSMenuExtraBase.h
//  MenuMeters
//
//  Created by Yuji on 2015/08/01.
//
//

#import <Foundation/Foundation.h>
#import "AppleUndocumented.h"
#import "MenuMeterDefaults.h"

@interface MenuMetersMenuExtraBase : NSMenuExtra <NSMenuDelegate>
{
    NSStatusItem* statusItem;
    NSTimer* updateTimer;
}
- (void)configDisplay:(NSString*)bundleID fromPrefs:(MenuMeterDefaults*)ourPrefs withTimerInterval:(NSTimeInterval)interval;
- (void)timerFired:(id)timer;
- (void)openMenuMetersPref:(id)sender;
- (void)setupAppearance;
@property(nonatomic, readonly) BOOL isMenuVisible;
@end

#define NSMenuExtra MenuMetersMenuExtraBase
#define kOpenMenuMetersPref                 @"Open MenuMeters preferences"

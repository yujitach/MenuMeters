//
//  NSMenuExtraBase.m
//  MenuMeters
//
//  Created by Yuji on 2015/08/01.
//
//

#import "MenuMetersMenuExtraBase.h"

@implementation MenuMetersMenuExtraBase
-(void)timerFired:(id)notused
{
    statusItem.button.image=[self image];
}
- (void)configDisplay:(NSString*)bundleID fromPrefs:(MenuMeterDefaults*)ourPrefs withTimerInterval:(NSTimeInterval)interval
{
    if([ourPrefs loadBoolPref:bundleID defaultValue:YES]){
        if(!statusItem){
            statusItem=[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
            statusItem.menu = self.menu;
            statusItem.menu.delegate = self;
        }
        [timer invalidate];
        timer=[NSTimer timerWithTimeInterval:interval target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
        [timer setTolerance:.2*interval];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    }else if(![ourPrefs loadBoolPref:bundleID defaultValue:YES] && statusItem){
        [timer invalidate];
        [[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
        statusItem=nil;
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

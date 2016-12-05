//
//  NSMenuExtraBase.m
//  MenuMeters
//
//  Created by Yuji on 2015/08/01.
//
//

#import "MenuMetersMenuExtraBase.h"

@implementation MenuMetersMenuExtraBase
-(instancetype)initWithBundle:(NSBundle*)bundle
{
    self=[super initWithBundle:bundle];
    return self;
}
-(void)timerFired:(id)notused
{
    NSImage *oldCanvas = statusItem.button.image;
    NSImage *canvas = oldCanvas;
    NSSize imageSize = NSMakeSize(self.length, self.view.frame.size.height);
    NSSize oldImageSize = canvas.size;
    if (imageSize.width != oldImageSize.width || imageSize.height != oldImageSize.height) {
        canvas = [[NSImage alloc] initWithSize:imageSize];
    }
    
    NSImage *image = self.image;
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

//
//  AuxPanelController.m
//  spires
//
//  Created by Yuji on 6/29/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "AuxPanelController.h"


@implementation AuxPanelController
-(void)windowDidLoad
{
    [self setWindowFrameAutosaveName:[self windowNibName]];
    [[self window] setLevel:NSNormalWindowLevel];
    [[self window] setIsVisible:[[NSUserDefaults standardUserDefaults] boolForKey:nibIsVisibleKey]];
    [[self window] setDelegate:self];
}
-(void)windowWillEnterFullScreen:(NSNotification *)notification
{
    [[self window] setLevel:NSFloatingWindowLevel];
}
-(void)windowWillExitFullScreen:(NSNotification *)notification
{
    [[self window] setLevel:NSNormalWindowLevel];
}
-(id)initWithWindowNibName:(NSString*)nibName
{
    self=[super initWithWindowNibName:nibName];
    nibIsVisibleKey=[nibName stringByAppendingString:@"IsVisible"];
    if([[NSUserDefaults standardUserDefaults] boolForKey:nibIsVisibleKey]){
	[self showWindow:self];
    }
    return self;
}
-(void)showhide:(id)sender
{
    if([[self window] isVisible]){
	[[self window] setIsVisible:NO];
    }else{
	[[self window] makeKeyAndOrderFront:sender];
    }
}
-(void)windowDidBecomeKey:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:nibIsVisibleKey];
}
-(void)windowWillClose:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:nibIsVisibleKey];
}

@end

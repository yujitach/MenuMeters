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

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate
{
    NSStatusItem*cpuStatusItem;
    MenuMeterCPUExtra*cpuExtra;

    NSStatusItem*diskStatusItem;
    MenuMeterDiskExtra*diskExtra;

    
    NSStatusItem*netStatusItem;
    MenuMeterNetExtra*netExtra;
    
    NSStatusItem*memStatusItem;
    MenuMeterMemExtra*memExtra;
    
    
    NSTimer*timer;
}

-(void)timerFired:(id)notused
{
    cpuStatusItem.menu=cpuExtra.menu;
    cpuStatusItem.button.image=cpuExtra.image;

    diskStatusItem.menu=diskExtra.menu;
    diskStatusItem.button.image=diskExtra.image;

    netStatusItem.menu=netExtra.menu;
    netStatusItem.button.image=netExtra.image;

    memStatusItem.menu=memExtra.menu;
    memStatusItem.button.image=memExtra.image;


}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    cpuExtra=[[MenuMeterCPUExtra alloc] initWithBundle:[NSBundle mainBundle]];
    cpuStatusItem=[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    
    diskExtra=[[MenuMeterDiskExtra alloc] initWithBundle:[NSBundle mainBundle]];
    diskStatusItem=[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];

    netExtra=[[MenuMeterNetExtra alloc] initWithBundle:[NSBundle mainBundle]];
    netStatusItem=[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];

    memExtra=[[MenuMeterMemExtra alloc] initWithBundle:[NSBundle mainBundle]];
    memStatusItem=[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];

    
    timer=[NSTimer timerWithTimeInterval:1 target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
    [timer setTolerance:.3];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end

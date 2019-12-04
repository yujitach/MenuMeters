//
//  MessageViewerController.h
//  spires
//
//  Created by Yuji on 8/16/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MessageViewerController : NSWindowController {
    IBOutlet NSTextView*tv;
    NSString*pathToRTF;
    NSTimer*annoyingTimer;
}
-(id)initWithRTF:(NSString*)path;
@end

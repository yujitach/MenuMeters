//
//  ImageHostController.m
//  MenuMeters
//
//  Created by Yuji Tachikawa on 2020/11/25.
//

#import "ImageHostController.h"

@interface ImageHostController ()
@property (retain) IBOutlet NSImageView *imageView;
@property (retain) IBOutlet NSTextView *textView;

@end

@implementation ImageHostController


- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

-(void)setImage:(NSImage*)image
{
    self.imageView.image=image;
}
-(void)prependMessage:(NSString *)string
{
    [self.textView.textStorage replaceCharactersInRange:NSMakeRange(0, 0) withString:string];
}

- (IBAction)copyContentToPasteboard:(id)sender {
    NSPasteboard*pb=[NSPasteboard generalPasteboard];
    [pb declareTypes:@[NSPasteboardTypeString] owner:self];
    [pb setString:self.textView.string forType:NSPasteboardTypeString];
    [[NSSound soundNamed:@"Submarine"] play];

}
@end

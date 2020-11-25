//
//  ImageHostController.m
//  MenuMeters
//
//  Created by Yuji Tachikawa on 2020/11/25.
//

#import "ImageHostController.h"

@interface ImageHostController ()
@property (weak) IBOutlet NSImageView *imageView;

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
@end

//
//  ImageHostController.h
//  MenuMeters
//
//  Created by Yuji Tachikawa on 2020/11/25.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImageHostController : NSWindowController
-(void)setImage:(NSImage*)image;
-(void)prependMessage:(NSString*)string;
@end

NS_ASSUME_NONNULL_END

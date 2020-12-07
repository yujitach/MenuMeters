//
//  LocalizedStrings.h
//  MenuMeters
//
//  Created by Yuji on 12/7/20.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface LocalizedStrings : NSObject
-(NSString*)objectForKey:(NSString*)key;
@end

extern LocalizedStrings*localizedStrings;

NS_ASSUME_NONNULL_END

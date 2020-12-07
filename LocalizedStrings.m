//
//  LocalizedStrings.m
//  MenuMeters
//
//  Created by Yuji on 12/7/20.
//

#import "LocalizedStrings.h"
LocalizedStrings*localizedStrings;
@implementation LocalizedStrings
-(NSString*)objectForKey:(NSString*)key
{
    return [[NSBundle mainBundle] localizedStringForKey:key value:nil table:nil];
}
+(void)load
{
    localizedStrings=[[LocalizedStrings alloc] init];
}
@end

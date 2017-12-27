//
//  Copyright (c) 2014 Enrico M. Crisostomo. All rights reserved.
//
//  License: BSD 3-Clause License
//  (http://opensource.org/licenses/BSD-3-Clause)
//

#import <Foundation/Foundation.h>

@interface EMCLoginItem : NSObject

- (instancetype)init;
- (instancetype)initWithBundle:(NSBundle *)bundle;
- (instancetype)initWithPath:(NSString *)path;

- (BOOL)isLoginItem;
- (void)addLoginItem;
- (void)removeLoginItem;
- (void)addAfterLast;
- (void)addAfterFirst;
- (void)addAfterItemWithPath:(NSString *)path;
- (void)addAfterBundle:(NSBundle *)bundle;
- (void)setIconRef:(IconRef)iconRef;

+ (instancetype)loginItem;
+ (instancetype)loginItemWithBundle:(NSBundle *)bundle;
+ (instancetype)loginItemWithPath:(NSString *)path;

@end

//
//  Created by Enrico Maria Crisostomo on 04/05/14.
//  Copyright (c) 2014 Enrico M. Crisostomo. All rights reserved.
//
//  License: BSD 3-Clause License
//  (http://opensource.org/licenses/BSD-3-Clause)
//

#import "EMCLoginItem.h"

#if !__has_feature(objc_arc)
#error This class requires ARC support to be enabled.
#endif

@implementation EMCLoginItem
{
    CFURLRef url;
    LSSharedFileListItemRef itemBeforeInsertion;
    CFURLRef itemBeforePath;
    IconRef _iconRef;
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        NSString * appPath = [[NSBundle mainBundle] bundlePath];
        [self initHelper:appPath];
    }
    
    return self;
}

- (void)dealloc
{
    if (_iconRef)
    {
        ReleaseIconRef(_iconRef);
    }
}

- (instancetype)initWithBundle:(NSBundle *)bundle
{
    if (!bundle)
    {
        NSException* nullException = [NSException
                                      exceptionWithName:@"NullPointerException"
                                      reason:@"Bundle cannot be null."
                                      userInfo:nil];
        @throw nullException;
    }
    
    self = [super init];
    
    if (self)
    {
        NSString * appPath = [bundle bundlePath];
        [self initHelper:appPath];
    }
    
    return self;
}

- (instancetype)initWithPath:(NSString *)appPath
{
    if (!appPath)
    {
        NSException* nullException = [NSException
                                      exceptionWithName:@"NullPointerException"
                                      reason:@"Path cannot be null."
                                      userInfo:nil];
        @throw nullException;
    }
    
    self = [super init];
    
    if (self)
    {
        [self initHelper:appPath];
    }
    
    return self;
}

- (void)initHelper:(NSString *)appPath
{
    url = (CFURLRef)CFBridgingRetain([NSURL fileURLWithPath:appPath]);
    itemBeforeInsertion = kLSSharedFileListItemLast;
}

+ (instancetype)loginItem
{
    return [[EMCLoginItem alloc] initWithBundle:[NSBundle mainBundle]];
}

+ (instancetype)loginItemWithBundle:(NSBundle *)bundle
{
    return [[EMCLoginItem alloc] initWithBundle:bundle];
}

+ (instancetype)loginItemWithPath:(NSString *)path
{
    return [[EMCLoginItem alloc] initWithPath:path];
}

- (void)setIconRef:(IconRef)iconRef
{
    if (_iconRef == iconRef)
    {
        return;
    }
    
    if (_iconRef)
    {
        ReleaseIconRef(_iconRef);
    }
    
    if (AcquireIconRef(iconRef) == noErr)
    {
        _iconRef = iconRef;
    }
    else
    {
        NSLog(@"Error: Cannot acquire IconRef.");
        _iconRef = nil;
    }
}

- (BOOL)isLoginItem
{
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL,
                                                            kLSSharedFileListSessionLoginItems,
                                                            NULL);
    
    if (loginItems)
    {
        UInt32 seed;
        CFArrayRef loginItemsArray = LSSharedFileListCopySnapshot(loginItems, &seed);
        
        for (id item in (__bridge NSArray *)loginItemsArray)
        {
            LSSharedFileListItemRef loginItem = (__bridge LSSharedFileListItemRef)item;
            CFURLRef itemUrl;
            
            if (LSSharedFileListItemResolve(loginItem, 0, &itemUrl, NULL) == noErr)
            {
                if (CFEqual(itemUrl, url))
                {
                    return YES;
                }
            }
            else
            {
                NSLog(@"Error: LSSharedFileListItemResolve failed.");
            }
        }
    }
    else
    {
        NSLog(@"Warning: LSSharedFileListCreate failed, could not get list of login items.");
    }
    
    return NO;
}

- (void)addLoginItem
{
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL,
                                                            kLSSharedFileListSessionLoginItems,
                                                            NULL);
    
    if (!loginItems)
    {
        NSLog(@"Error: LSSharedFileListCreate failed, could not get list of login items.");
        return;
    }
    
    // If an item path has been specified as specific insertion point for the
    // login item to add, then look for it.
    if(!LSSharedFileListInsertItemURL(loginItems,
                                      [self findInsertionPoint:loginItems],
                                      NULL,
                                      _iconRef,
                                      url,
                                      NULL,
                                      NULL))
    {
        NSLog(@"Error: LSSharedFileListInsertItemURL failed, could not create login item.");
    }
}

- (LSSharedFileListItemRef)findInsertionPoint:(LSSharedFileListRef)loginItems
{
    if (itemBeforeInsertion)
    {
        return itemBeforeInsertion;
    }
    
    // itemBeforePath
    const LSSharedFileListItemRef found = [self findItem:loginItems withPath:itemBeforePath];
    
    if (found)
    {
        return found;
    }
    
    NSLog(@"Warning: Could not find item with specified path.");
    
    // If no item with the specified path has been found, then the last position
    // is returned.
    return kLSSharedFileListItemLast;
}

- (LSSharedFileListItemRef)findItem:(LSSharedFileListRef)loginItems
                           withPath:(CFURLRef)path
{
    UInt32 seed;
    CFArrayRef loginItemsArray = LSSharedFileListCopySnapshot(loginItems, &seed);
    
    for (id item in (__bridge NSArray *)loginItemsArray)
    {
        LSSharedFileListItemRef loginItem = (__bridge LSSharedFileListItemRef)item;
        CFURLRef itemUrl;
        
        if (LSSharedFileListItemResolve(loginItem, 0, &itemUrl, NULL) == noErr)
        {
            if (CFEqual(itemUrl, path))
            {
                return loginItem;
            }
        }
    }
    
    return nil;
}

- (void)removeLoginItem
{
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL,
                                                            kLSSharedFileListSessionLoginItems,
                                                            NULL);
    if (loginItems)
    {
        BOOL removed = NO;
        UInt32 seed;
        CFArrayRef loginItemsArray = LSSharedFileListCopySnapshot(loginItems, &seed);
        
        for (id item in (__bridge NSArray *)loginItemsArray)
        {
            LSSharedFileListItemRef loginItem = (__bridge LSSharedFileListItemRef)item;
            CFURLRef itemUrl;
            
            if (LSSharedFileListItemResolve(loginItem, 0, &itemUrl, NULL) == noErr)
            {
                if (CFEqual(itemUrl, url))
                {
                    if (LSSharedFileListItemRemove(loginItems, loginItem) == noErr)
                    {
                        removed = YES;
                        break;
                    }
                    else
                    {
                        NSLog(@"Error: Unknown error while removing login item.");
                    }
                }
            }
            else
            {
                NSLog(@"Warning: LSSharedFileListItemResolve failed, could not resolve item.");
            }
        }
        
        if (!removed)
        {
            NSLog(@"Error: could not find login item to remove.");
        }
    }
    else
    {
        NSLog(@"Warning: could not get list of login items.");
    }
}

- (void)addAfterLast
{
    itemBeforeInsertion = kLSSharedFileListItemLast;
    itemBeforePath = nil;
}

- (void)addAfterFirst
{
    itemBeforeInsertion = kLSSharedFileListItemBeforeFirst;
    itemBeforePath = nil;
}

- (void)addAfterItemWithPath:(NSString *)path
{
    if (!path)
    {
        NSException* nullException = [NSException
                                      exceptionWithName:@"NullPointerException"
                                      reason:@"Path cannot be null."
                                      userInfo:nil];
        @throw nullException;
    }
    
    itemBeforeInsertion = nil;
    itemBeforePath = (CFURLRef)CFBridgingRetain([NSURL fileURLWithPath:path]);
}

- (void)addAfterBundle:(NSBundle *)bundle
{
    if (!bundle)
    {
        NSException* nullException = [NSException
                                      exceptionWithName:@"NullPointerException"
                                      reason:@"Bundle cannot be null."
                                      userInfo:nil];
        @throw nullException;
    }
    
    itemBeforeInsertion = nil;
    itemBeforePath = (CFURLRef)CFBridgingRetain([NSURL fileURLWithPath:[bundle bundlePath]]);
}

@end


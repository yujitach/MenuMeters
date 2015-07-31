//
//	AppleUndocumented.h
//
//	Things Apple would rather we didn't know about...
//

// Apple private function to get MenuRef from NSMenu
extern MenuRef _NSGetCarbonMenu(NSMenu *);

// Routines to handle adding and remove menu extras in HIServices (from ASM source)
int CoreMenuExtraGetMenuExtra(CFStringRef identifier, void *menuExtra);
int CoreMenuExtraAddMenuExtra(CFURLRef path, int position, int whoCares, int whoCares2, int whoCares3, int whoCares4);
int CoreMenuExtraRemoveMenuExtra(void *menuExtra, int whoCares);

// Distributed notification of theme changes on 10.10
#define kAppleInterfaceThemeChangedNotification		@"AppleInterfaceThemeChangedNotification"

// SystemUIPlugin
@interface NSMenuExtra : NSStatusItem
{
    NSBundle *_bundle;
    NSMenu *_menu;
    NSView *_view;
#ifdef __LP64__
    double _length;
#else
    float _length;
#endif
    struct {
        unsigned int customView:1;
        unsigned int menuDown:1;
        unsigned int reserved:30;
    } _flags;
    id _controller;
}

- (id)initWithBundle:(id)arg1;
- (id)initWithBundle:(id)arg1 data:(id)arg2;
- (void)willUnload;
- (void)dealloc;
- (id)bundle;
#ifdef __LP64__
- (double)length;
- (void)setLength:(double)arg1;
#else
- (float)length;
- (void)setLength:(float)arg1;
#endif
- (id)image;
- (void)setImage:(id)arg1;
- (id)alternateImage;
- (void)setAlternateImage:(id)arg1;
- (id)menu;
- (void)setMenu:(id)arg1;
- (id)toolTip;
- (void)setToolTip:(id)arg1;
- (id)view;
- (void)setView:(id)arg1;
- (BOOL)convertedForNewUI;
- (BOOL)isMenuDown;
- (BOOL)isMenuDownForAX;
- (void)drawMenuBackground:(BOOL)arg1;
- (void)popUpMenu:(id)arg1;
- (void)unload;
- (id)statusBar;
- (SEL)action;
- (void)setAction:(SEL)arg1;
- (id)target;
- (void)setTarget:(id)arg1;
- (id)title;
- (void)setTitle:(id)arg1;
- (id)attributedTitle;
- (void)setAttributedTitle:(id)arg1;
- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)arg1;
- (void)setHighlightMode:(BOOL)arg1;
- (BOOL)highlightMode;
- (void)sendActionOn:(int)arg1;
- (id)_initInStatusBar:(id)arg1 withLength:(float)arg2 withPriority:(int)arg3;
- (id)_window;
- (id)_button;
- (void)_adjustLength;

@end

@interface NSMenuExtraView : NSView
{
    NSMenu *_menu;
    NSMenuExtra *_menuExtra;
    NSImage *_image;
    NSImage *_alternateImage;
}

- (id)initWithFrame:(NSRect)arg1 menuExtra:(NSMenuExtra *)arg2;
- (void)dealloc;
- (void)setMenu:(id)arg1;
- (id)image;
- (void)setImage:(id)arg1;
- (id)alternateImage;
- (void)setAlternateImage:(id)arg1;
- (void)drawRect:(struct _NSRect)arg1;
- (void)mouseDown:(id)arg1;

@end

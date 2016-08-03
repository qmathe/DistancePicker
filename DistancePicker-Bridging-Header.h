/*
	Copyright (C) 2014 Quentin Mathe
 
	Date:  September 2014
	License:  MIT
 */

#import <UIKit/UIGestureRecognizer.h>

@interface UIGestureRecognizer (MissingPublicAPI)
- (void)touchesBegan: (NSSet *)touches withEvent: (UIEvent *)event;
- (void)touchesMoved: (NSSet *)touches withEvent: (UIEvent *)event;
- (void)touchesEnded: (NSSet *)touches withEvent: (UIEvent *)event;
- (void)touchesCancelled: (NSSet *)touches withEvent: (UIEvent *)event;
@end

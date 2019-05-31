/*
	Copyright (C) 2014 Quentin Mathe
 
	Date:  September 2014
	License:  MIT
 */

#import <UIKit/UIGestureRecognizer.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIGestureRecognizer (MissingPublicAPI)
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event;
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event;
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event;
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event;
@end

NS_ASSUME_NONNULL_END

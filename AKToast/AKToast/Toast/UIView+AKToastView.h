//
//  UIView+AKToastView.h
//  AKToast
//
//  Created by Arafat on 9/11/15.
//  Copyright (c) 2015 Arafat Khan. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const AKToastPositionTop;
extern NSString * const AKToastPositionNearToTop;
extern NSString * const AKToastPositionCenter;
extern NSString * const AKToastPositionBottom;


@interface UIView (AKToastView)

- (void)AKToastWithMessage:(NSString *)message title:(NSString *)title duration:(NSTimeInterval)duration position:(id)position;

@end

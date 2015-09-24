//
//  UIView+AKToastView.m
//  AKToast
//
//  Created by Arafat on 9/11/15.
//  Copyright (c) 2015 Arafat Khan. All rights reserved.
//

#import "UIView+AKToastView.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

/*
 *  CONFIGURE THESE VALUES TO ADJUST LOOK & FEEL,
 *  DISPLAY DURATION, ETC.
 */

// general appearance
static const CGFloat AKToastVerticalPaddingNearToTop  = 100.0;
static const CGFloat AKToastHorizontalPadding   = 10.0;
static const CGFloat AKToastVerticalPadding     = 10.0;
static const CGFloat AKToastMaxWidth            = 0.8;      // 80% of parent view width
static const CGFloat AKToastMaxHeight           = 0.8;      // 80% of parent view height
static const CGFloat AKToastCornerRadius        = 5.0;
static const CGFloat AKToastOpacity             = 0.8;
static const CGFloat AKToastFontSize            = 16.0;
static const CGFloat AKToastMaxTitleLines       = 0;
static const CGFloat AKToastMaxMessageLines     = 0;
static const NSTimeInterval AKToastFadeDuration = 0.5;

// shadow appearance
static const CGFloat AKToastShadowOpacity       = 0.5;
static const CGFloat AKToastShadowRadius        = 6.0;
static const CGSize  AKToastShadowOffset        = { 4.0, 4.0 };
static const BOOL    AKToastDisplayShadow       = YES;

// display duration
static const NSTimeInterval AKToastDefaultDuration  = 3.0;

// image view size
static const CGFloat AKToastImageViewWidth      = 80.0;
static const CGFloat AKToastImageViewHeight     = 80.0;

// activity
static const CGFloat AKToastActivityWidth       = 100.0;
static const CGFloat AKToastActivityHeight      = 100.0;
static const NSString * AKToastActivityDefaultPosition = @"center";

// interaction
static const BOOL AKToastHidesOnTap             = YES;     // excludes activity views

// associative reference keys
static const NSString * AKToastTimerKey         = @"AKToastTimerKey";
static const NSString * AKToastActivityViewKey  = @"AKToastActivityViewKey";
static const NSString * AKToastTapCallbackKey   = @"AKToastTapCallbackKey";

// positions
NSString * const AKToastPositionTop             = @"top";
NSString * const AKToastPositionNearToTop       = @"neartotop";
NSString * const AKToastPositionCenter          = @"center";
NSString * const AKToastPositionBottom          = @"bottom";

@implementation UIView (AKToastView)

#pragma mark - initializer
- (void)AKToastWithMessage:(NSString *)message title:(NSString *)title duration:(NSTimeInterval)duration position:(id)position  {
    
    UIView *toast = [self viewForMessage:message title:title];
    [self showToast:toast duration:duration position:position];
}

#pragma mark - Helpers
- (CGPoint)centerPointForPosition:(id)point withToast:(UIView *)toast {
    if([point isKindOfClass:[NSString class]]) {
        if([point caseInsensitiveCompare:AKToastPositionTop] == NSOrderedSame) {
            return CGPointMake(self.bounds.size.width/2, (toast.frame.size.height / 2) + AKToastVerticalPadding);
        }
        else if([point caseInsensitiveCompare:AKToastPositionNearToTop] == NSOrderedSame) {
            return CGPointMake(self.bounds.size.width/2, (toast.frame.size.height / 2) + AKToastVerticalPaddingNearToTop);
        }
        else if([point caseInsensitiveCompare:AKToastPositionCenter] == NSOrderedSame) {
            return CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
        }
    } else if ([point isKindOfClass:[NSValue class]]) {
        return [point CGPointValue];
    }
    
    // default to bottom
    return CGPointMake(self.bounds.size.width/2, (self.bounds.size.height - (toast.frame.size.height / 2)) - AKToastVerticalPadding);
}

- (CGSize)sizeForString:(NSString *)string font:(UIFont *)font constrainedToSize:(CGSize)constrainedSize lineBreakMode:(NSLineBreakMode)lineBreakMode {
    if ([string respondsToSelector:@selector(boundingRectWithSize:options:attributes:context:)]) {
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.lineBreakMode = lineBreakMode;
        NSDictionary *attributes = @{NSFontAttributeName:font, NSParagraphStyleAttributeName:paragraphStyle};
        CGRect boundingRect = [string boundingRectWithSize:constrainedSize options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:nil];
        return CGSizeMake(ceilf(boundingRect.size.width), ceilf(boundingRect.size.height));
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [string sizeWithFont:font constrainedToSize:constrainedSize lineBreakMode:lineBreakMode];
#pragma clang diagnostic pop
}

- (void)showToast:(UIView *)toast {
    [self showToast:toast duration:AKToastDefaultDuration position:nil];
}

- (void)showToast:(UIView *)toast duration:(NSTimeInterval)duration position:(id)position {
    [self showToast:toast duration:duration position:position tapCallback:nil];
    
}


- (void)showToast:(UIView *)toast duration:(NSTimeInterval)duration position:(id)position
      tapCallback:(void(^)(void))tapCallback
{
    /* Make it center toast view */
    toast.center = [self centerPointForPosition:position withToast:toast];
    toast.alpha = 1.0;
    
    /* Created background view */
    /* Purpose, User can click anywhere to disappear whole view */
    UIView *bgView = [[UIView alloc] initWithFrame:self.bounds];
    bgView.backgroundColor = [UIColor clearColor];
    [bgView addSubview:toast];
    bgView.alpha = 1.0;
    
    if (AKToastHidesOnTap) {
        UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:bgView action:@selector(handleToastTapped:)];
        [bgView addGestureRecognizer:recognizer];
        bgView.userInteractionEnabled = YES;
        bgView.exclusiveTouch = YES;
        
    }
    
    /* Added custom toast view to main bg view */
    [self addSubview:bgView];
    
    /* Begin animation */
    [UIView animateWithDuration:AKToastFadeDuration
                          delay:0
                        options:(UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction)
                     animations:^{
                         bgView.alpha = 1.0;
                     } completion:^(BOOL finished) {
                         NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:duration target:self selector:@selector(toastTimerDidFinish:) userInfo:bgView repeats:NO];
                         // associate the timer with the toast view
                         objc_setAssociatedObject (bgView, &AKToastTimerKey, timer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                         objc_setAssociatedObject (bgView, &AKToastTapCallbackKey, tapCallback, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                     }];
}


#pragma mark - Custom UILable's

- (UILabel *)getCustomLabelWithText:(NSString *) text{
    
    UILabel *label = [[UILabel alloc] init];
    label.numberOfLines = AKToastMaxMessageLines;
    label.font = [UIFont systemFontOfSize:AKToastFontSize];
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    label.alpha = 1.0;
    label.text = text;
    return label;
}

- (void)hideToast:(UIView *)toast {
    [UIView animateWithDuration:AKToastFadeDuration
                          delay:0.0
                        options:(UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionBeginFromCurrentState)
                     animations:^{
                         toast.alpha = 0.0;
                     } completion:^(BOOL finished) {
                         [toast removeFromSuperview];
                     }];
}


#pragma mark - Events

- (void)toastTimerDidFinish:(NSTimer *)timer {
    [self hideToast:(UIView *)timer.userInfo];
}

- (void)handleToastTapped:(UITapGestureRecognizer *)recognizer {
    NSTimer *timer = (NSTimer *)objc_getAssociatedObject(self, &AKToastTimerKey);
    [timer invalidate];
    
    void (^callback)(void) = objc_getAssociatedObject(self, &AKToastTapCallbackKey);
    if (callback) {
        callback();
    }
    [self hideToast:recognizer.view];
}


- (UIView *)viewForMessage:(NSString *)message title:(NSString *)title {
    
    /* dynamically build a toast view with any combination of message, title, & image. */
    UILabel *messageLabel = nil;
    UILabel *titleLabel = nil;
    
    /* create the parent view */
    UIView *wrapperView = [[UIView alloc] init];
    wrapperView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin);
    wrapperView.layer.cornerRadius = AKToastCornerRadius;
    
    if (AKToastDisplayShadow) {
        wrapperView.layer.shadowColor = [UIColor blackColor].CGColor;
        wrapperView.layer.shadowOpacity = AKToastShadowOpacity;
        wrapperView.layer.shadowRadius = AKToastShadowRadius;
        wrapperView.layer.shadowOffset = AKToastShadowOffset;
    }
    
    wrapperView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:AKToastOpacity];
    
    if (title != nil) {
        titleLabel = [self getCustomLabelWithText:title];
        titleLabel.frame = CGRectMake(0.0, 0.0, 300, 50);
    }
    
    if (message != nil) {
        messageLabel = [self getCustomLabelWithText:title];
        messageLabel.frame = CGRectMake(0.0, 50.0, 300, 50);
    }
    
    wrapperView.frame = CGRectMake(0.0, 0.0, 300, 100);
    
    if(titleLabel != nil) {
        [wrapperView addSubview:titleLabel];
    }
    
    if(messageLabel != nil) {
        [wrapperView addSubview:messageLabel];
    }
    
    return wrapperView;
}


@end

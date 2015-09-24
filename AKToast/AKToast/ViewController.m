//
//  ViewController.m
//  AKToast
//
//  Created by Arafat on 9/11/15.
//  Copyright (c) 2015 Arafat Khan. All rights reserved.
//

#import "ViewController.h"
#import "UIView+AKToastView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


#pragma mark - Actions
- (IBAction)messageWithTitle:(id)sender{
    
    [self.view AKToastWithMessage:@"AK Toast View" title:@"Hello!" duration:2.0 position:AKToastPositionNearToTop ];
}

@end

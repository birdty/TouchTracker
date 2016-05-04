//
//  BNRDrawViewController.m
//  TouchTracker
//
//  Created by Tyler Bird on 2/20/16.
//  Copyright (c) 2016 Big Nerd Ranch. All rights reserved.
//

#import "BNRDrawViewController.h"
#import "BNRDrawView.h"

@interface BNRDrawViewController ()

@end

@implementation BNRDrawViewController

-(void)loadView
{
    self.view = [[BNRDrawView alloc] initWithFrame:CGRectZero];
}

@end

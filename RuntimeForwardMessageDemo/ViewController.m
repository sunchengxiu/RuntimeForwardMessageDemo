//
//  ViewController.m
//  RuntimeForwardMessageDemo
//
//  Created by 孙承秀 on 2018/5/25.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import "ViewController.h"
#import "RCPerson.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    RCPerson *person = [RCPerson new];
    person.name = @"sun";
    person.address = @"dalian";
    [person performSelector:@selector(eat) withObject:nil];
    NSLog(@"%@--------%@",[person name],[person address]);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

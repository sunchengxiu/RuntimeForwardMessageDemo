//
//  ViewController.m
//  RuntimeForwardMessageDemo
//
//  Created by 孙承秀 on 2018/5/25.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import "ViewController.h"
#import "RCPerson.h"
#import "RCStudent.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    RCPerson *person = [RCPerson new];
    RCStudent *stu = [RCStudent new];
    person.name = @"sun";
    person.address = @"dalian";
    [person performSelector:@selector(eat) withObject:nil];
    [person performSelector:@selector(drinking:) withObject:@"coffe"];
    [stu performSelector:@selector(eating:) withObject:@"coke"];
    NSLog(@"%@--------%@",[person name],[person address]);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

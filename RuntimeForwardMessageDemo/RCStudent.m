//
//  RCStudent.m
//  RuntimeForwardMessageDemo
//
//  Created by 孙承秀 on 2018/5/27.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import "RCStudent.h"
#import "RCOneStudent.h"
#import "RCTwoStudent.h"
@implementation RCStudent

-(void)drinking:(NSString *)object{
    NSLog(@"i am student drinking-%@",object);
}
/**
 抛出一个方法签名
 
 */
-(NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector{
    NSString *selName = NSStringFromSelector(aSelector);
    if ([selName isEqualToString:@"eating:"]) {
        // 返回真正的方法签名，后面的forwardInvocation根据真正的方法签名去执行
        NSMethodSignature *sig = [NSMethodSignature signatureWithObjCTypes:"v@:@"];
        return sig;
    }
    return [super methodSignatureForSelector:aSelector];
}
/**
 真正的执行方法
 */
-(void)forwardInvocation:(NSInvocation *)anInvocation{
    NSString *selName = NSStringFromSelector([anInvocation selector]);
    if ([selName isEqualToString:@"eating:"]) {
        NSString *obj;
        [anInvocation getArgument:&obj atIndex:2];
        NSLog(@"arg is %@",obj);
        // 可以转发给多个对象来实现
        RCOneStudent *one = [RCOneStudent new];
        RCTwoStudent * two = [RCTwoStudent new];
        [anInvocation invokeWithTarget:one];
        [anInvocation invokeWithTarget:two];
    }
}
-(void)doesNotRecognizeSelector:(SEL)aSelector{
    [super doesNotRecognizeSelector:aSelector];
    NSLog(@"没找到");
}
@end

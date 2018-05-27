//
//  RCPerson.m
//  RuntimeForwardMessageDemo
//
//  Created by 孙承秀 on 2018/5/25.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import "RCPerson.h"
#import "RCStudent.h"
#import <objc/runtime.h>
static const char *runtimeKey ;
@implementation RCPerson
@dynamic name,address;
+(BOOL)resolveInstanceMethod:(SEL)sel{
    NSString *selName = NSStringFromSelector(sel);
    if ([selName hasPrefix:@"set"]) {
        class_addMethod(self, sel, (IMP)internalSetter, "v@:@");
        return YES;
    } else if([selName isEqualToString:@"eat"]){
        class_addMethod(self, sel, (IMP)internalEat, "v@:");
        return YES;
    } else if ([selName isEqualToString:@"drinking:"]){
        NSLog(@"drinking");
        return [super resolveInstanceMethod:sel];
    }
    else if ([selName isEqualToString:@"eating:"]){
        return [super resolveInstanceMethod:sel];
    }
    else {
        class_addMethod(self, sel, (IMP)internalGetter, "@@:");
        return YES;
    }
    return [super resolveInstanceMethod:sel];
}
#pragma mark --------- runtime 第三步 运行时补救未实现的方法 ----------
// 由Student展示

#pragma mark --------- runtime 第二步 运行时补救未实现的方法 ----------
/**
 将方法转发给别的对象实现,只能根据方法名转发给一个对象
 */
- (id)forwardingTargetForSelector:(SEL)aSelector{
    RCStudent *student = [RCStudent new];
    if ([student respondsToSelector:aSelector]) {
        return student;
    }
    return [super forwardingTargetForSelector:aSelector];
}
#pragma mark --------- runtime 第一步 运行时补救未实现的方法 ----------
static void internalEat(id self , SEL _cmd){
    NSLog(@"i am eating");
}
static id internalGetter(id self , SEL _cmd){
    NSMutableDictionary *values = getValues(self);
    NSString *selectorName = NSStringFromSelector(_cmd);
    return [values valueForKey:selectorName];
}
static void internalSetter(id self,SEL _cmd ,id value){
    NSString *setterName = NSStringFromSelector(_cmd);
    NSRange range = NSMakeRange(3, setterName.length - 4);
    NSString *fakeName = [setterName substringWithRange:range];
    NSString *first = [[fakeName substringToIndex:1] lowercaseString];
    NSString *second = [fakeName substringFromIndex:1];
    NSString *key = [NSString stringWithFormat:@"%@%@",first,second];
    NSMutableDictionary *values = (NSMutableDictionary *)getValues(self);
    if (value) {
        [values setObject:value forKey:key];
    }
}
static NSMutableDictionary *getValues(id self ){
    NSMutableDictionary *values = objc_getAssociatedObject(self, &runtimeKey);
    if (!values ) {
        values = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, &runtimeKey, values, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return values;
}
@end

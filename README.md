# Runtime 动态消息补救和转发（附 DEMO）


OBJC 是一门动态语言，当调用一个方法的时候，实际上是进行消息的转发，要想实现一个方法的实现，需要根据 `SEL` 和 `IMP`， `SEL`实际上是方法的函数名，好比门牌号一样，而真正的实现方法是由`IMP`来实现的，找到真正的地址去实现方法，就相当于我们的`implement`.

当我们发送一个消息的时候，在当前类和父类没有找到对象的方法的时候，消息转发流程开始，如果我们的方法没有对应的实现的时候，就会进行消息转发补救，主要分以下三类

1.动态方法解析：resolveInstanceMethod，此方法允许你告诉系统是否找到方法，可自行通过 `class_addMethod`来添加方法的实现

2.快速转发：forwardingTargetForSelector，允许你告诉系统此方法由哪个对象来实现，此方法只能返回一个对象，只能由一个对象来实现。

3.慢速转发：methodSignatureForSelector，此方法允许你返回一个和你调用的方法一样的方法签名，如果返回一个正确的方法签名，则 runtime 会根据签名返回一个 `NSInvocation`，通过`invokeWithTarget`,向对象发送消息，此方法可以发送给多个对象

## 动态方法解析（resolveInstanceMethod）

通过实例来解释动态方法解析，我们现实中都会遇到这样的问题，我们通过`property`生成一个属性的时候，系统会为我们动态生成`set`和`get`方法，加入我们有这样的需求，每次用户调用set方法的时候我们都进行存储，存储到数据库或者`userdefault`中，那么我们就需要在每个属性对应的方法里面写存储过程，多一个属性就需要多写，这样会造成代码冗余，我们可以完全通过runtime的方法，来动态转移方法的实现。

上面需求已经说完了，要完成上面的需求，就不能让系统为我们生成 `set` 和 `get` 方法，我们需要自己来实现，所以需要通过关键字`@dynamic`,来告诉系统不用你为我生成响应的方法，如果是这样的话，我们再调用 `person.name` `person.address`,就会报错，因为我们告诉系统不要为我们生成`set`和`get`方法，那应该怎么办呢，黑科技->runtime 动态方法的补救和转发

代码：

```
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
```


我们这里只看`internalSetter`和`internalGetter`的 if else 语句即可，其余下面会说到，上面什么意思呢，意思就是捕获到调用 `set`和`get`方法之类，动态通过`class_addMethod`添加一个方法，是不是很简单，方法的实现是一个 C 函数，可以看到 `class_addMethod` 的几个参数，和我前面说的是一样的，最重要的两个参数 `SEL` 和 `IMP`，一个是方法编号，一个是真正的方法实现，就可以满足我们的需求了，在那个 公共的 C 函数入口 做我们的事情就可以了，而后面的 `v@:@`是什么意思呢，函数默认都带有两个隐藏参数，`self`和`_cmd`，第一个 `v`的意思是返回值为 `void`，第二个`@`代表 ID 类型的`self`，第三个`:`代表方法`_cmd`,最后普一个`@`，代表函数的参数，是不是问题迎刃而解了。

## 快速转发（forwardingTargetForSelector）

下面我们调用 OBJC 的动态调用方法的函数，去动态的调用一个方法，这样就不会报错 ` [person performSelector:@selector(drinking:) withObject:@"coffe"];`,我们在 `person` 里面没有对该方法的生命和实现，文章后有 DEMO 可下载自己看，这个时候我们运行，会在运行时候崩溃，因为没有方法的实现，这个时候怎么做呢，用上面的动态方法解析探后添加一个方法是可以的，这里我们用另外一个方法，forwardingTargetForSelector，也很简单，快速妆发就是告诉系统这个方法有谁来实现，只能返回给一个对象

```
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

```

这里，我们将这个方法，直接转发给了 `student` 对象,这里的 `dringking`方法没有通过`class_addMethod`的方式来做。

## 慢速转发（methodSignatureForSelector，invokeWithTarget）

如果以上两个方法都没有补救，那么进行最后这一步，`methodSignatureForSelector `这个方法会返回一个方法签名，就是我上面讲到的`v@:@`这种签名，返回给系统，然后系统得到了一个方法签名，才会将消息继续向下转发

```


-(NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector{
    NSString *selName = NSStringFromSelector(aSelector);
    if ([selName isEqualToString:@"eating:"]) {
        // 返回真正的方法签名，后面的forwardInvocation根据真正的方法签名去执行
        NSMethodSignature *sig = [NSMethodSignature signatureWithObjCTypes:"v@:@"];
        return sig;
    }
    return [super methodSignatureForSelector:aSelector];
}


```

上面是返回方法签名


```

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

```

这里是方法的执行，可以看到这里可以讲方法转发给多个对象来实现



## DEMO

上面就是对 runtime 动态消息补救和转发的简单解释，这里是 [DEMO](https://github.com/sunchengxiu/RuntimeForwardMessageDemo.git) 
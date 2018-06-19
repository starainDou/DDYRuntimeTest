# DDYRuntimeTest


> ## Runtime简介

![Sheep.png](http://upload-images.jianshu.io/upload_images/1465510-b933722b93f9a07e.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

> #### runtime是什么（原理）
runtime是一套比较底层的纯C语言API, 属于1个C语言库, 包含了很多底层的C语言API。
在我们平时编写的OC代码中, 程序运行过程时, 其实最终都是转成了runtime的C语言代码, runtime算是OC的幕后工作者

> #### 发送消息(消息机制)

```
// 方法调用的本质，就是让对象发送消息，使用消息机制前提，必须导入#import <objc/message.h>
// 对象方法
Person *person = [[Person alloc] init];
[person eat];
 //就是让实例对象发送消息 objc_msgSend(person, @selector(eat));

// 类方法
[Person run];
// 等价   [[Person class] run];
// 就是让类对象发送消息 objc_msgSend([Person class], @selector(run));
```

可以新建一个类MyClass证明

```
#import "MyClass.h"
@implementation MyClass
-(instancetype)init{
    if (self = [super init]) {
        [self showUserName];
    }
    return self;
}
-(void)showUserName{
    NSLog(@"Dave Ping");
}

```

然后使用clang重写命令

``` clang -rewrite-objc MyClass.m ```

得到MyClass.cpp文件

```
static instancetype _I_MyClass_init(MyClass * self, SEL _cmd) {
    if (self = ((MyClass *(*)(__rw_objc_super *, SEL))(void *)objc_msgSendSuper)((__rw_objc_super){(id)self, (id)class_getSuperclass(objc_getClass("MyClass"))}, sel_registerName("init"))) {
        ((void (*)(id, SEL))(void *)objc_msgSend)((id)self, sel_registerName("showUserName"));
    }
    return self;
}
```

> #### 消息转发

当[person eat];时如果ea方法不存在，会报经典错误 unrecognized selector sent to instance，此时用消息转发解决
消息转发机制三个步骤（方案）： 动态方法解析，备用接受者，完整转发

方法在调用时，系统会查看这个对象能否接收这个消息（查看这个类有没有这个方法，或有没有实现这个方法。），如果不能且只在不能的情况下，就会调用下面这几个方法，给你“补救”的机会，先理解为几套防止程序crash的备选方案，我们就是利用这几个方案进行消息转发，注意一点，前一套方案实现后一套方法就不会执行。如果这几套方案你都没有做处理，那么程序就会报错crash。

方案一：动态方法解析

```
+ (BOOL)resolveInstanceMethod:(SEL)sel;
+ (BOOL)resolveClassMethod:(SEL)sel;
```

方案二：备用接收者

```
- (id)forwardingTargetForSelector:(SEL)aSelector;
```

方案三：完整转发

```
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector;
- (void)forwardInvocation:(NSInvocation *)anInvocation;
```

详解：

新建一个Person的类，定义两个未实现的方法：

```
@interface Person : NSObject
- (void)eat;
+ (Person *)run;
@end
```

1.动态方法解析
对象在接收到未知的消息时，首先会调用所属类的类方法+resolveInstanceMethod:(实例方法)或+resolveClassMethod:(类方法)。在这个方法中，我们有机会为该未知消息新增一个”处理方法”“。不过使用该方法的前提是我们已经实现了该”处理方法”，只需要在运行时通过class_addMethod函数动态添加到类里面就可以了。

```
void functionForMethod(id self, SEL _cmd) {
 NSLog(@"%@:%s", self, sel_getName(_cmd));
}

Class functionForClassMethod(id self, SEL _cmd) {
 NSLog(@"%@:%s", self, sel_getName(_cmd));
 return [Person class];
}

+ (BOOL)resolveClassMethod:(SEL)sel {
NSLog(@"resolveClassMethod");
NSString *selString = NSStringFromSelector(sel);
if ([selString isEqualToString:@"run"]) {
Class metaClass = objc_getMetaClass("Person");
// 动态添加方法
class_addMethod(metaClass, @selector(run), (IMP)functionForClassMethod, "v@:");
return YES;
}
return [super resolveClassMethod:sel];
}

+ (BOOL)resolveInstanceMethod:(SEL)sel {
NSLog(@"resolveInstanceMethod");
if (sel == @selector(eat)) {
class_addMethod(self, sel, (IMP)functionForMethod, "v@:");
return YES;
}
return [super resolveInstanceMethod:sel];
}
```

2备用接受者
动态方法解析无法处理消息，则会走备用接受者。这个备用接受者只能是一个新的对象，不能是self本身，否则就会出现无限循环。如果我们没有指定相应的对象来处理aSelector，则应该调用父类的实现来返回结果。

```
@interface Dog : NSObject
- (void)eat;
@end

@implementation Dog
- (void)eat {
 NSLog(@"%@, %p", self, _cmd);
}
@end
```

```
- (id)forwardingTargetForSelector:(SEL)sel {
NSLog(@"forwardingTargetForSelector");
NSString *selectorString = NSStringFromSelector(aSelector);
// 将消息交给_helper来处理
if ([selectorString isEqualToString:@"eat"]) {
 return [[Dog alloc] init];
}
return [super forwardingTargetForSelector:aSelector];
}
```

3 完整转发

```
// 必须重写这个方法，消息转发机制的使用从这个方法中获取的信息来创建NSInvocation对象
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSString *sel = NSStringFromSelector(aSelector);
    if ([sel isEqualToString:@"eat"]) {
        return [NSMethodSignature signatureWithObjCTypes:"v@:"];
    }
    return [super methodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    SEL sel = [anInvocation selector];
    Dog *dog = [[Dog alloc] init];
    if ([dog respondsToSelector:sel]) {
        [anInvocation invokeWithTarget:dog];
    }
}
```


> #### KVC

KVC全称是Key Value Coding （键值编码），定义在NSKeyValueCoding.h文件中，是一个非正式协议。KVC提供了一种间接访问其属性方法或成员变量的机制，可以通过字符串来访问对应的属性方法或成员变量，KVO 就是基于 KVC 实现的关键技术之一。
在[NSKeyValueCoding](https://developer.apple.com/library/mac/#documentation/Cocoa/Reference/Foundation/Protocols/NSKeyValueCoding_Protocol/Reference/Reference.html#//apple_ref/occ/cat/NSKeyValueCoding)中提供了KVC通用的访问方法，分别是getter方法valueForKey:和setter方法setValue:forKey:，以及其衍生的keyPath方法，这两个方法各个类通用的。并且由KVC提供默认的实现，我们也可以自己重写对应的方法来改变实现。

KVC最典型的两个应用场景：
1，对私有变量进行赋值(setValue:forKey:)
2，字典转模型(如 [self setValuesForKeysWithDictionary:dict];)
但要注意
1，字典转模型时,字典中的某个key一定要在模型中有对应的属性，否则重写- setValue: forUndefinedKey:
2，如果一个模型中包含了另外的模型对象,是不能直接转化成功的。
3，通过kvc转化模型中的模型,也是不能直接转化成功的。

安全性检查

KVC存在一个问题在于，因为传入的key或keyPath是一个字符串，这样很容易写错或者属性自身修改后字符串忘记修改，这样会导致Crash。

可以利用iOS的[反射机制](https://www.jianshu.com/p/4fde3afcaf1a)来规避这个问题，通过@selector()获取到方法的SEL，然后通过NSStringFromSelector()将SEL反射为字符串。这样在@selector()中传入方法名的过程中，编译器会有合法性检查，如果方法不存在或未实现会报黄色警告。

[KVC原理剖析](http://www.cocoachina.com/ios/20180305/22441.html)

> #### KVO

KVO，即key-value-observing,利用一个key来找到某个属性并监听其值得改变。其实这也是一种典型的观察者模式。

KVO的用法

1，添加观察者
2，在观察者中实现监听方法，observeValueForKeyPath: ofObject: change: context:
3，移除观察者

KVO原理（底层实现）

KVO是基于runtime机制实现的，当一个类的属性被观察的时候，系统会通过runtime动态的创建一个该类的派生类NSKVONotifying_class，并且会在这个派生类中重写基类被观察的属性的setter方法，而且系统将这个类的isa指针指向了派生类，从而实现了给监听的属性赋值时调用的是派生类的setter方法。重写的setter方法会在调用原setter方法前后，通知观察对象值得改变。
键值观察通知依赖于NSObject 的两个方法: willChangeValueForKey: 和 didChangevlueForKey:；在一个被观察属性发生改变之前， willChangeValueForKey:一定会被调用，这就 会记录旧的值。而当改变发生后，didChangeValueForKey:会被调用，继而 observeValueForKey:ofObject:change:context: 也会被调用

[KVC和KVO](https://www.jianshu.com/p/f1393d10109d)

> #### 方法交换（Method Swizzling 黑魔法）

方法交换实现的需求场景：自己创建了一个功能性的方法，在项目中多次被引用，当项目的需求发生改变时，要使用另一种功能代替这个功能，要求是不改变旧的项目(也就是不改变原来方法的实现)。

```
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    // 需求：给imageNamed方法提供功能，每次加载图片就判断下图片是否加载成功。
    // 步骤一：先搞个分类，定义一个能加载图片并且能打印的方法+ (instancetype)imageWithName:(NSString *)name;
    // 步骤二：交换imageNamed和imageWithName的实现，就能调用imageWithName，间接调用imageWithName的实现。
    UIImage *image = [UIImage imageNamed:@"123"];
}

@end

@implementation UIImage (Image)
// 加载分类到内存的时候调用
+ (void)load
{
    // 交换方法

    // 获取imageWithName方法地址
    Method imageWithName = class_getClassMethod(self, @selector(imageWithName:));

    // 获取imageWithName方法地址
    Method imageName = class_getClassMethod(self, @selector(imageNamed:));

    // 交换方法地址，相当于交换实现方式
    method_exchangeImplementations(imageWithName, imageName);
    // 实例方法 Method originalMethod = class_getInstanceMethod([self class], @selector(size));
}

// 不能在分类中重写系统方法imageNamed，因为会把系统的功能给覆盖掉，而且分类中不能调用super.

// 既能加载图片又能打印
+ (instancetype)imageWithName:(NSString *)name
{
    // 这里调用imageWithName，相当于调用imageName
    UIImage *image = [self imageWithName:name];

    if (image == nil) {
        NSLog(@"加载空的图片");
    }

    return image;
}
@end
```

交换方法的实现原理：

这还是要从方法调用的流程说起，
1，首先会获取当前对象的isa指针，然后去isa指向的类中查找，
2，根据传入的SEL找到对应方法名（函数入口）
3，然后去方法区直接调用函数实现

最优实现，防止子类中交换出现unrecognized selector sent to instance 0x...
[.](http://www.cocoachina.com/ios/20170703/19704.html)
```
Method originalMethod = class_getInstanceMethod([self class], @selector(setImage:));
    Method swizzleMethod = class_getInstanceMethod([self class], @selector(setMaskImage:));
    BOOL didAddMethod = class_addMethod([self class], @selector(setImage:), method_getImplementation(swizzleMethod), method_getTypeEncoding(swizzleMethod));
    if (didAddMethod) {
        class_replaceMethod([self class], @selector(setMaskImage:), method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    }else{
        method_exchangeImplementations(originalMethod, swizzleMethod);
    }
```


> #### 方法关联

1 给分类添加属性

```
// 定义关联的key
static const char *key = "name";

@implementation NSObject (Property)

- (NSString *)name
{
    // 根据关联的key，获取关联的值。
    return objc_getAssociatedObject(self, key);
}

- (void)setName:(NSString *)name
{
    // 第一个参数：给哪个对象添加关联
    // 第二个参数：关联的key，通过这个key获取
    // 第三个参数：关联的value
    // 第四个参数:关联的策略
    objc_setAssociatedObject(self, key, name, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
```

为category添加属性2

```
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface NSObject (CategoryWithProperty)
@property (nonatomic, strong) NSObject *property;
@end

@implementation NSObject (CategoryWithProperty)
- (NSObject *)property { 
return objc_getAssociatedObject(self, @selector(property));
}
- (void)setProperty:(NSObject *)value { 
objc_setAssociatedObject(self, @selector(property), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end
```

2 给对象添加关联对象


比如 ：我们想把更多的参数传给alertView代理
```
- (void)shopCartCell:(FFShopCartCell *)shopCartCell didDeleteClickedAtRecId:(NSString *)recId
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"确认删除" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
    
    // 传递多参数
    objc_setAssociatedObject(alert, "suppliers_id", @"1", OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(alert, "warehouse_id", @"2", OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    alert.tag = [recId intValue];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        
        NSString *warehouse_id = objc_getAssociatedObject(alertView, "warehouse_id");
        NSString *suppliers_id = objc_getAssociatedObject(alertView, "suppliers_id");
        NSString *recId = [NSString stringWithFormat:@"%ld",(long)alertView.tag];
    }
}
```

> #### 获取实例变量、属性、对象方法、类方法等

```
#pragma mark 获取一个类的属性列表
- (void)getPropertiesOfClass:(NSString *)classString {
    Class class = NSClassFromString(classString);
    unsigned int count = 0;
    objc_property_t *propertys = class_copyPropertyList(class, &count);
    for(int i = 0;i < count;i ++)
    {
        objc_property_t property = propertys[i];
        NSString *propertyName = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        NSLog(@"uialertion.property = %@",propertyName);
    }
}
#pragma mark 获取一个类的成员变量列表
- (void)getIvarListOfClass:(NSString *)classString {
    Class class = NSClassFromString(classString);
    unsigned int count = 0;
    Ivar *ivars = class_copyIvarList(class, &count);
    for(int i =0;i < count;i ++)
    {
        Ivar ivar = ivars[i];
        NSString *ivarName = [NSString stringWithCString:ivar_getName(ivar) encoding:NSUTF8StringEncoding];
        const char *type = ivar_getTypeEncoding(ivar);
        NSLog(@"uialertion.ivarName = %@   type = %s",ivarName,type);
    }
}

#pragma mark 获取一个类的所有方法
- (void)getMethodsOfClass:(NSString *)classString {
    Class class = NSClassFromString(classString);
    unsigned int count = 0;
    Method *methods = class_copyMethodList(class, &count);
    for (int i = 0; i < count; i++) {
        SEL sel = method_getName(methods[i]);
        NSLog(@"Methods = %@",NSStringFromSelector(sel));
    }
    
    free(methods);
}

#pragma mark 获取一个类的所有类方法
- (void)getClassMethodsOfClass:(NSString *)classString {
    Class class = NSClassFromString(classString);
    // Class class  = [NSString class];
    unsigned int count = 0;
    Method *classMethods = class_copyMethodList(objc_getMetaClass(class_getName(class)), &count);
    for (int i = 0; i < count; i++) {
        SEL sel = method_getName(classMethods[i]);
        NSLog(@"Class Methods = %@",NSStringFromSelector(sel));
    }
}

#pragma mark 获取协议列表
- (void)getProtocolsOfClass:(NSString *)classString {
    Class class = NSClassFromString(classString);
    unsigned int count;
    __unsafe_unretained Protocol **protocols = class_copyProtocolList(class, &count);
    for (unsigned int i = 0; i < count; i++) {
        const char *name = protocol_getName(protocols[i]);
        printf("Protocols = %s\n",name);
    }
}
```

> #### SEL、Method、IMP的含义及区别

在运行时，类（Class）维护了一个消息分发列表来解决消息的正确发送。每一个消息列表的入口是一个方法（Method），这个方法映射了一对键值对，其中键是这个方法的名字（SEL），值是指向这个方法实现的函数指针 implementation（IMP）。


> ##推荐

[西木 runtime完整总结](http://www.jianshu.com/p/6b905584f536)
[iOS-Runtime-Headers](https://github.com/nst/iOS-Runtime-Headers/)
[为什么object_getClass(obj)与[OBJ class]返回的指针不同](http://www.huangyibiao.com/archives/452)
[动手实现objc_msgSend](http://www.ting30.com/zy/2016/43440.html)
[Runtime对方法的操作](http://www.cnblogs.com/gugupluto/p/3159733.html)
[运行时简介](http://www.jianshu.com/p/6241032fbbe4)
[神经病院Objective-C Runtime住院第二天——消息发送与转发](https://www.jianshu.com/p/4d619b097e20)
[iOS面试题](http://www.cocoachina.com/ios/20180305/22453.html)
[Runtime Method Swizzling开发实例汇总](https://www.jianshu.com/p/f6dad8e1b848)
[Runtime 10种用法](https://www.jianshu.com/p/3182646001d1)
[Runtime知识点概括以及使用场景](https://blog.csdn.net/deft_mkjing/article/details/53789125)

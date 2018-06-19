#import "DDYRuntime.h"
#import <objc/runtime.h>

@implementation DDYRuntime

#pragma mark 获取一个类的属性列表
+ (NSArray *)getPropertiesOfClass:(NSString *)classString {
    Class class = NSClassFromString(classString);
    unsigned int count = 0;
    objc_property_t *propertys = class_copyPropertyList(class, &count);
    
    NSMutableArray *tempArray = [NSMutableArray array];
    for(int i = 0;i < count;i ++)
    {
        objc_property_t property = propertys[i];
        NSString *propertyName = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        NSLog(@"property = %@",propertyName);
        [tempArray addObject:[NSString stringWithFormat:@"property = %@",propertyName]];
    }
    return tempArray;
}
#pragma mark 获取一个类的成员变量列表
+ (NSArray *)getIvarListOfClass:(NSString *)classString {
    Class class = NSClassFromString(classString);
    unsigned int count = 0;
    Ivar *ivars = class_copyIvarList(class, &count);
    
    NSMutableArray *tempArray = [NSMutableArray array];
    for(int i =0;i < count;i ++)
    {
        Ivar ivar = ivars[i];
        NSString *ivarName = [NSString stringWithCString:ivar_getName(ivar) encoding:NSUTF8StringEncoding];
        const char *type = ivar_getTypeEncoding(ivar);
        NSLog(@"ivarName = %@   type = %s",ivarName,type);
        [tempArray addObject:[NSString stringWithFormat:@"ivarName = %@, type = %s", ivarName, type]];
    }
    return tempArray;
}

#pragma mark 获取一个类的所有方法
+ (NSArray *)getMethodsOfClass:(NSString *)classString {
    Class class = NSClassFromString(classString);
    unsigned int count = 0;
    Method *methods = class_copyMethodList(class, &count);
    
    NSMutableArray *tempArray = [NSMutableArray array];
    for (int i = 0; i < count; i++) {
        SEL sel = method_getName(methods[i]);
        NSLog(@"Methods = %@",NSStringFromSelector(sel));
        [tempArray addObject:[NSString stringWithFormat:@"Methods = %@", NSStringFromSelector(sel)]];
    }
    free(methods);
    return tempArray;
}

#pragma mark 获取一个类的所有类方法
+ (NSArray *)getClassMethodsOfClass:(NSString *)classString {
    Class class = NSClassFromString(classString);
    unsigned int count = 0;
    Method *classMethods = class_copyMethodList(objc_getMetaClass(class_getName(class)), &count);
    
    NSMutableArray *tempArray = [NSMutableArray array];
    for (int i = 0; i < count; i++) {
        SEL sel = method_getName(classMethods[i]);
        NSLog(@"Class Methods = %@",NSStringFromSelector(sel));
        [tempArray addObject:[NSString stringWithFormat:@"Class Methods = %@", NSStringFromSelector(sel)]];
    }
    return tempArray;
}

#pragma mark 获取协议列表
+ (NSArray *)getProtocolsOfClass:(NSString *)classString {
    Class class = NSClassFromString(classString);
    unsigned int count;
    __unsafe_unretained Protocol **protocols = class_copyProtocolList(class, &count);
    
    NSMutableArray *tempArray = [NSMutableArray array];
    for (unsigned int i = 0; i < count; i++) {
        const char *name = protocol_getName(protocols[i]);
        printf("Protocols = %s\n",name);
        [tempArray addObject:[NSString stringWithFormat:@"Protocols = %s", name]];
    }
    return tempArray;
}

@end

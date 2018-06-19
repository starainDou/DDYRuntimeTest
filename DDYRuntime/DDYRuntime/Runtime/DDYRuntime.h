//
//  DDYRuntime.h
//  DDYRuntime
//
//  Created by SmartMesh on 2018/6/19.
//  Copyright © 2018年 com.smartmesh. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DDYRuntime : NSObject

/** 获取一个类的属性列表 */
+ (NSArray *)getPropertiesOfClass:(NSString *)classString;

/** 获取一个类的成员变量列表 */
+ (NSArray *)getIvarListOfClass:(NSString *)classString;

/** 获取一个类的所有方法 */
+ (NSArray *)getMethodsOfClass:(NSString *)classString;

/** 获取一个类的所有类方法 */
+ (NSArray *)getClassMethodsOfClass:(NSString *)classString;

/** 获取协议列表 */
 + (NSArray *)getProtocolsOfClass:(NSString *)classString;

@end

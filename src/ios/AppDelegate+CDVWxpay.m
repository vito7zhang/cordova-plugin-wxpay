//
//  AppDelegate+CDVWxpay.m
//  wxPay
//
//  Created by vito7zhang on 2017/5/16.
//  Copyright © 2017年 vito7zhang. All rights reserved.
//

#import "AppDelegate+CDVWxpay.h"
#import <objc/runtime.h>
#import "CDVWxpay.h"

@implementation AppDelegate (CDVWxpay)


void swizzleMethod(Class c, SEL originalSelector){
    NSString *original = NSStringFromSelector(originalSelector);

    SEL swizzledSelector = NSSelectorFromString([@"swizzled_" stringByAppendingString:original]);
    SEL noopSelector = NSSelectorFromString([@"noop_" stringByAppendingString:original]);

    Method originalMethod, swizzledMethod, noop;
    originalMethod = class_getInstanceMethod(c, originalSelector);
    swizzledMethod = class_getInstanceMethod(c, swizzledSelector);
    noop = class_getInstanceMethod(c, noopSelector);

    BOOL didAddMethod = class_addMethod(c,
                                        originalSelector,
                                        method_getImplementation(swizzledMethod),
                                        method_getTypeEncoding(swizzledMethod));

    if (didAddMethod){
        class_replaceMethod(c,
                            swizzledSelector,
                            method_getImplementation(noop),
                            method_getTypeEncoding(originalMethod));
    }
    else{
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

+ (void)load{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class cls = [self class];

        swizzleMethod(cls, @selector(application:didFinishLaunchingWithOptions:));
        swizzleMethod(cls, @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:));
        swizzleMethod(cls, @selector(application:didReceiveRemoteNotification:));
    });
}

- (BOOL)swizzled_application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions{
    BOOL ret = [self swizzled_application:application didFinishLaunchingWithOptions:launchOptions];

    if (ret){
        NSString *appId = [self.viewController.settings objectForKey:@"wechatappid"];
        if (appId)
        {
            CDVWxpay *wxpayPlugin = [self.viewController getCommandInstance:@"Wxpay"];
            [wxpayPlugin registerApp:appId];
        }
    }

    return ret;
}


-(BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url{
    return [WXApi handleOpenURL:url delegate:[CDVWxpay sharePay]];
}

-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation{
    return [WXApi handleOpenURL:url delegate:[CDVWxpay sharePay]];
}

-(BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options{
    return [WXApi handleOpenURL:url delegate:[CDVWxpay sharePay]];
}

@end

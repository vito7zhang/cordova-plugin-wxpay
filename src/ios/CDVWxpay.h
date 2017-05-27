//
//  CDVWxpay.h
//  wxPay
//
//  Created by vito7zhang on 2017/5/16.
//  Copyright © 2017年 vito7zhang. All rights reserved.
//


#import <Cordova/CDV.h>
#import "WXApi.h"
#import "WXApiObject.h"

@interface CDVWxpay:CDVPlugin <WXApiDelegate>
+(id)sharePay;
@property (nonatomic, strong) NSString *currentCallbackId;
@property (nonatomic, strong) NSString *wechatAppId;

- (void)payment:(CDVInvokedUrlCommand *)command;
- (void)registerApp:(NSString *)wechatAppId;

@end

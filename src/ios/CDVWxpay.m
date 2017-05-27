//
//  CDVWxpay.m
//  wxPay
//
//  Created by vito7zhang on 2017/5/16.
//  Copyright © 2017年 vito7zhang. All rights reserved.
//

#import "CDVWxpay.h"


static CDVWxpay *wxpay = nil;

@implementation CDVWxpay



- (void)payment:(CDVInvokedUrlCommand *)command{
    [self.commandDelegate runInBackground:^{
        // check arguments
        NSDictionary *params = [command.arguments objectAtIndex:0];
        if (!params){
            [self failWithCallbackID:command.callbackId withMessage:@"参数格式错误"];
            return ;
        }
        NSString *appid = nil;
        NSString *noncestr = nil;
        NSString *package = nil;
        NSString *partnerid = nil;
        NSString *prepayid = nil;
        NSString *timestamp = nil;
        NSString *sign = nil;

        // check the params
        if (![params objectForKey:@"appid"]){
            [self failWithCallbackID:command.callbackId withMessage:@"appid参数错误"];
            return ;
        }
        appid = [params objectForKey:@"appid"];

        if (![params objectForKey:@"noncestr"]){
            [self failWithCallbackID:command.callbackId withMessage:@"noncestr参数错误"];
            return ;
        }
        noncestr = [params objectForKey:@"noncestr"];

        if (![params objectForKey:@"package"]){
            [self failWithCallbackID:command.callbackId withMessage:@"package参数错误"];
            return ;
        }
        package = [params objectForKey:@"package"];

        if (![params objectForKey:@"partnerid"]){
            [self failWithCallbackID:command.callbackId withMessage:@"partnerid参数错误"];
            return ;
        }
        partnerid = [params objectForKey:@"partnerid"];

        if (![params objectForKey:@"prepayid"]){
            [self failWithCallbackID:command.callbackId withMessage:@"prepayid参数错误"];
            return ;
        }
        prepayid = [params objectForKey:@"prepayid"];

        if (![params objectForKey:@"timestamp"]){
            [self failWithCallbackID:command.callbackId withMessage:@"timestamp参数错误"];
            return ;
        }
        timestamp = [params objectForKey:@"timestamp"];

        if (![params objectForKey:@"sign"]){
            [self failWithCallbackID:command.callbackId withMessage:@"sign参数错误"];
            return ;
        }
        sign = [params objectForKey:@"sign"];

        // 向微信注册
        [WXApi registerApp:appid];

        if (![WXApi isWXAppInstalled]) {
            [self failWithCallbackID:command.callbackId withMessage:@"未安装微信"];
            return;
        }

        PayReq *req = [[PayReq alloc] init];
        req.openID = appid;
        req.partnerId = partnerid;
        req.prepayId = prepayid;
        req.nonceStr = noncestr;
        req.timeStamp = timestamp.intValue;
        req.package = package;
        req.sign = sign;
        NSLog(@"req = %@",req);
        [WXApi sendReq:req];
        //日志输出
        NSLog(@"\nappid=%@\npartid=%@\nprepayid=%@\nnoncestr=%@\ntimestamp=%ld\npackage=%@\nsign=%@",req.openID,req.partnerId,req.prepayId,req.nonceStr,(long)req.timeStamp,req.package,req.sign );

        // save the callback id
        self.currentCallbackId = command.callbackId;

//        CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"调起成功"];
//
//        [self.commandDelegate sendPluginResult:commandResult callbackId:command.callbackId];
    }];
}

- (void)registerApp:(NSString *)wechatAppId{
    self.wechatAppId = wechatAppId;

    [WXApi registerApp:wechatAppId];

    NSLog(@"Register wechat app: %@", wechatAppId);
}

#pragma mark "WXApiDelegate"

/**
 * Not implemented
 */
- (void)onReq:(BaseReq *)req{
    NSLog(@"%@", req);
}

- (void)onResp:(BaseResp *)resp{
    BOOL success = NO;
    NSString *message = @"Unknown";

    switch (resp.errCode){
        case WXSuccess:
        success = YES;
        break;

        case WXErrCodeCommon:
        message = @"普通错误类型";
        break;

        case WXErrCodeUserCancel:
        message = @"用户点击取消并返回";
        break;

        case WXErrCodeSentFail:
        message = @"发送失败";
        break;

        case WXErrCodeAuthDeny:
        message = @"授权失败";
        break;

        case WXErrCodeUnsupport:
        message = @"微信不支持";
        break;
    }

    if (success){
        if ([resp isKindOfClass:[PayResp class]]){
            NSString *strMsg = [NSString stringWithFormat:@"支付结果：retcode = %d, retstr = %@", resp.errCode,resp.errStr];

            CDVPluginResult *commandResult = nil;

            if (resp.errCode == 0){
                commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:strMsg];
            }
            else{
                commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:strMsg];
            }

            [self.commandDelegate sendPluginResult:commandResult callbackId:self.currentCallbackId];
        }
        else{
            NSLog(@"回调不是支付类型");

            [self successWithCallbackID:self.currentCallbackId];
        }
    }
    else{
        [self failWithCallbackID:self.currentCallbackId withMessage:message];

    }
    NSLog(@"message = %@",message);
    self.currentCallbackId = nil;
}

#pragma mark "CDVPlugin Overrides"

- (void)handleOpenURL:(NSNotification *)notification{
    NSURL* url = [notification object];

    if ([url isKindOfClass:[NSURL class]] && [url.scheme isEqualToString:self.wechatAppId]){
        [WXApi handleOpenURL:url delegate:self];
    }
}

#pragma mark "Private methods"

- (NSData *)getNSDataFromURL:(NSString *)url{
    NSData *data = nil;

    if ([url hasPrefix:@"http://"] || [url hasPrefix:@"https://"]){
        data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
    }else if([url containsString:@"temp:"]){
        url =  [NSTemporaryDirectory() stringByAppendingPathComponent:[url componentsSeparatedByString:@"temp:"][1]];
        data = [NSData dataWithContentsOfFile:url];
    }
    else{
        // local file
        url = [[NSBundle mainBundle] pathForResource:[url stringByDeletingPathExtension] ofType:[url pathExtension]];
        data = [NSData dataWithContentsOfFile:url];
    }

    return data;
}

- (UIImage *)getUIImageFromURL:(NSString *)url{
    NSData *data = [self getNSDataFromURL:url];
    return [UIImage imageWithData:data];
}

- (void)successWithCallbackID:(NSString *)callbackID{
    [self successWithCallbackID:callbackID withMessage:@"OK"];
}

- (void)successWithCallbackID:(NSString *)callbackID withMessage:(NSString *)message{
    CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:message];
    [self.commandDelegate sendPluginResult:commandResult callbackId:callbackID];
}

- (void)failWithCallbackID:(NSString *)callbackID withError:(NSError *)error{
    [self failWithCallbackID:callbackID withMessage:[error localizedDescription]];
}

- (void)failWithCallbackID:(NSString *)callbackID withMessage:(NSString *)message{
    CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:message];
    [self.commandDelegate sendPluginResult:commandResult callbackId:callbackID];
}



+(id)sharePay{
    static dispatch_once_t token;
    dispatch_once(&token,^{
        if(wxpay == nil){
            wxpay = [[CDVWxpay alloc]init];
        }
    } );
    return wxpay;
}
+(id)allocWithZone:(NSZone *)zone{
    @synchronized(self){
        if (!wxpay) {
            wxpay = [super allocWithZone:zone]; //确保使用同一块内存地址
            return wxpay;
        }
        return nil;
    }
}

- (id)copyWithZone:(NSZone *)zone{
    return wxpay;
}

@end

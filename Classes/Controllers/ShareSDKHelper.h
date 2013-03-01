//
// ShareSDKHelper
//
// Created by nick on 13-3-1.
// Copyright (c) 2012年 ToraySoft. All rights reserved.
// 



#import <Foundation/Foundation.h>


@interface ShareSDKHelper : NSObject

+ (void)shareWithUrl:(NSURL *)url title:(NSString *)title fromController:(UIViewController *)controller withView:(UIView *)view;

@end
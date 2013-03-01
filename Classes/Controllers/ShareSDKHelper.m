//
// ShareSDKHelper
//
// Created by nick on 13-3-1.
// Copyright (c) 2012年 ToraySoft. All rights reserved.
// 



#import <ShareSDK/ShareSDK.h>
#import "ShareSDKHelper.h"


@implementation ShareSDKHelper {

}
+ (void)shareWithUrl:(NSURL *)url title:(NSString *)title fromController:(UIViewController *)controller withView:(UIView *)view {
    NSString *content = [NSString stringWithFormat:@"%@ %@", title, url];
    id<ISSPublishContent> publishContent = [ShareSDK publishContent:content
                                                     defaultContent:@""
                                                              image:nil
                                                       imageQuality:0.8
                                                          mediaType:SSPublishContentMediaTypeNews
                                                              title:title
                                                                url:[url absoluteString]
                                                       musicFileUrl:nil
                                                            extInfo:nil
                                                           fileData:nil];

    //定制微信好友内容
    [publishContent addWeixinSessionUnitWithType:INHERIT_VALUE
                                         content:[url absoluteString]
                                           title:INHERIT_VALUE
                                             url:INHERIT_VALUE
                                           image:INHERIT_VALUE
                                    imageQuality:INHERIT_VALUE
                                    musicFileUrl:INHERIT_VALUE
                                         extInfo:INHERIT_VALUE
                                        fileData:INHERIT_VALUE];

    //定制微信朋友圈内容
    [publishContent addWeixinTimelineUnitWithType:[NSNumber numberWithInteger:SSPublishContentMediaTypeMusic]
                                          content:[url absoluteString]
                                            title:INHERIT_VALUE
                                              url:INHERIT_VALUE
                                            image:INHERIT_VALUE
                                     imageQuality:INHERIT_VALUE
                                     musicFileUrl:nil
                                          extInfo:nil
                                         fileData:nil];

    //定制QQ分享内容
    [publishContent addQQUnitWithType:INHERIT_VALUE
                              content:[url absoluteString]
                                title:INHERIT_VALUE
                                  url:INHERIT_VALUE
                                image:INHERIT_VALUE
                         imageQuality:INHERIT_VALUE];

    //定制邮件分享内容
    [publishContent addMailUnitWithSubject:INHERIT_VALUE
                                   content:[url absoluteString]
                                    isHTML:[NSNumber numberWithBool:YES]
                               attachments:INHERIT_VALUE];

    //定制短信分享内容
    [publishContent addSMSUnitWithContent:INHERIT_VALUE];

    //定制有道云笔记分享内容
    [publishContent addYouDaoNoteUnitWithContent:INHERIT_VALUE
                                           title:INHERIT_VALUE
                                          author:@"StarupNews"
                                          source:@"http://news.dbanotes.net/"
                                     attachments:INHERIT_VALUE];

    [ShareSDK showShareActionSheet:controller
            iPadContainer:[ShareSDK iPadShareContainerWithView:view arrowDirect:UIPopoverArrowDirectionUp]
                     //iPadContainer:nil
                         shareList:nil
                           content:publishContent
                     statusBarTips:YES
                        convertUrl:YES      //委托转换链接标识，YES：对分享链接进行转换，NO：对分享链接不进行转换，为此值时不进行回流统计。
                       authOptions:nil
                  shareViewOptions:[ShareSDK defaultShareViewOptionsWithTitle:@"内容分享"
                                                              oneKeyShareList:[NSArray defaultOneKeyShareList]
                                                               qqButtonHidden:NO
                                                        wxSessionButtonHidden:NO
                                                       wxTimelineButtonHidden:NO
                                                         showKeyboardOnAppear:YES]
                            result:^(ShareType type, SSPublishContentState state, id<ISSStatusInfo> statusInfo, id<ICMErrorInfo> error, BOOL end) {
                                if (state == SSPublishContentStateSuccess)
                                {
                                    NSLog(@"分享成功");
                                }
                                else if (state == SSPublishContentStateFail)
                                {
                                    NSLog(@"分享失败,错误码:%d,错误描述:%@", [error errorCode], [error errorDescription]);
                                }
                            }];
}


@end
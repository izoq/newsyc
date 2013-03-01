//
//  AppDelegate.m
//  newsyc
//
//  Created by Grant Paul on 3/3/11.
//  Copyright 2011 Xuzz Productions, LLC. All rights reserved.
//

#import <ShareSDK/ShareSDK.h>
#import <QQApi/QQApi.h>

#import "AppDelegate.h"
#import "SessionListController.h"
#import "MainTabBarController.h"

#import "SubmissionListController.h"
#import "SearchController.h"
#import "SessionProfileController.h"
#import "BrowserController.h"
#import "MoreController.h"
#import "EmptyController.h"


#import "UINavigationItem+MultipleItems.h"
#import "WXApi.h"

@implementation UINavigationController (AppDelegate)

- (BOOL)controllerBelongsOnLeft:(UIViewController *)controller {
    return [controller isKindOfClass:[MainTabBarController class]]
            || [controller isKindOfClass:[SessionListController class]]
            || [controller isKindOfClass:[SearchController class]]
            || [controller isKindOfClass:[ProfileController class]]
            || [controller isKindOfClass:[MoreController class]]
            || [controller isKindOfClass:[SubmissionListController class]];
}

- (BOOL)controllerRequiresClearing:(UIViewController *)controller {
    return [controller isKindOfClass:[SessionListController class]];
}

- (void)popToController:(UIViewController *)controller animated:(BOOL)animated {
    AppDelegate *delegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        if ([[self viewControllers] containsObject:controller]) {
            [delegate popBranchToViewController:controller animated:animated];
        } else if ([delegate leafContainsViewController:controller]) {
            [delegate popLeafToViewController:controller animated:animated];
        } else {
            [NSException raise:@"UINavigationControllerPopException" format:@"can't find where to pop"];
        }
    } else {
        [delegate popBranchToViewController:controller animated:animated];
    }
}

- (void)willShowController:(UIViewController *)controller animated:(BOOL)animated {
    AppDelegate *delegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        if ([self controllerRequiresClearing:controller]) {
            [delegate clearLeafViewControllerAnimated:animated];
        }
    }
}

- (void)pushController:(UIViewController *)controller animated:(BOOL)animated {
    AppDelegate *delegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        if ([self presentingViewController] == nil) {
            if ([self controllerBelongsOnLeft:controller]) {
                [delegate pushBranchViewController:controller animated:animated];
            } else if ([self controllerBelongsOnLeft:[self topViewController]]) {
                [delegate setLeafViewController:controller animated:animated];
            } else {
                [delegate pushLeafViewController:controller animated:animated];
            }
        } else {
            if (![self controllerBelongsOnLeft:controller]) {
                if ([[self presentingViewController] presentingViewController] != nil && [[self presentingViewController] isKindOfClass:[UINavigationController class]]) {
                    // If we are a double-stacked modal controller, push on the bottom controller.
                    UINavigationController *presenting = (UINavigationController *) [self presentingViewController];
                    [presenting pushViewController:controller animated:animated];
                } else {
                    [delegate pushLeafViewController:controller animated:animated];
                }

                [self dismissViewControllerAnimated:animated completion:NULL];
            } else {
                [self pushViewController:controller animated:animated];
            }
        }
    } else {
        [delegate pushBranchViewController:controller animated:animated];
    }
}

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [WXApi registerApp:@"wx952197dea896a89f"];
    [QQApi registerPluginWithId:@"QQ075BCD15"];
    [ShareSDK registerApp:@"7a3cc705ac"];

    //横屏设置
    [ShareSDK setInterfaceOrientationMask:UIInterfaceOrientationMaskLandscape];

    //监听用户信息变更
    [ShareSDK addNotificationWithName:SSN_USER_INFO_UPDATE target:self
                               action:@selector(userInfoUpdateHandler:)];

    window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    HNSessionController *sessionController = [HNSessionController sessionController];
    NSArray *sessions = [sessionController sessions];
    HNSession *recentSession = [sessionController recentSession];

    if (recentSession == nil && [sessions count] == 1) {
        recentSession = [sessions lastObject];
    }

    SessionListController *sessionListController = [[SessionListController alloc] init];
    [sessionListController setAutomaticDisplaySession:recentSession];
    [sessionListController autorelease];

    navigationController = [[NavigationController alloc] initWithRootViewController:sessionListController];
    [navigationController setLoginDelegate:sessionListController];
    [navigationController setDelegate:self];
    [navigationController autorelease];

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [window setRootViewController:navigationController];

        [HNObjectBodyRenderer setDefaultFontSize:13.0f];
    } else if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        rightNavigationController = [[NavigationController alloc] init];
        [rightNavigationController setLoginDelegate:sessionListController];
        [rightNavigationController setDelegate:self];
        [rightNavigationController autorelease];

        [self clearLeafViewControllerAnimated:NO];

        splitController = [[SplitViewController alloc] init];
        [splitController setViewControllers:[NSArray arrayWithObjects:navigationController, rightNavigationController, nil]];
        if ([splitController respondsToSelector:@selector(setPresentsWithGesture:)])
            [splitController setPresentsWithGesture:YES];
        [splitController setDelegate:self];
        [splitController autorelease];

        [window setRootViewController:splitController];

        [HNObjectBodyRenderer setDefaultFontSize:16.0f];
    } else {
        NSAssert(NO, @"Invalid Device Type");
    }

    [window makeKeyAndVisible];

    [InstapaperSession logoutIfNecessary];
    [sessionController refresh];

    pingController = [[PingController alloc] init];
    [pingController setDelegate:self];
    [pingController ping];

    return YES;
}

#pragma mark - View Controllers

- (void)navigationController:(UINavigationController *)navigation willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [navigation willShowController:viewController animated:animated];
}

- (BOOL)splitViewController:(UISplitViewController *)svc shouldHideViewController:(UIViewController *)vc inOrientation:(UIInterfaceOrientation)orientation {
    return UIInterfaceOrientationIsPortrait(orientation);
}

- (void)splitViewController:(UISplitViewController *)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)pc {
    popoverItem = [barButtonItem retain];
    // XXX: work around navigation bar shrinking this button
    //[popoverItem setTitle:@"HN"];
    [popoverItem setTitle:@"SN"];
    popover = [pc retain];

    NSArray *controllers = [rightNavigationController viewControllers];
    if ([controllers count] > 0) {
        UIViewController *root = [controllers objectAtIndex:0];
        [[root navigationItem] addLeftBarButtonItem:popoverItem atPosition:UINavigationItemPositionLeft];
    }
}

- (void)splitViewController:(UISplitViewController *)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)button {
    NSArray *controllers = [rightNavigationController viewControllers];
    if ([controllers count] > 0) {
        UIViewController *root = [controllers objectAtIndex:0];
        [[root navigationItem] removeLeftBarButtonItem:popoverItem];
    }

    [popoverItem release];
    popoverItem = nil;
    [popover release];
    popover = nil;
}

- (void)splitViewController:(UISplitViewController *)svc popoverController:(UIPopoverController *)pc willPresentViewController:(UIViewController *)viewController {
    // XXX: workaround Apple bug causing the controller to stretch to fill
    // the entire screen after it unloads the view from a memory warning
    CGRect frame = [[viewController view] frame];
    frame.size.width = 320.0f;
    [[viewController view] setFrame:frame];
}

- (void)pushBranchViewController:(UIViewController *)branchController animated:(BOOL)animated {
    [navigationController pushViewController:branchController animated:animated];

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [[branchController navigationItem] setRightBarButtonItems:[[branchController navigationItem] leftBarButtonItems]];
        [[branchController navigationItem] setLeftBarButtonItems:nil];
    }
}

- (void)pushLeafViewController:(UIViewController *)leafController animated:(BOOL)animated {
    [rightNavigationController pushViewController:leafController animated:animated];
}

- (BOOL)leafContainsViewController:(UIViewController *)leafController {
    return [[rightNavigationController viewControllers] containsObject:leafController];
}

- (void)setLeafViewController:(UIViewController *)leafController animated:(BOOL)animated {
    [rightNavigationController setViewControllers:[NSArray arrayWithObject:leafController]];

    if (popoverItem != nil)
        [[leafController navigationItem] addLeftBarButtonItem:popoverItem atPosition:UINavigationItemPositionLeft];
    if (popover != nil)
        [popover dismissPopoverAnimated:animated];
}

- (void)clearLeafViewControllerAnimated:(BOOL)animated {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        EmptyController *emptyController = [[EmptyController alloc] init];
        if (popoverItem != nil)
            [[emptyController navigationItem] addLeftBarButtonItem:popoverItem atPosition:UINavigationItemPositionLeft];
        [rightNavigationController setViewControllers:[NSArray arrayWithObject:emptyController]];
        [emptyController release];
    }
}

- (void)popBranchToViewController:(UIViewController *)branchController animated:(BOOL)animated {
    [navigationController popToViewController:branchController animated:animated];
}

- (void)popLeafToViewController:(UIViewController *)leafController animated:(BOOL)animated {
    [rightNavigationController popToViewController:leafController animated:animated];
}

#pragma mark - Ping Controller

- (void)pingController:(PingController *)ping completedAcceptingURL:(NSURL *)url {
    BrowserController *browserController = [[BrowserController alloc] initWithURL:url];
    [navigationController pushController:browserController animated:YES];
    [browserController release];

    [pingController release];
    pingController = nil;
}

- (void)pingController:(PingController *)ping failedWithError:(NSError *)error {
    [pingController release];
    pingController = nil;
}

- (void)pingControllerCompletedWithoutAction:(PingController *)ping {
    [pingController release];
    pingController = nil;
}

#pragma mark - Application Lifecycle

- (void)applicationWillResignActive:(UIApplication *)application {

}

- (void)applicationDidEnterBackground:(UIApplication *)application {

}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [[NSUserDefaults standardUserDefaults] synchronize];

    [[HNSessionController sessionController] refresh];

    [InstapaperSession logoutIfNecessary];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {

}

- (void)applicationWillTerminate:(UIApplication *)application {

}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    return [ShareSDK handleOpenURL:url wxDelegate:self];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [ShareSDK handleOpenURL:url wxDelegate:self];
}

- (void)dealloc {
    [window release];
    [navigationController release];
    [rightNavigationController release];
    [splitController release];

    [super dealloc];
}

- (void)userInfoUpdateHandler:(NSNotification *)notif {
    NSMutableArray *authList = [NSMutableArray arrayWithContentsOfFile:[NSString stringWithFormat:@"%@/authListCache.plist", NSTemporaryDirectory()]];
    if (authList == nil) {
        authList = [NSMutableArray array];
    }

    NSString *platName = nil;
    NSInteger plat = [[[notif userInfo] objectForKey:SSK_PLAT] integerValue];
    switch (plat) {
        case ShareTypeSinaWeibo:
            platName = @"新浪微博";
            break;
        case ShareType163Weibo:
            platName = @"网易微博";
            break;
        case ShareTypeDouBan:
            platName = @"豆瓣";
            break;
        case ShareTypeFacebook:
            platName = @"Facebook";
            break;
        case ShareTypeKaixin:
            platName = @"开心网";
            break;
        case ShareTypeQQSpace:
            platName = @"QQ空间";
            break;
        case ShareTypeRenren:
            platName = @"人人网";
            break;
        case ShareTypeSohuWeibo:
            platName = @"搜狐微博";
            break;
        case ShareTypeTencentWeibo:
            platName = @"腾讯微博";
            break;
        case ShareTypeTwitter:
            platName = @"Twitter";
            break;
        case ShareTypeInstapaper:
            platName = @"Instapaper";
            break;
        case ShareTypeYouDaoNote:
            platName = @"有道云笔记";
            break;
        default:
            platName = @"未知";
    }
    id <ISSUserInfo> userInfo = [[notif userInfo] objectForKey:SSK_USER_INFO];

    BOOL hasExists = NO;
    for (int i = 0; i < [authList count]; i++) {
        NSMutableDictionary *item = [authList objectAtIndex:i];
        ShareType type = (ShareType) [[item objectForKey:@"type"] integerValue];
        if (type == plat) {
            [item setObject:[userInfo nickname] forKey:@"username"];
            hasExists = YES;
            break;
        }
    }

    if (!hasExists) {
        NSDictionary *newItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                             platName,
                                                             @"title",
                                                             [NSNumber numberWithInteger:plat],
                                                             @"type",
                                                             [userInfo nickname],
                                                             @"username",
                                                             nil];
        [authList addObject:newItem];
    }

    [authList writeToFile:[NSString stringWithFormat:@"%@/authListCache.plist", NSTemporaryDirectory()] atomically:YES];
}

@end

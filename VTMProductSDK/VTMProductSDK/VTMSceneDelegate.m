//
//  VTMSceneDelegate.m
//  VTMProductSDK
//

#import "VTMSceneDelegate.h"
#import "AppDelegate.h"
#import "SVProgressHUD.h"

@implementation VTMSceneDelegate

- (AppDelegate *)appDelegate {
    return (AppDelegate *)UIApplication.sharedApplication.delegate;
}

- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:UIWindowScene.class]) {
        return;
    }

    // `UISceneStoryboardFile = Main` makes UIKit instantiate the window and the
    // storyboard's initial controller before this callback. Keep AppDelegate.window
    // populated because the existing demo switches rootViewController through it.
    [self appDelegate].window = self.window;

    // SVProgressHUD creates and permanently caches its shared view here. It must run
    // after the scene window has been assigned; doing this in didFinishLaunching would
    // use a nil window and cache a zero-sized view.
    [SVProgressHUD setDefaultStyle:SVProgressHUDStyleDark];
    [self.window makeKeyAndVisible];
}

#pragma mark - Forward the existing AppDelegate lifecycle entry points

- (void)sceneWillResignActive:(UIScene *)scene {
    [[self appDelegate] applicationWillResignActive:UIApplication.sharedApplication];
}

- (void)sceneDidEnterBackground:(UIScene *)scene {
    [[self appDelegate] applicationDidEnterBackground:UIApplication.sharedApplication];
}

- (void)sceneWillEnterForeground:(UIScene *)scene {
    [[self appDelegate] applicationWillEnterForeground:UIApplication.sharedApplication];
}

- (void)sceneDidBecomeActive:(UIScene *)scene {
    [[self appDelegate] applicationDidBecomeActive:UIApplication.sharedApplication];
}

@end

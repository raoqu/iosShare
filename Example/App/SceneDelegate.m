#import "SceneDelegate.h"
#import "ViewController.h"
// TODO: Uncomment after completing Swift setup
// #import "XExtensionItemExample-Swift.h"

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:[UIWindowScene class]]) {
        return;
    }
    
    UIWindowScene *windowScene = (UIWindowScene *)scene;
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
    
    // TODO: Replace with ContentViewController after completing Swift setup
    // ContentViewController *contentViewController = [[ContentViewController alloc] init];
    // UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:contentViewController];
    
    // Temporary: Using old ViewController until Swift setup is complete
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[[ViewController alloc] init]];
    
    self.window.rootViewController = navigationController;
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
}

- (void)sceneDidDisconnect:(UIScene *)scene {
    // Called as the scene is being released by the system.
}

- (void)sceneDidBecomeActive:(UIScene *)scene {
    // Called when the scene has moved from an inactive state to an active state.
}

- (void)sceneWillResignActive:(UIScene *)scene {
    // Called when the scene will move from an active state to an inactive state.
}

- (void)sceneWillEnterForeground:(UIScene *)scene {
    // Called as the scene transitions from the background to the foreground.
}

- (void)sceneDidEnterBackground:(UIScene *)scene {
    // Called as the scene transitions from the foreground to the background.
}

@end

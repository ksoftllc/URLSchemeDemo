//
//  AppDelegate.m
//  UrlSchemeDemo
//
//  Created by Chuck Krutsinger on 6/21/17.
//  Copyright © 2017 Countermind Ventures, LLC. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    if (![launchOptions objectForKey:UIApplicationLaunchOptionsURLKey])
    {
        UIAlertController * alert=   [UIAlertController
                                      alertControllerWithTitle:@"Info"
                                      message:@"App launched directly without URL"
                                      preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Ok"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * _Nonnull action) {
                                                    //
                                                }]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
        });
    }
    return YES;
}

-(BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
    BOOL allowURL = [[options objectForKey:UIApplicationOpenURLOptionsSourceApplicationKey] hasPrefix:@"com.countermind.miclinic.webiz"];
    
    if (allowURL)
    {
        NSDictionary* parameters = [self parametersDictionaryFromQuery:[url query]];
        NSString* aUrlInfo = [NSString stringWithFormat:@"url:\n%@\n\nscheme:\n%@\n\nusername:\n%@\n\npassword:\n%@\n\nhost: %@\n\nparameters:\n%@"
                              ,[url description]
                              ,[url scheme]
                              ,[url user] //encrypted
                              ,[url password] //encrypted
                              ,[url host]
                              ,parameters];
        UIAlertController * alert=   [UIAlertController
                                      alertControllerWithTitle:nil
                                      message:aUrlInfo
                                      preferredStyle:UIAlertControllerStyleAlert];
        
        NSURL* aCallbackUrl = nil;
        NSString* aCallbackProvided = [parameters objectForKey:@"callback"];
        if (aCallbackProvided)
        {
            aCallbackUrl = [NSURL URLWithString:aCallbackProvided];
        }
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Ok"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * _Nonnull action) {
                                                    if (aCallbackUrl)
                                                    {
                                                        [[UIApplication sharedApplication] openURL:aCallbackUrl
                                                                                           options:@{}
                                                                                 completionHandler:^(BOOL success) {
                                                                                     NSLog(@"Opened %@", aCallbackUrl);
                                                                                 }];

                                                    }
                                                }]];
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
        });
    }
    
    return allowURL;
}

- (NSDictionary*)parametersDictionaryFromQuery:(NSString*)tQuery
{
    NSMutableDictionary* queryDict = [NSMutableDictionary new];
    NSArray* queryComponents = [tQuery componentsSeparatedByString:@"&"];
    for (NSString* pair in queryComponents)
    {
        NSArray* elements = [pair componentsSeparatedByString:@"="];
        NSString* key = elements[0];
        NSString* val = elements[1];
        [queryDict setObject:val forKey:key];
    }
    return queryDict;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end

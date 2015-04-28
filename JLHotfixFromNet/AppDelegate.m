//
//  AppDelegate.m
//  JLHotfixFromNet
//
//  Created by Aimy on 4/28/15.
//  Copyright (c) 2015 aimy. All rights reserved.
//

#import "AppDelegate.h"

#import <dlfcn.h>
#import <mach-o/loader.h>
#import <mach-o/dyld.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    //lib path, also can download a dylib form net and store in disk
    NSString *libPath = [NSString stringWithFormat:@"%@/Lib/TestSO.framework",[[NSBundle mainBundle] bundlePath]];
    //use dlopen to load lib (only 64bit devices iOS7up OK)
    [self loadDylibFromDlopenWithPath:[libPath stringByAppendingPathComponent:@"TestSO"]];
    //use bundle to load lib (32bit and 64bit devices iOS7 OK)
    [self loadDylibFromBundlebWithPath:libPath];
    //new a class in lib
    NSObject *test = [NSClassFromString(@"TestClass") new];
    //call method
    [test performSelector:NSSelectorFromString(@"showTime")];
    
    return YES;
}

- (void)loadDylibFromBundlebWithPath:(NSString *)path
{
    NSError *error = nil;
    NSBundle *bundle = [NSBundle bundleWithPath:path];
    if ([bundle loadAndReturnError:&error]) {
        NSLog(@"bundle load framework success.");
    }
    else {
        NSLog(@"bundle load framework err:%@",error);
    }
    
    if ([bundle isLoaded]) {
        NSLog(@"loaded");
    }
    
    [bundle unload];
    
    if (![bundle isLoaded]) {
        NSLog(@"unloaded");
    }
    
    [bundle load];
    
    if ([bundle isLoaded]) {
        NSLog(@"loaded");
    }
}

- (void)loadDylibFromDlopenWithPath:(NSString *)path
{
    void *lib = NULL;
    lib = dlopen([path cStringUsingEncoding:NSUTF8StringEncoding], RTLD_NOW);
    if (lib) {
        NSLog(@"dlopen load framework success.");
    }
    else {
        NSLog(@"dlopen error: %s", dlerror());
    }
    
    dlclose(lib);
    
    lib = NULL;
}

@end

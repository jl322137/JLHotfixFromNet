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

#import "TestObject.h"

#import <AFNetworking.h>
#import <ZipArchive.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.

    NSString *downloadString = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/TestSO.framework.zip"];
    [[NSFileManager defaultManager] removeItemAtPath:downloadString error:nil];

    //switch to download lib from the network, default copy lib from main bundle for test
    BOOL useNet = NO;
    if (! useNet) {
        //lib path, also can download a dylib form net and store in disk
        [[NSFileManager defaultManager] copyItemAtPath:[NSString stringWithFormat:@"%@/Lib/TestSO.framework.zip",[[NSBundle mainBundle] bundlePath]] toPath:downloadString error:nil];
        [self unzipAndLoadLib:downloadString];
    }
    else {
        AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:nil];
        NSURLSessionDownloadTask *task = [manager downloadTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://localhost:3000/downloadlib/TestSO.framework.zip"]] progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
            return [NSURL URLWithString:downloadString];
        } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
            if (!error && filePath) {
                [self unzipAndLoadLib:filePath.relativePath];
            }
        }];
        
        [task resume];
    }
    
    return YES;
}

- (void)doTest:(NSURL *)fileUrl
{
    //fix crash
    TestObject *test = [TestObject new];
    [test willCrash];

    //get a new object
    NSObject *testClass = [NSClassFromString(@"TestClass") new];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [testClass performSelector:NSSelectorFromString(@"showTime")];
#pragma clang diagnostic pop

    //test storyboard
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Storyboard" bundle:[NSBundle bundleWithURL:fileUrl]];
    UIViewController *testStoryboardVC = [sb instantiateInitialViewController];
    [self.window.rootViewController presentViewController:testStoryboardVC animated:YES completion:nil];

    //get a new vc with res
    UIViewController *testVC = [[NSClassFromString(@"TestVC") alloc] initWithNibName:@"TestVC" bundle:[NSBundle bundleWithURL:fileUrl]];
    [testStoryboardVC presentViewController:testVC animated:YES completion:nil];
}

- (void)unzipAndLoadLib:(NSString *)filePath
{
    ZipArchive *za = [[ZipArchive alloc] init];
    // 1
    if ([za UnzipOpenFile:filePath]) {
        // 2
        BOOL ret = [za UnzipFileTo:[[NSFileManager defaultManager] URLForDirectory:NSLibraryDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil].relativePath overWrite: YES];
        if (NO == ret){
            return ;
        }

        [za UnzipCloseFile];

        // 3
        NSURL *fileUrl = [[NSURL alloc] initFileURLWithPath:[filePath substringToIndex:filePath.length - 4] isDirectory:YES];

        // 4
        dispatch_async(dispatch_get_main_queue(), ^{

            //use dlopen to load lib
            [self loadDylibFromDlopenWithPath:[fileUrl URLByAppendingPathComponent:@"TestSO"]];

            //use bundle to load lib
            [self loadDylibFromBundlebWithPath:fileUrl];

            //test
            [self doTest:fileUrl];
        });
    }
}

- (void)loadDylibFromBundlebWithPath:(NSURL *)path
{
    if (!path.isFileURL) {
        NSLog(@"is not a file path");
        return ;
    }

    NSError *error = nil;
    NSBundle *bundle = [NSBundle bundleWithURL:path];
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

- (void)loadDylibFromDlopenWithPath:(NSURL *)path
{
    void *lib = NULL;
    lib = dlopen([path.relativePath cStringUsingEncoding:NSUTF8StringEncoding], RTLD_NOW);
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

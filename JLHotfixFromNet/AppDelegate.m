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

#import <AFNetworking.h>
#import <ZipArchive.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    //lib path, also can download a dylib form net and store in disk
//    NSURL *libPath = [[NSURL alloc] initFileURLWithPath:[NSString stringWithFormat:@"%@/Lib/TestSO.framework",[[NSBundle mainBundle] bundlePath]] isDirectory:YES];
    //need more test
    //use bundle to load lib (32bit and 64bit devices iOS7 OK, prefer)
//    [self loadDylibFromDlopenWithPath:[libPath URLByAppendingPathComponent:@"TestSO"]];
    //use dlopen to load lib (only 64bit devices iOS7up OK)
//    [self loadDylibFromBundlebWithPath:libPath];
    //new a class in lib
//    NSObject *test = [NSClassFromString(@"TestClass") new];
//    //call method
//    [test performSelector:NSSelectorFromString(@"showTime")];
    
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:nil];
    NSURLSessionDownloadTask *task = [manager downloadTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://localhost:3000/downloadlib/TestSO.framework.zip"]] progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        NSURL *downloadURL = [[NSFileManager defaultManager] URLForDirectory:NSLibraryDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
        return [downloadURL URLByAppendingPathComponent:[response suggestedFilename]];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        if (!error && filePath) {
            ZipArchive *za = [[ZipArchive alloc] init];
            // 1
            if ([za UnzipOpenFile:filePath.relativePath]) {
                // 2
                BOOL ret = [za UnzipFileTo:filePath.relativePath overWrite: YES];
                if (NO == ret){
                    return ;
                }
                
                [za UnzipCloseFile];
                
                // 3
                NSURL *fileUrl = [[NSURL alloc] initFileURLWithPath:[filePath.relativePath substringToIndex:filePath.relativePath.length - 4] isDirectory:YES];
                
                // 4           
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self loadDylibFromDlopenWithPath:[fileUrl URLByAppendingPathComponent:@"TestSO"]];
//                    [self loadDylibFromBundlebWithPath:fileUrl];
                    NSObject *test = [NSClassFromString(@"TestClass") new];
                    [test performSelector:NSSelectorFromString(@"showTime")];
                });
            }
        }
    }];
    
    [task resume];
    
    return YES;
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
    lib = dlopen([path.absoluteString cStringUsingEncoding:NSUTF8StringEncoding], RTLD_NOW);
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

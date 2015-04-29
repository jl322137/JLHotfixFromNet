//
//  TestObjectFix.m
//  JLHotfixFromNet
//
//  Created by Aimy on 4/29/15.
//  Copyright (c) 2015 aimy. All rights reserved.
//

#import "TestObjectFix.h"

#import <objc/runtime.h>

@implementation TestObjectFix

+ (void)load
{
    Method origMethod = class_getInstanceMethod(NSClassFromString(@"TestObject"), NSSelectorFromString(@"willCrash"));
    if (!origMethod) {
        NSLog(@"original method %@ not found for class %@", NSStringFromSelector(NSSelectorFromString(@"willCrash")), NSClassFromString(@"TestObject"));
    }
    
    Method altMethod = class_getInstanceMethod(self, NSSelectorFromString(@"doNotCrash"));
    if (!altMethod) {
        NSLog(@"original method %@ not found for class %@", NSStringFromSelector(NSSelectorFromString(@"doNotCrash")), [self class]);
    }
    
    method_setImplementation(origMethod, class_getMethodImplementation(self, NSSelectorFromString(@"doNotCrash")));
    
    NSLog(@"load");
}

- (void)doNotCrash
{
    NSLog(@"overwrite crash method");
}

@end

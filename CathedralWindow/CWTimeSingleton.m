//
//  CWTimeSingleton.m
//  CathedralWindow
//
//  Created by Hendrik Demmer on 9/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CWTimeSingleton.h"

@interface CWTimeSingleton ()
{
    NSTimeInterval _time;
}
@end

@implementation CWTimeSingleton

+ (CWTimeSingleton *)sharedInstance
{
    static CWTimeSingleton * _sharedInstance;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!_sharedInstance)
            _sharedInstance = [[CWTimeSingleton alloc] init];
    });
    
    return _sharedInstance;
}

- (NSTimeInterval)currentTime
{
    return _time;
}

-(void)addTime:(NSTimeInterval)time
{
    _time+=time;
}

@end

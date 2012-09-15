//
//  CWTimeSingleton.h
//  CathedralWindow
//
//  Created by Hendrik Demmer on 9/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CWTimeSingleton : NSObject

+ (CWTimeSingleton*) sharedInstance;

- (NSTimeInterval)currentTime;
- (void)addTime:(NSTimeInterval)time;

@end

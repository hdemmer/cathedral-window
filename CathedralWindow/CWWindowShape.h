//
//  CWWindowShape.h
//  CathedralWindow
//
//  Created by Hendrik Demmer on 9/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <GLKit/GLKit.h>

@interface CWWindowShape : NSObject

- (BOOL) containsVertex:(CWVertex)vertex;
- (CWVertex) intersectLineFrom:(CWVertex)a to:(CWVertex)b;

@end

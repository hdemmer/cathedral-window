//
//  CWWindowShape.h
//  CathedralWindow
//
//  Created by Hendrik Demmer on 9/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <GLKit/GLKit.h>

typedef enum {
    CWWST_ROUND=0,
    CWWST_FIRST
} CWWindowShapeType;

typedef struct {
    float u;
    float v;
} CWIntersectResult;

@interface CWWindowShape : NSObject

@property (nonatomic, assign) float rotation;
@property (nonatomic, assign) CWWindowShapeType shapeType;

- (BOOL) containsPointU:(float)u V:(float)v;

- (CWIntersectResult) intersectLineFromU1:(float)u1 V1:(float)v1 toU2:(float)u2 V2:(float)v2;


- (CWVertex)intersectLineFrom:(CWVertex)a to:(CWVertex)b;
- (CWVertex)intersectLine2From:(CWVertex)a to:(CWVertex)b;


@end

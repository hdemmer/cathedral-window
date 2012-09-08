//
//  CWWindowShape.m
//  CathedralWindow
//
//  Created by Hendrik Demmer on 9/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CWWindowShape.h"

@implementation CWWindowShape
@synthesize rotation=_rotation;
@synthesize shapeType=_shapeType;

- (BOOL)containsVertex:(CWVertex)vertex
{
    float u = 2.0f*(vertex.x - 0.5f);
    float v = 2.0f*(vertex.y - 0.5f);
    
    if (self.shapeType == CWWST_ROUND)
    {    
        return sqrt(u*u+v*v)<0.8;
    } else if (self.shapeType = CWWST_FIRST)
    {
        GLKMatrix3 rot = GLKMatrix3MakeRotation(-M_PI_2-self.rotation, 0, 0, 1);
        
        GLKVector3 rotatedPoint = GLKMatrix3MultiplyVector3(rot, GLKVector3Make(u, v, 0));
        
        float excenter = 2;
        
        u = rotatedPoint.x;
        v = rotatedPoint.y;
                
        float d = sqrtf(u*u+(excenter-v)*(excenter-v));
        float a = atan2f((excenter-v), u);
        
        BOOL inSegment = (d>excenter-0.65)&&(d<excenter+0.65-fabsf((a-M_PI_2)))&&fabsf(a-M_PI_2)<M_PI/(13.5f - 0.6*(d - excenter));
        
        return inSegment || sqrtf(u*u+(0.65-v)*(0.65-v))<0.29 || sqrtf(u*u+(-0.5-v)*(-0.5-v))<0.4;
    }
    return NO;
}

// a must be contained, b must not
- (CWVertex)intersectLineFrom:(CWVertex)a to:(CWVertex)b withCounter:(int)iteration;
{
    CWVertex half = a;
    half.x = (a.x + b.x)*0.5f;
    half.y = (a.y + b.y)*0.5f;
    
    if (iteration > 10)
        return half;
    
    if ([self containsVertex:half])
    {
        return [self intersectLineFrom:half to:b withCounter:iteration+1];
    } else {
        return [self intersectLineFrom:a to:half withCounter:iteration+1];
    }
    
}

- (CWVertex)intersectLineFrom:(CWVertex)a to:(CWVertex)b
{
    if ([self containsVertex:a])
        return [self intersectLineFrom:a to:b withCounter:0];
    if ([self containsVertex:b])
        return [self intersectLineFrom:b to:a withCounter:0];
    
    return a;
}

@end

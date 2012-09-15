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

- (BOOL) containsPointU:(float)u V:(float)v
{
    u = 2.0f*(u - 0.5f);
    v = 2.0f*(v - 0.5f);
    
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
- (CWIntersectResult)intersectLineFromU1:(float)u1 V1:(float)v1 toU2:(float)u2 V2:(float)v2 withCounter:(int)iteration;
{
    float halfu = (u1 + u2)*0.5f;
    float halfv = (v1 + v2)*0.5f;
    
    if (iteration > 10)
    {
        CWIntersectResult result;
        result.u=halfu;
        result.v = halfv;
        return result;
    }
    
    if ([self containsPointU:halfu V:halfv])
    {
        return [self intersectLineFromU1:halfu V1:halfv toU2:u2 V2:v2 withCounter:iteration+1];
    } else {
        return [self intersectLineFromU1:u1 V1:v1 toU2:halfu V2:halfv withCounter:iteration+1];
    }
    
}

- (CWIntersectResult)intersectLineFromU1:(float)u1 V1:(float)v1 toU2:(float)u2 V2:(float)v2
{
    if ([self containsPointU:u1 V:v1])
        return [self intersectLineFromU1:u1 V1:v1 toU2:u2 V2:v2 withCounter:0];
    if ([self containsPointU:u2 V:v2])
        return [self intersectLineFromU1:u2 V1:v2 toU2:u1 V2:v1 withCounter:0];
    
    CWIntersectResult deflt;
    deflt.u=u1;
    deflt.v = v1;
    return deflt;
}


- (CWVertex)intersectLineFrom:(CWVertex)a to:(CWVertex)b
{
    CWIntersectResult result = [self intersectLineFromU1:a.x V1:a.y toU2:b.x V2:b.y];

    b.x=result.u;
    b.y=result.v;
    
    return b;
}

- (CWVertex)intersectLine2From:(CWVertex)a to:(CWVertex)b
{
    CWIntersectResult result = [self intersectLineFromU1:a.x2 V1:a.y2 toU2:b.x2 V2:b.y2];
    
    b.x2=result.u;
    b.y2=result.v;
    
    return b;
}


@end

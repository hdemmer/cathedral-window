//
//  CWWindowShape.m
//  CathedralWindow
//
//  Created by Hendrik Demmer on 9/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CWWindowShape.h"

@implementation CWWindowShape

- (BOOL)containsVertex:(CWVertex)vertex
{
    float u = 2.0f*(vertex.x - 0.5f);
    float v = 2.0f*(vertex.y - 0.5f);
    
    return sqrt(u*u+v*v)<1; 
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

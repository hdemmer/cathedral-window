//
//  CWTriangleProcessor.m
//  CathedralWindow
//
//  Created by Hendrik Demmer on 9/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CWTriangleProcessor.h"

@implementation CWTriangleProcessor

+ (CWTriangles)rejectTriangles:(CWTriangles)triangles withBlock:(CWTriangleRejectBlock)triangleRejectBlock
{
    CWTriangles result;
    result.numberOfVertices = 0;
    result.vertices = malloc(triangles.numberOfVertices * sizeof(CWVertex));
    
    for (int i = 0; i<triangles.numberOfVertices;i+=3)
    {
        BOOL reject = triangleRejectBlock(triangles.vertices[i], triangles.vertices[i+1], triangles.vertices[i+2]);
        
        if (!reject)
        {
            result.vertices[result.numberOfVertices] = triangles.vertices[i];
            result.vertices[result.numberOfVertices+1] = triangles.vertices[i+1];
            result.vertices[result.numberOfVertices+2] = triangles.vertices[i+2];
            
            result.numberOfVertices += 3;
            
        }
    }
    
    return result;
}

@end

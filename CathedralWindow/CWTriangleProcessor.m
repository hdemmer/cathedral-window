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

+ (CWTriangles)intersectTriangles:(CWTriangles)triangles withWindowShape:(CWWindowShape*)shape
{
    CWTriangles result;
    result.numberOfVertices = 0;
    result.vertices = malloc(triangles.numberOfVertices * sizeof(CWVertex)*3);
    
    for (int i = 0; i<triangles.numberOfVertices;i+=3)
    {
        CWVertex a = triangles.vertices[i];
        CWVertex b = triangles.vertices[i+1];
        CWVertex c = triangles.vertices[i+2];
        
        BOOL containsA = [shape containsVertex:a];
        BOOL containsB = [shape containsVertex:b];
        BOOL containsC = [shape containsVertex:c];
        
        if (containsA || containsB || containsC)
        {
            if (containsA && containsB && containsC)
            {
                // as is
                
                result.vertices[result.numberOfVertices] = a;
                result.vertices[result.numberOfVertices+1] = b;
                result.vertices[result.numberOfVertices+2] = c;
                
                result.numberOfVertices += 3;
            }
            
            if (containsA && !containsB && !containsC)
            {
                b = [shape intersectLineFrom:a to:b];
                c = [shape intersectLineFrom:a to:c];
                
                result.vertices[result.numberOfVertices] = a;
                result.vertices[result.numberOfVertices+1] = b;
                result.vertices[result.numberOfVertices+2] = c;
                
                result.numberOfVertices += 3;

            } else if (containsB && !containsA && !containsC)
            {
                a = [shape intersectLineFrom:b to:a];
                c = [shape intersectLineFrom:b to:c];
                
                result.vertices[result.numberOfVertices] = a;
                result.vertices[result.numberOfVertices+1] = b;
                result.vertices[result.numberOfVertices+2] = c;
                
                result.numberOfVertices += 3;

            } else if (containsC && !containsB && !containsA)
            {
                b = [shape intersectLineFrom:c to:b];
                a = [shape intersectLineFrom:c to:a];
                
                result.vertices[result.numberOfVertices] = a;
                result.vertices[result.numberOfVertices+1] = b;
                result.vertices[result.numberOfVertices+2] = c;
                
                result.numberOfVertices += 3;

            }
            
            if (containsA && containsB && !containsC)
            {
                CWVertex x = [shape intersectLineFrom:a to:c];
                CWVertex y = [shape intersectLineFrom:b to:c];
                
                result.vertices[result.numberOfVertices] = a;
                result.vertices[result.numberOfVertices+1] = b;
                result.vertices[result.numberOfVertices+2] = x;
                
                result.numberOfVertices += 3;

                result.vertices[result.numberOfVertices] = b;
                result.vertices[result.numberOfVertices+1] = x;
                result.vertices[result.numberOfVertices+2] = y;
                
                result.numberOfVertices += 3;

            } else if (!containsA && containsB && containsC)
            {
                CWVertex x = [shape intersectLineFrom:b to:a];
                CWVertex y = [shape intersectLineFrom:c to:a];
                
                result.vertices[result.numberOfVertices] = b;
                result.vertices[result.numberOfVertices+1] = c;
                result.vertices[result.numberOfVertices+2] = x;
                
                result.numberOfVertices += 3;
                
                result.vertices[result.numberOfVertices] = c;
                result.vertices[result.numberOfVertices+1] = x;
                result.vertices[result.numberOfVertices+2] = y;
                
                result.numberOfVertices += 3;
                
            } else if (containsA && !containsB && containsC)
            {
                CWVertex x = [shape intersectLineFrom:a to:b];
                CWVertex y = [shape intersectLineFrom:c to:b];
                
                result.vertices[result.numberOfVertices] = a;
                result.vertices[result.numberOfVertices+1] = c;
                result.vertices[result.numberOfVertices+2] = x;
                
                result.numberOfVertices += 3;
                
                result.vertices[result.numberOfVertices] = c;
                result.vertices[result.numberOfVertices+1] = x;
                result.vertices[result.numberOfVertices+2] = y;
                
                result.numberOfVertices += 3;
                
            }

            
        }
    }
    
    return result;
}

@end

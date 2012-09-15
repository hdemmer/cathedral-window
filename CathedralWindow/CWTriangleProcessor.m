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
        
        BOOL containsA = [shape containsPointU:a.x V:a.y];
        BOOL containsB = [shape containsPointU:b.x V:b.y];
        BOOL containsC = [shape containsPointU:c.x V:c.y];

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
        } else {
            // push through for animation
            
            CWVertex zero = a;
            zero.x = 0.5f;
            zero.y=0.5f;
            
            a = [shape intersectLineFrom:zero to:a];
            b = [shape intersectLineFrom:zero to:b];
            c = [shape intersectLineFrom:zero to:c];
            
            a.l1 = 1.0f; // hacked to pass through clip info
            
            
            result.vertices[result.numberOfVertices] = a;
            result.vertices[result.numberOfVertices+1] = b;
            result.vertices[result.numberOfVertices+2] = c;
            
            result.numberOfVertices += 3;

        }
    }
    
    return result;
}


+ (CWTriangles)intersectTriangles2:(CWTriangles)triangles withWindowShape:(CWWindowShape*)shape
{
    CWTriangles result;
    result.numberOfVertices = 0;
    result.vertices = malloc(triangles.numberOfVertices * sizeof(CWVertex)*3);
    
    for (int i = 0; i<triangles.numberOfVertices;i+=3)
    {
        CWVertex a = triangles.vertices[i];
        CWVertex b = triangles.vertices[i+1];
        CWVertex c = triangles.vertices[i+2];

        BOOL containsA1 = [shape containsPointU:a.x V:a.y];
        BOOL containsB1 = [shape containsPointU:b.x V:b.y];
        BOOL containsC1 = [shape containsPointU:c.x V:c.y];

        BOOL containsA = [shape containsPointU:a.x2 V:a.y2];
        BOOL containsB = [shape containsPointU:b.x2 V:b.y2];
        BOOL containsC = [shape containsPointU:c.x2 V:c.y2];
        
        if (containsA || containsB || containsC || containsA1 || containsB1 || containsC1)
        {
            if (containsA && containsB && containsC)
            {
                // as is
                
                result.vertices[result.numberOfVertices] = a;
                result.vertices[result.numberOfVertices+1] = b;
                result.vertices[result.numberOfVertices+2] = c;
                
                result.numberOfVertices += 3;
            }
            
            if (!containsA && !containsB && !containsC)
            {
                if (a.l1 != 1.0f)
                {
                // remove in animation
                
                CWVertex zero = a;
                zero.x2 = 0.5f;
                zero.y2=0.5f;
                                    
               a = [shape intersectLine2From:zero to:a];
                b = [shape intersectLine2From:zero to:b];
                c = [shape intersectLine2From:zero to:c];
                    
                    a.r2=0;
                    a.g2=0;
                    a.b2=0;
                    b.r2=0;
                    b.g2=0;
                    b.b2=0;
                    c.r2=0;
                    c.g2=0;
                    c.b2=0;

                result.vertices[result.numberOfVertices] = a;
                result.vertices[result.numberOfVertices+1] = b;
                result.vertices[result.numberOfVertices+2] = c;
                
                result.numberOfVertices += 3;
                }
            }
            
            if (containsA && !containsB && !containsC)
            {
                b = [shape intersectLine2From:a to:b];
                c = [shape intersectLine2From:a to:c];
                
                result.vertices[result.numberOfVertices] = a;
                result.vertices[result.numberOfVertices+1] = b;
                result.vertices[result.numberOfVertices+2] = c;
                
                result.numberOfVertices += 3;
                
            } else if (containsB && !containsA && !containsC)
            {
                a = [shape intersectLine2From:b to:a];
                c = [shape intersectLine2From:b to:c];
                
                result.vertices[result.numberOfVertices] = a;
                result.vertices[result.numberOfVertices+1] = b;
                result.vertices[result.numberOfVertices+2] = c;
                
                result.numberOfVertices += 3;
                
            } else if (containsC && !containsB && !containsA)
            {
                b = [shape intersectLine2From:c to:b];
                a = [shape intersectLine2From:c to:a];
                
                result.vertices[result.numberOfVertices] = a;
                result.vertices[result.numberOfVertices+1] = b;
                result.vertices[result.numberOfVertices+2] = c;
                
                result.numberOfVertices += 3;
                
            }
            
            if (containsA && containsB && !containsC)
            {
                CWVertex x = [shape intersectLine2From:a to:c];
                CWVertex y = [shape intersectLine2From:b to:c];
                
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
                CWVertex x = [shape intersectLine2From:b to:a];
                CWVertex y = [shape intersectLine2From:c to:a];
                
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
                CWVertex x = [shape intersectLine2From:a to:b];
                CWVertex y = [shape intersectLine2From:c to:b];
                
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

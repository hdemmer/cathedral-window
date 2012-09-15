//
//  CWTriangleProcessor.h
//  CathedralWindow
//
//  Created by Hendrik Demmer on 9/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CWWindowShape.h"

typedef BOOL (^CWTriangleRejectBlock)(CWVertex a, CWVertex b, CWVertex c);

@interface CWTriangleProcessor : NSObject

+ (CWTriangles) rejectTriangles:(CWTriangles)triangles withBlock:(CWTriangleRejectBlock) triangleRejectBlock;

+ (CWTriangles)intersectTriangles:(CWTriangles)triangles withWindowShape:(CWWindowShape*)shape;
+ (CWTriangles)intersectTriangles2:(CWTriangles)triangles withWindowShape:(CWWindowShape*)shape;
@end

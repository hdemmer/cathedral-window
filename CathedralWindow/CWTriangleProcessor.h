//
//  CWTriangleProcessor.h
//  CathedralWindow
//
//  Created by Hendrik Demmer on 9/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef BOOL (^CWTriangleRejectBlock)(CWVertex a, CWVertex b, CWVertex c);

@interface CWTriangleProcessor : NSObject

+ (CWTriangles) rejectTriangles:(CWTriangles)triangles withBlock:(CWTriangleRejectBlock) triangleRejectBlock;

@end

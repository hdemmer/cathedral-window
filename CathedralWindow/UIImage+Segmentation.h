//
//  UIImage+Segmentation.h
//  CathedralWindow
//
//  Created by Hendrik Demmer on 9/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

typedef struct {
    CWVertex *vertices;
    int numberOfVertices;
} CWSegmentationResult;

@interface UIImage (Segmentation)

- (CWSegmentationResult)segmentIntoTriangles;

@end

//
//  CWWindow.h
//  CathedralWindow
//
//  Created by Hendrik Demmer on 9/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <GLKit/GLKit.h>

#import "CWWindowShape.h"

#import "CWTimeSingleton.h"

@interface CWWindow : NSObject
{    
    GLuint _vertexArray;
    GLuint _vertexBuffer;

    GLuint _textures[2];
}

@property (nonatomic, assign) GLKVector3 origin;

@property (nonatomic, retain) UIImage * nextImage;
@property (nonatomic, retain) UIImage * currentImage;

- (BOOL) isBusy;

- (id)initWithOrigin:(GLKVector3)origin scale:(float)scale andWindowShape:(CWWindowShape*)shape;

- (void) pushImage:(UIImage*)image;

- (void) draw;

- (BOOL) containsPoint:(GLKVector3)point;

@end

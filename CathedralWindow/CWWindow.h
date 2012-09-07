//
//  CWWindow.h
//  CathedralWindow
//
//  Created by Hendrik Demmer on 9/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <GLKit/GLKit.h>


@interface CWWindow : NSObject
{    
    GLuint _vertexArray;
    GLuint _vertexBuffer;

    GLuint _texture;
}

@property (nonatomic, assign) GLKVector3 origin;

- (id)initWithImage:(UIImage*)image origin:(GLKVector3)origin;

- (void) draw;

- (void) tearDown;


@end

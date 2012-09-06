//
//  CWWindow.m
//  CathedralWindow
//
//  Created by Hendrik Demmer on 9/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CWWindow.h"

@interface CWWindow ()
{
    int _numVertices;
}
@end

@implementation CWWindow
@synthesize origin=_origin;

- (id)initWithImage:(UIImage *)image origin:(GLKVector3)origin
{
    self = [super init];
    
    if (self)
    {
        self.origin = origin;
        [self setupWithImage:image];
    }
    
    return self;
}


#define IMAGE_SIZE 256

#import "UIImage+Segmentation.h"

- (void) setupWithImage:(UIImage*)image
{
    // now setup the buffers
    
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    
    CWSegmentationResult result = [image segmentIntoTriangles];
    
    _numVertices = result.numberOfVertices;
    
    CWVertex * vertices = result.vertices;
    
    for (int i =0; i< _numVertices; i++)
    {
        vertices[i].x += -0.5 + self.origin.x;
        vertices[i].y += -0.5 + self.origin.y;
        vertices[i].z += self.origin.z;
    }
    
    glBufferData(GL_ARRAY_BUFFER, sizeof(CWVertex)*_numVertices, vertices, GL_STATIC_DRAW);

    // TODO: free
    
    // and finish
    
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, GL_FALSE, 24, 0);
    glEnableVertexAttribArray(ATTRIB_COLOR);
    glVertexAttribPointer(ATTRIB_COLOR, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(12));
    
    glBindVertexArrayOES(0);

}

- (void)draw
{
    glBindVertexArrayOES(_vertexArray);
    glDrawArrays(GL_TRIANGLES, 0, _numVertices);

}

- (void) tearDown
{
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);

}

@end

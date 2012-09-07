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
#import "CWTriangleProcessor.h"


- (void) setupWithImage:(UIImage*)image
{        
    // tex
    
    glGenTextures(1, &_texture);
    glBindTexture(GL_TEXTURE_2D, _texture);
    
    glTexParameteri(GL_TEXTURE_2D, GL_GENERATE_MIPMAP, GL_FALSE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST); 
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST); 
        
    // triangles
    
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);

    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    
    CWTriangles result = [image segmentIntoTriangles];
    
    CWTriangles newResult = [CWTriangleProcessor rejectTriangles:result withBlock:^BOOL(CWVertex a, CWVertex b, CWVertex c) {
        return sqrt(a.x*a.x + a.y*a.y)>1;
    }];
    
    free(result.vertices);
    result = newResult;
    
    _numVertices = result.numberOfVertices;
    
    CWVertex * vertices = result.vertices;
    
    for (int i =0; i< _numVertices; i+=3)
    {
        
    }

    
    for (int i =0; i< _numVertices; i++)
    {
        vertices[i].u = vertices[i].x;
        vertices[i].v = vertices[i].y;
        
        vertices[i].x += -0.5 + self.origin.x;
        vertices[i].y += -0.5 + self.origin.y;
        vertices[i].z += self.origin.z;
    }
    
    glBufferData(GL_ARRAY_BUFFER, sizeof(CWVertex)*_numVertices, vertices, GL_STATIC_DRAW);

    free(result.vertices);
    
    // and finish
    
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, GL_FALSE, 40, 0);
    glEnableVertexAttribArray(ATTRIB_COLOR);
    glVertexAttribPointer(ATTRIB_COLOR, 3, GL_FLOAT, GL_FALSE, 40, BUFFER_OFFSET(12));
    glEnableVertexAttribArray(ATTRIB_TEXCOORDS);
    glVertexAttribPointer(ATTRIB_TEXCOORDS, 4, GL_FLOAT, GL_FALSE, 40, BUFFER_OFFSET(24));
    
    glBindVertexArrayOES(0);

}

- (void)draw
{
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _texture);
    glBindVertexArrayOES(_vertexArray);
    glDrawArrays(GL_TRIANGLES, 0, _numVertices);

}

- (void) tearDown
{
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);

}

@end

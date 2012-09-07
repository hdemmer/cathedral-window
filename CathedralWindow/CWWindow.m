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
@property (nonatomic,strong) CWWindowShape*windowShape;
@end

@implementation CWWindow
@synthesize origin=_origin;
@synthesize windowShape=_windowShape;

- (id)initWithImage:(UIImage *)image origin:(GLKVector3)origin andWindowShape:(CWWindowShape *)shape
{
    self = [super init];
    
    if (self)
    {
        self.origin = origin;
        self.windowShape = shape;
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
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR); 
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR); 
        
    // triangles
    
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);

    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    
    CWTriangles result = [image segmentIntoTriangles];
    
    CWTriangles newResult = [CWTriangleProcessor intersectTriangles:result withWindowShape:self.windowShape];
    free(result.vertices);
    result = newResult;

/*    
    CWTriangles newResult = [CWTriangleProcessor rejectTriangles:result withBlock:^BOOL(CWVertex a, CWVertex b, CWVertex c) {
        return sqrt(a.x*a.x + a.y*a.y)>1;
    }];
    
    free(result.vertices);
    result = newResult;
  */  
    _numVertices = result.numberOfVertices;
    
    CWVertex * vertices = result.vertices;
    
    // set local coordinates
    for (int i =0; i< _numVertices; i+=3)
    {
        vertices[i].l1 = 1;
        vertices[i].l2 = 0;
        vertices[i].l3 = 0;

        vertices[i+1].l1 = 0;
        vertices[i+1].l2 = 1;
        vertices[i+1].l3 = 0;

        vertices[i+2].l1 = 0;
        vertices[i+2].l2 = 0;
        vertices[i+2].l3 = 1;
    }

    // translate and tex coords
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
    glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, GL_FALSE, 48, 0);
    glEnableVertexAttribArray(ATTRIB_COLOR);
    glVertexAttribPointer(ATTRIB_COLOR, 3, GL_FLOAT, GL_FALSE, 48, BUFFER_OFFSET(12));
    glEnableVertexAttribArray(ATTRIB_TEXCOORDS);
    glVertexAttribPointer(ATTRIB_TEXCOORDS, 2, GL_FLOAT, GL_FALSE, 48, BUFFER_OFFSET(24));
    glEnableVertexAttribArray(ATTRIB_LOCALCOORDS);
    glVertexAttribPointer(ATTRIB_LOCALCOORDS, 4, GL_FLOAT, GL_FALSE, 48, BUFFER_OFFSET(32));
    
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

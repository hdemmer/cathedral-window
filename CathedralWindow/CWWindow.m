//
//  CWWindow.m
//  CathedralWindow
//
//  Created by Hendrik Demmer on 9/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CWWindow.h"

@implementation CWWindow

int numVertices = 24;

- (id)initWithImage:(UIImage *)image
{
    self = [super init];
    
    if (self)
    {
        [self setup];
    }
    
    return self;
}


float cwRandom(float min, float max)
{
    return (rand() / (float)RAND_MAX)*(max - min) + min;
}


- (void) bindWindowVertices
{
    CWVertex * vertices = malloc(numVertices * sizeof(CWVertex));
    
    for (int i = 0; i < numVertices; i++)
    {
        vertices[i].z = -4;
        
        vertices[i].r = cwRandom(0.5, 1);
        vertices[i].g = cwRandom(0.5, 1);
        vertices[i].b = cwRandom(0.5, 1);
    }
    
    for (int i = 0; i < numVertices; i+=6)
    {
        
        vertices[0+i].x = -1+i/3-2;
        vertices[0+i].y = -1;
        
        vertices[1+i].x = 1+i/3-2;
        vertices[1+i].y = 1;
        
        vertices[2+i].x = 1+i/3-2;
        vertices[2+i].y = -1;
        
        vertices[3+i].x = 1+i/3-2;
        vertices[3+i].y = 1;
        
        vertices[4+i].x = -1+i/3-2;
        vertices[4+i].y = -1;
        
        vertices[5+i].x = -1+i/3-2;
        vertices[5+i].y = 1;
    }
    
    glBufferData(GL_ARRAY_BUFFER, sizeof(CWVertex)*numVertices, vertices, GL_STATIC_DRAW);
    
    free(vertices);
}

- (void) setup
{
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    [self bindWindowVertices];
    
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, GL_FALSE, 24, 0);
    glEnableVertexAttribArray(ATTRIB_COLOR);
    glVertexAttribPointer(ATTRIB_COLOR, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(12));
    
    glBindVertexArrayOES(0);

}

- (void)draw
{
    glBindVertexArrayOES(_vertexArray);
    glDrawArrays(GL_TRIANGLES, 0, numVertices);

}

- (void) tearDown
{
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);

}

@end

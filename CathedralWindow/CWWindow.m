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


float cwRandom(float min, float max)
{
    return (rand() / (float)RAND_MAX)*(max - min) + min;
}

#define IMAGE_SIZE 256

- (void) setupWithImage:(UIImage*)image
{
    // First get the image into your data buffer
    CGImageRef imageRef = [image CGImage];
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData = (unsigned char*) calloc(height * width * 4, sizeof(unsigned char));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, IMAGE_SIZE, IMAGE_SIZE,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGContextScaleCTM(context, 1, -1);
    CGContextDrawImage(context, CGRectMake(0, -IMAGE_SIZE, IMAGE_SIZE * width/(float)height, IMAGE_SIZE), imageRef);
    CGContextRelease(context);

    // now setup the buffers
    
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    
    // generate vertices
    
    width = IMAGE_SIZE;
    height = IMAGE_SIZE;
    
    _numVertices = width*height*6;
    
    CWVertex * vertices = malloc(_numVertices * sizeof(CWVertex));
    
    for (int i = 0; i < _numVertices; i++)
    {
        vertices[i].z = self.origin.z;
    }
    
    float pixWidth = 1.0f / width;
    float pixHeigth = 1.0f / height;
    
    for (int x=0; x<width; x++)
    {
        for (int y=0; y<height; y++)
        {
            int baseIndex = 6*(x+width*y);
            
            int byteIndex = (bytesPerRow * y) + x * bytesPerPixel;
            
            for (int i = 0; i<6;i++)
            {
                vertices[baseIndex+i].r = rawData[byteIndex] / 255.0f + cwRandom(0.0, 0.1);
                vertices[baseIndex+i].g = rawData[byteIndex+1]/ 255.0f +cwRandom(0.0, 0.1);
                vertices[baseIndex+i].b = rawData[byteIndex+2]/ 255.0f +cwRandom(0.0, 0.1);
            }
            
                
                vertices[baseIndex+0].x = -0.5f+pixWidth * x + self.origin.x;
                vertices[baseIndex+0].y = -0.5f+pixHeigth * y + self.origin.y;
                
                vertices[baseIndex+1].x = -0.5f+pixWidth*(x + 1) + self.origin.x;
                vertices[baseIndex+1].y = -0.5f+pixHeigth*(y+1) + self.origin.y;
                
                vertices[baseIndex+2].x = -0.5f+pixWidth*(x+1) + self.origin.x;
                vertices[baseIndex+2].y = -0.5f+pixHeigth*y + self.origin.y;
                
                vertices[baseIndex+3].x = -0.5f+pixWidth*(x+1) + self.origin.x;
                vertices[baseIndex+3].y = -0.5f+pixHeigth*(y+1) + self.origin.y;
                
                vertices[baseIndex+4].x = -0.5f+pixWidth*x  + self.origin.x;
                vertices[baseIndex+4].y = -0.5f+pixHeigth*y + self.origin.y;
                
                vertices[baseIndex+5].x = -0.5f+pixWidth*x + self.origin.x;
            vertices[baseIndex+5].y = -0.5f+pixHeigth*(y+1) +self.origin.y;
         
        }
    }
    
    glBufferData(GL_ARRAY_BUFFER, sizeof(CWVertex)*_numVertices, vertices, GL_STATIC_DRAW);
    
    free(vertices);
    
    // and finish
    
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, GL_FALSE, 24, 0);
    glEnableVertexAttribArray(ATTRIB_COLOR);
    glVertexAttribPointer(ATTRIB_COLOR, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(12));
    
    glBindVertexArrayOES(0);
    
    free(rawData);

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

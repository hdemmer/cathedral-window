//
//  CWWindow.m
//  CathedralWindow
//
//  Created by Hendrik Demmer on 9/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CWWindow.h"

#import "CWTimeSingleton.h"

@interface CWWindow ()
{
    int _numVertices;
    float _scale;
}
@property (nonatomic,strong) CWWindowShape*windowShape;
@end

@implementation CWWindow
@synthesize origin=_origin;
@synthesize windowShape=_windowShape;

@synthesize currentImage=_currentImage;
@synthesize nextImage=_nextImage;

- (id)initWithOrigin:(GLKVector3)origin scale:(float)scale andWindowShape:(CWWindowShape *)shape
{
    self = [super init];
    
    if (self)
    {
        _scale = scale;
        self.origin = origin;
        self.windowShape = shape;
        
        glGenVertexArraysOES(1, &_vertexArray);
        glGenBuffers(1, &_vertexBuffer);
        glGenTextures(2, _textures);
        
    }
    
    return self;
}

-(void)dealloc
{
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);
    
    glDeleteTextures(2, _textures);
}

#define IMAGE_SIZE 256

#define GRID_STEP 8

- (UIImage*)image:(UIImage*)image ByScalingAndCroppingForSize:(CGSize)targetSize
{
    UIImage *sourceImage = image;
    UIImage *newImage = nil;        
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    
    if (CGSizeEqualToSize(imageSize, targetSize) == NO) 
    {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if (widthFactor > heightFactor) 
            scaleFactor = widthFactor; // scale to fit height
        else
            scaleFactor = heightFactor; // scale to fit width
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        // center the image
        if (widthFactor > heightFactor)
        {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5; 
        }
        else 
            if (widthFactor < heightFactor)
            {
                thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
            }
    }       
    
    UIGraphicsBeginImageContext(targetSize); // this will crop
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    if(newImage == nil) 
        NSLog(@"could not scale image");
    
    //pop the context to get back to the default
    UIGraphicsEndImageContext();
    return newImage;
}

- (CWTriangles)segmentIntoTriangles
{
    CWTriangles result;
    
    NSUInteger width = IMAGE_SIZE;
    NSUInteger height = IMAGE_SIZE;
    unsigned char *rawData[2] = {(unsigned char*) calloc(height * width * 4, sizeof(unsigned char)),(unsigned char*) calloc(height * width * 4, sizeof(unsigned char))};
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    {
        CGImageRef imageRef = [self.currentImage CGImage];
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        
        CGContextRef context = CGBitmapContextCreate(rawData[0], width, height,
                                                     bitsPerComponent, bytesPerRow, colorSpace,
                                                     kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
        CGColorSpaceRelease(colorSpace);
        
        CGContextScaleCTM(context, 1, -1);
        
        CGContextDrawImage(context, CGRectMake(0, -IMAGE_SIZE, width, height), imageRef);
        CGContextRelease(context);
    }
    {
        CGImageRef imageRef = [self.nextImage CGImage];
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        
        CGContextRef context = CGBitmapContextCreate(rawData[1], width, height,
                                                     bitsPerComponent, bytesPerRow, colorSpace,
                                                     kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
        CGColorSpaceRelease(colorSpace);
        
        CGContextScaleCTM(context, 1, -1);
        
        CGContextDrawImage(context, CGRectMake(0, -IMAGE_SIZE, width, height), imageRef);
        CGContextRelease(context);
    }
    
    unsigned char *hueData[2] = {(unsigned char*) calloc(IMAGE_SIZE * IMAGE_SIZE, sizeof(unsigned char)),(unsigned char*) calloc(IMAGE_SIZE * IMAGE_SIZE, sizeof(unsigned char))};
    unsigned char *lumaData[2] = {(unsigned char*) calloc(IMAGE_SIZE * IMAGE_SIZE, sizeof(unsigned char)),(unsigned char*) calloc(IMAGE_SIZE * IMAGE_SIZE, sizeof(unsigned char))};
    
    for (int x = 0; x < IMAGE_SIZE; x++)
    {
        for (int y = 0; y < IMAGE_SIZE; y++)
        {
            for (int i=0; i<2;i++)
            {
                float r = rawData[i][(x+y*width)*4]/255.0f;
                float g = rawData[i][(x+y*width)*4+1] / 255.0f;
                float b = rawData[i][(x+y*width)*4+2] /255.0f;
                
                float hue = atan2f(sqrtf(3)*(g-b), 2.0f*(r-g-b));
                
                hueData[i][x+y*IMAGE_SIZE] = (hue * 255.0);
                
                float luma = 0.299*r+0.587*g+0.114*b;
                
                lumaData[i][x+y*IMAGE_SIZE] = (luma * 255.0);
            }
        }
    }
    
    unsigned char *sobelData[2] = {(unsigned char*) calloc(IMAGE_SIZE * IMAGE_SIZE, sizeof(unsigned char)),(unsigned char*) calloc(IMAGE_SIZE * IMAGE_SIZE, sizeof(unsigned char))};
    
    for (int x = 1; x < IMAGE_SIZE-1; x++)
    {
        for (int y = 1; y < IMAGE_SIZE-1; y++)
        {
            for (int i=0; i<2;i++)
            {
                
                float xgrad = 
                -1 * hueData[i][(y-1) * IMAGE_SIZE + x-1] +
                -2 * hueData[i][y * IMAGE_SIZE + x-1] +
                -1 * hueData[i][(y+1) * IMAGE_SIZE + x-1] +
                1 * hueData[i][(y-1) * IMAGE_SIZE + x+1] +
                2 * hueData[i][y * IMAGE_SIZE + x+1] +
                1 * hueData[i][(y+1) * IMAGE_SIZE + x+1];
                
                float ygrad =
                -1 * hueData[i][(y-1) * IMAGE_SIZE + x-1] +
                -2 * hueData[i][(y-1) * IMAGE_SIZE + x] +
                -1 * hueData[i][(y-1) * IMAGE_SIZE + x+1] +
                1 * hueData[i][(y+1) * IMAGE_SIZE + x-1] +
                2 * hueData[i][(y+1) * IMAGE_SIZE + x] +
                1 * hueData[i][(y+1) * IMAGE_SIZE + x+1];
                
                float sobel = sqrtf(xgrad*xgrad + ygrad * ygrad);
                
                sobelData[i][x+y*IMAGE_SIZE] = sobel;
            }
        }
    }
    
    // tex
    
    glBindTexture(GL_TEXTURE_2D, _textures[0]);
    
    glTexParameteri(GL_TEXTURE_2D, GL_GENERATE_MIPMAP, GL_FALSE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR); 
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR); 
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, IMAGE_SIZE, IMAGE_SIZE, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, lumaData[0]);
    
    glBindTexture(GL_TEXTURE_2D, _textures[1]);
    
    glTexParameteri(GL_TEXTURE_2D, GL_GENERATE_MIPMAP, GL_FALSE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR); 
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR); 
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, IMAGE_SIZE, IMAGE_SIZE, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, lumaData[1]);
    
    // calculate nodes
    
    int gridStep = GRID_STEP / (float)_scale;
    if (gridStep > 16)
        gridStep = 16;
    
    int gridWidth = IMAGE_SIZE / (float)gridStep;
    
    int numNodes = gridWidth * gridWidth;
    
    CWVertex * nodes = calloc(numNodes, sizeof(CWVertex));
    
    NSTimeInterval theTime = [[CWTimeSingleton sharedInstance] currentTime];
    
    for (int x=0; x<gridWidth; x++)
    {
        for (int y=0; y<gridWidth; y++)
        {
            int shift = y % 2 + 1;
            int cx = x*gridStep+ gridStep / 2;
            int cy = y*gridStep+ gridStep / 2;
            
            int mx = cx;
            int my = cy;
            int sobelAtM = 0;
            
            int mx2 = cx;
            int my2 = cy;
            int sobelAtM2 = 0;
            
            for (int sx=x*gridStep+shift*gridStep*0.5f; sx<(x+1)*gridStep+shift*gridStep*0.5f; sx++)
            {
                for (int sy=y*gridStep; sy<(y+1)*gridStep; sy++)
                {
                    unsigned char sobel = sobelData[0][sx + IMAGE_SIZE * sy];
                    
                    if (sobel > sobelAtM)
                    {
                        mx = sx;
                        my = sy;
                        sobelAtM = sobel;
                    }
                    
                    unsigned char sobel2 = sobelData[1][sx + IMAGE_SIZE * sy];
                    
                    if (sobel2 > sobelAtM2)
                    {
                        mx2 = sx;
                        my2 = sy;
                        sobelAtM2 = sobel2;
                    }
                }
            }
            
            {
                nodes[x+gridWidth*y].x = mx/(float)IMAGE_SIZE;
                nodes[x+gridWidth*y].y = my/(float)IMAGE_SIZE;
                nodes[x+gridWidth*y].z = cwRandom(0, 0.001);
                
                float r = rawData[0][(x*gridStep + width * y*gridStep)*bytesPerPixel]/ 255.0f;
                float g = rawData[0][(x*gridStep + width * y*gridStep)*bytesPerPixel+1]/ 255.0f;
                float b = rawData[0][(x*gridStep + width * y*gridStep)*bytesPerPixel+2]/ 255.0f;
                nodes[x+gridWidth*y].r = r +cwRandom(0.0, 0.1);
                nodes[x+gridWidth*y].g = g +cwRandom(0.0, 0.1);
                nodes[x+gridWidth*y].b = b+cwRandom(0.0, 0.1);
            }
            {
                nodes[x+gridWidth*y].x2 = mx2/(float)IMAGE_SIZE;
                nodes[x+gridWidth*y].y2 = my2/(float)IMAGE_SIZE;
                nodes[x+gridWidth*y].z2 = cwRandom(0, 0.001);
                
                float r = rawData[1][(x*gridStep + width * y*gridStep)*bytesPerPixel]/ 255.0f;
                float g = rawData[1][(x*gridStep + width * y*gridStep)*bytesPerPixel+1]/ 255.0f;
                float b = rawData[1][(x*gridStep + width * y*gridStep)*bytesPerPixel+2]/ 255.0f;
                nodes[x+gridWidth*y].r2 = r +cwRandom(0.0, 0.1);
                nodes[x+gridWidth*y].g2 = g +cwRandom(0.0, 0.1);
                nodes[x+gridWidth*y].b2 = b+cwRandom(0.0, 0.1);
                
            }
            nodes[x+gridWidth*y].animationStartTime = theTime;
            
        }
    }
    
    // move border vertices onto grid
    for (int x=0; x<gridWidth; x++)
    {
        nodes[x].y=0.0f;
        nodes[x*gridWidth].y=0.0f;
        
        nodes[x + (gridWidth-1)*gridWidth].y=1.0f;
        nodes[(gridWidth-1)+x*gridWidth].x=1.0f;
    }
    
    int numVertices = (gridWidth-1)*(gridWidth-1)*6;
    
    CWVertex * vertices = malloc(numVertices * sizeof(CWVertex));

    for (int x=0; x<gridWidth-1; x++)
    {
        for (int y=0; y<gridWidth-1; y++)
        {
            int baseIndex = 6*(x+(gridWidth-1)*y);
            
            vertices[baseIndex+0] = nodes[x+1+y*gridWidth];
            vertices[baseIndex+1] = nodes[x+y*gridWidth];
            vertices[baseIndex+2] = nodes[x+1+(y+1)*gridWidth];
            vertices[baseIndex+3] = nodes[x+1+(y+1)*gridWidth];
            vertices[baseIndex+4] = nodes[x+y*gridWidth];
            vertices[baseIndex+5] = nodes[x+(y+1)*gridWidth];
            
            
            float r = (vertices[baseIndex+0].r+vertices[baseIndex+1].r+vertices[baseIndex+2].r) / 3.0f;
            float g = (vertices[baseIndex+0].g+vertices[baseIndex+1].g+vertices[baseIndex+2].g) / 3.0f;
            float b = (vertices[baseIndex+0].b+vertices[baseIndex+1].b+vertices[baseIndex+2].b) / 3.0f;
            
            for (int i=0; i<3; i++)
            {
                vertices[baseIndex+i].r=r+cwRandom(0.0, 0.1);
                vertices[baseIndex+i].g=g+cwRandom(0.0, 0.1);
                vertices[baseIndex+i].b=b+cwRandom(0.0, 0.1);
            }
            
            baseIndex+=3;
            
            r = (r+vertices[baseIndex+0].r+vertices[baseIndex+1].r+vertices[baseIndex+2].r) / 4.0f;
            g = (g+vertices[baseIndex+0].g+vertices[baseIndex+1].g+vertices[baseIndex+2].g) / 4.0f;
            b = (b+vertices[baseIndex+0].b+vertices[baseIndex+1].b+vertices[baseIndex+2].b) / 4.0f;
            
            for (int i=0; i<3; i++)
            {
                vertices[baseIndex+i].r=r+cwRandom(0.0, 0.1);;
                vertices[baseIndex+i].g=g+cwRandom(0.0, 0.1);;
                vertices[baseIndex+i].b=b+cwRandom(0.0, 0.1);;
            }
        }
    }
    
    result.numberOfVertices = numVertices;
    result.vertices = vertices;
    
    for (int i=0; i<2; i++)
    {
        free(rawData[i]);
        
        free(hueData[i]);
        free(lumaData[i]);
        free(sobelData[i]);
    }
    
    
    return result;
    
    // TODO:
    /*
     CWTriangles newResult = [CWTriangleProcessor intersectTriangles:result withWindowShape:self.windowShape];
     free(result.vertices);
     result = newResult;
     */
}


float cwRandom(float min, float max)
{
    return (rand() / (float)RAND_MAX)*(max - min) + min;
}


#import "CWTriangleProcessor.h"


- (void) pushImage:(UIImage *)image
{
    self.currentImage = self.nextImage;
    self.nextImage = [self image:image ByScalingAndCroppingForSize:CGSizeMake(IMAGE_SIZE, IMAGE_SIZE)];
    
    // triangles
    
    glBindVertexArrayOES(_vertexArray);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    
    CWTriangles result = [self segmentIntoTriangles];
    
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
        
        vertices[i].u2 = vertices[i].x2;
        vertices[i].v2 = vertices[i].y2;
        
        vertices[i].x = (-0.5 + vertices[i].x)*_scale + self.origin.x;
        vertices[i].y = (-0.5 + vertices[i].y)*_scale + self.origin.y;
        vertices[i].z += self.origin.z;
        
        vertices[i].x2 = (-0.5 + vertices[i].x2)*_scale + self.origin.x;
        vertices[i].y2 = (-0.5 + vertices[i].y2)*_scale + self.origin.y;
        vertices[i].z2 += self.origin.z;
    }
    
    glBufferData(GL_ARRAY_BUFFER, sizeof(CWVertex)*_numVertices, vertices, GL_STATIC_DRAW);
    
    free(result.vertices);
    
    // and finish
    
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, GL_FALSE, 84, 0);
    glEnableVertexAttribArray(ATTRIB_COLOR);
    glVertexAttribPointer(ATTRIB_COLOR, 3, GL_FLOAT, GL_FALSE, 84, BUFFER_OFFSET(12));
    glEnableVertexAttribArray(ATTRIB_TEXCOORDS);
    glVertexAttribPointer(ATTRIB_TEXCOORDS, 2, GL_FLOAT, GL_FALSE, 84, BUFFER_OFFSET(24));
    glEnableVertexAttribArray(ATTRIB_LOCALCOORDS);
    glVertexAttribPointer(ATTRIB_LOCALCOORDS, 4, GL_FLOAT, GL_FALSE, 84, BUFFER_OFFSET(32));
    
    glEnableVertexAttribArray(ATTRIB_VERTEX2);
    glVertexAttribPointer(ATTRIB_VERTEX2, 3, GL_FLOAT, GL_FALSE, 84, BUFFER_OFFSET(48));
    glEnableVertexAttribArray(ATTRIB_COLOR2);
    glVertexAttribPointer(ATTRIB_COLOR2, 3, GL_FLOAT, GL_FALSE, 84, BUFFER_OFFSET(60));
    glEnableVertexAttribArray(ATTRIB_TEXCOORDS2);
    glVertexAttribPointer(ATTRIB_TEXCOORDS2, 2, GL_FLOAT, GL_FALSE, 84, BUFFER_OFFSET(72));
    glEnableVertexAttribArray(ATTRIB_ANIMATION_START_TIME);
    glVertexAttribPointer(ATTRIB_ANIMATION_START_TIME, 1, GL_FLOAT, GL_FALSE, 84, BUFFER_OFFSET(80));
    
    glBindVertexArrayOES(0);
}

- (void)draw
{
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _textures[0]);
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, _textures[1]);
    glBindVertexArrayOES(_vertexArray);
    glDrawArrays(GL_TRIANGLES, 0, _numVertices);
    
}

- (BOOL)containsPoint:(GLKVector3)point
{
    CWVertex v;
    v.x = (point.x - self.origin.x)/_scale + 0.5f;
    v.y = (point.y - self.origin.y)/_scale + 0.5f;
    v.z = 0.0f;
    
    return [self.windowShape containsVertex:v];
    
}

@end

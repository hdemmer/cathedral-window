//
//  UIImage+Segmentation.m
//  CathedralWindow
//
//  Created by Hendrik Demmer on 9/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UIImage+Segmentation.h"

#define IMAGE_SIZE 256

#define GRID_STEP 16


float cwRandom(float min, float max)
{
    return (rand() / (float)RAND_MAX)*(max - min) + min;
}

@implementation UIImage (Segmentation)

- (CWSegmentationResult)segmentIntoTriangles
{
    CWSegmentationResult result;
    
    CGImageRef imageRef = [self CGImage];
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData = (unsigned char*) calloc(height * width * 4, sizeof(unsigned char));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);

    unsigned char *hueData = (unsigned char*) calloc(IMAGE_SIZE * IMAGE_SIZE, sizeof(unsigned char));
    
    for (int x = 0; x < IMAGE_SIZE; x++)
    {
        for (int y = 0; y < IMAGE_SIZE; y++)
        {
            float r = rawData[(x+y*width)*4]/255.0f;
            float g =  rawData[(x+y*width)*4+1] / 255.0f;
            float b = rawData[(x+y*width)*4+2] /255.0f;
            
            float hue = atan2f(sqrtf(3)*(g-b), 2.0f*(r-g-b));
            
            hueData[x+y*IMAGE_SIZE] = (hue * 255.0);
        }
    }
    
    unsigned char *sobelData = (unsigned char*) calloc(IMAGE_SIZE * IMAGE_SIZE, sizeof(unsigned char));
    
    for (int x = 1; x < IMAGE_SIZE-1; x++)
    {
        for (int y = 1; y < IMAGE_SIZE-1; y++)
        {
            float xgrad = 
            -1 * hueData[(y-1) * IMAGE_SIZE + x-1] +
            -2 * hueData[y * IMAGE_SIZE + x-1] +
            -1 * hueData[(y+1) * IMAGE_SIZE + x-1] +
            1 * hueData[(y-1) * IMAGE_SIZE + x+1] +
            2 * hueData[y * IMAGE_SIZE + x+1] +
            1 * hueData[(y+1) * IMAGE_SIZE + x+1];
            
            float ygrad =
            -1 * hueData[(y-1) * IMAGE_SIZE + x-1] +
            -2 * hueData[(y-1) * IMAGE_SIZE + x] +
            -1 * hueData[(y-1) * IMAGE_SIZE + x+1] +
            1 * hueData[(y+1) * IMAGE_SIZE + x-1] +
            2 * hueData[(y+1) * IMAGE_SIZE + x] +
            1 * hueData[(y+1) * IMAGE_SIZE + x+1];
            
            float sobel = sqrtf(xgrad*xgrad + ygrad * ygrad);
            
            sobelData[x+y*IMAGE_SIZE] = sobel;
        }
    }
    
    // calculate nodes
    
    int gridStep = GRID_STEP;
    int gridWidth = IMAGE_SIZE / (float)gridStep;
    
    int numNodes = gridWidth * gridWidth;
    
    float * nodes[2] = {calloc(numNodes, sizeof(float)),calloc(numNodes, sizeof(float))};
    
    for (int x=0; x<gridWidth; x++)
    {
        for (int y=0; y<gridWidth; y++)
        {
            int shift = y % 2 + 1;
            int cx = x*gridStep+ shift*(gridStep / 2);
            int cy = y*gridStep+ gridStep / 2;
            
            /*
            int mx = cx;
            int my = cy;
            int sobelAtM = 0;
            
            for (int sx=x*gridStep; x<(x+1)*gridStep; sx++)
            {
                for (int sy=y*gridStep; y<(y+1)*gridStep; sy++)
                {
                    
                    
                }
            }*/
            
            
            nodes[0][x+gridWidth*y] = cx/(float)IMAGE_SIZE;    // x
            nodes[1][x+gridWidth*y] = cy/(float)IMAGE_SIZE;    // x
            
        }
    }
    
    
    int numVertices = gridWidth*gridWidth*6;
    
    CWVertex * vertices = malloc(numVertices * sizeof(CWVertex));
    
    for (int x=0; x<gridWidth-1; x++)
    {
        for (int y=0; y<gridWidth-1; y++)
        {
            int baseIndex = 6*(x+gridWidth*y);
            
            for (int i = 0; i<6;i++)
            {
                unsigned char r = rawData[(x*gridStep + width * y*gridStep)*bytesPerPixel];
                unsigned char g = rawData[(x*gridStep + width * y*gridStep)*bytesPerPixel+1];
                unsigned char b = rawData[(x*gridStep + width * y*gridStep)*bytesPerPixel+2];
                vertices[baseIndex+i].r = r / 255.0f + cwRandom(0.0, 0.1);
                vertices[baseIndex+i].g = g / 255.0f +cwRandom(0.0, 0.1);
                vertices[baseIndex+i].b = b / 255.0f +cwRandom(0.0, 0.1);

                vertices[baseIndex+i].z = 0;
            }
            
            
            vertices[baseIndex+0].x = -0.5f+nodes[0][x+1+y*gridWidth];
            vertices[baseIndex+0].y = -0.5f+nodes[1][x+1+y*gridWidth];
            
            vertices[baseIndex+1].x = -0.5f+nodes[0][x+y*gridWidth];
            vertices[baseIndex+1].y = -0.5f+nodes[1][x+y*gridWidth];
            
            vertices[baseIndex+2].x = -0.5f+nodes[0][x+1+(y+1)*gridWidth];
            vertices[baseIndex+2].y = -0.5f+nodes[1][x+1+(y+1)*gridWidth];
            
            vertices[baseIndex+3].x = -0.5f+nodes[0][x+1+(y+1)*gridWidth];
            vertices[baseIndex+3].y = -0.5f+nodes[1][x+1+(y+1)*gridWidth];
            
            vertices[baseIndex+4].x = -0.5f+nodes[0][x+y*gridWidth];
            vertices[baseIndex+4].y = -0.5f+nodes[1][x+y*gridWidth];
            
            vertices[baseIndex+5].x = -0.5f+nodes[0][x+(y+1)*gridWidth];
            vertices[baseIndex+5].y = -0.5f+nodes[1][x+(y+1)*gridWidth];
        }
    }

    result.numberOfVertices = numVertices;
    result.vertices = vertices;
    
    return result;
}


@end

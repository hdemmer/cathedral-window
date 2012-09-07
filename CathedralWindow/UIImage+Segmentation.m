//
//  UIImage+Segmentation.m
//  CathedralWindow
//
//  Created by Hendrik Demmer on 9/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UIImage+Segmentation.h"

#define IMAGE_SIZE 256

#define GRID_STEP 8


float cwRandom(float min, float max)
{
    return (rand() / (float)RAND_MAX)*(max - min) + min;
}

@implementation UIImage (Segmentation)

- (UIImage*)imageByScalingAndCroppingForSize:(CGSize)targetSize
{
    UIImage *sourceImage = self;
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
    
    CGImageRef imageRef = [[self imageByScalingAndCroppingForSize:CGSizeMake(IMAGE_SIZE, IMAGE_SIZE)] CGImage];
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
    
    CGContextScaleCTM(context, 1, -1);
    
    CGContextDrawImage(context, CGRectMake(0, -IMAGE_SIZE, width, height), imageRef);
    CGContextRelease(context);

    unsigned char *hueData = (unsigned char*) calloc(IMAGE_SIZE * IMAGE_SIZE, sizeof(unsigned char));
    unsigned char *lumaData = (unsigned char*) calloc(IMAGE_SIZE * IMAGE_SIZE, sizeof(unsigned char));
    
    for (int x = 0; x < IMAGE_SIZE; x++)
    {
        for (int y = 0; y < IMAGE_SIZE; y++)
        {
            float r = rawData[(x+y*width)*4]/255.0f;
            float g =  rawData[(x+y*width)*4+1] / 255.0f;
            float b = rawData[(x+y*width)*4+2] /255.0f;
            
            float hue = atan2f(sqrtf(3)*(g-b), 2.0f*(r-g-b));
            
            hueData[x+y*IMAGE_SIZE] = (hue * 255.0);
            
            float luma = 0.299*r+0.587*g+0.114*b;
            
            lumaData[x+y*IMAGE_SIZE] = (luma * 255.0);
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
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, IMAGE_SIZE, IMAGE_SIZE, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, lumaData);
    
    // calculate nodes
    
    int gridStep = GRID_STEP;
    int gridWidth = IMAGE_SIZE / (float)gridStep;
    
    int numNodes = gridWidth * gridWidth;
    
    CWVertex * nodes = calloc(numNodes, sizeof(CWVertex));
    
    for (int x=0; x<gridWidth; x++)
    {
        for (int y=0; y<gridWidth; y++)
        {
            int shift = y % 2 + 1;
            int cx = x*gridStep+ shift*(gridStep / 2);
            int cy = y*gridStep+ gridStep / 2;
            
            int mx = cx;
            int my = cy;
            int sobelAtM = 0;
            
            for (int sx=x*gridStep; sx<(x+1)*gridStep; sx++)
            {
                for (int sy=y*gridStep; sy<(y+1)*gridStep; sy++)
                {
                    unsigned char sobel = sobelData[sx + IMAGE_SIZE * sy];
                    
                    if (sobel > sobelAtM)
                    {
                        mx = sx;
                        my = sy;
                        sobelAtM = sobel;
                    }
                    
                }
            }
            
            nodes[x+gridWidth*y].x = mx/(float)IMAGE_SIZE;    // x
            nodes[x+gridWidth*y].y = my/(float)IMAGE_SIZE;    // x
            nodes[x+gridWidth*y].z = 0;
            
            unsigned char r = rawData[(x*gridStep + width * y*gridStep)*bytesPerPixel];
            unsigned char g = rawData[(x*gridStep + width * y*gridStep)*bytesPerPixel+1];
            unsigned char b = rawData[(x*gridStep + width * y*gridStep)*bytesPerPixel+2];
            nodes[x+gridWidth*y].r = r / 255.0f +cwRandom(0.0, 0.1);
            nodes[x+gridWidth*y].g = g / 255.0f +cwRandom(0.0, 0.1);
            nodes[x+gridWidth*y].b = b / 255.0f +cwRandom(0.0, 0.1);

        }
    }
    
    
    int numVertices = gridWidth*gridWidth*6;
    
    CWVertex * vertices = malloc(numVertices * sizeof(CWVertex));
    
    for (int x=0; x<gridWidth-1; x++)
    {
        for (int y=0; y<gridWidth-1; y++)
        {
            int baseIndex = 6*(x+gridWidth*y);
            
            
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
    
    free(rawData);
    
    free(hueData);
    free(lumaData);
    free(sobelData);
    
    return result;
}


@end

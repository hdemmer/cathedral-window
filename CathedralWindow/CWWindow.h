//
//  CWWindow.h
//  CathedralWindow
//
//  Created by Hendrik Demmer on 9/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <GLKit/GLKit.h>

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

// Attribute index.
enum
{
    ATTRIB_VERTEX,
    ATTRIB_COLOR,
    NUM_ATTRIBUTES
};

typedef struct {
    float x;
    float y;
    float z;
    float r;
    float g;
    float b;
} CWVertex;

@interface CWWindow : NSObject
{    
    GLuint _vertexArray;
    GLuint _vertexBuffer;

}

@property (nonatomic, assign) float originX;
@property (nonatomic, assign) float originY;

- (id)initWithImage:(UIImage*)image X:(float)x Y:(float)y;

- (void) draw;

- (void) tearDown;


@end

//
//  Shader.vsh
//  CathedralWindow
//
//  Created by Hendrik Demmer on 9/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

attribute vec4 position;

varying lowp vec4 colorVarying;

uniform mat4 modelViewProjectionMatrix;

void main()
{
    vec4 diffuseColor = vec4(0.4, 0.4, 1.0, 1.0);
    
    colorVarying = diffuseColor;
    
    gl_Position = modelViewProjectionMatrix * position;
}

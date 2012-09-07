//
//  Shader.fsh
//  CathedralWindow
//
//  Created by Hendrik Demmer on 9/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

varying lowp vec4 colorVarying;
varying lowp vec4 texCoords2;
uniform sampler2D Texture;

void main()
{
    lowp float luma = texture2D(Texture,texCoords2.xy).x;
    gl_FragColor = colorVarying * (luma + 0.5)/1.5;
}

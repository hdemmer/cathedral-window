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
    lowp float luma = dot(texture2D(Texture,texCoords2.xy).xyz,vec3(0.299,0.587,0.114));
    gl_FragColor = colorVarying * (luma + 1.0)*0.5;
}

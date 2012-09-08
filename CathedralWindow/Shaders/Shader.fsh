//
//  Shader.fsh
//  CathedralWindow
//
//  Created by Hendrik Demmer on 9/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

varying lowp vec3 colorBaseV;
varying lowp vec3 colorGlowV;
varying lowp float intensityDirectV;
varying lowp vec2 texCoordsV;
varying lowp vec4 localCoordsV;

uniform lowp vec3 sunColor;
uniform sampler2D Texture;

void main()
{
    mediump float thickness = 2.0*localCoordsV.x*2.0*localCoordsV.y* localCoordsV.z * 2.0;
    lowp float lead = clamp(thickness*8.0,0.2+0.5*(1.0-(gl_FragCoord.w*gl_FragCoord.w)),1.0);
    lowp float luma = (texture2D(Texture,texCoordsV).x + 0.5)/1.5;
    
    lowp vec3 result = lead * 0.5* (luma * (colorBaseV + colorGlowV)+colorGlowV + intensityDirectV * mix(colorGlowV,sunColor,0.5*thickness));
    
    gl_FragColor = vec4(result,1.0);
}

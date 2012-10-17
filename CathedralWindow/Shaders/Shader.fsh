//
//  Shader.fsh
//  CathedralWindow
//
//  Created by Hendrik Demmer on 9/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

varying lowp vec3 colorBaseV;
varying lowp float intensityDirectV;
varying lowp vec3 colorGlowV;
varying lowp float lambda;
varying lowp vec2 texCoordsV;
varying lowp vec2 texCoordsV2;
varying lowp vec3 localCoordsV;

uniform lowp vec3 sunColor;
uniform sampler2D Texture;
uniform sampler2D Texture2;

void main()
{
    mediump float thickness = localCoordsV.x*localCoordsV.y*localCoordsV.z;
    thickness = thickness*8.0;
    lowp float lead = clamp(thickness*8.0,0.2+0.5*(1.0-(gl_FragCoord.w*gl_FragCoord.w)),1.0);
    lowp float diffuseLuma = texture2D(Texture,texCoordsV).x;
    lowp float diffuseLuma2 = texture2D(Texture2,texCoordsV2).x;    
    lowp float luma = (mix(diffuseLuma,diffuseLuma2,lambda) + 0.5)/1.5;
        
    lowp vec3 result = lead * (luma * (colorBaseV + colorGlowV)+colorGlowV + 2.0*intensityDirectV * mix(colorGlowV,sunColor,thickness));
    
    gl_FragColor = vec4(result,1.0);
}

//
//  Shader.fsh
//  CathedralWindow
//
//  Created by Hendrik Demmer on 9/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

varying mediump vec4 colorBaseAndIntensityDirectV;
varying mediump vec4 colorGlowAndLambdaV;
varying mediump vec4 localCoordsV;
varying mediump vec2 texCoordsV;
varying mediump vec2 texCoords2V;

uniform mediump vec3 sunColor;
uniform sampler2D Texture;
uniform sampler2D Texture2;

void main()
{
    mediump float diffuseLuma = texture2D(Texture,texCoordsV).x;
    mediump float diffuseLuma2 = texture2D(Texture2,texCoords2V).x;

    mediump float thickness = localCoordsV.x*localCoordsV.y*localCoordsV.z;
    thickness = thickness*8.0;
    mediump float lead = clamp(thickness*8.0,0.2+0.5*(1.0-(gl_FragCoord.w*gl_FragCoord.w)),1.0);
    mediump float luma = (mix(diffuseLuma,diffuseLuma2,colorGlowAndLambdaV.w) + 0.5)/1.5;
        
    mediump vec3 result = lead * (luma * (colorBaseAndIntensityDirectV.xyz + colorGlowAndLambdaV.xyz)+colorGlowAndLambdaV.xyz + colorBaseAndIntensityDirectV.w * mix(colorGlowAndLambdaV.xyz,sunColor,thickness));

    gl_FragColor = vec4(result,1.0);
}

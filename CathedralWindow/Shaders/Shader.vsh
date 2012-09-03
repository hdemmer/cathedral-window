//
//  Shader.vsh
//  CathedralWindow
//
//  Created by Hendrik Demmer on 9/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

attribute vec3 position;
attribute vec3 diffuse;

varying lowp vec4 colorVarying;

uniform mat4 modelViewProjectionMatrix;

uniform vec3 sunVector;
uniform vec3 sunColor;

void main()
{
    float sunAngle = clamp(dot(normalize(sunVector), normalize(position)),0.0,1.0);
    
    sunAngle = sunAngle * sunAngle;
    
    float luma = dot(diffuse, vec3(0.299,0.587,0.114));
    
    vec3 base = diffuse * 0.2;
    vec3 colorGlow = mix(diffuse,luma*vec3(1.0,1.0,1.0), -1.0) * sunAngle;
    vec3 direct = clamp(sunAngle-0.5,0.0,1.0) * luma * sunColor;
    
    sunAngle = sunAngle * sunAngle;
    
    colorVarying = vec4(base + colorGlow + direct,1.0);
    
    gl_Position = modelViewProjectionMatrix * vec4(position,1.0);
}

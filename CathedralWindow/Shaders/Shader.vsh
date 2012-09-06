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

uniform vec3 eyePosition;

uniform float ambientIntensity;
uniform vec3 sunVector;
uniform vec3 sunColor;

void main()
{
    vec3 normal = vec3(0.0,0.0,-1.0);
    
    float sunAngle = clamp(dot(normalize(sunVector), normalize(eyePosition-position+6.0*normal))-0.5,0.0,1.0);
        
    float sunAngleToNormal = dot(normalize(sunVector), normal);
    
    float glowCoeff = (clamp(sunAngleToNormal,0.0,1.0) + sunAngle)*0.5;

    sunAngle = clamp(sunAngle-0.46,0.0,1.0)*50.0;
    sunAngle = sunAngle * sunAngle;
    
    float luma = dot(diffuse, vec3(0.299,0.587,0.114));
    
    vec3 base = diffuse * ambientIntensity;
    vec3 colorGlow = mix(diffuse,luma*vec3(1.0,1.0,1.0), -1.0) * glowCoeff;  // kick out sat
    vec3 direct = sunAngle * luma*luma * sunColor;

    colorVarying = vec4(base + colorGlow + direct,1.0);
    
    gl_Position = modelViewProjectionMatrix * vec4(position,1.0);
}

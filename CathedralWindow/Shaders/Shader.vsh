//
//  Shader.vsh
//  CathedralWindow
//
//  Created by Hendrik Demmer on 9/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

attribute vec3 position;
attribute vec3 diffuse;
attribute vec2 texCoords;
attribute vec4 localCoords;

varying lowp vec3 colorBaseV;
varying lowp vec3 colorGlowV;
varying mediump float intensityDirectV;

varying lowp vec2 texCoordsV;
varying lowp vec4 localCoordsV;

uniform mat4 modelViewProjectionMatrix;

uniform vec3 eyePosition;

uniform float ambientIntensity;
uniform vec3 sunVector;

void main()
{
    vec3 normal = vec3(0.0,0.0,1.0);
    
    float sunAngle = clamp((dot(normalize(sunVector), normalize(position-eyePosition))+1.0)*0.25,0.0,1.0);
    //clamp((dot(normalize(sunVector), normalize(normalize(eyePosition)*4.0-position))+1.0)*0.25,0.0,1.0);
        
    float sunAngleToNormal = dot(normalize(sunVector), normal);
    
    float glowCoeff = (clamp(sunAngleToNormal,0.0,1.0) + sunAngle)*0.5;

    sunAngle = clamp(sunAngle-0.46,0.0,1.0)*30.0+ clamp(sunAngle-0.4995,0.0,1.0)*3000.0;
    sunAngle = sunAngle * sunAngle;
    
    float luma = dot(diffuse, vec3(0.299,0.587,0.114));
    
    vec3 base = diffuse * ambientIntensity;
    vec3 colorGlow = mix(diffuse,luma*vec3(1.0,1.0,1.0), -1.5) * glowCoeff;  // kick out sat
    intensityDirectV = sunAngle * luma*luma;

    colorBaseV = base;
    colorGlowV = colorGlow;
    
    texCoordsV = texCoords;
    localCoordsV=localCoords;
    
    gl_Position = modelViewProjectionMatrix * vec4(position,1.0);
}

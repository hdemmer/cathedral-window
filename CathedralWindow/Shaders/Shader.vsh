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
attribute vec3 position2;
attribute vec3 diffuse2;
attribute vec2 texCoords2;
attribute float animationStartTime;

varying lowp vec3 colorBaseV;
varying lowp vec3 colorGlowV;
varying lowp vec3 colorBaseV2;
varying lowp vec3 colorGlowV2;
varying lowp float intensityDirectV;

varying lowp vec2 texCoordsV;
varying lowp vec2 texCoordsV2;
varying lowp vec3 localCoordsV;
varying lowp float lambda;

uniform mat4 modelViewProjectionMatrix;

uniform vec3 eyePosition;

uniform float ambientIntensity;
uniform vec3 sunVector;

uniform float theTime;

void main()
{
    vec3 normal = vec3(0.0,0.0,1.0);
    
    float sunAngle = clamp((dot(normalize(sunVector), normalize(position-eyePosition))+1.0)*0.25,0.0,1.0);
        
    float sunAngleToNormal = dot(normalize(sunVector), normal);
    
    float glowCoeff = (clamp(sunAngleToNormal,0.0,1.0) + sunAngle)*0.5;

    sunAngle = clamp(sunAngle-0.46,0.0,1.0)*30.0+ clamp(sunAngle-0.4995,0.0,1.0)*3000.0;
    sunAngle = sunAngle * sunAngle;
    
    float luma = dot(diffuse, vec3(0.299,0.587,0.114));
    float luma2 = dot(diffuse2, vec3(0.299,0.587,0.114));
    
    vec3 base = diffuse * ambientIntensity;
    vec3 base2 = diffuse2 * ambientIntensity;
    vec3 colorGlow = mix(diffuse,luma*vec3(1.0,1.0,1.0), -1.5) * glowCoeff;  // kick out sat
    vec3 colorGlow2 = mix(diffuse2,luma*vec3(1.0,1.0,1.0), -1.5) * glowCoeff;  // kick out sat
    intensityDirectV = sunAngle * luma*luma;
    
    texCoordsV = texCoords;
    texCoordsV2 = texCoords2;
    localCoordsV=localCoords.xyz;
    
    lambda = smoothstep(0.0,1.0,clamp(theTime - animationStartTime, 0.0,1.0));
    
    vec3 positionMix = mix(position,position2,lambda);

    colorBaseV = mix(base, base2, lambda);
    colorGlowV = mix(colorGlow, colorGlow2, lambda);
    
    gl_Position = modelViewProjectionMatrix * vec4(positionMix,1.0);
}

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
    
    sunAngle = sunAngle * sunAngle * sunAngle * sunAngle;
    
    vec3 base = diffuse * 0.2;
    vec3 colorGlow = vec3(diffuse.x - 0.5, diffuse.y - 0.5, diffuse.y - 0.5) * sunAngle;
    vec3 direct = clamp(sunAngle-0.5,0.0,1.0) * 2.0 * sunColor;
    
    sunAngle = sunAngle * sunAngle * sunAngle * sunAngle;

    vec3 whiteOut = clamp(sunAngle-0.5,0.0,1.0) * vec3(1.0,1.0,1.0);
    
    colorVarying = vec4(base + colorGlow + direct + whiteOut,1.0);
    
    gl_Position = modelViewProjectionMatrix * vec4(position,1.0);
}

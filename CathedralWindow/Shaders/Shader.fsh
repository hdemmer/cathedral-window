//
//  Shader.fsh
//  CathedralWindow
//
//  Created by Hendrik Demmer on 9/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}

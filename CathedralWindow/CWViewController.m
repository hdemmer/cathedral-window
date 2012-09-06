//
//  CWViewController.m
//  CathedralWindow
//
//  Created by Hendrik Demmer on 9/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CWViewController.h"

#import "CWWindow.h"

// Uniform index.
enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_EYE_POSITION,
    UNIFORM_SUN_VECTOR,
    UNIFORM_SUN_COLOR,
    UNIFORM_AMBIENT_INTENSITY,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

@interface CWViewController () {
    GLuint _program;
    
    GLKMatrix4 _modelViewProjectionMatrix;
    
    CGPoint _pan;
}
@property (strong, nonatomic) EAGLContext *context;

- (void)setupGL;
- (void)tearDownGL;

- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;
@end

@implementation CWViewController

@synthesize context = _context;
@synthesize windows=_windows;

#define MAX_PAN 300

- (void) panGestureRecognizerFired:(UIPanGestureRecognizer*)panGestureRecognizer
{
    CGPoint pan = [panGestureRecognizer translationInView:self.view];
    [panGestureRecognizer setTranslation:CGPointZero inView:self.view];

    _pan.x += pan.x;
    _pan.y += pan.y;

    if (_pan.x < -MAX_PAN)
        _pan.x = -MAX_PAN;

    if (_pan.x > MAX_PAN)
        _pan.x = MAX_PAN;

    if (_pan.y < -MAX_PAN)
        _pan.y = -MAX_PAN;

    if (_pan.y > MAX_PAN)
        _pan.y = MAX_PAN;

}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIPanGestureRecognizer * panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognizerFired:)];
    [self.view addGestureRecognizer:panGestureRecognizer];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [self setupGL];
}

- (void)viewDidUnload
{    
    [super viewDidUnload];
    
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
	self.context = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc. that aren't in use.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}
- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
    
    [self loadShaders];
    
    glEnable(GL_DEPTH_TEST);
    
    self.windows = [NSArray arrayWithObjects:
                    [[CWWindow alloc] initWithImage:[UIImage imageNamed:@"splash.jpg"] origin:GLKVector3Make(0, 0, 0)],
                    [[CWWindow alloc] initWithImage:[UIImage imageNamed:@"splash.jpg"] origin:GLKVector3Make(-1, 0, 0)],
                    [[CWWindow alloc] initWithImage:[UIImage imageNamed:@"splash.jpg"] origin:GLKVector3Make(1, 0, 0)],
                    nil];
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
    for (CWWindow * window in self.windows)
    {
        [window tearDown];
    }
    self.windows = nil;
    
    
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(55.0f), aspect, 0.1f, 100.0f);
    
    
    float x = -_pan.x / MAX_PAN;
    float y = _pan.y / MAX_PAN;
    
    float z = 0.4;

    GLKVector3 eye = GLKVector3Make(x, y, z);
    eye = GLKVector3Normalize(eye);
    
    glUniform3f(uniforms[UNIFORM_EYE_POSITION], eye.x, eye.y,eye.z);

    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeLookAt(eye.x,eye.y,eye.z, 0, 0, 0, 0, 1, 0);
        
    _modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(0.1f, 0.1f, 0.2f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    
    // Render the object again with ES2
    glUseProgram(_program);
    
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _modelViewProjectionMatrix.m);
    
    float t = self.timeSinceFirstResume;
    
    glUniform3f(uniforms[UNIFORM_SUN_VECTOR], cosf(t), 0.0*sinf(t),sinf(t));
    glUniform3f(uniforms[UNIFORM_SUN_COLOR], 1.0f, 0.95f, 0.75f);

    glUniform1f(uniforms[UNIFORM_AMBIENT_INTENSITY], 0.2+0.05*cosf(t));

    for (CWWindow * window in self.windows)
    {
        [window draw];
    }
}

#pragma mark -  OpenGL ES 2 shader compilation

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    _program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(_program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(_program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(_program, ATTRIB_VERTEX, "position");
    glBindAttribLocation(_program, ATTRIB_COLOR, "diffuse");
    
    // Link program.
    if (![self linkProgram:_program]) {
        NSLog(@"Failed to link program: %d", _program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        return NO;
    }
    
    // Get uniform locations.
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(_program, "modelViewProjectionMatrix");
    uniforms[UNIFORM_EYE_POSITION] = glGetUniformLocation(_program, "eyePosition");
    uniforms[UNIFORM_SUN_VECTOR] = glGetUniformLocation(_program, "sunVector");
    uniforms[UNIFORM_SUN_COLOR] = glGetUniformLocation(_program, "sunColor");
    uniforms[UNIFORM_AMBIENT_INTENSITY] = glGetUniformLocation(_program, "ambientIntensity");
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

@end

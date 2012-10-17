//
//  CWViewController.m
//  CathedralWindow
//
//  Created by Hendrik Demmer on 9/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CWViewController.h"

#import "CWWindow.h"

#import "CWTimeSingleton.h"

#import <AssetsLibrary/AssetsLibrary.h>

// Uniform index.
enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_EYE_POSITION,
    UNIFORM_SUN_VECTOR,
    UNIFORM_SUN_COLOR,
    UNIFORM_AMBIENT_INTENSITY,
    UNIFORM_TEXTURE_SAMPLER,
    UNIFORM_TEXTURE_SAMPLER2,
    UNIFORM_THE_TIME,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

@interface CWViewController () {
    GLuint _program;
    
    GLKMatrix4 _modelViewMatrix;
    GLKMatrix4 _projectionMatrix;
    GLKMatrix4 _modelViewProjectionMatrix;
    
    GLKVector3 _lookAt;
    
    CGPoint _pan;
    float _zoom;
    
    float _animationLambda;
    CWWindow * _pickedWindow;
    
    NSTimeInterval _lastRandomImage;
    NSInteger _lastRandomIndex;
}
@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) ALAssetsLibrary * assetsLibrary;
@property (strong, nonatomic) NSMutableArray * mutableAssets;

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
@synthesize toolbar = _toolbar;
@synthesize assetsLibrary=_assetsLibrary;
@synthesize mutableAssets = _mutableAssets;

#define MAX_PAN 300

- (GLKVector3) solveZZeroWith:(GLKVector3)p1 and:(GLKVector3)p2 iterations:(int)iterations
{
    GLKVector3 half = GLKVector3Lerp(p1, p2, 0.5f);
    if (iterations>25)
        return half;
    
    
    if (half.z >0)
    {
        return [self solveZZeroWith:half and:p2 iterations:iterations+1];
    } else {
        return [self solveZZeroWith:p1 and:half iterations:iterations+1];
    }
}

- (void) tapRecognizerFired:(UITapGestureRecognizer*)tapGestureRecognizer
{
    
    CGPoint location = [tapGestureRecognizer locationInView:self.view];
    
    if (_pickedWindow)
    {
        if (location.y < self.toolbar.frame.size.height)
            return;
    }
    
    /*[UIView animateWithDuration:0.5 animations:^{
     self.toolbar.alpha = 1.0f;
     }];*/
    
    GLKVector3 window_coord = GLKVector3Make(location.x,self.view.frame.size.height-location.y, 0.0f);
    bool result;
    int viewport[4];
    viewport[0] = 0.0f;
    viewport[1] = 0.0f;
    viewport[2] = self.view.frame.size.width;
    viewport[3] = self.view.frame.size.height;
    GLKVector3 near_pt = GLKMathUnproject(window_coord, _modelViewMatrix, _projectionMatrix, &viewport[0], &result);
    window_coord = GLKVector3Make(location.x,self.view.frame.size.height-location.y, 1.0f);
    GLKVector3 far_pt = GLKMathUnproject(window_coord, _modelViewMatrix, _projectionMatrix, &viewport[0], &result);
    
    GLKVector3 pointInPlane = [self solveZZeroWith:near_pt and:far_pt iterations:0];
    
    for (CWWindow * window in self.windows)
    {
        if ([window containsPoint:pointInPlane])
        {
            [self randomImageForWindow:window];
            _animationLambda = 0.0f;
            _pickedWindow = window;
            return;
        }
    }
}

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

- (void) pinchGestureRecognizerFired:(UIPinchGestureRecognizer*)pinchGestureRecognizer
{
    _zoom /= [pinchGestureRecognizer scale];
    pinchGestureRecognizer.scale = 1.0f;
    
    if (_zoom >4.0)
        _zoom = 4.0;
    
    if (_zoom < 1.0)
        _zoom = 1.0;
}

- (void)loadAssets
{
    self.assetsLibrary = [[ALAssetsLibrary alloc] init];
    self.mutableAssets = [NSMutableArray arrayWithCapacity:1024];
    
    [self.assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if ([group numberOfAssets])
        {
            
            [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                if (result)
                {
                    [self.mutableAssets addObject:result];
                }
            } ];
        }
    } failureBlock:^(NSError *error) {
        NSLog(@"fail");
    }];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIPanGestureRecognizer * panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognizerFired:)];
    [self.view addGestureRecognizer:panGestureRecognizer];
    
    UIPinchGestureRecognizer * pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGestureRecognizerFired:)];
    [self.view addGestureRecognizer:pinchGestureRecognizer];
    
    UITapGestureRecognizer * tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapRecognizerFired:)];
    tapRecognizer.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapRecognizer];
    
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [self setupGL];
    [self performSelectorInBackground:@selector(loadAssets) withObject:nil];
}

- (void)viewDidUnload
{
    [self setToolbar:nil];
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
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) randomImageForWindow:(CWWindow*)window
{
    if (![self.mutableAssets count])
    {
        [self performSelector:@selector(randomImageForWindow:) withObject:window afterDelay:1.0];
        return;
    }
    
    NSInteger i = rand() % [self.mutableAssets count];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        ALAsset * asset = [self.mutableAssets objectAtIndex:i];
        [window pushImage:[UIImage imageWithCGImage:[asset thumbnail]]];
    });
}

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
    
    [self loadShaders];
    
    glEnable(GL_DEPTH_TEST);
    glDisable(GL_BLEND);
//    glBlendFunc(GL_ONE, GL_SRC_COLOR);
    
    _zoom = 4.0f;
    
    CWWindowShape * shape = [[CWWindowShape alloc] init];
    
    NSMutableArray * mutableWindows = [NSMutableArray arrayWithCapacity:24];
    
    [mutableWindows addObject:[[CWWindow alloc] initWithOrigin:GLKVector3Make(0, 0, 0) scale:1.2 andWindowShape:shape]];
    
    for (int i = 0; i < 12; i++)
    {
        shape = [[CWWindowShape alloc] init];
        shape.shapeType = CWWST_FIRST;
        
        float t = i/6.0f * M_PI;
        GLKVector3 origin = GLKVector3Make(cosf(t), sin(t), 0);
        
        shape.rotation = t;
        
        [mutableWindows addObject:[[CWWindow alloc] initWithOrigin:origin scale:1.0 andWindowShape:shape]];
        
        GLKVector3 origin2 = GLKVector3Make(1.37*cosf(t+M_PI_2 / 6.0f), 1.37*sin(t+M_PI_2 / 6.0f), 0);
        
        shape = [[CWWindowShape alloc] init];
        shape.shapeType = CWWST_ROUND;
        
        [mutableWindows addObject:[[CWWindow alloc] initWithOrigin:origin2 scale:0.25 andWindowShape:shape]];
    }
    
    
    self.windows = [NSArray arrayWithArray:mutableWindows];
    
    [self.windows enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self randomImageForWindow:(CWWindow*)obj];
    }];
    
    glUseProgram(_program);
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
    self.windows = nil; // releases and tears down windows
    
    
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
}

- (GLKVector3) eyePosition
{
    float x = -_pan.x / MAX_PAN;
    float y = _pan.y / MAX_PAN;
    
    float z = 0.4;
    
    GLKVector3 eye = GLKVector3Make(x, y, z);
    eye = GLKVector3Normalize(eye);
    eye = GLKVector3MultiplyScalar(eye, _zoom);
    
    eye.x += _lookAt.x;
    eye.y += _lookAt.y;
    
    return eye;
}

#pragma mark - GLKView and GLKViewController delegate methods


- (void)update
{
    [[CWTimeSingleton sharedInstance] addTime:self.timeSinceLastUpdate];
    
    /*
     // disabled for now, because it is irritating
    NSTimeInterval t = [[CWTimeSingleton sharedInstance] currentTime];
    
    if (t - _lastRandomImage > 1.0)
    {
        NSInteger windowIndex = rand() % [self.windows count];
        
        if (windowIndex != _lastRandomIndex)
        {
            [self randomImageForWindow:[self.windows objectAtIndex:windowIndex]];
            
            _lastRandomImage = t;
            _lastRandomIndex = windowIndex;
        }
    }
    */
    
    _animationLambda += self.timeSinceLastUpdate/2.0;
    if (_animationLambda > 1)
        _animationLambda = 1;
    
    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    _projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(55.0f), aspect, 0.1f, 100.0f);
    
    GLKVector3 lookAt = _lookAt;
    
    GLKVector3 targetLookAt = GLKVector3Make(0, 0, 0);
    if (_pickedWindow)
    {
        targetLookAt = _pickedWindow.origin;
    }
    
    lookAt = GLKVector3Lerp(lookAt, targetLookAt, _animationLambda);
    _lookAt = lookAt;
    
    GLKVector3 eye = [self eyePosition];
    _modelViewMatrix = GLKMatrix4MakeLookAt(eye.x,eye.y,eye.z, lookAt.x, lookAt.y, lookAt.z, 0, 1, 0);
    
    _modelViewProjectionMatrix = GLKMatrix4Multiply(_projectionMatrix, _modelViewMatrix);
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(0.01f, 0.01f, 0.02f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    GLKVector3 eye = [self eyePosition];
    glUniform3f(uniforms[UNIFORM_EYE_POSITION], eye.x, eye.y,eye.z);
    float theTime = [[CWTimeSingleton sharedInstance] currentTime];
    glUniform1f(uniforms[UNIFORM_THE_TIME], theTime);
    
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _modelViewProjectionMatrix.m);
    
    float t = self.timeSinceFirstResume;
    
    t = 4;
    
    GLKVector3 sunVector = GLKVector3Normalize(GLKVector3Make(cosf(t), -0.4*sinf(t),sinf(t)));
    glUniform3f(uniforms[UNIFORM_SUN_VECTOR], sunVector.x, sunVector.y, sunVector.z);
    glUniform3f(uniforms[UNIFORM_SUN_COLOR], 1.0f, 0.95f, 0.75f);
    
    glUniform1f(uniforms[UNIFORM_AMBIENT_INTENSITY], 0.3+0.1*sinf(t));
    
    glActiveTexture(GL_TEXTURE0);
    glUniform1i(uniforms[UNIFORM_TEXTURE_SAMPLER], 0);
    
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
    glBindAttribLocation(_program, ATTRIB_TEXCOORDS, "texCoords");
    glBindAttribLocation(_program, ATTRIB_LOCALCOORDS, "localCoords");
    glBindAttribLocation(_program, ATTRIB_VERTEX2, "position2");
    glBindAttribLocation(_program, ATTRIB_COLOR2, "diffuse2");
    glBindAttribLocation(_program, ATTRIB_TEXCOORDS2, "texCoords2");
    glBindAttribLocation(_program, ATTRIB_ANIMATION_START_TIME, "animationStartTime");
    
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
    
    uniforms[UNIFORM_TEXTURE_SAMPLER] = glGetUniformLocation(_program, "Texture");
    uniforms[UNIFORM_TEXTURE_SAMPLER2] = glGetUniformLocation(_program, "Texture2");
    uniforms[UNIFORM_THE_TIME] = glGetUniformLocation(_program, "theTime");
    
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

- (void) deselectPickedWindow
{
    _pickedWindow = nil;
    _animationLambda=0.0;
    
    [UIView animateWithDuration:0.5 animations:^{
        self.toolbar.alpha = 0.0f;
    }];
}

- (IBAction)donePressed:(id)sender {
    [self deselectPickedWindow];
}

- (IBAction)cameraPressed:(id)sender {
    if ([UIImagePickerController isSourceTypeAvailable:
         UIImagePickerControllerSourceTypePhotoLibrary])
    {
        UIImagePickerController *imagePicker =
        [[UIImagePickerController alloc] init];
        imagePicker.delegate = self;
        imagePicker.sourceType =
        UIImagePickerControllerSourceTypePhotoLibrary;
        imagePicker.allowsEditing = YES;
        [self presentModalViewController:imagePicker
                                animated:YES];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo
{
    [_pickedWindow pushImage:image];
    
    [self deselectPickedWindow];
    
    [picker dismissModalViewControllerAnimated:YES];
}

- (IBAction)actionPressed:(id)sender {
}
@end

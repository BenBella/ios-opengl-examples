//
//  OpenGLView.m
//  HelloOpenGL
//
//  Created by ; Andrlík on 2/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OpenGLView.h"
#import "CC3GLMatrix.h"

typedef struct {
    float Position[3];
    float Color[4];
} Vertex;

const Vertex Vertices[] = {
    {{1,-1,0},{1,0,0,1}},
    {{1,1,0},{0,0,0,1}},
    {{-1,1,0},{0,1,0,1}},
    {{-1,-1,0},{0,1,0,1}},
    {{1,-1,-1},{1,0,0,1}},
    {{1,1,-1},{0,0,0,1}},
    {{-1,1,-1},{0,1,0,1}},
    {{-1,-1,-1},{0,1,0,1}}
};

const GLubyte Indices[] = {
    // Front
    0, 1, 2,
    2, 3, 0,
    // Back
    4, 6, 5,
    4, 7, 6,
    // Left
    2, 7, 3,
    7, 6, 2,
    // Right
    0, 4, 1,
    4, 1, 5,
    // Top
    6, 2, 1,
    1, 6, 5,
    // Bottom
    0, 3, 7,
    0, 7, 4
};

@implementation OpenGLView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setupLayer];
        [self setupContext];
        [self setupDepthBuffer];
        [self setupRenderBuffer];
        [self setupFrameBuffer];
        [self compileShaders];
        [self setupVBOs];
        [self setupDisplayLink];
        //[self render];
    }
    return self;
}

+ (Class)layerClass
/* To set up a view display OpenGL content, you need to set it's default layer to sepcial kind of layer caller CAEAGLLayer. The way you set the default layer is to simply overwrite the layerClass mehod. The returned CAEAGLLayer object is a wrapper for a Core Animation surface that is fully compatible with OpenGL ES function calls. */
{
    return [CAEAGLLayer class];
}

- (void)setupLayer 
/* By default, CALayers are set to non-opaque(i.e. transparent). However, this is bad for performance reasons (especially with OpenGL), so it's best to set this opaque when is posible */
{
    _eaglLayer = (CAEAGLLayer *) self.layer;
    [_eaglLayer setOpaque: YES];
}

- (void)setupContext 
/* To do anything with OpenGL, you need to create an EAGLContext, and set the current context to the newly created context.
 
 EAGLContext serve as a 3D rendering surface.
 
 An EAGLContext manages all of the information iOS needs to draw with OpenGL. It's similar to how you need a Core Graphics context to do anything with Core Graphics
 
 When you create a context, you specify what version of the API you want to use. Here, you specify that you want to use OpenGL ES 2.0. If it is not available (such as if the program was run on an iPhone 3GS), the app would terminate. */
{   
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    _context = [[EAGLContext alloc] initWithAPI:api];
    if (!_context) {
        NSLog(@"Failed to initialize OpenGLES 2.0 context");
        exit(1);
    }
    
    if (![EAGLContext setCurrentContext:_context]) {
        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }
}

- (void)setupRenderBuffer
/* (the surface on which the content is rendered)
 
 The next step to use is to create a render buffer, which is an OpenGL object that stores the rendered image to present to the screen.
 
 Sometimes you'll see a render buffer also refered to as a color buffer, because in essence it's storing colours to display!
 
 There are three steps to create a render buffer:
 1. Call glGenRenderBuffers to create a new render buffer object. This returns a unique integer for the render buffer (we store it here in _colorRenderBuffer). Sometimes you'll see this unique integer refered it as an "OpenGL name".
 2. Call glBindRenderbuffer to tell OpenGL "whanever I refer to GL_RENDERBUFFER, I really mean _colorRenderBuffer".
 3. Finaly, allocate some storage for the render buffer. The EAGLContext you created earlier has a method you can use for this called renderbufferStorage */
{
    glGenRenderbuffers(1, &_colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);        
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];    
}

- (void)setupDepthBuffer
{
    glGenRenderbuffers(1, &_depthRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, self.frame.size.width, self.frame.size.height);    
}

- (void)setupFrameBuffer 
/* A frame buffer is an OpenGL object that contains a render buffer, and some other buffers you'll learn about later such as a depth buffer, stencil buffer, and accumulation buffer.
 
 The first two steps for creating a frame buffer is very similar to creating a render buffer - it uses the glGen and  glBind like you'have seen before, just ending with "FrameBuffer" instead of "RenderBuffer"
 
 The last function call (glFramebufferRenderbufer) is now however. It lets you attach the render buffer you created  earlier to the frame buffer's GL_COLOR_ATTACHMENT0 slot */
{
    GLuint framebuffer;
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);   
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthRenderBuffer);
}

- (GLuint)compileShader:(NSString *)shaderName withTipe:(GLenum)shaderType 
/* You might be surprised by this (it’s kinda weird to have an app compiling code on the fly!), but it’s set up this way so that the shader code isn’t dependent on any particular graphics chip, etc. */
{
    /* Gets an NSString with the contents of the file. This is regular old UIKit programming, many of you should be used to this kind of stuff already. */
    NSString * shaderPath = [[NSBundle mainBundle] pathForResource: shaderName ofType: @"glsl"];
    NSError * error;
    NSString * shaderString = [NSString stringWithContentsOfFile: shaderPath encoding: NSUTF8StringEncoding error: &error];
    if (!shaderString) {
        NSLog(@"Error loading shader: %@", error.localizedDescription);
        exit(1);
    }
    
    /* Calls glCreateShader to create a OpenGL object to represent the shader. When you call this function you need to pass in a shaderType to indicate whether it’s a fragment or vertex shader. We take ethis as a parameter to this method. */
    GLuint shaderHandle = glCreateShader(shaderType);
    
    /* Calls glShaderSource to give OpenGL the source code for this shader. We do some conversion here to convert the source code from an NSString to a C-string. */
    const char * shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLenght = [shaderString length];
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLenght);
    
    /* Finally, calls glCompileShader to compile the shader at runtime! */
    glCompileShader(shaderHandle);
    
    /* This can fail – and it will in practice if your GLSL code has errors in it. When it does fail, it’s useful to get some output messages in terms of what went wrong. This code uses glGetShaderiv and glGetShaderInfoLog to output any error messages to the screen (and quit so you can fix the bug!) */
    GLint compileSucces;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSucces);
    if (compileSucces == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSString * messageString = [NSString stringWithUTF8String: messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    return shaderHandle;
}

- (void)compileShaders 
{
    
    /* Vertex shaders are programs that get called once per vertex in your scene. So if you are rendering a simple scene with a single square, with one vertex at each corner, this would be called four times. Its job is to perform some calculations such as lighting, geometry transforms, etc., figure out the final position of the vertex, and also pass on some data to the fragment shader. */
    GLuint vertexShader = [self compileShader:@"SimpleVertex" withTipe:GL_VERTEX_SHADER];
    
    /* Fragment shaders are programs that get called once per pixel (sort of) in your scene. So if you’re rendering that same simple scene with a single square, it will be called once for each pixel that the square covers. Fragment shaders can also perform lighting calculations, etc, but their most important job is to set the final color for the pixel. */
    GLuint fragmentShader = [self compileShader:@"SimpleFragment" withTipe:GL_FRAGMENT_SHADER];
    
    /* Calls glCreateProgram, glAttachShader, and glLinkProgram to link the vertex and fragment shaders into a complete program. (loads shaders to the GPU) */
    GLuint programHandle = glCreateProgram();
    glAttachShader(programHandle, vertexShader);
    glAttachShader(programHandle, fragmentShader);
    glLinkProgram(programHandle);
    
    /* Calls glGetProgramiv and glGetProgramInfoLog to check and see if there were any link errors, and display the output and quit if so. */
    GLint linkSuccess;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(programHandle, sizeof(messages), 0, &messages[0]);
        NSString * messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    /* Calls glUseProgram to tell OpenGL to actually use this program when given vertex info. */
    glUseProgram(programHandle);
    
    /* Finally, calls glGetAttribLocation to get a pointer to the input values for the vertex shader, so we can set them in code. Also calls glEnableVertexAttribArray to enable use of these arrays (they are disabled by default). */
    _positionSlot = glGetAttribLocation(programHandle, "Position");
    _colorSlot = glGetAttribLocation(programHandle, "SourceColor");
    glEnableVertexAttribArray(_positionSlot);
    glEnableVertexAttribArray(_colorSlot);
    
    _projectionUniform = glGetUniformLocation(programHandle, "Projection");
    _modelViewUniform = glGetUniformLocation(programHandle, "ModelView");
}

- (void)setupVBOs
/* The best way to send data to OpenGL is through something called Vertex Buffer Objects. Basically these are OpenGL objects that store buffers of vertex data for you. You use a few function calls to send your data over to OpenGL-land.
 
 There are two types of vertex buffer objects – one to keep track of the per-vertex data (like we have in the Vertices array), and one to keep track of the indices that make up triangles (like we have in the Indices array). */
{
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
    
    GLuint indexBuffer;
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
}

- (void)setupDisplayLink
/* Ideally we would like to synchronize the time we render with OpenGL to the rate at which the screen refreshes. */
{
    CADisplayLink * displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)render:(CADisplayLink *)displayLink
/* Call glClearColor to specify the RGB and alpha (transparency) values to use when clearing the screen.
 
 Call glClear to actually perform the clearing. Remember that there can be different types of buffers, such as the render/colour buffer we're displaying, and others we're not using yet such as depth or stencil buffers. Here we use the GL_COLOR_BUFFER_BIT to specify what exactly to clear - in this case, the current render/color buffer.
 
 Call a method on the OpenGL context to present the render/color buffer to the UIVie's layer.
*/
{
    glClearColor(47.0/255.0, 47.0/255.0, 47.0/255.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);
    
    /* Projection */
    CC3GLMatrix * projection = [CC3GLMatrix matrix];
    float h = 4.0f * self.frame.size.height / self.frame.size.width;
    [projection populateFromFrustumLeft:-2 andRight:2 andBottom:-h/2 andTop:h/2 andNear:4 andFar:10];
    glUniformMatrix4fv(_projectionUniform, 1, 0, projection.glMatrix);
    
    /* Transformation */
    CC3GLMatrix * modelView = [CC3GLMatrix matrix];
    [modelView populateFromTranslation:CC3VectorMake(sin(CACurrentMediaTime()), 0, -7)];
    
    _currentRotation += displayLink.duration * 90;
    [modelView rotateBy:CC3VectorMake(_currentRotation, _currentRotation, 0)];
    
    glUniformMatrix4fv(_modelViewUniform, 1, 0, modelView.glMatrix);
    
    /* Calls glViewport to set the portion of the UIView to use for rendering. This sets it to the entire window, but if you wanted a smallar part you could change these values. */
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    
    /* Calls glVertexAttribPointer to feed the correct values to the two input variables for the vertex shader – the Position and SourceColor attributes. 
     
     This is a particularly important function so let’s go over how it works carefully.
     
     The first parameter specifies the attribute name to set. We got these earlier when we called glGetAttribLocation.
     The second parameter specifies how many values are present for each vertex. If you look back up at the Vertex struct, you’ll see that for the position there are three floats (x,y,z) and for the color there are four floats (r,g,b,a).
     The third parameter specifies the type of each value – which is float for both Position and Color.
     The fourth parameter is always set to false.
     The fifth parameter is the size of the stride, which is a fancy way of saying “the size of the data structure containing the per-vertex data”. So we can simply pass in sizeof(Vertex) here to get the compiler to compute it for us.
     The final parameter is the offset within the structure to find this data. The position data is at the beginning of the structure so we can pass 0 here, the color data is after the Position data (which was 3 floats, so we pass 3 * sizeof(float)). */
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);
    glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid*) (sizeof(float) * 3));
    
    /* This is also an important function so let’s discuss each parameter here as well.
     
     The first parameter specifies the manner of drawing the vertices. There are different options you may come across in other tutorials like GL_LINE_STRIP or GL_TRIANGLE_FAN, but GL_TRIANGLES is the most generically useful (especially when combined with VBOs) so it’s what we cover here.
     The second parameter is the count of vertices to render. We use a C trick to compute the number of elements in an array here by dividing the sizeof(Indices) (which gives us the size of the array in bytes) by sizeof(Indices[0]) (which gives us the size of the first element in the arary).
     The third parameter is the data type of each individual index in the Indices array. We’re using an unsigned byte for that so we specify that here.
     From the documentation, it appears that the final parameter should be a pointer to the indices. But since we’re using VBOs it’s a special case – it will use the indices array we already passed to OpenGL-land in the GL_ELEMENT_ARRAY_BUFFER. */
    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
    
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)dealloc
{
    [_context release];
    _context = nil;
    [super dealloc];
}

@end

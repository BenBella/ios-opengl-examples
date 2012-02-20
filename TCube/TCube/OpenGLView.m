//
//  OpenGLView.m
//  HelloOpenGL
//
//  Created by ; Andrlík on 2/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OpenGLView.h"
#import "CC3GLMatrix.h"

#define TEX_COORD_MAX   4

typedef struct {
    float Position[3];
    float Color[4];
    float TexCoord[2];
} Vertex;

const Vertex Vertices[] = {    
    // Front
    {{1, -1, 0}, {80.0/255.0,80.0/255.0,80.0/255.0,1}, {TEX_COORD_MAX, 0}},
    {{1, 1, 0}, {240.0/255.0,240.0/255.0,240.0/255.0,1}, {TEX_COORD_MAX, TEX_COORD_MAX}},
    {{-1, 1, 0}, {150.0/255.0,150.0/255.0,150.0/255.0,1}, {0, TEX_COORD_MAX}},
    {{-1, -1, 0}, {255.0/255.0,255.0/255.0,255.0/255.0,1}, {0, 0}},
    // Back
    {{1, 1, -2}, {80.0/255.0,80.0/255.0,80.0/255.0,1}, {TEX_COORD_MAX, 0}},
    {{-1, -1, -2}, {240.0/255.0,240.0/255.0,240.0/255.0,1}, {TEX_COORD_MAX, TEX_COORD_MAX}},
    {{1, -1, -2}, {150.0/255.0,150.0/255.0,150.0/255.0,1}, {0, TEX_COORD_MAX}},
    {{-1, 1, -2}, {255.0/255.0,255.0/255.0,255.0/255.0,1}, {0, 0}},
    // Left
    {{-1, -1, 0}, {80.0/255.0,80.0/255.0,80.0/255.0,1}, {TEX_COORD_MAX, 0}}, 
    {{-1, 1, 0}, {240.0/255.0,240.0/255.0,240.0/255.0,1}, {TEX_COORD_MAX, TEX_COORD_MAX}},
    {{-1, 1, -2}, {150.0/255.0,150.0/255.0,150.0/255.0,1}, {0, TEX_COORD_MAX}},
    {{-1, -1, -2}, {255.0/255.0,255.0/255.0,255.0/255.0,1}, {0, 0}},
    // Right
    {{1, -1, -2}, {80.0/255.0,80.0/255.0,80.0/255.0,1}, {TEX_COORD_MAX, 0}},
    {{1, 1, -2}, {240.0/255.0,240.0/255.0,240.0/255.0,1}, {TEX_COORD_MAX, TEX_COORD_MAX}},
    {{1, 1, 0}, {150.0/255.0,150.0/255.0,150.0/255.0,1}, {0, TEX_COORD_MAX}},
    {{1, -1, 0}, {255.0/255.0,255.0/255.0,255.0/255.0,1}, {0, 0}},
    // Top
    {{1, 1, 0}, {80.0/255.0,80.0/255.0,80.0/255.0,1}, {TEX_COORD_MAX, 0}},
    {{1, 1, -2}, {240.0/255.0,240.0/255.0,240.0/255.0,1}, {TEX_COORD_MAX, TEX_COORD_MAX}},
    {{-1, 1, -2}, {150.0/255.0,150.0/255.0,150.0/255.0,1}, {0, TEX_COORD_MAX}},
    {{-1, 1, 0}, {255.0/255.0,255.0/255.0,255.0/255.0,1}, {0, 0}},
    // Bottom
    {{1, -1, -2}, {80.0/255.0,80.0/255.0,80.0/255.0,1}, {TEX_COORD_MAX, 0}},
    {{1, -1, 0}, {240.0/255.0,240.0/255.0,240.0/255.0,1}, {TEX_COORD_MAX, TEX_COORD_MAX}},
    {{-1, -1, 0}, {150.0/255.0,150.0/255.0,150.0/255.0,1}, {0, TEX_COORD_MAX}}, 
    {{-1, -1, -2}, {255.0/255.0,255.0/255.0,255.0/255.0,1}, {0, 0}}
};

const GLubyte Indices[] = {
    // Front
    0, 1, 2,
    2, 3, 0,
    // Back
    4, 5, 6,
    4, 5, 7,
    // Left
    8, 9, 10,
    10, 11, 8,
    // Right
    12, 13, 14,
    14, 15, 12,
    // Top
    16, 17, 18,
    18, 19, 16,
    // Bottom
    20, 21, 22,
    22, 23, 20
};

/* In the first section, we define a new set of vertices for the rectangle where we’ll draw the logo texture. Note we make it a little bit smaller than the front face, and we also make the z coordinate slightly taller so it will show up. Otherwise, it could be discarded by the depth test. */
const Vertex Vertices2[] = {
    {{0.5, -0.5, 0.01}, {1, 1, 1, 1}, {1, 1}},
    {{0.5, 0.5, 0.01}, {1, 1, 1, 1}, {1, 0}},
    {{-0.5, 0.5, 0.01}, {1, 1, 1, 1}, {0, 0}},
    {{-0.5, -0.5, 0.01}, {1, 1, 1, 1}, {0, 1}},
};

const GLubyte Indices2[] = {
    1, 0, 2, 3
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
        _floorTexture = [self setupTexture:@"tile_floor.png"];
        _logoTexture = [self setupTexture:@"DD_logo.png"];
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
    
    _texCoordSlot = glGetAttribLocation(programHandle, "TexCoordIn");
    glEnableVertexAttribArray(_texCoordSlot);
    _textureUniform = glGetUniformLocation(programHandle, "Texture");
}

- (void)setupVBOs
/* The best way to send data to OpenGL is through something called Vertex Buffer Objects. Basically these are OpenGL objects that store buffers of vertex data for you. You use a few function calls to send your data over to OpenGL-land.
 
 There are two types of vertex buffer objects – one to keep track of the per-vertex data (like we have in the Vertices array), and one to keep track of the indices that make up triangles (like we have in the Indices array). */
{
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
    
    glGenBuffers(1, &_indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
    
    glGenBuffers(1, &_vertexBuffer2);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer2);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices2), Vertices2, GL_STATIC_DRAW);
    
    glGenBuffers(1, &_indexBuffer2);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer2);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices2), Indices2, GL_STATIC_DRAW);
}

- (GLuint)setupTexture:(NSString *)fileName {    
    /* Get Core Graphics image reference. As you can see this is the simplest step. We just use the UIImage imageNamed initializer I’m sure you’ve seen many times, and then access its CGImage property. */
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
    if (!spriteImage) {
        NSLog(@"Failed to load image %@", fileName);
        exit(1);
    }
    
    /* Create Core Graphics bitmap context. To create a bitmap context, you have to allocate space for it yourself. Here we use some function calls to get the width and height of the image, and then allocate width*height*4 bytes.
     
     “Why times 4?” you may wonder. When we call the method to draw the image data, it will write one byte each for red, green, blue, and alpha – so 4 bytes in total.
     
     “Why 1 byte per each?” you may wonder. Well, we tell Core Graphics to do this when we set up the context. The fourth parameter to CGBitmapContextCreate is the bits per component, and we set this to 8 bits (1 byte). */
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    GLubyte * spriteData = (GLubyte *) calloc(width*height*4, sizeof(GLubyte));
    
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4, 
                                                       CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);    
    
    /* Draw the image into the context. This is also a pretty simiple step – we just tell Core Graphics to draw the image at the specified rectangle. Since we’re done with the context at this point, we can release it. */
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    
    CGContextRelease(spriteContext);
    
    /* Send the pixel data to OpenGL. We first need to call glGenTextures to create a texture object and give us its unique ID (called “name”). */
    GLuint texName;
    glGenTextures(1, &texName);
    glBindTexture(GL_TEXTURE_2D, texName);
    
    /* Setting the GL_TEXTURE_MIN_FILTER is actually required if you aren’t using mipmaps (like this case!) I didn’t know this at first and didn’t include this line, and nothing showed up. I found out later on that this is actually listed in the OpenGL common mistakes – d’oh */
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST); 
    
    /* The final step is to send the pixel data buffer we created earlier over to OpenGL with glTexImage2D. When you call this function, you specify the format of the pixel data you send in. Here we specify GL_RGBA and GL_UNSIGNED_BYTE to say “there’s 1 byte for red, green, blue, and alpha.” */
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    free(spriteData);        
    return texName;    
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
    glClearColor(200.0/255.0, 200.0/255.0, 200.0/255.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);
    
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);
    
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
    
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    
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
    
    
    /*
    */
    glVertexAttribPointer(_texCoordSlot, 2, GL_FLOAT, GL_FALSE, 
                          sizeof(Vertex), (GLvoid*) (sizeof(float) * 7));    
    
    /* First, we activate the texture unit we want to load our texture into. On iOS, we’re guaranteed to have at least 2 texture units, and most of the time 8. This can be good if you need to perform computations on more than one texture at a time. However, for this tutorial, we don’t really need to use more than one texture unit at a time, so we’ll just stick the first texture unit (GL_TEXTURE0). 
     
        Note that lines 1 and 3 aren’t strictly necessary, and a lot of times you’ll see code that doesn’t even include those lines. This is because it’s assuming GL_TEXTURE0 is already the active texture unit, and doesn’t bother setting the uniform because it defaults to 0 anyway. */
    glActiveTexture(GL_TEXTURE0); 
    glBindTexture(GL_TEXTURE_2D, _floorTexture);
    glUniform1i(_textureUniform, 0);
    
    /* This is also an important function so let’s discuss each parameter here as well.
     
     The first parameter specifies the manner of drawing the vertices. There are different options you may come across in other tutorials like GL_LINE_STRIP or GL_TRIANGLE_FAN, but GL_TRIANGLES is the most generically useful (especially when combined with VBOs) so it’s what we cover here.
     The second parameter is the count of vertices to render. We use a C trick to compute the number of elements in an array here by dividing the sizeof(Indices) (which gives us the size of the array in bytes) by sizeof(Indices[0]) (which gives us the size of the first element in the arary).
     The third parameter is the data type of each individual index in the Indices array. We’re using an unsigned byte for that so we specify that here.
     From the documentation, it appears that the final parameter should be a pointer to the indices. But since we’re using VBOs it’s a special case – it will use the indices array we already passed to OpenGL-land in the GL_ELEMENT_ARRAY_BUFFER. */
    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
    
    
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer2);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer2);
    
    glActiveTexture(GL_TEXTURE0); 
    glBindTexture(GL_TEXTURE_2D, _logoTexture);
    glUniform1i(_textureUniform, 0); 
    
    glUniformMatrix4fv(_modelViewUniform, 1, 0, modelView.glMatrix);
    
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);
    glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid*) (sizeof(float) * 3));
    glVertexAttribPointer(_texCoordSlot, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid*) (sizeof(float) * 7));
    
    glDrawElements(GL_TRIANGLE_STRIP, sizeof(Indices2)/sizeof(Indices2[0]), GL_UNSIGNED_BYTE, 0);
    
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

- (void)clear
{
    glClearColor(200.0/255.0, 200.0/255.0, 200.0/255.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

- (void)dealloc
{
    [_context release];
    _context = nil;
    [super dealloc];
}

@end

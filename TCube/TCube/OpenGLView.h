//
//  OpenGLView.h
//  HelloOpenGL
//
//  Created by Lukáš Andrlík on 2/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>

@interface OpenGLView : UIView {
    CAEAGLLayer * _eaglLayer;
    EAGLContext * _context;
    GLuint _vertexBuffer;
    GLuint _indexBuffer;
    GLuint _vertexBuffer2;
    GLuint _indexBuffer2;
    GLuint _colorRenderBuffer;
    GLuint _depthRenderBuffer;
    GLuint _positionSlot;
    GLuint _colorSlot;
    GLuint _floorTexture;
    GLuint _logoTexture;
    GLuint _texCoordSlot;
    GLuint _textureUniform;
    GLuint _projectionUniform;
    GLuint _modelViewUniform;
    float _currentRotation;
}

+ (Class)layerClass;
- (void)setupLayer;
- (void)setupContext;
- (void)setupDepthBuffer;
- (void)setupRenderBuffer;
- (void)setupFrameBuffer;
- (GLuint)compileShader:(NSString *)shaderName withTipe:(GLenum)shaderType;
- (void)compileShaders;
- (void)setupVBOs;
- (GLuint)setupTexture:(NSString *)fileName;
- (void)setupDisplayLink;
- (void)render:(CADisplayLink *)displayLink;
- (void)clear;
@end

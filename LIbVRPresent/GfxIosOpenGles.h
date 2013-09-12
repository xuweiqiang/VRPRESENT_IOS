//
//  GfxIosOpenGles.h
//  LIbVRPresent
//
//  Created by weiqiang xu on 11/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "ESRender.h"
#import <UIKit/UIKit.h>

//#define OLDVERSION

#define FLUSH_TEXUTRE 0xff 
typedef struct _vertexStruct
{
    GLfloat position[3];
    GLfloat color[4];
    GLfloat texCoord[2];
} vertexStruct;

typedef struct
{
    Boolean valid;
    vertexStruct parms[4];
    GLuint width;
    GLuint height;
    long format;
    
    GLuint miWidth;
    GLuint miHeight;
    Rect srcRect;
    Rect dstRect;
    GLuint textueId;
    Boolean hidden;
    GLfloat alpha;
    
    GLuint vertexbufferId;
    GLuint indexbufferId;
    GLfloat colorKey[4];
}STextureParams;
#define MAX_SURFACENUM  4
@interface GfxIosOpenGles : NSObject <ESRender>
{
    GLuint _defaultFBOName;
    GLuint _colorRenderbuffer;
    GLint backingWidth;
    GLint backingHeight;
    
    GLuint _viewWidth;
    GLuint _viewHeight;
    
    GLuint _positionSlot;
    GLuint _colorSlot;
    GLuint _texCoordSlot;
    GLuint _textureUniform;
    GLuint _textureUniform2;
    
    GLuint _brightness;
    GLuint _contrast;
    EAGLContext * _context;
    
    CAEAGLLayer* m_layer;
    float m_aspectRatio;
    
    STextureParams mSurfaces[MAX_SURFACENUM*3];
    Boolean mInit;
    GLuint m_programHandle;
    GLuint m_vertexShader;
    GLuint m_fragmentShader;
    
    GLuint _Y_TextureUniform;
    GLuint _U_TextureUniform;
    GLuint _V_TextureUniform;
    
    GLuint _Y2_TextureUniform;
    GLuint _U2_TextureUniform;
    GLuint _V2_TextureUniform;
    
    GLuint _bUsingYUV_TextureUniform;
    GLuint _bUsingRGB;
    GLuint _colorKey_TextureUniform;
    GLuint _alpha;
    
    UIApplicationState mApplicationState;
}

-(GLuint) compileShader:(NSString*)shaderName withType:(GLenum)shaderType;
- (GLuint) compileShaderCode:(NSString*)shadercode withType:(GLenum)shaderType;
-(void) compileShaders;
-(GLfloat) getMiPercent:(GLuint)width;
-(GLuint) getMiValue:(GLuint)width;
- (void) deallocOnMainThread;

@property (retain,nonatomic)   EAGLContext * _context;

@end

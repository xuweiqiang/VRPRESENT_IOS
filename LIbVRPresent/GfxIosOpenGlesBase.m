//
//  GfxIosOpenGlesBase.m
//  LIbVRPresent
//
//  Created by weiqiang xu on 11/28/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "GfxIosOpenGlesBase.h"
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

#ifndef MAKEFOURCC
#define MAKEFOURCC(ch0,ch1,ch2,ch3)	\
((int)(char)(ch0) | (int)(char)(ch1)<<8| (int)(char)(ch2)<<16| (int)(char)(ch3)<<24)
#endif


@implementation GfxIosOpenGlesBase

const GLfloat vertices[] = {
    1,-1,0,
    1,1,0,    
    -1,1,0,    
    -1,-1,0
};

GLfloat verticesTexcoords[] = {
    1, 1,
    1, 0,
    0, 0,
    0, 1,
};


- (id<ESRender>) initWithContext:(EAGLContext *)context AndDrawable:(id<EAGLDrawable>)drawable width:(GLuint)width 
                          height:(GLuint)height format:(long)format
{
	self = [super init];

    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
    
    if (!_context || ![EAGLContext setCurrentContext:_context])
    {
        [self release];
        return nil;
    }

   
    m_dwWidth = width;
    m_dwHeight = height;
    m_dwMiWidth = [self getMiValue:width];
    m_dwMiHeight   = [self getMiValue:height];
    m_format = format;
    
    GLfloat widthPercent =  [self getMiPercent:m_dwWidth];
    GLfloat heightPercent =  [self getMiPercent:m_dwHeight];

    for(int i=0;i<sizeof(verticesTexcoords)/sizeof(verticesTexcoords[0])/2;i++)
    {
        verticesTexcoords[i*2] *= widthPercent;
        verticesTexcoords[i*2+1] *= heightPercent;
    }

    
    glGenFramebuffersOES(1, &defaultFramebuffer);
    glGenRenderbuffersOES(1, &colorRenderbuffer);
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, defaultFramebuffer);
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
    glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, colorRenderbuffer);

    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrthof(-1.0f, 1.0f, -1.0f, 1.0f, -1.0f, 1.0f);
	glMatrixMode(GL_MODELVIEW);
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glEnableClientState(GL_VERTEX_ARRAY);
    glTexCoordPointer(2, GL_FLOAT, 0, verticesTexcoords);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);

    glGenTextures(1, &m_textueId);

    glBindTexture(GL_TEXTURE_2D, m_textueId);
    // Set the texture parameters to use a minifying filter and a linear filer (weighted average)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    // Specify a 2D texture image, providing the a pointer to the image data in memory
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, m_dwMiWidth, m_dwMiHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
    
    // Enable use of the texture
    glEnable(GL_TEXTURE_2D);

    return self;

}
- (void)render:(unsigned char*)src_buffer
{
    [EAGLContext setCurrentContext:_context];
    
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, defaultFramebuffer);
    glClear(GL_COLOR_BUFFER_BIT);


    glBindTexture (GL_TEXTURE_2D, m_textueId);

   	
    if (m_format == MAKEFOURCC('R','5','6','5')) {
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, m_dwMiWidth, m_dwMiHeight, 0, GL_RGB, GL_UNSIGNED_SHORT_5_6_5, 0);
        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, m_dwMiWidth, m_dwMiHeight, GL_RGB, GL_UNSIGNED_SHORT_5_6_5, src_buffer);
    }
    else if (m_format == MAKEFOURCC('X','R','G','B')) {
        glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA,  m_dwMiWidth , m_dwMiHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, m_dwMiWidth, m_dwMiHeight, GL_RGBA, GL_UNSIGNED_BYTE, src_buffer);
    }

    
    
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
    [_context presentRenderbuffer:GL_RENDERBUFFER_OES];
	
    GLenum erro = glGetError();
    if (erro!= GL_NO_ERROR) {
        NSLog(@"OPENGLES RENDER ERROR:0x%x \n",erro);
    }


}
- (BOOL)resizeFromLayer:(CAEAGLLayer*)layer
{
	// Allocate color buffer backing based on the current layer size
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:layer];
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
	
    float aspectSrc = (float)m_dwWidth/(float)m_dwHeight;
    float aspectScn = (float)backingWidth/(float)backingHeight;
    
    GLint adjustedWidth = 0;
    GLint adjustedHeight = 0;
    if (m_mode == 0x10) {
        if(aspectSrc > aspectScn)
        {
            adjustedWidth = backingWidth;
            adjustedHeight = adjustedWidth/aspectSrc;
            glViewport(0, (backingHeight-adjustedHeight)/2, adjustedWidth, adjustedHeight);
        }
        else
        {
            adjustedHeight = backingHeight;
            adjustedWidth = adjustedHeight*aspectSrc;
            glViewport((backingWidth-adjustedWidth)/2, 0, adjustedWidth, adjustedHeight);
            
        }
    }
    else    // cropping mode
    {
        if(aspectSrc > aspectScn)
        {
            adjustedHeight = backingHeight;
            adjustedWidth = adjustedHeight*aspectSrc;
            glViewport((backingWidth-adjustedWidth)/2, 0, adjustedWidth, adjustedHeight);
        }    
        else
        {
            adjustedWidth = backingWidth;
            adjustedHeight = adjustedWidth/aspectSrc;
            glViewport(0, (backingHeight-adjustedHeight)/2, adjustedWidth, adjustedHeight);
        }
        
        
    }
    
    
    if (glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES)
	{
		NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
        return NO;
    }
    
    m_layer = layer;
    return YES;
}

- (void) dealloc
{
	// Tear down GL
	if (defaultFramebuffer)
	{
		glDeleteFramebuffersOES(1, &defaultFramebuffer);
		defaultFramebuffer = 0;
	}
	
	if (colorRenderbuffer)
	{
		glDeleteRenderbuffersOES(1, &colorRenderbuffer);
		colorRenderbuffer = 0;
	}
	
    if (m_textueId) {
        glDeleteTextures(1, &m_textueId);
        m_textueId = nil;
    }
	// Tear down context
	if ([EAGLContext currentContext] == _context)
        [EAGLContext setCurrentContext:nil];
	
	[_context release];
	_context = nil;
	
	[super dealloc];
}

- (GLuint) getMiValue:(GLuint)width
{
    switch (width) {
        case 2:
        case 4:
        case 8:
        case 16:
        case 32:
        case 64:
        case 128:
        case 256:
        case 512:
        case 1024:
        case 2056:
            return width;
        default:
            break;
    } 
    GLuint mi =0;
    
    while(width >0)
    {
        mi++;
        width >>= 1;
    }
    return (2<<(mi-1));
}

- (GLfloat) getMiPercent:(GLuint)width
{
    GLuint mivalue = [self getMiValue:width];
    
    return (GLfloat)((GLfloat)width/(GLfloat)mivalue);
}

- (void)SetZoomMode:(long)mode
{
    m_mode = mode;
    [self resizeFromLayer:m_layer];
}



@end

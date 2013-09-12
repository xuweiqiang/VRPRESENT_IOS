//
//  GfxIosOpenGlesBase.h
//  LIbVRPresent
//
//  Created by weiqiang xu on 11/28/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ESRender.h"
#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@interface GfxIosOpenGlesBase : NSObject <ESRender>
{
    EAGLContext * _context;
    GLint backingWidth;
    GLint backingHeight;
    GLuint defaultFramebuffer, colorRenderbuffer;
    GLuint m_dwWidth;
    GLuint m_dwHeight;
    GLuint m_dwMiWidth;
    GLuint m_dwMiHeight;
    GLuint m_textueId;
    long m_format;
    long m_mode;
    CAEAGLLayer* m_layer;

}
- (GLuint) getMiValue:(GLuint)width;
- (GLfloat) getMiPercent:(GLuint)width;

@end

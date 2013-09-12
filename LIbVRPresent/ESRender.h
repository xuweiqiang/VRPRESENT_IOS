//
//  ESRender.h
//  LIbVRPresent
//
//  Created by weiqiang xu on 11/28/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>


#import <UIKit/UIKit.h>

@protocol ESRender <NSObject>

- (id<ESRender>) initWithContext:(EAGLContext *)context AndDrawable:(id<EAGLDrawable>)drawable;
- (GLuint) createTextureWidth:(GLuint) width height:(GLuint) height format:(long)format;
- (void) DestroyTexture:(GLuint)textureId;
- (void) ShowHideTexture:(GLuint)textureId Show:(Boolean)bShow;
- (void) SetSrcRectTexture:(GLuint)textureId rect:(Rect*) pRect;
- (void) SetDestRectTexture:(GLuint)textureId rect:(Rect*) dstRect;
- (void) RenderTexture:(GLuint)textureId buffer:(unsigned char**)bufferArray width:(int *)widthArray height:(int *)heightArray;
- (void) SetAlphaTexture:(GLuint)textureId alpha:(float)alpha;

- (BOOL)resizeFromLayer:(CAEAGLLayer*)layer;
- (int) getWindowWidth:(int*)pWidth height:(int*)pHeight;

- (void) SetBrightness:(float)brightness;
- (void) SetContrast:(float)contrast;
- (void) SetColorKey:(GLuint)textureId y:(float)y u:(float)u v:(float)v;
- (void) GetApplicationState:(UIApplicationState*) pState;


@end

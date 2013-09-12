//
//  GfxIosOpenGles.m
//  LIbVRPresent
//
//  Created by weiqiang xu on 11/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "GfxIosOpenGles.h"

#ifndef MAKEFOURCC
#define MAKEFOURCC(ch0,ch1,ch2,ch3)	\
((int)(char)(ch0) | (int)(char)(ch1)<<8| (int)(char)(ch2)<<16| (int)(char)(ch3)<<24)
#endif

#define FIND_TEXTURE_ID_ORRETURN(i)    \
for (i=0; i<MAX_SURFACENUM; i++) {  \
if (mSurfaces[i].valid && mSurfaces[i].textueId == textureId) { \
break;                      \
}                               \
}                                   \
if (i>=MAX_SURFACENUM) {            \
return;                         \
}


#import <mach/mach.h>



static float cpu_usage()
{
    kern_return_t kr;
    task_info_data_t tinfo;
    mach_msg_type_number_t task_info_count;
    
    task_info_count = TASK_INFO_MAX;
    kr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)tinfo, &task_info_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    
    task_basic_info_t      basic_info;
    thread_array_t         thread_list;
    mach_msg_type_number_t thread_count;
    
    thread_info_data_t     thinfo;
    mach_msg_type_number_t thread_info_count;
    
    thread_basic_info_t basic_info_th;
    uint32_t stat_thread = 0; // Mach threads
    
    basic_info = (task_basic_info_t)tinfo;
    
    // get threads in the task
    kr = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    if (thread_count > 0)
        stat_thread += thread_count;
    
    long tot_sec = 0;
    long tot_usec = 0;
    float tot_cpu = 0;
    int j;
    
    for (j = 0; j < thread_count; j++)
    {
        thread_info_count = THREAD_INFO_MAX;
        kr = thread_info(thread_list[j], THREAD_BASIC_INFO,
                         (thread_info_t)thinfo, &thread_info_count);
        if (kr != KERN_SUCCESS) {
            return -1;
        }
        
        basic_info_th = (thread_basic_info_t)thinfo;
        
        if (!(basic_info_th->flags & TH_FLAGS_IDLE)) {
            tot_sec = tot_sec + basic_info_th->user_time.seconds + basic_info_th->system_time.seconds;
            tot_usec = tot_usec + basic_info_th->system_time.microseconds + basic_info_th->system_time.microseconds;
            tot_cpu = tot_cpu + basic_info_th->cpu_usage / (float)TH_USAGE_SCALE * 100.0;
        }
        
    } // for each thread
    
    return tot_cpu;
}


@implementation GfxIosOpenGles
@synthesize _context;
EAGLContext * _context;
const GLubyte indices[] = {
    0,1,2,
    2,3,0
};


- (GLuint) compileShader:(NSString*)shaderName withType:(GLenum)shaderType
{
    if(mApplicationState != UIApplicationStateActive)
        return 0;

    NSString* shaderPath = [[NSBundle mainBundle] pathForResource:shaderName ofType:@"glsl"];
    NSError* error;
    
    NSString* shaderString = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
    if(!shaderString)
    {
        NSLog(@"FAILED to compileShader \n");
        return 0;
    }
    
    GLuint shaderHandle = glCreateShader(shaderType);
    
    const char* shaderStringUTF8 = [shaderString UTF8String];
    const GLint shaderStringLength = [shaderString length];
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    
    glCompileShader(shaderHandle);
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if(compileSuccess == GL_FALSE)
    {
        NSLog(@"FAILED to compileShader \n");
        return 0;
    }
    return shaderHandle;
}

- (GLuint) compileShaderCode:(NSString*)shadercode withType:(GLenum)shaderType;
{
    if(mApplicationState != UIApplicationStateActive)
        return 0;

    NSString* shaderString = shadercode;
    if(!shaderString)
    {
        NSLog(@"FAILED to compileShader \n");
        return 0;
    }
    
    GLuint shaderHandle = glCreateShader(shaderType);
    
    const char* shaderStringUTF8 = [shaderString UTF8String];
    const GLint shaderStringLength = [shaderString length];
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    
    glCompileShader(shaderHandle);
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if(compileSuccess == GL_FALSE)
    {
        GLint infoLen = 0;
        glGetShaderiv(shaderHandle, GL_INFO_LOG_LENGTH, &infoLen);
        if(infoLen > 1) {
            char* infoLog = (char*)malloc(sizeof(char) * infoLen); 
            glGetShaderInfoLog(shaderHandle, infoLen, NULL, infoLog); 
            NSLog(@"Error compiling shader:\n%s\n", infoLog); 
            free(infoLog);
        } 
        glDeleteShader(shaderHandle);
        return 0;
    }
    return shaderHandle;
}

-(void) compileShaders
{
    if(mApplicationState != UIApplicationStateActive)
        return;

    //    GLuint vertexShader = [self compileShader:@"SimpleVertex" withType:GL_VERTEX_SHADER];
    //    GLuint fragmentShader = [self compileShader:@"SimpleFragment" withType:GL_FRAGMENT_SHADER];
    
    const char vertexShaderCode[] =        "   \
    attribute vec4 Position;        \
    attribute vec4 SourceColor;     \
    attribute vec2 TexCooordIn;     \
    varying vec4 DestinationColor;  \
    varying vec2 TexCoordOut;       \
    void main()                     \
    {                               \
    DestinationColor = SourceColor; \
    gl_Position = Position; \
    TexCoordOut = TexCooordIn;  \
    }   \
    ";
    
    const char fragmengShaderCode_RGB565_MAIN[] =        "   \
    varying lowp vec4 DestinationColor; \
    varying lowp vec2 TexCoordOut;  \
    uniform sampler2D main_texture;    \
    uniform sampler2D Y_texture;    \
    uniform sampler2D U_texture;    \
    uniform sampler2D V_texture;    \
    uniform sampler2D UV_texture;    \
    uniform lowp float Brightness;    \
    uniform lowp float Contrast;    \
    uniform bool bUsingYUV;    \
    void main() \
    {   \
    mediump vec3 yuv;       \
    lowp vec3 rgb;  \
    gl_FragColor = texture2D(main_texture,TexCoordOut);    \
    gl_FragColor.rgb /= gl_FragColor.a;\
    gl_FragColor.rgb = ((gl_FragColor.rgb - 0.5) * Contrast) + 0.5;   \
    gl_FragColor.rgb += Brightness;\
    gl_FragColor.rgb *= gl_FragColor.a;\
    }   \
    ";
 //codec matric
//    const highp mat3 yuv2rgb = mat3(        1.164,       1.164,         1.164,   \
//                                    0,          -0.38,          2.018,    \
//                                    1.159,      -0.813,         0);  \

 //bt.601
//    const highp mat3 yuv2rgb = mat3(        1.164,       1.164,         1.164,   \
//                                    0,          -0.3916,          2.0165,    \
//                                    1.5954,      -0.8126,         0);  \

//bt.709
//    const highp mat3 yuv2rgb = mat3(        1.164,       1.164,         1.164,   \
//                                    0,          -0.2131,          2.111,    \
//                                    1.7921,      -0.5327,         0);  \

    const char fragmengShaderCode[] =        "   \
    varying lowp vec4 DestinationColor; \
    varying lowp vec2 TexCoordOut;  \
    uniform sampler2D main_texture;    \
    uniform sampler2D main_texture2;    \
    uniform sampler2D Y_texture;    \
    uniform sampler2D U_texture;    \
    uniform sampler2D V_texture;    \
    uniform sampler2D Y2_texture;    \
    uniform sampler2D U2_texture;    \
    uniform sampler2D V2_texture;    \
    uniform lowp float Brightness;    \
    uniform lowp float Contrast;    \
    uniform lowp float UsingYUV;    \
    uniform lowp float UsingRGB;    \
    uniform mediump float Alpha;    \
    uniform mediump vec4 ColorKey; \
    const highp mat3 yuv2rgb = mat3(        1.164,       1.164,         1.164,   \
    0,          -0.3916,          2.0165,    \
    1.5954,      -0.8126,         0);  \
    \
    void adjustVideoEffect()    \
    {   \
        gl_FragColor.rgb /= gl_FragColor.a;\
        gl_FragColor.rgb = ((gl_FragColor.rgb - 0.5) * Contrast) + 0.5;   \
        gl_FragColor.rgb += Brightness;\
        gl_FragColor.rgb *= gl_FragColor.a;\
    }   \
    void updateTexutre(inout mediump vec3 yuv,sampler2D y,sampler2D u,sampler2D v,inout mediump vec3 rgb)    \
    {   \
        yuv.x = texture2D(y, TexCoordOut).r - 0.0625;     \
        yuv.y = texture2D(v, TexCoordOut).r  - 0.5;     \
        yuv.z = texture2D(u, TexCoordOut).r - 0.5;     \
        rgb =  yuv2rgb* yuv;   \
    }   \
    void updateTextureByColorKeyAlpha(inout mediump vec3 yuv,inout mediump vec3 rgb)    \
    {   \
        if((abs(yuv.x - ColorKey.x+0.0625) <0.001)  \
                && (abs(yuv.y - ColorKey.y+0.5) <0.001)   \
                && (abs(yuv.z - ColorKey.z+0.5) <0.001)   \
                && (abs(ColorKey.w - 1.0) <0.001)   \
                ||((TexCoordOut.y<0.009))&&(abs(ColorKey.w - 1.0) <0.001)) \
            gl_FragColor = vec4(rgb, 0.0);    \
        else    \
            gl_FragColor = vec4(rgb, Alpha);    \
    }   \
    \
    void main() \
    {   \
    mediump vec3 yuv;       \
    mediump vec3 rgb;  \
    if(abs(UsingYUV - 1.0) <= 0.1)   \
    {           \
        updateTexutre(yuv,Y_texture,U_texture,V_texture,rgb);   \
        updateTextureByColorKeyAlpha(yuv,rgb);    \
    }           \
    else if(abs(UsingYUV - 2.0) <= 0.1)   \
    {           \
        updateTexutre(yuv,Y2_texture,U2_texture,V2_texture,rgb);   \
        updateTextureByColorKeyAlpha(yuv,rgb);    \
    }   \
    else if(abs(UsingRGB - 1.0) <= 0.1)      \
        gl_FragColor = texture2D(main_texture,TexCoordOut);    \
    else if(abs(UsingRGB - 2.0) <= 0.1)   \
        gl_FragColor = texture2D(main_texture2,TexCoordOut);    \
    \
    adjustVideoEffect();    \
    }   \
    ";
    
    NSString* shaderString = [[NSString alloc] initWithUTF8String:vertexShaderCode];
    m_vertexShader = [self compileShaderCode: shaderString
                                    withType:GL_VERTEX_SHADER];
    [shaderString release];
    
#ifdef OLDVERSION
    shaderString = [[NSString alloc] initWithUTF8String:fragmengShaderCode_RGB565_MAIN];
#else
    shaderString = [[NSString alloc] initWithUTF8String:fragmengShaderCode];
#endif
    m_fragmentShader = [self compileShaderCode: shaderString
                                      withType:GL_FRAGMENT_SHADER];
    [shaderString release];
    
    
    m_programHandle = glCreateProgram();
    glAttachShader(m_programHandle, m_vertexShader);
    glAttachShader(m_programHandle, m_fragmentShader);
    glLinkProgram(m_programHandle);
    
    GLint linkSuccess;
    glGetProgramiv(m_programHandle, GL_LINK_STATUS, &linkSuccess);
    if(linkSuccess == GL_FALSE)
    {
        GLint infoLen = 0;
        glGetProgramiv(m_programHandle, GL_INFO_LOG_LENGTH, &infoLen);
        if(infoLen > 1) 
        {
            char* infoLog = (char*)malloc(sizeof(char) * infoLen); 
            glGetProgramInfoLog(m_programHandle, infoLen, NULL, infoLog); 
            NSLog(@"Error linking program:\n%s\n", infoLog);
            free(infoLog);
        }
        glDeleteShader(m_vertexShader);
        glDeleteShader(m_fragmentShader);
        glDeleteProgram(m_programHandle);
        return;
    }
    glUseProgram(m_programHandle);
    
    _positionSlot = glGetAttribLocation(m_programHandle, "Position");
    _colorSlot    = glGetAttribLocation(m_programHandle, "SourceColor");
    
    _texCoordSlot = glGetAttribLocation(m_programHandle, "TexCooordIn");
    _textureUniform = glGetUniformLocation(m_programHandle, "main_texture");
    _Y_TextureUniform = glGetUniformLocation(m_programHandle, "Y_texture");
    _U_TextureUniform = glGetUniformLocation(m_programHandle, "U_texture");
    _V_TextureUniform = glGetUniformLocation(m_programHandle, "V_texture");
    
    _textureUniform2 = glGetUniformLocation(m_programHandle, "main_texture2");
    
    _Y2_TextureUniform = glGetUniformLocation(m_programHandle, "Y2_texture");
    _U2_TextureUniform = glGetUniformLocation(m_programHandle, "U2_texture");
    _V2_TextureUniform = glGetUniformLocation(m_programHandle, "V2_texture");
    
    
    _bUsingYUV_TextureUniform = glGetUniformLocation(m_programHandle, "UsingYUV");
    glUniform1f(_bUsingYUV_TextureUniform, 0.0);
    
    _bUsingRGB=glGetUniformLocation(m_programHandle, "UsingRGB");
    glUniform1f(_bUsingRGB, 0.0);
    
    _alpha = glGetUniformLocation(m_programHandle, "Alpha");
    glUniform1f(_alpha, 1.0);
    
    _colorKey_TextureUniform = glGetUniformLocation(m_programHandle, "ColorKey");
    glUniform4f(_colorKey_TextureUniform, 0.0,0.0,0.0,0.0);
    
    
    _brightness = glGetUniformLocation(m_programHandle, "Brightness");
    float default_brightness = 0.0f;
    glUniform1f(_brightness, default_brightness);
    
    _contrast = glGetUniformLocation(m_programHandle, "Contrast");
    float default_contrast = 1.0f;
    glUniform1f(_contrast, default_contrast);
    
    
    glEnableVertexAttribArray(_positionSlot);
    glEnableVertexAttribArray(_colorSlot);    
    glEnableVertexAttribArray(_texCoordSlot);
    
    glEnable(GL_BLEND);
    //    glBlendFunc(GL_CONSTANT_ALPHA, GL_ONE_MINUS_CONSTANT_ALPHA);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    NSLog(@"compile shader success \n");
}

- (GLuint) createTextureWidth:(GLuint) width height:(GLuint) height format:(long)format
{
    if(mApplicationState != UIApplicationStateActive)
        return 0;

    //get a texture
    int emptySurfaceId = 0;
    for(emptySurfaceId=0;emptySurfaceId<MAX_SURFACENUM;emptySurfaceId++)
    {
        if (mSurfaces[emptySurfaceId].valid == NO) {
            break;
        }
    }
    
    if (emptySurfaceId >= MAX_SURFACENUM)
        return 0;
    
    mSurfaces[emptySurfaceId].width = width;
    mSurfaces[emptySurfaceId].height = height;
    mSurfaces[emptySurfaceId].format = format;
    mSurfaces[emptySurfaceId].miWidth   = [self getMiValue:width];
    mSurfaces[emptySurfaceId].miHeight    = [self getMiValue:height];
    mSurfaces[emptySurfaceId].alpha = 1.0f;
	mSurfaces[emptySurfaceId].hidden = true;
    memset(mSurfaces[emptySurfaceId].colorKey, 0, sizeof(mSurfaces[emptySurfaceId].colorKey));
    //
    GLfloat widthPercent =  [self getMiPercent:width];
    GLfloat heightPercent =  [self getMiPercent:height];
    
    vertexStruct verticesTmp[] = {
        {{1,-1,0},{1,0,0,1.0},{1.0,1.0}},
        {{1,1,0},{0,1,0,1.0},{1.0,0.0}},    
        {{-1,1,0},{0,0,1,1.0},{0.0,0.0}},    
        {{-1,-1,0},{0,0,0,1.0},{0.0,1.0}}
    };
    
    
    for(int i=0;i<sizeof(verticesTmp)/sizeof(verticesTmp[0]);i++)
    {
        verticesTmp[i].texCoord[0] *= widthPercent;
        verticesTmp[i].texCoord[1] *= heightPercent;
        verticesTmp[i].position[2] = emptySurfaceId;
    }
    memcpy(mSurfaces[emptySurfaceId].parms, verticesTmp, sizeof(verticesTmp));
    
	
	unsigned char* pFlushBuff = (unsigned char*)malloc(mSurfaces[emptySurfaceId].miWidth*mSurfaces[emptySurfaceId].miHeight*4);
	if(pFlushBuff == 0)
    {
		NSLog(@"failed to malloc pFlushBuff");
        return 0;
    }
	glBindTexture(GL_TEXTURE_2D, mSurfaces[emptySurfaceId].textueId);
	if (mSurfaces[emptySurfaceId].format == MAKEFOURCC('R','5','6','5')) {
		memset(pFlushBuff, 0, mSurfaces[emptySurfaceId].miWidth*mSurfaces[emptySurfaceId].miHeight*2);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, mSurfaces[emptySurfaceId].miWidth, mSurfaces[emptySurfaceId].miHeight, 0, GL_RGB, GL_UNSIGNED_SHORT_5_6_5, 0);
		glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, mSurfaces[emptySurfaceId].miWidth, mSurfaces[emptySurfaceId].miHeight, GL_RGB, GL_UNSIGNED_SHORT_5_6_5, pFlushBuff);
	}
	else if (mSurfaces[emptySurfaceId].format == MAKEFOURCC('X','R','G','B')) {
		memset(pFlushBuff, 0, mSurfaces[emptySurfaceId].miWidth*mSurfaces[emptySurfaceId].miHeight*4);
		glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA,  mSurfaces[emptySurfaceId].miWidth, mSurfaces[emptySurfaceId].miHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
		glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, mSurfaces[emptySurfaceId].miWidth, mSurfaces[emptySurfaceId].miHeight, GL_RGBA, GL_UNSIGNED_BYTE, pFlushBuff);
	}
	else if (mSurfaces[emptySurfaceId].format == MAKEFOURCC('R','5','5','5')) {
		memset(pFlushBuff, 0, mSurfaces[emptySurfaceId].miWidth*mSurfaces[emptySurfaceId].miHeight*2);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, mSurfaces[emptySurfaceId].miWidth, mSurfaces[emptySurfaceId].miHeight, 0, GL_RGBA, GL_UNSIGNED_SHORT_5_5_5_1, 0);
		glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, mSurfaces[emptySurfaceId].miWidth, mSurfaces[emptySurfaceId].miHeight, GL_RGBA, GL_UNSIGNED_SHORT_5_5_5_1, pFlushBuff);
	}
	else if (mSurfaces[emptySurfaceId].format == MAKEFOURCC('Y','V','1','2')) {
		memset(pFlushBuff, 0x10, mSurfaces[emptySurfaceId].miWidth*mSurfaces[emptySurfaceId].miHeight);
		memset(pFlushBuff+mSurfaces[emptySurfaceId].miWidth*mSurfaces[emptySurfaceId].miHeight
               , 0x80, mSurfaces[emptySurfaceId].miWidth*mSurfaces[emptySurfaceId].miHeight/2);
        
        glBindTexture (GL_TEXTURE_2D, mSurfaces[emptySurfaceId].textueId);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, mSurfaces[emptySurfaceId].miWidth,
                     mSurfaces[emptySurfaceId].miHeight, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, 0);
        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, mSurfaces[emptySurfaceId].miWidth,
                        mSurfaces[emptySurfaceId].miHeight, GL_LUMINANCE, GL_UNSIGNED_BYTE, pFlushBuff);
        
        glBindTexture (GL_TEXTURE_2D, mSurfaces[MAX_SURFACENUM + emptySurfaceId*2].textueId);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, mSurfaces[emptySurfaceId].miWidth>>1,
                     mSurfaces[emptySurfaceId].miHeight>>1, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, 0);
        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, mSurfaces[emptySurfaceId].miWidth>>1,
                        mSurfaces[emptySurfaceId].miHeight>>1, GL_LUMINANCE, GL_UNSIGNED_BYTE,
                        pFlushBuff+mSurfaces[emptySurfaceId].miWidth*mSurfaces[emptySurfaceId].miHeight);
        
        glBindTexture (GL_TEXTURE_2D, mSurfaces[MAX_SURFACENUM+emptySurfaceId*2+1].textueId);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, mSurfaces[emptySurfaceId].miWidth>>1, mSurfaces[emptySurfaceId].miHeight>>1,
                     0, GL_LUMINANCE, GL_UNSIGNED_BYTE, 0);
        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, mSurfaces[emptySurfaceId].miWidth>>1, mSurfaces[emptySurfaceId].miHeight>>1,
                        GL_LUMINANCE, GL_UNSIGNED_BYTE, pFlushBuff+mSurfaces[emptySurfaceId].miWidth*mSurfaces[emptySurfaceId].miHeight*5/4);
    }
    
    free(pFlushBuff);
    
    glBindBuffer(GL_ARRAY_BUFFER, mSurfaces[emptySurfaceId].vertexbufferId);
    glBufferData(GL_ARRAY_BUFFER, sizeof(mSurfaces[emptySurfaceId].parms), mSurfaces[emptySurfaceId].parms, GL_STATIC_DRAW);
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, mSurfaces[emptySurfaceId].indexbufferId);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
    
    mSurfaces[emptySurfaceId].valid = YES;
    
    return mSurfaces[emptySurfaceId].textueId;
}

- (void) DestroyTexture:(GLuint)textureId
{
    int i;
    FIND_TEXTURE_ID_ORRETURN(i)
	mSurfaces[i].valid = NO;
    return;
}

- (void) ShowHideTexture:(GLuint)textureId Show:(Boolean)bShow
{
    int i;
    FIND_TEXTURE_ID_ORRETURN(i)
    mSurfaces[i].hidden = !bShow;
    
    return;
}


- (void) SetSrcRectTexture:(GLuint)textureId rect:(Rect*) pRect
{
    if(mApplicationState == UIApplicationStateBackground)
        return;

    int i;
    FIND_TEXTURE_ID_ORRETURN(i)
    mSurfaces[i].srcRect = *pRect;
    
    
    GLfloat widthPercent =  [self getMiPercent: mSurfaces[i].width];
    GLfloat heightPercent =  [self getMiPercent: mSurfaces[i].height];
    
    float cropWidth = (mSurfaces[i].srcRect.right - mSurfaces[i].srcRect.left)/
    (float)(mSurfaces[i].width);
    float cropHeight = (mSurfaces[i].srcRect.bottom - mSurfaces[i].srcRect.top)/
    (float)(mSurfaces[i].height);
    
    
    mSurfaces[i].parms[0].texCoord[0] = widthPercent*(1.0f - cropWidth)/2 + widthPercent*cropWidth;
    mSurfaces[i].parms[0].texCoord[1] = heightPercent*(1.0f- cropHeight)/2 + heightPercent*cropHeight;
    
    mSurfaces[i].parms[1].texCoord[0] = widthPercent*(1.0f - cropWidth)/2 + widthPercent*cropWidth;
    mSurfaces[i].parms[1].texCoord[1] = heightPercent*(1.0f - cropHeight)/2;
    
    mSurfaces[i].parms[2].texCoord[0] = widthPercent*(1.0f - cropWidth)/2;
    mSurfaces[i].parms[2].texCoord[1] = heightPercent*(1.0f- cropHeight)/2;
    
    mSurfaces[i].parms[3].texCoord[0] = widthPercent*(1.0f -cropWidth)/2;
    mSurfaces[i].parms[3].texCoord[1] = heightPercent*(1.0f- cropHeight)/2+ heightPercent*cropHeight;
    
    
    glBindBuffer(GL_ARRAY_BUFFER, mSurfaces[i].vertexbufferId);
    glBufferData(GL_ARRAY_BUFFER, sizeof(mSurfaces[i].parms), mSurfaces[i].parms, GL_STATIC_DRAW);
    
    return;
}

- (void) SetDestRectTexture:(GLuint)textureId rect:(Rect*) dstRect
{
    if(mApplicationState != UIApplicationStateActive)
        return;

	if (dstRect->left > backingWidth || dstRect->right > backingWidth
		|| dstRect->top > backingHeight || dstRect->bottom > backingHeight) {
		return;
	}
    int i;
    FIND_TEXTURE_ID_ORRETURN(i)
    mSurfaces[i].dstRect = *dstRect;
    
    float left,top,right,bottom;
    left = mSurfaces[i].dstRect.left/(float)backingWidth;
    top = mSurfaces[i].dstRect.top/(float)backingHeight;
    right = mSurfaces[i].dstRect.right/(float)backingWidth;
    bottom = mSurfaces[i].dstRect.bottom/(float)backingHeight;
    
    //Convert cordination system
    left = left*2-1;
    right = right*2-1;
    top = (top*2 - 1)*-1;
    bottom = (bottom*2 -1)*-1;
    
    mSurfaces[i].parms[0].position[0] = right;
    mSurfaces[i].parms[0].position[1] = bottom;
    
    mSurfaces[i].parms[1].position[0] = right;
    mSurfaces[i].parms[1].position[1] = top;
    
    mSurfaces[i].parms[2].position[0] = left;
    mSurfaces[i].parms[2].position[1] = top;
    
    mSurfaces[i].parms[3].position[0] = left;
    mSurfaces[i].parms[3].position[1] = bottom;
    
    glBindBuffer(GL_ARRAY_BUFFER, mSurfaces[i].vertexbufferId);
    glBufferData(GL_ARRAY_BUFFER, sizeof(mSurfaces[i].parms), mSurfaces[i].parms, GL_STATIC_DRAW);
    
    return;
}

- (void) SetAlphaTexture:(GLuint)textureId alpha:(float)alpha
{
    int i;
    FIND_TEXTURE_ID_ORRETURN(i)
    mSurfaces[i].alpha = alpha;
    return;
}

- (void) RenderTexture:(GLuint)textureId buffer:(unsigned char**)bufferArray width:(int *)widthArray height:(int *)heightArray
{
    if(mApplicationState != UIApplicationStateActive)
        return;

    if (mInit == NO) {
        return;
    }
    if (textureId == 0) {
        return;
    }
    if(m_layer == 0)
        return;

    [EAGLContext setCurrentContext:_context];
    
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    float yuv_surface_id = 0.0f;
    float rgb_surface_id = 0.0f;
    int i = 0;
    for (i=0; i<MAX_SURFACENUM; i++) {
        if (mSurfaces[i].valid == NO) {
            continue;
        }
        if (mSurfaces[i].hidden) {
            continue;
        }
        
        glBindBuffer(GL_ARRAY_BUFFER, mSurfaces[i].vertexbufferId);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, mSurfaces[i].indexbufferId);
        
        glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(vertexStruct), 0);
        glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE, sizeof(vertexStruct),(GLvoid*)(sizeof(GLfloat)*3));
        glVertexAttribPointer(_texCoordSlot, 2, GL_FLOAT, GL_FALSE, sizeof(vertexStruct), (GLvoid*)(sizeof(GLfloat)*7));
        
        glBindTexture (GL_TEXTURE_2D, mSurfaces[i].textueId);
        
        glUniform1f(_alpha, mSurfaces[i].alpha);

        if (mSurfaces[i].format == MAKEFOURCC('Y','V','1','2')) {
            yuv_surface_id += 1.0f;
            glUniform1f(_bUsingYUV_TextureUniform, yuv_surface_id);
            if(yuv_surface_id -1.0f < 0.001)
            {
                glUniform1i(_Y_TextureUniform, i);
                glUniform1i(_U_TextureUniform, MAX_SURFACENUM+i*2);
                glUniform1i(_V_TextureUniform, MAX_SURFACENUM+i*2+1);
            }
            else if(yuv_surface_id -2.0f < 0.001)
            {
                glUniform1i(_Y2_TextureUniform, i);
                glUniform1i(_U2_TextureUniform, MAX_SURFACENUM+i*2);
                glUniform1i(_V2_TextureUniform, MAX_SURFACENUM+i*2+1);
            }
            glUniform4f(_colorKey_TextureUniform, mSurfaces[i].colorKey[0],mSurfaces[i].colorKey[1],mSurfaces[i].colorKey[2],mSurfaces[i].colorKey[3]);
        }
        else
        {
            rgb_surface_id += 1.0f;
            glUniform1f(_bUsingRGB, rgb_surface_id);
            
            glUniform1f(_bUsingYUV_TextureUniform, 0.0f);
            
#ifdef OLDVERSION
            glUniform1i(_textureUniform, i);
#else
            if(rgb_surface_id -1.0f < 0.001)
                glUniform1i(_textureUniform, i);
            else
                glUniform1i(_textureUniform2, i);
#endif
        }
        
        if ((textureId!=FLUSH_TEXUTRE) && textureId == mSurfaces[i].textueId) {
            if (mSurfaces[i].format == MAKEFOURCC('R','5','6','5')) {
                glBindTexture (GL_TEXTURE_2D, mSurfaces[i].textueId);
                glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, mSurfaces[i].miWidth, mSurfaces[i].miHeight, 0, GL_RGB, GL_UNSIGNED_SHORT_5_6_5, 0);
                glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, widthArray[0], heightArray[0], GL_RGB, GL_UNSIGNED_SHORT_5_6_5, bufferArray[0]);
            }
            else if (mSurfaces[i].format == MAKEFOURCC('X','R','G','B')) {
                glBindTexture (GL_TEXTURE_2D, mSurfaces[i].textueId);
                glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA,  mSurfaces[i].miWidth, mSurfaces[i].miHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
                glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, widthArray[0], heightArray[0], GL_RGBA, GL_UNSIGNED_BYTE, bufferArray[0]);
            }
            else if (mSurfaces[i].format == MAKEFOURCC('R','5','5','5')) {
                glBindTexture (GL_TEXTURE_2D, mSurfaces[i].textueId);
                glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, mSurfaces[i].miWidth, mSurfaces[i].miHeight, 0, GL_RGBA, GL_UNSIGNED_SHORT_5_5_5_1, 0);
                glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, widthArray[0], heightArray[0], GL_RGBA, GL_UNSIGNED_SHORT_5_5_5_1, bufferArray[0]);
            }
            else if (mSurfaces[i].format == MAKEFOURCC('Y','V','1','2')) {
                glBindTexture (GL_TEXTURE_2D, mSurfaces[i].textueId);
                glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, mSurfaces[i].miWidth, mSurfaces[i].miHeight, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, 0);
                glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, widthArray[0], heightArray[0], GL_LUMINANCE, GL_UNSIGNED_BYTE, bufferArray[0]);
                
                
                glBindTexture (GL_TEXTURE_2D, mSurfaces[MAX_SURFACENUM+i*2].textueId);
                glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, mSurfaces[i].miWidth>>1, mSurfaces[i].miHeight>>1, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, 0);
                glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, widthArray[1], heightArray[1], GL_LUMINANCE, GL_UNSIGNED_BYTE,bufferArray[1] );
                
                
                glBindTexture (GL_TEXTURE_2D, mSurfaces[MAX_SURFACENUM+i*2+1].textueId);
                glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, mSurfaces[i].miWidth>>1, mSurfaces[i].miHeight>>1, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, 0);
                glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, widthArray[2], heightArray[2], GL_LUMINANCE, GL_UNSIGNED_BYTE, bufferArray[2]);
            }
        }
        glDrawElements(GL_TRIANGLES, sizeof(indices)/sizeof(indices[0]), GL_UNSIGNED_BYTE, 0);
        
    }
    
    [_context presentRenderbuffer:GL_RENDERBUFFER];
    return;
}

- (id<ESRender>) initWithContext:(EAGLContext *)context AndDrawable:(id<EAGLDrawable>)drawable
{
    if(mApplicationState != UIApplicationStateActive)
        return nil;

	self = [super init];
    
    memset(mSurfaces, 0, sizeof(mSurfaces));
    
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!_context || ![EAGLContext setCurrentContext:self._context])
    {
        [self release];
        return nil;
    }
    
    glGenRenderbuffers(1, &_colorRenderbuffer);
	glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderbuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:drawable];
    
    glGenFramebuffers(1, &_defaultFBOName);
	glBindFramebuffer(GL_FRAMEBUFFER, _defaultFBOName);
	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderbuffer);
    
    
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    
    long ret = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if( ret!= GL_FRAMEBUFFER_COMPLETE)
	{
		NSLog(@"failed to make complete framebuffer object 0x%lx", ret);
		return NO;
	}
    else
    {
		NSLog(@"opengl initialization successed \n");
    }
    
    [self compileShaders];
    
    
    for (int i=0; i<MAX_SURFACENUM*3; i++)
    {
        glActiveTexture(GL_TEXTURE0+i);
        glGenTextures(1, &mSurfaces[i].textueId);
        glBindTexture(GL_TEXTURE_2D, mSurfaces[i].textueId);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
//        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        
        
        glGenBuffers(1, &mSurfaces[i].vertexbufferId);
        glGenBuffers(1, &mSurfaces[i].indexbufferId);
        
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationStatusChanged:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationStatusChanged:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationStatusChanged:) name:UIApplicationDidBecomeActiveNotification object:nil];

    mApplicationState = [UIApplication sharedApplication].applicationState;
    
    mInit = YES;
    
    return self;
}

- (void)applicationStatusChanged:(UIApplication*)application
{
    mApplicationState = [UIApplication sharedApplication].applicationState;

    
}


- (int) getWindowWidth:(int*)pWidth height:(int*)pHeight
{
    if (mInit == NO) {
        return -1;
    }
    *pWidth = backingWidth;
    *pHeight = backingHeight;
    return 0;
}

- (BOOL)resizeFromLayer:(CAEAGLLayer*)layer
{
    if (mInit == NO) {
        return -1;
    }
    
    if(mApplicationState != UIApplicationStateActive)
        return -1;
    
    [EAGLContext setCurrentContext:_context];
    
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderbuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    
    glViewport(0, 0, backingWidth, backingHeight);
    
    
    NSLog(@"resizeFromLayer %@ to %d,%d \n",layer,backingWidth,backingHeight);
    
    long ret = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if ( ret != GL_FRAMEBUFFER_COMPLETE)
	{
        NSLog(@"Failed to make complete framebuffer object resize 0x%lx",ret);
        return NO;
    }
    
	for (int i=0; i<MAX_SURFACENUM; i++) {
        if(mSurfaces[i].valid)
		{
			glBindBuffer(GL_ARRAY_BUFFER, mSurfaces[i].vertexbufferId);
			glBufferData(GL_ARRAY_BUFFER, sizeof(mSurfaces[i].parms), mSurfaces[i].parms, GL_STATIC_DRAW);
		    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, mSurfaces[i].indexbufferId);
			glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
            
		}
        
	}
	
    m_layer = layer;
    return YES;
}

- (GLuint) getMiValue:(GLuint)width
{
    if (width == 0) {
        return -1;
    }
    GLuint mi =0;
    
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
        case 2048:
            return width;
        default:
            break;
    } 
    
    while(width >0)
    {
        mi++;
        width >>= 1;
    }
    return (2 <<(mi-1));
}

- (GLfloat) getMiPercent:(GLuint)width
{
    GLuint mivalue = [self getMiValue:width];
    
    return (GLfloat)((GLfloat)width/(GLfloat)mivalue);
}

- (void) SetBrightness:(float)brightness
{
    if(mApplicationState != UIApplicationStateActive)
        return;

    glUniform1f(_brightness, brightness);
}

- (void) SetContrast:(float)contrast
{
    if(mApplicationState != UIApplicationStateActive)
        return;

    glUniform1f(_contrast, contrast);
}

- (void) SetColorKey:(GLuint)textureId y:(float)y u:(float)u v:(float)v
{
    if(y-0.0f<0.01 && u-0.0f<0.01 &&v-0.0f<0.01 )
        return;
    int i;
    FIND_TEXTURE_ID_ORRETURN(i)
    mSurfaces[i].colorKey[0] = y;
    mSurfaces[i].colorKey[1] = u;
    mSurfaces[i].colorKey[2] = v;
    mSurfaces[i].colorKey[3] = 1.0f;
    
    return ;
}
- (void) GetApplicationState:(UIApplicationState*) pState
{
    *pState = mApplicationState;
    return ;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self performSelectorOnMainThread:@selector(deallocOnMainThread) withObject:self waitUntilDone:YES];
    [super dealloc];
    
}

- (void) deallocOnMainThread
{
    for (int i=0; i<MAX_SURFACENUM*3; i++) {
        if(mSurfaces[i].textueId)
            glDeleteTextures(1, &mSurfaces[i].textueId);
        if(mSurfaces[i].vertexbufferId)
            glDeleteBuffers(1, &mSurfaces[i].vertexbufferId);
        if(mSurfaces[i].indexbufferId)
            glDeleteBuffers(1, &mSurfaces[i].indexbufferId);
        
    }
    
    glDeleteShader(m_vertexShader);
    glDeleteShader(m_fragmentShader);
    glDeleteProgram(m_programHandle);
    
    glDeleteRenderbuffers(1, &_colorRenderbuffer);
    glDeleteFramebuffers(1, &_defaultFBOName);
    
    [EAGLContext setCurrentContext:nil];
    
	[_context release];
}
@end

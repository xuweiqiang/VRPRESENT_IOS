/*
     File: EAGLView.m
 Abstract: The EAGLView class is a UIView subclass that renders OpenGL scene.
  Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2010~2011 Apple Inc. All Rights Reserved.
 
 */

#import "EAGLView.h"
#import <QuartzCore/QuartzCore.h>

#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>

//#import "ES2Renderer.h"
#include "GfxPresent.h"

@implementation EAGLView

@synthesize progressView;

#define TEST_REV2

IMcVideoPresenter* m_pPresenter = NULL;

IMcVideoPresenterAdv* m_pPresenterAdv = NULL;
IMcVideoPresenterStream* m_pStream1 = NULL;
IMcVideoPresenterStream* m_pStream2 = NULL;


VP_CANVASINFO_PARAMS m_canvasInfo;


unsigned char* m_pbuff = NULL;
@synthesize animating;
@dynamic animationFrameInterval;

int surfwidth = 720;
int surfheight = 480;
FILE* mFile = nil;
long mFileSize =0;
// You must implement this method
+ (Class) layerClass
{
    return [CAEAGLLayer class];
}

//The GL view is stored in the nib file. When it's unarchived it's sent -initWithCoder:
- (id) initWithCoder:(NSCoder*)coder
{    
    if ((self = [super initWithCoder:coder]))
	{
        // Get the layer
        CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
        
        eaglLayer.opaque = TRUE;
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
		
#ifndef TEST_REV2        
        m_pPresenter = 	CreateVideoPresenter();
        if (m_pPresenter==NULL) {
            NSLog(@"error :%d \n",__LINE__);
        }
        struct VP_OpenOptions option;
        memset(&option, 0, sizeof(option));
        option.dwWidth = surfwidth;
        option.dwHeight = surfheight;
        option.dwFourCC = 'Y'|'V'<<8|'1'<<16|'2'<<24;
        HRESULT hr = m_pPresenter->Open(&option, sizeof(option));
        if(FAILED(hr))
            NSLog(@"error :%d \n",__LINE__);
        VR_IOS_PARAMS m_surf_param;
        m_surf_param.context = (void*)_context;
        m_surf_param.drawable = (void*)self.layer;
        hr = m_pPresenter->Set(IID_IMcVideoPresenter, MC_PROPID_VP_VP_HND, NULL, NULL,&m_surf_param,sizeof(m_surf_param));
        if(FAILED(hr))
            NSLog(@"error :%d \n",__LINE__);

#else        
        
        m_pPresenterAdv = CreateVideoPresenterAdv();
        VP_OpenOptionsAdv option;
        memset(&option, 0, sizeof(option));
        
        VR_IOS_PARAMS m_surf_param;
        m_surf_param.context = (void*)_context;
        m_surf_param.drawable = (void*)self.layer;
        option.surfparam = m_surf_param;
        m_pPresenterAdv->Open(&option, sizeof(option));
        
        
        m_pPresenterAdv->Get(IID_IMcVideoPresenter, MC_PROPID_VP_CANVAS_INFO, 
                             0, 0, &m_canvasInfo, sizeof(m_canvasInfo),0);
        
        
        
        VP_OPEN_STREAM_PARAMS stream_parms;
        memset(&stream_parms, 0, sizeof(stream_parms));
        stream_parms.type = eMAINSTREAM;
        stream_parms.dwWidth = surfwidth;
        stream_parms.dwHeight = surfheight;
        stream_parms.dwFourCC = 'Y'|'V'<<8|'1'<<16|'2'<<24;
        stream_parms.fAlpha = 1.0f;
//        stream_parms.dwAspectX = 25;
//        stream_parms.dwAspectY = 9;
        m_pPresenterAdv->CreateStream(&stream_parms, sizeof(stream_parms), &m_pStream1);
        m_pStream1->Open();
        
        RECT dstRect1;
        SetRect(&dstRect1, 10, 0, m_canvasInfo.dwWidth-10, m_canvasInfo.dwHeight-10);
        m_pStream1->Set(IID_IMcVideoPresenter, MC_PROPID_VP_RECTDST, 0, 0, &dstRect1, sizeof(dstRect1));
        
        bool bEnable = true;
        m_pStream1->Set(IID_IMcVideoPresenter, MC_PROPID_VP_ENABLE, 0, 0, &bEnable, sizeof(bEnable));
//
//        stream_parms.dwHeight = surfheight;
//        stream_parms.type = eSUBSTREAMS;
//        m_pPresenterAdv->CreateStream(&stream_parms, sizeof(stream_parms), &m_pStream2);
//        m_pStream2->Open();
//        RECT dstRect2;
//        SetRect(&dstRect2, 20, 20, m_canvasInfo.dwWidth/2, m_canvasInfo.dwHeight/2);
//        m_pStream2->Set(IID_IMcVideoPresenter, MC_PROPID_VP_RECTDST, 0, 0, &dstRect2, sizeof(dstRect2));
//        m_pStream2->Set(IID_IMcVideoPresenter, MC_PROPID_VP_ENABLE, 0, 0, &bEnable, sizeof(bEnable));
//
        
        DWORD colorkey = 0x0;
//        m_pStream1->Set(IID_IMcVideoPresenter, MC_PROPID_VP_COLORKEYSRC, 0, 0, &colorkey, sizeof(colorkey));
//        m_pStream2->Set(IID_IMcVideoPresenter, MC_PROPID_VP_COLORKEYSRC, 0, 0, &colorkey, sizeof(colorkey));
//
//                VP_ZOOM_MODE mode = VP_ZOOM_MODE_STRETCH;
        VP_ZOOM_MODE mode = VP_ZOOM_MODE_LETTERBOX;
        m_pStream1->Set(IID_IMcVideoPresenter, MC_PROPID_VP_ZOOM, NULL, NULL,&mode,sizeof(mode));
        mode = VP_ZOOM_MODE_STRETCH;
//        m_pStream2->Set(IID_IMcVideoPresenter, MC_PROPID_VP_ZOOM, NULL, NULL,&mode,sizeof(mode));

//        DWORD alpha = MAX_ALPHA_VAL/2;
//        m_pStream2->Set(IID_IMcVideoPresenter, MC_PROPID_VP_ALPHA, NULL, NULL,&alpha,sizeof(alpha));
        
        
#endif
        
        m_pbuff = (unsigned char*)malloc(surfwidth*surfheight*3/2);
        if(m_pbuff == NULL)
            NSLog(@"error :%d \n",__LINE__);


//        
//        VP_DEINTERLACE_MODE deMode = VP_DEINTERLACE_BOB_SINGLE_FIELD;
//        m_pPresenter->Set(IID_IMcVideoPresenter, MC_PROPID_VP_DEINTERLACE_MODE, NULL, NULL,&deMode,sizeof(deMode));

        
		animating = FALSE;
		displayLinkSupported = FALSE;
		animationFrameInterval = 1;
		displayLink = nil;
		animationTimer = nil;
		
		// A system version of 3.1 or greater is required to use CADisplayLink. The NSTimer
		// class is used as fallback when it isn't available.
		NSString *reqSysVer = @"3.1";
		NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
		if ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending)
			displayLinkSupported = TRUE;
        
        NSString *path = [[NSBundle mainBundle] pathForResource:@"533.000__CTV_1_720X480" ofType:@"YUV"];
        mFile = fopen([path cStringUsingEncoding:NSASCIIStringEncoding], "r");
       if(mFile == nil)
       {
           NSLog(@"OPEN FILE %s failed \n", [path cStringUsingEncoding:NSASCIIStringEncoding]);
           return nil;
       }
        fseek(mFile, 0, SEEK_END);
        mFileSize = ftell(mFile);
        [self layoutSubviews];
    }
	
    return self;
}

- (void) drawView:(id)sender
{   
//	[EAGLContext setCurrentContext:_context];
    
//    memset(m_pbuff, rand(), surfwidth*surfheight*3/2);
    int byteRead = fread(m_pbuff, 1, surfwidth*surfheight*3/2, mFile);
    if (byteRead < surfwidth*surfheight*3/2) {
        fseek(mFile, 0, SEEK_SET);
    }
    unsigned char* pBuffArr[3];
    pBuffArr[0] = m_pbuff;
    pBuffArr[1] = m_pbuff + surfwidth*surfheight;
    pBuffArr[2] = m_pbuff + surfwidth*surfheight*5/4;
    DWORD strides[3] = {surfwidth,surfwidth/2,surfwidth/2};
    
    if (m_pStream1) {
        HRESULT hr = m_pStream1->Present(pBuffArr, strides, 0);
        if(FAILED(hr))
            NSLog(@"error :%d \n",__LINE__);
    }

    if (m_pStream2) {
        HRESULT hr = m_pStream2->Present(pBuffArr, strides, 0);
        if(FAILED(hr))
            NSLog(@"error :%d \n",__LINE__);
    }

    if (m_pPresenterAdv) {
        HRESULT hr = m_pPresenterAdv->Render(0);
        if (hr == VR_FAIL_CANVASCHANGED) {
            m_pPresenterAdv->Get(IID_IMcVideoPresenter, MC_PROPID_VP_CANVAS_INFO, 
                                 0, 0, &m_canvasInfo, sizeof(m_canvasInfo),0);
            RECT dstRect1;
            SetRect(&dstRect1, 0, 0, m_canvasInfo.dwWidth, m_canvasInfo.dwHeight);
            m_pStream1->Set(IID_IMcVideoPresenter, MC_PROPID_VP_RECTDST, 0, 0, &dstRect1, sizeof(dstRect1));
            RECT dstRect2;
            //SetRect(&dstRect2, 0, 0, m_canvasInfo.dwWidth/2, m_canvasInfo.dwHeight/2);
            SetRect(&dstRect2, 0, 0, m_canvasInfo.dwWidth/2, m_canvasInfo.dwHeight);
//            m_pStream2->Set(IID_IMcVideoPresenter, MC_PROPID_VP_RECTDST, 0, 0, &dstRect2, sizeof(dstRect2));

        }
        if(FAILED(hr))
            NSLog(@"error :%d \n",__LINE__);
    }

    if (m_pPresenter) {
        HRESULT hr = m_pPresenter->Present(pBuffArr, strides, 0);
        if(FAILED(hr))
            NSLog(@"error :%d \n",__LINE__);
        hr = m_pPresenter->Present(0, 0, eANDROID_UI_FLIP);
        if(FAILED(hr))
            NSLog(@"error :%d \n",__LINE__);
    }
//    float progress = ((float)ftell(mFile)/(float)mFileSize);
//    [progressView setProgress:progress  animated:YES];
        
}

- (void) layoutSubviews
{
    NSLog(@"layoutSubviews");
   
    if(m_pPresenter)
    {
        HRESULT hr = m_pPresenter->Set(IID_IMcVideoPresenter, 
                        MC_PROPID_VP_RECT_SCREEN, NULL, NULL,(LPVOID)self.layer,0);
        if(FAILED(hr))
            NSLog(@"error :%d \n",__LINE__);
    }

    if(m_pPresenterAdv)
    {
        HRESULT hr = m_pPresenterAdv->Set(IID_IMcVideoPresenter,
                        MC_PROPID_VP_RECT_SCREEN, NULL, NULL,(LPVOID)self.layer,0);
        if(FAILED(hr))
            NSLog(@"error :%d \n",__LINE__);
    }

    [self drawView:nil];
}

- (NSInteger) animationFrameInterval
{
	return animationFrameInterval;
}

- (void) setAnimationFrameInterval:(NSInteger)frameInterval
{
	// Frame interval defines how many display frames must pass between each time the
	// display link fires. The display link will only fire 30 times a second when the
	// frame internal is two on a display that refreshes 60 times a second. The default
	// frame interval setting of one will fire 60 times a second when the display refreshes
	// at 60 times a second. A frame interval setting of less than one results in undefined
	// behavior.
	if (frameInterval >= 1)
	{
		animationFrameInterval = frameInterval;
		
		if (animating)
		{
			[self stopAnimation];
			[self startAnimation];
		}
	}
}

- (void) startAnimation
{
	if (!animating)
	{
		if (displayLinkSupported)
		{
			// CADisplayLink is API new to iPhone SDK 3.1. Compiling against earlier versions will result in a warning, but can be dismissed
			// if the system version runtime check for CADisplayLink exists in -initWithCoder:. The runtime check ensures this code will
			// not be called in system versions earlier than 3.1.
			
			displayLink = [NSClassFromString(@"CADisplayLink") displayLinkWithTarget:self selector:@selector(drawView:)];
			[displayLink setFrameInterval:animationFrameInterval];
			[displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		}
		else
			animationTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)((1.0 / 60.0) * animationFrameInterval) target:self selector:@selector(drawView:) userInfo:nil repeats:TRUE];
		
		animating = TRUE;
	}
}

- (void)stopAnimation
{
	if (animating)
	{
		if (displayLinkSupported)
		{
			[displayLink invalidate];
			displayLink = nil;
		}
		else
		{
			[animationTimer invalidate];
			animationTimer = nil;
		}
		
		animating = FALSE;
	}
}

- (void) setBrightness:(float)brightness
{
//    DWORD input = brightness;
//    m_pPresenterAdv->Set(IID_IMcVideoPresenter, MC_PROPID_VP_BRIGHTNESS, NULL, NULL,&input,sizeof(input));
    VP_ZOOM_MODE mode = VP_ZOOM_MODE_LETTERBOX;

    if(brightness<5.0f)
        mode = VP_ZOOM_MODE_LETTERBOX;
    else
        mode = VP_ZOOM_MODE_CROPPING;
    
    m_pStream1->Set(IID_IMcVideoPresenter, MC_PROPID_VP_ZOOM, NULL, NULL,&mode,sizeof(mode));

}

- (void) setContrast:(float)contrast
{
    DWORD input = contrast;
    m_pPresenterAdv->Set(IID_IMcVideoPresenter, MC_PROPID_VP_CONTRAST, NULL, NULL,&input,sizeof(input));
}

- (void) dealloc
{
    if(m_pbuff)
    {
        free(m_pbuff);
        m_pbuff = NULL;
    }
//    [renderer release];

    if (m_pStream2) {
        m_pStream2->Close();
        m_pStream2->Release();
        m_pStream2 = NULL;
    }

    if (m_pStream1) {
        m_pStream1->Close();
        m_pStream1->Release();
        m_pStream1 = NULL;
    }
        if(m_pPresenterAdv)
        {
            m_pPresenterAdv->Close();
            m_pPresenterAdv->Release();
            m_pPresenterAdv = NULL;
        }
	if (m_pPresenter) {
        m_pPresenter->Close();
        delete m_pPresenter;
        m_pPresenter = NULL;
    }
	
	// tear down context
//	if ([EAGLContext currentContext] == _context)
//        [EAGLContext setCurrentContext:nil];
	if (mFile) {
        fclose(mFile);
    }
//	[_context release];
	
    [super dealloc];
}

@end

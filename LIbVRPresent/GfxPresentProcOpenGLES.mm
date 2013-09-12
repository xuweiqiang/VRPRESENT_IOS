//===================================== ========================================
//  CIDANA CONFIDENTIAL INFORMATION
//
//	THIS SOURCE CODE IS PROPRIETARY INFORMATION BELONGING TO CIDANA, INC.
// 	ANY USE INCLUDING BUT NOT LIMITED TO COPYING OF CODE, CONCEPTS, AND/OR
//	ALGORITHMS IS PROHIBITED EXCEPT WITH EXPRESS WRITTEN PERMISSION BY THE 
//	COMPANY.
//
// 	THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY
// 	KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
// 	IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR
// 	PURPOSE.
//
// 	Copyright (c) 2008  Cidana, Inc.  All Rights Reserved.
//
//-----------------------------------------------------------------------------



#import "GfxIosOpenGles.h"
@interface NsFlip : NSObject {
@private
    void* gfxOpenGL;
}
-(void) resizeScreen;
-(void) initContext;
-(void) createTexture:(NSNumber*)idx;
@property (nonatomic, assign) void* gfxOpenGL;
@end

@class ESRender;

typedef struct
{
	NsFlip* m_flipObject;
	ESRender* m_glRender;
	CAEAGLLayer* m_flipLayer;
}GfxPresentProcContext;

#include "GfxBuildDef.h"

#include <stdio.h>
#include "GfxPresent.h"

#include "dp.h"
#include "tchar.h"
#include "GfxPresentProcOpenGLES.h"
#include "GfxPresentStreamOpenGLES.h"


DWORD    timeGetTime(void) {
    struct timeval my_timeval;
    if (gettimeofday(&my_timeval, NULL))
        return 0;
    return (DWORD)(my_timeval.tv_sec * 1000) + (my_timeval.tv_usec / 1000);
}


static HRESULT ConvertPrecision(LONG& lSrcVal, const LONG lDstMax, const LONG lDstMin, const LONG lSrcMax,const LONG lSrcMin)
{
	LONG lSrcNum = lSrcMax - lSrcMin;
	LONG lDstNum = lDstMax - lDstMin;
    
	if(lSrcVal>lSrcMax)
		lSrcVal = lDstMax;
	else if(lSrcVal < lSrcMin)
		lSrcVal = lDstMin;
	else		
		lSrcVal = lDstMin + (lSrcVal-lSrcMin)*lDstNum/lSrcNum;
	return S_OK;
}


CVRProcOpenglES ::CVRProcOpenglES () :
m_Init(false),
m_bcanChanged(true),
m_pVideoMixer(NULL),
m_wndwidth(0),
m_wndheight(0)
{
	ZeroMemory(&m_pStmArrar, sizeof(m_pStmArrar));	
	InitializeCriticalSection(&m_csDisplay);
	memset(&m_android_param, 0,sizeof(m_android_param));
	m_pContext = (void*)malloc(sizeof(GfxPresentProcContext));
	if(NULL == m_pContext)
	{
		NSLog(@"CVRProcOpenglES Out of Memory");
	}
    
    GfxPresentProcContext* g_InternalContext = (GfxPresentProcContext*)m_pContext;
	g_InternalContext->m_flipObject = [[NsFlip alloc]init];
	g_InternalContext->m_flipObject.gfxOpenGL = this;
	g_InternalContext->m_glRender = nil;
	g_InternalContext->m_flipLayer = nil;
}

CVRProcOpenglES ::~CVRProcOpenglES ()
{
	if(m_pContext)
	{
		GfxPresentProcContext*  g_InternalContext = (GfxPresentProcContext*)m_pContext;
		[g_InternalContext->m_flipObject release];
		g_InternalContext->m_flipObject = nil;
		free( m_pContext);
	}
    
	DeleteCriticalSection(&m_csDisplay);
}	


STDMETHODIMP CVRProcOpenglES ::Open(IN VP_OpenOptionsAdv *pOpenParams, IN DWORD dwOpenSize)
{
	HRESULT hr = S_OK;
	if(pOpenParams==NULL )	return E_INVALIDARG;
	if(m_Init)
		return E_UNEXPECTED;
    
	memset(&m_surf_param, 0 ,sizeof(m_surf_param));
	
	m_surf_param = pOpenParams->surfparam;
	
	GfxPresentProcContext* g_InternalContext = (GfxPresentProcContext*)m_pContext;
    [g_InternalContext->m_flipObject  initContext];
//	[g_InternalContext->m_flipObject performSelectorOnMainThread:@selector(initContext) withObject:nil waitUntilDone:YES];
    
	m_Init = true;
	return hr;
}

STDMETHODIMP CVRProcOpenglES ::Close()
{
    
	if(!m_Init)
		return E_UNEXPECTED;
    for(int i=0;i<MAX_STREAM ;i++)
	{
		if(m_pStmArrar[i].valid)
            DestroyStream(m_pStmArrar[i].pStream);
    }
    
	OpenGLESUnInit();
    
	m_Init = false;
    
    
	return S_OK;
}


STDMETHODIMP CVRProcOpenglES::Render(DWORD dwRenderFlags)
{
	if(!m_Init)	return VR_FAIL_UNOPEN;
    
    int window_width = 0;
    int window_height = 0;
    int ret = 0;
    
	GfxPresentProcContext* g_InternalContext = (GfxPresentProcContext*)m_pContext;
	ret = [g_InternalContext->m_glRender getWindowWidth:(int*)&window_width height:(int*)&window_height];
    if (ret == 0 &&(window_width!=0) && (window_height != 0)) {
        if((m_wndwidth != window_width) || (m_wndheight != window_height))
        {
            m_wndwidth = window_width;
            m_wndheight  = window_height;
            m_bcanChanged = true;
        }
    }
    if(m_bcanChanged)
		return VR_FAIL_CANVASCHANGED;
    
    return S_OK;
}


STDMETHODIMP CVRProcOpenglES ::Get(IN REFGUID guidPropSet, IN DWORD dwPropID, IN LPVOID pInstanceData, 
                                   IN DWORD cbInstanceData, IN LPVOID pPropData, IN DWORD cbPropData, OUT DWORD *pcbReturned)
{
	switch (dwPropID)
	{
		case MC_PROPID_VP_CANVAS_INFO:
        {
            if(pPropData == NULL)	return E_INVALIDARG;
            if(!m_Init)	return VR_FAIL_UNOPEN;
            VP_CANVASINFO_PARAMS* pArgs = (VP_CANVASINFO_PARAMS*)pPropData;
            pArgs->dwWidth = m_wndwidth;
            pArgs->dwHeight = m_wndheight;
            m_bcanChanged = false;
            return S_OK;
        }
            
        case MC_PROPID_VP_VP_HND:
        {
            if(pPropData == NULL)	return E_INVALIDARG;
            if(!m_Init)	return VR_FAIL_UNOPEN;
            VR_IOS_PARAMS* pArgs = (VR_IOS_PARAMS*)pPropData;
            *pArgs = m_surf_param;
            return S_OK;
        }
            
        case MC_PROPID_VP_ALLSTREAMS:
		{
			IMcVideoPresenterStream** pArray = (IMcVideoPresenterStream**)pPropData;
			int intputArraySize = cbPropData/ sizeof(IMcVideoPresenterStream*);
			if(pArray == 0)	
				return E_INVALIDARG;
			
			if(GetStreamNumber()> intputArraySize)
				return E_OUTOFMEMORY;
            
			int i = 0;
			int j = 0;
			for(i=0;i<MAX_STREAM ;i++)
			{
				if(m_pStmArrar[i].valid)	
				{
					pArray[j++] = m_pStmArrar[i].pStream;
				}
			}
			if(pcbReturned)
				*pcbReturned = j; 
			return S_OK;
		}

		default:
			break;
	}
	return E_PROP_ID_UNSUPPORTED;
}

STDMETHODIMP CVRProcOpenglES::ResizeScreenInternal()
{
	GfxPresentProcContext* g_InternalContext = (GfxPresentProcContext*)m_pContext;
    [g_InternalContext->m_glRender resizeFromLayer:g_InternalContext->m_flipLayer];
    return S_OK;
}

STDMETHODIMP CVRProcOpenglES::CreateTextureInternal(int i)
{
    DWORD fourcc  = 0;
    if (m_pStmArrar[i].param.type == eMAINSTREAM)
    {
//        fourcc = MAKE_FOURCC('R','5','6','5');
        fourcc = MAKE_FOURCC('Y','V','1','2');
    }
    else
                fourcc = MAKE_FOURCC('Y','V','1','2');
//        fourcc = MAKE_FOURCC('R','5','5','5');
    
	GfxPresentProcContext* g_InternalContext = (GfxPresentProcContext*)m_pContext;
	m_pStmArrar[i].textureId = [g_InternalContext->m_glRender createTextureWidth:m_pStmArrar[i].param.dwWidth 
                                                                          height:m_pStmArrar[i].param.dwHeight format:fourcc];
    
    return S_OK;
}

STDMETHODIMP CVRProcOpenglES::Set(IN REFGUID guidPropSet, IN DWORD dwPropID, IN LPVOID pInstanceData, 
                                  IN DWORD cbInstanceData, IN LPVOID pPropData, IN DWORD cbPropData)
{
	if(!pPropData)
		return E_FAIL;
    
	switch (dwPropID)
	{
        case MC_PROPID_VP_RECT_SCREEN:
        {
			GfxPresentProcContext*  g_InternalContext = (GfxPresentProcContext*)m_pContext;
            g_InternalContext->m_flipLayer = (CAEAGLLayer*)pPropData;
            ResizeScreenInternal();
            break;
        }
		default:
			break;
	}
    
	return S_OK;
}


STDMETHODIMP CVRProcOpenglES ::CreateStream(IN VP_OPEN_STREAM_PARAMS *pOpenParams,
                                            IN DWORD dwOpenSize ,OUT IMcVideoPresenterStream **ppStream)
{
	HRESULT hr = S_OK;
	if(!pOpenParams || !ppStream )
		return E_INVALIDARG;
    
	if(!m_Init)	return VR_FAIL_UNOPEN;
    
    //Init a free stream	
	UINT i;
	for(i=0;i<MAX_STREAM ;i++)
	{
		if(!m_pStmArrar[i].valid)	break;
	}
    
	if(i>= MAX_STREAM)	return E_UNEXPECTED;
	memcpy(&m_pStmArrar[i].param, pOpenParams, sizeof(VP_OPEN_STREAM_PARAMS));
    
    
	DWORD miWidth = 0;
	DWORD miHeight = 0;
	
    hr = CalculateGLStride(pOpenParams->dwWidth, &miWidth);	
    if(FAILED(hr))
        return E_INVALIDARG;
    hr = CalculateGLStride(pOpenParams->dwHeight, &miHeight);
    if(FAILED(hr))
        return E_INVALIDARG;
    
    m_pStmArrar[i].pBuf = (LPBYTE)malloc(miWidth*miHeight*2);
    if(!m_pStmArrar[i].pBuf ) return E_FAIL;
    memset(m_pStmArrar[i].pBuf, 0x00,miWidth*miHeight*2);
    
    
	GfxPresentProcContext* g_InternalContext = (GfxPresentProcContext*)m_pContext;
    
    UIApplicationState state;
    while(YES)
    {
        if(g_InternalContext->m_glRender != nil)
            break;
         usleep(100*1000);
    
    }
	EnterCriticalSection(&m_csDisplay);
    CreateTextureInternal(i);
    LeaveCriticalSection(&m_csDisplay);
    
    m_pStmArrar[i].pStream = new CVRStreamOpenglES(m_pStmArrar[i].pBuf, 
                                                   &m_csDisplay, &m_pStmArrar[i].param, miWidth, miHeight,g_InternalContext->m_glRender, 
                                                   m_pStmArrar[i].textureId,&m_bcanChanged);
	if(!m_pStmArrar[i].pStream)	goto RET;
    
	m_pStmArrar[i].valid = true;
    
	if(ppStream)
		*ppStream = static_cast<IMcVideoPresenterStream*>(m_pStmArrar[i].pStream);
    
	return hr;
	
RET:
    
	m_pStmArrar[i].pStream->Release();
    m_pStmArrar[i].pStream = nil;
    
	if(m_pStmArrar[i].pBuf)
	{
		free(m_pStmArrar[i].pBuf);
		m_pStmArrar[i].pBuf = NULL;
	}
	ZeroMemory(&m_pStmArrar[i], sizeof(SSTREAM_INFO));
	return E_FAIL;
}


STDMETHODIMP CVRProcOpenglES ::DestroyStream(IN IMcVideoPresenterStream *ppStream)
{
	if(!ppStream)	return E_FAIL;
	GfxPresentProcContext*  g_InternalContext = (GfxPresentProcContext*)m_pContext;
	for(int i=0;i<MAX_STREAM;i++)
	{
		if(m_pStmArrar[i].pStream == ppStream)
		{
			EnterCriticalSection(&m_csDisplay);
            [g_InternalContext->m_glRender DestroyTexture:m_pStmArrar[i].textureId];
            m_pStmArrar[i].pStream->Release();
			if(m_pStmArrar[i].pBuf)
				free(m_pStmArrar[i].pBuf);
			ZeroMemory(&m_pStmArrar[i], sizeof(SSTREAM_INFO));
			LeaveCriticalSection(&m_csDisplay);
			return S_OK;
		}
	}
	return E_NOTIMPL;
}


STDMETHODIMP CVRProcOpenglES::OpenGLESInit()
{
	if(m_surf_param.drawable == 0)
		return E_FAIL;
	GfxPresentProcContext*  g_InternalContext = (GfxPresentProcContext*)m_pContext;
    g_InternalContext->m_glRender = (ESRender*)[[GfxIosOpenGles alloc] initWithContext:(EAGLContext *)(m_surf_param.context)
                                                                           AndDrawable:(id<EAGLDrawable>)(m_surf_param.drawable)];
    
    if (g_InternalContext->m_glRender == nil) {
        DP("OPENGLES 2.0 isn't supported !!!! \n");
		return E_FAIL;
    }
	[g_InternalContext->m_glRender getWindowWidth:(int*)&m_wndwidth height:(int*)&m_wndheight];
	m_bcanChanged = true;
    
	return S_OK;
}

STDMETHODIMP CVRProcOpenglES::OpenGLESUnInit()
{
	GfxPresentProcContext*  g_InternalContext = (GfxPresentProcContext*)m_pContext;
    
    if (g_InternalContext->m_glRender)
    {
        [g_InternalContext->m_glRender release];
        g_InternalContext->m_glRender = nil;
    }
	return S_OK;
}

STDMETHODIMP CVRProcOpenglES::CalculateGLStride(DWORD input, DWORD* pOut)
{
    GLint maxResolution = 0;
    glGetIntegerv(GL_MAX_TEXTURE_SIZE, &maxResolution);
    
	if(!pOut ||(input>maxResolution && maxResolution!=0) )	return E_FAIL;
    
    GLuint mi =0;
    
    switch (input) {
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
            *pOut = input;
            return S_OK;
        default:
            break;
    } 
    
    while(input >0)
    {
        mi++;
        input >>= 1;
    }
    *pOut =2 <<(mi-1);
    return S_OK;
}
int CVRProcOpenglES::GetStreamNumber()
{
	int streamNum = 0;
	for(int i=0;i<MAX_STREAM ;i++)
	{
		if(m_pStmArrar[i].valid)	
			streamNum++;
	}
	return streamNum;

}


@implementation NsFlip
@synthesize gfxOpenGL;

- (void) resizeScreen
{
	CVRProcOpenglES* gfx =  (CVRProcOpenglES*)self.gfxOpenGL;
    gfx->ResizeScreenInternal();
}

- (void) initContext
{
	CVRProcOpenglES* gfx =  (CVRProcOpenglES*)self.gfxOpenGL;
	gfx->OpenGLESInit();
}
- (void) createTexture:(NSNumber*)idx
{
	CVRProcOpenglES* gfx =  (CVRProcOpenglES*)self.gfxOpenGL;
	gfx->CreateTextureInternal(idx.intValue);
	[idx release];
    
}

@end

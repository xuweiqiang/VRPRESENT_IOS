//=============================================================================
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

#ifndef _GFXPRESENT_DEF_H_
#define _GFXPRESENT_DEF_H_

#ifndef EXPORT
#define EXPORT extern "C" _declspec(dllexport)
#endif

#define VIDEOPRESENTER_V2_FILENAME _T("LibVRPresent_V2.dll")

#include "GfxOverlay.h"
#include "DMCP.h"
#include "ci_codec_type.h"
#include "ci_imageproc.h"




#ifdef __linux__
typedef struct _DDCOLORCONTROL
{
    DWORD               dwSize;
    DWORD               dwFlags;
    LONG                lBrightness;
    LONG                lContrast;
    LONG                lHue;
    LONG                lSaturation;
    LONG                lSharpness;
    LONG                lGamma;
    LONG                lColorEnable;
    DWORD               dwReserved1;
} DDCOLORCONTROL;

#define DDCOLOR_BRIGHTNESS              0x00000001l
#define DDCOLOR_CONTRAST                0x00000002l
#define DDCOLOR_HUE                     0x00000004l
#define DDCOLOR_SATURATION              0x00000008l
#define DDCOLOR_SHARPNESS               0x00000010l
#define DDCOLOR_GAMMA                   0x00000020l
#define DDCOLOR_COLORENABLE             0x00000040l
#else
#include <stdio.h>
#include <windows.h>
#include <ddraw.h>
#endif


typedef struct
{
	RECT m_rSrcSize;	
	RECT m_rSrcClip;	
	RECT m_rDst;
	BOOL bOpen;
}VP_HANDLE;


class CVRPresentOvl : 
	public IMcVideoPresenter
{
public:
	CVRPresentOvl();
	virtual ~CVRPresentOvl();

	
	//Interface 2.5
	STDMETHODIMP Open(VP_OpenOptions *pOptions, DWORD dwOptionSize);
	STDMETHODIMP Close();
	STDMETHODIMP  CreateSurface(VR_SURFACE_TYPE type, VP_SURFACE_OpenOptions* pparam);
	STDMETHODIMP  DestroySurface(VR_SURFACE_TYPE type);
	STDMETHODIMP Reset();
	STDMETHODIMP SetInterface(DWORD dwRoute, REFIID riid, LPUNKNOWN pUnk);
	STDMETHODIMP SetVBI(VP_VIDEOBUFFER_INFO *pVBI);
	STDMETHODIMP SetFPS(DWORD dwFPS);
	STDMETHODIMP GetBackBuffers(DWORD *pdwBackBuffers);
	STDMETHODIMP Restore();
	STDMETHODIMP GetStatus(DWORD *pdwStatus);
	STDMETHODIMP GetCaps(VP_CAPS *pCaps);

	STDMETHODIMP Get(REFGUID guidPropSet, DWORD dwPropID, LPVOID pInstanceData, DWORD cbInstanceData, LPVOID pPropData, DWORD cbPropData, DWORD *pcbReturned);
	STDMETHODIMP Set(REFGUID guidPropSet, DWORD dwPropID, LPVOID pInstanceData, DWORD cbInstanceData, LPVOID pPropData, DWORD cbPropData);
	STDMETHODIMP GetSurface(VR_SURFACE_TYPE type, REFGUID guidPropSet, DWORD dwPropID, LPVOID pInstanceData, DWORD cbInstanceData, LPVOID pPropData, DWORD cbPropData, DWORD *pcbReturned);
	STDMETHODIMP SetSurface(VR_SURFACE_TYPE type, REFGUID guidPropSet, DWORD dwPropID, LPVOID pInstanceData, DWORD cbInstanceData, LPVOID pPropData, DWORD cbPropData);
	STDMETHODIMP PrepareBuffer(VR_SURFACE_TYPE type, LONG lNum, LPBYTE *ppbPlanes, DWORD *pdwStride, DWORD dwFlags);
	STDMETHODIMP PresentBuffer(VR_SURFACE_TYPE type, LONG lNum, DWORD dwFlags);
	STDMETHODIMP Present(VR_SURFACE_TYPE type, LPBYTE *ppbPlanes, DWORD *pdwStrides, DWORD dwFlags);
	STDMETHODIMP PrepareBuffer(LONG lNum, LPBYTE *ppbPlanes, DWORD *pdwStride, DWORD dwFlags);
	STDMETHODIMP PresentBuffer(LONG lNum, DWORD dwFlags);
	STDMETHODIMP Present(LPBYTE *ppbPlanes, DWORD *pdwStrides, DWORD dwFlags);
	STDMETHODIMP PresentRect(LPBYTE *ppbPlanes, DWORD *pdwStrides,DWORD dwFlags ,RECT* pSrcRgn, RECT* pDstRgn); 
    STDMETHODIMP Release();


#ifdef VM_SUPPORT
	STDMETHODIMP Lock(LONG num, LPVOID *ppBuf, LONG *pStride, DWORD *pPixCount){return E_NOTIMPL;};
	STDMETHODIMP Unlock(LONG num){return E_NOTIMPL;};
#endif

	STDMETHODIMP LockSurface( LPBYTE *ppData, DWORD *pdwStride);
	STDMETHODIMP UnlockSurface(); 
	STDMETHODIMP FlipSurface();


protected:
	STDMETHODIMP Restore(BOOL bResDMCP);
	HRESULT SetSrcSize(DWORD dwWidth, DWORD dwHeight);
	HRESULT UpdateDisplayParameters();
	static HRESULT ConvertPrecision(LONG& lSrcVal, const LONG lDstMax, const LONG lDstMin, const LONG lSrcMax,const LONG lSrcMin);
	HRESULT InitColorControl();
	HRESULT RestoreColorControl();
	STDMETHODIMP ConvertVRType2VMType(VR_SURFACE_TYPE type, VM_SURFACE_LAYER_ID* pId);
	HRESULT SetVideoWndDst();
	HRESULT SetRectDstInt(RECT* pDst);

	#ifdef  USE_IPP_ROTATION
	STDMETHODIMP PrepareBufferIPP_YV12(LPBYTE frameBuffer, 	LONG lStride , LPBYTE *ppbPlanes, DWORD *pdwStrides,DWORD* pdwBufStrides);
	#endif

	HRESULT UpdateDestPos();

	CRITICAL_SECTION m_csDisplay; 

	VP_ZOOM_MODE m_lZoomMode;
	LONG m_lInterpolationMode;
	LONG m_lRotationMode;
	LONG m_lDeblockMode;
	LONG m_lResampleMode;
	BOOL m_lRenderEnabled;
	LONG m_alCC[10];
	BOOL m_bZoomEnable;
	bool m_bDMCPEnable;

	VP_VIDEOBUFFER_INFO m_VBI;

	//
	// Video Port information
	//
	RECT m_rDst;		// destination rectangle to store the image, relative to video window/port.
	RECT m_rSrcSize;	// source size (also used as source clipping region) 
	RECT m_rScreen;		// size of currently active screen
	DWORD m_dwStatus;
	DWORD m_dwPresentIndex;	// the current frame to be used by Present

	GfxOverlayInfo m_ginfo;
	IMcGfxOverlay *m_pOverlay;
	unsigned int    m_FPS;
	VP_OpenOptions m_OpenOptions;
	LONG m_overlayType;
	CI_IMAGEPROC_COLOROPTION m_videoEffect;
	IMcVideoWindow * m_pVideoWindow;
	DWORD surfaceFourCC;
	static const DWORD const_SurfFourCC[];
	static const DWORD const_InputFourCC[];

	VP_HANDLE m_surfHandle[MAX_SURFACE_NUM];
	IMcVideoPresenterMixer *m_pvideoMixer;
	BOOL m_bOpen,m_bGoMixer;
	VP_VIDEO_MEMORY_INFO* pVideoMemoryInfo;
	VP_VIDEO_MEMORY_INFO m_bufferMemoryInfo;

	GfxPrepareDataV2 m_PrepareData;
	DDCOLORCONTROL m_sColorCaps;
	BOOL m_bSoftScale;
	VP_OpenOptions m_SoftOpenOptions;

	//For DMCP 
	IDmcpDisplay *m_pDMCP;
	BOOL	m_DMCP_dsp_enable;
	DWORD 	m_lastpresent_tick;
	DWORD 	m_DMCP_ACP_flag;
	DWORD 	m_DMCP_CGMS_flag;
	DWORD 	m_DMCP_HDCP_flag;
#ifndef WINCE
//	IMcVideoMixer *m_pVideoMixer_D3D;
#endif
	VP_DEINTERLACE_MODE m_Deinterlaced_Mode;
	RECT rVideoWnd;
	RECT m_absoluteRectBak;
	VP_VSYNC_MODE m_vsyncMode;

	LPBYTE m_pOSDbuf;
	DWORD m_dwCkeySrc;
	DWORD m_StreamCount;

	VP_OpenOptions m_unsupportOptions;
	bool m_unsupportSizeFlag;

};


class CVRPresent : 
	public IMcVideoPresenter
{
public:
	CVRPresent();
	virtual ~CVRPresent();


	//Interface 2.5
	STDMETHODIMP Open(VP_OpenOptions *pOptions, DWORD dwOptionSize);
	STDMETHODIMP Close();
	STDMETHODIMP  CreateSurface(VR_SURFACE_TYPE type, VP_SURFACE_OpenOptions* pparam){return E_NOTIMPL;};
	STDMETHODIMP  DestroySurface(VR_SURFACE_TYPE type){return E_NOTIMPL;};
	STDMETHODIMP Reset();
	STDMETHODIMP SetInterface(DWORD dwRoute, REFIID riid, LPUNKNOWN pUnk);
	STDMETHODIMP SetVBI(VP_VIDEOBUFFER_INFO *pVBI){return E_NOTIMPL;};
	STDMETHODIMP SetFPS(DWORD dwFPS);
	STDMETHODIMP GetBackBuffers(DWORD *pdwBackBuffers);
	STDMETHODIMP Restore(){return E_NOTIMPL;};
	STDMETHODIMP GetStatus(DWORD *pdwStatus){return E_NOTIMPL;};
	STDMETHODIMP GetCaps(VP_CAPS *pCaps){return E_NOTIMPL;};

	STDMETHODIMP Get(REFGUID guidPropSet, DWORD dwPropID, LPVOID pInstanceData, DWORD cbInstanceData, LPVOID pPropData, DWORD cbPropData, DWORD *pcbReturned);
	STDMETHODIMP Set(REFGUID guidPropSet, DWORD dwPropID, LPVOID pInstanceData, DWORD cbInstanceData, LPVOID pPropData, DWORD cbPropData);
	STDMETHODIMP Present(LPBYTE *ppbPlanes, DWORD *pdwStrides, DWORD dwFlags);


	STDMETHODIMP GetSurface(VR_SURFACE_TYPE type, REFGUID guidPropSet, DWORD dwPropID, 
		LPVOID pInstanceData, DWORD cbInstanceData, LPVOID pPropData, DWORD cbPropData, 
		DWORD *pcbReturned) {return E_NOTIMPL;};
	STDMETHODIMP SetSurface(VR_SURFACE_TYPE type, REFGUID guidPropSet, DWORD dwPropID, 
		LPVOID pInstanceData, DWORD cbInstanceData, LPVOID pPropData, DWORD cbPropData)
		{return E_NOTIMPL;};
	STDMETHODIMP PrepareBuffer(VR_SURFACE_TYPE type, LONG lNum, LPBYTE *ppbPlanes, 
		DWORD *pdwStride, DWORD dwFlags){return E_NOTIMPL;};
	STDMETHODIMP PresentBuffer(VR_SURFACE_TYPE type, LONG lNum, DWORD dwFlags){return E_NOTIMPL;};
	STDMETHODIMP Present(VR_SURFACE_TYPE type, LPBYTE *ppbPlanes, DWORD *pdwStrides, DWORD dwFlags){return E_NOTIMPL;};
	STDMETHODIMP PrepareBuffer(LONG lNum, LPBYTE *ppbPlanes, DWORD *pdwStride, DWORD dwFlags);
	STDMETHODIMP PresentBuffer(LONG lNum, DWORD dwFlags){return E_NOTIMPL;};
	STDMETHODIMP PresentRect(LPBYTE *ppbPlanes, DWORD *pdwStrides,DWORD dwFlags ,RECT* pSrcRgn, RECT* pDstRgn){return E_NOTIMPL;}; 

protected:
 	HRESULT SetSrcSize(DWORD dwWidth, DWORD dwHeight);
	HRESULT UpdateDisplayParameters();
	HRESULT SetVideoWndDst();
	HRESULT SetRectDstInt(RECT* pDst);

	#ifdef  USE_IPP_ROTATION
	STDMETHODIMP PrepareBufferIPP_YV12(LPBYTE frameBuffer, 	LONG lStride , LPBYTE *ppbPlanes, DWORD *pdwStrides,DWORD* pdwBufStrides);
	#endif
	CRITICAL_SECTION m_csDisplay; 

	//LONG m_lZoomMode;
	//LONG m_lInterpolationMode;
	LONG m_lRotationMode;
	LONG m_lDeblockMode;
	LONG m_lResampleMode;
	//LONG m_lRenderEnabled;
	LONG m_alCC[10];
	//BOOL m_bZoomEnable;
	//bool m_bDMCPEnable;

	//VP_VIDEOBUFFER_INFO m_VBI;

	//
	// Video Port information
	//
	RECT m_rDst;		// destination rectangle to store the image, relative to video window/port.
	RECT m_rSrcSize;	// source size (also used as source clipping region) 
	DWORD m_dwStatus;
	DWORD m_dwPresentIndex;	// the current frame to be used by Present

	unsigned int    m_FPS;
	VP_OpenOptions m_OpenOptions;
	LONG m_overlayType;
	CI_IMAGEPROC_COLOROPTION m_videoEffect;
 	DWORD surfaceFourCC;
	static const DWORD const_SurfFourCC[];
	static const DWORD const_InputFourCC[];

	VP_HANDLE m_surfHandle[MAX_SURFACE_NUM];
	BOOL m_bOpen,m_bGoMixer;
	VP_VIDEO_MEMORY_INFO* pVideoMemoryInfo;
	VP_VIDEO_MEMORY_INFO m_bufferMemoryInfo;

	GfxPrepareDataV2 m_PrepareData;
	DDCOLORCONTROL m_sColorCaps;
	BOOL m_bSoftScale;
	VP_OpenOptions m_SoftOpenOptions;

	VP_DEINTERLACE_MODE m_Deinterlaced_Mode;
	RECT rVideoWnd;
	RECT m_absoluteRectBak;
	VP_VSYNC_MODE m_vsyncMode;

	DWORD m_dwCkeySrc;
	DWORD m_StreamCount;

	//ICivmVideoMixer* m_pVideoMixer;
	//ICivmVideoContext* m_pVideoContext;
	DWORD m_dstSurfFourCC;
	
	ICivmVideoContext* m_ContextArray[8];

};

#endif //_GFXPRESENT_DEF_H_

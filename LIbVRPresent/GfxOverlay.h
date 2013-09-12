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

#ifndef _GFXOVERLAY_H_
#define _GFXOVERLAY_H_

#ifdef __linux__
#ifndef ANDROID
	#if defined(ST)|| defined(GFX_FB_LINUX)  || defined(ST_LINUX) || defined(PXA_LINUX) || defined(__QNX__)
	#else
//	#include <X11/Xlib.h>
	#endif
#else
#include "windows.h"
#endif
#endif

#if defined(SIRF_A4_OLDOS) || defined(SAMSUNG_2416) || defined(APOLLO_SAMSUNG2450) || defined(NAVI)
#define NO_ROT_SCL
#endif

#define GFXOVERLAY_SURF_OVERLAY	-1
#define GFXOVERLAY_SURF_PRIMARY	-2

#define MAX_BRIGHTNESS_INTERNAL 10000
#define MIN_BRIGHTNESS_INTERNAL 0
#define MAX_CONTRAST_INTERNAL 20000
#define MIN_CONTRAST_INTERNAL 0
#define MAX_HUE_INTERNAL 180
#define MIN_HUE_INTERNAL -180
#define MAX_SATURATION_INTERNAL 20000
#define MIN_SATURATION_INTERNAL 0
#define MAX_SHARPNESS_INTERNAL 10
#define MIN_SHARPNESS_INTERNAL 0
#define MAX_GAMMA_INTERNAL 500
#define MIN_GAMMA_INTERNAL 1
#define MAX_COLOREN_INTERNAL 1
#define MIN_COLOREN_INTERNAL 0
#define MAX_ALPHA_INTERNAL 100
#define MIN_ALPHA_INTERNAL 0

#ifndef MAKEFOURCC
	#define MAKEFOURCC(ch0,ch1,ch2,ch3)	\
	((DWORD)(BYTE)(ch0) | (DWORD)(BYTE)(ch1)<<8| (DWORD)(BYTE)(ch2)<<16| (DWORD)(BYTE)(ch3)<<24)
#endif

struct GfxOverlayInfo
{
	DWORD dwSize;
	DWORD dwWidth;
	DWORD dwHeight;
	DWORD dwBackBuffers;
	DWORD dwFourCC;
	DWORD dwCaps;
};

#ifdef ST_LINUX
#include "../../3rdparty/ST_Linux/noDataCopy/stglib.h"
#include "../../3rdparty/ST_Linux/noDataCopy/STSGA_lib.h"

typedef struct {
	STHDC   hdc;
	DWORD yBuff;
	DWORD uOffset;
	DWORD vOffset;
	DWORD yStride;
	DWORD uStride;
	DWORD vStride;
	STHBITMAP	m_bitmap;
}GfxST_HND;

#elif defined(RENESAS)
typedef struct {
  unsigned char* pYBuff;
  unsigned char* pUVBuff;
}GfxRENESAS_HND;

#endif
enum 
{
	GFXOVERLAY_CAP_FLIP_BOB = (1<<0),
	GFXOVERLAY_CAP_FLIP_DEINTERLACE = (1<<1),
};

enum
{
	GFXOVERLAY_FLIP_ODD = (1<<0),
	GFXOVERLAY_FLIP_EVEN = (1<<1),
	GFXOVERLAY_FLIP_FIXED = (1<<2),
};

enum
{
	GFXOVERLAY_SCALE_X = (1<<0),
	GFXOVERLAY_SCALE_Y = (1<<1)
};

enum
{
	GFXOVERLAY_DEINTERLACE_WEAVE,
	GFXOVERLAY_DEINTERLACE_BOB_SINGLE_FIELD,
	GFXOVERLAY_DEINTERLACE_BOB_DOUBLE_FIELD
};

enum
{
	GFXOVERLAY_CAPS_HIDE_NOT_SUPPORT = (1<<0),
	GFXOVERLAY_CAPS_CROPPING_SUPPORT = (1<<1),
	GFXOVERLAY_CAPS_ZOOM_SUPPORT = (1<<2),
		
};

typedef struct _DDCOLORCONTROL DDCOLORCONTROL;
typedef struct _DDGAMMARAMP DDGAMMARAMP;

DECLARE_INTERFACE(IMcGfxOverlay)
{
	STDMETHOD (Open)(DWORD dwWidth, DWORD dwHeight, DWORD dwBuffers, const DWORD *pdwFourCC, float fAspectRatio, RECT* pDst = NULL) PURE;
	STDMETHOD (Close)() PURE;
	STDMETHOD (Lock)(LONG num, LPVOID *ppBuf, LONG *pStride, DWORD *pPixCount) PURE;
	STDMETHOD (Unlock)(LONG num) PURE;
	STDMETHOD (Flip)(LONG num, DWORD dwFlags) PURE;
	STDMETHOD (Show)(BOOL bShow) PURE;
	STDMETHOD (GetSurfScaleRects)(LONG num, RECT *pRSrcRect, RECT *pDstRect, DWORD *pdwFlags) PURE;	// After locking: prefers to convert SrcRect to DstRect on source surface
	STDMETHOD (SetSurfScale)(LONG num, RECT *pScale, DWORD dwFlags) PURE;							// Before unlocking: pScale should be pDstRect and dwFlags should be *pdwFlags if conversion performed.
	STDMETHOD (SetSrcRect)(const RECT *pRect) PURE;
	STDMETHOD (SetDstRect)(const RECT *pRect) PURE;
	STDMETHOD (SetScnRect)(const RECT *pRect) PURE;
	STDMETHOD (GetScnRect)(RECT *pRect) PURE;
	STDMETHOD (GetSurfaceInfo)(GfxOverlayInfo *pInfo) PURE;
	STDMETHOD (SetAlpha)(DWORD dwAlpha) PURE;
	STDMETHOD (IsOpen)() PURE;
	STDMETHOD (SetSrcColorKey)(BOOL bEnable, DWORD dwSrcCkey) PURE;
	STDMETHOD (SetDstColorKey)(BOOL bEnable, DWORD dwDstCkey) PURE;
	// windows specific
	#if defined (__linux__) && !defined (__QNX__)
	STDMETHOD (SetWindowHandle)(Window hwnd) PURE;
	STDMETHOD (GetWindowHandle)(Window& hwnd) PURE;
	STDMETHOD (UIFlip)(LPVOID pHandle) PURE;
	#else
	STDMETHOD (SetWindowHandle)(HWND hwnd) PURE;
	STDMETHOD (GetWindowHandle)(HWND& hwnd) PURE;
	#endif
	STDMETHOD (GetColorControl)(LONG num, DDCOLORCONTROL *pCC) PURE;
	STDMETHOD (GetGammaControl)(LONG num, DDGAMMARAMP *pGR) PURE;
	STDMETHOD (SetColorControl)(LONG num, DDCOLORCONTROL *pCC) PURE;
	STDMETHOD (SetGammaControl)(LONG num, DDGAMMARAMP *pGR) PURE;
	STDMETHOD (GetDDCaps)(LONG*pCaps) PURE;
	STDMETHOD (GetDDDevice)(LPVOID *pDevice, DWORD *pdwSize) PURE;
	STDMETHOD (GetVRHandle)(LPVOID pHandle) PURE;
	STDMETHOD (SetVRHandle)(LPVOID pHandle) PURE;
	STDMETHOD (SetHWRenderSurf)(LPVOID pSurf,int mode=0) PURE;
	STDMETHOD (SetDeinterlaceMode)(DWORD dwMode) PURE;
	STDMETHOD (GetDeinterlaceMode)(DWORD* pdwMode) PURE;
	STDMETHOD (SetVSYNC)(DWORD dwMode) PURE;
	STDMETHOD (GetVSYNC)(DWORD* pdwMode) PURE;	
	STDMETHOD (SetDisplayMode)(int disp_mode) PURE;
#ifdef SAMSUNG6410
	STDMETHOD (OpenSys)() PURE;
	STDMETHOD (OpenMedia)() PURE;
#endif	
#ifdef ST_LINUX
	STDMETHOD (SetFLipDelay)(int val) PURE;
#endif	

};

IMcGfxOverlay *CreateOverlayDDraw(DWORD surface_type);
IMcGfxOverlay *CreateOverlayTitan();
IMcGfxOverlay *CreateOverlayTitanII();
IMcGfxOverlay *CreateOverlayTitanII_OSD();
IMcGfxOverlay *CreateOverlayGDI();
IMcGfxOverlay *CreateOverlayRMI();
IMcGfxOverlay *CreateOverlaySDL();

#if ((_WIN32_WCE == 0x502)||(_WIN32_WCE == 0x501))
IMcGfxOverlay *CreateOverlayGx();
#endif
#ifndef _WIN32_WCE
IMcGfxOverlay *CreateOverlayD3D();
#endif

#ifdef SAMSUNG
IMcGfxOverlay *CreateOverlaySAMSUNG();
#endif

#ifdef PXA
IMcGfxOverlay *CreateOverlayPXA();
#endif

#ifdef ANDROID
IMcGfxOverlay *CreateOverlayAndroid();
#endif

#ifdef GFX_FB
IMcGfxOverlay *CreateOverlayFB();
#endif

#ifdef ST
IMcGfxOverlay *CreateOverlayST();
#endif

#ifdef GFX_DDRAW_OSD
IMcGfxOverlay *CreateDDrawOSD();
#endif

#ifdef GFX_ANDROID_SF
IMcGfxOverlay *CreateAndroidSF();
#endif

#ifdef GFX_ANDROID_OMX
IMcGfxOverlay *CreateOverlayAndroid();
#endif

#ifdef GFX_ANDROID_OPENGL_ES
IMcGfxOverlay *CreateOverlayAndroidOGL();
#endif

#ifdef GFX_ANDROID_OCE
IMcGfxOverlay *CreateOverlayAndroidOCE();
#endif

#ifdef GFX_OPENGL
IMcGfxOverlay *CreateOverlayOPENGL();
#endif

#ifdef SAMSUNG6410
IMcGfxOverlay *CreateOverlaySAMSUNG6410();
#endif

#ifdef RENESAS
IMcGfxOverlay *CreateOverlayRenesas();
IMcGfxOverlay *CreateOverlayRenesasHW();
#endif


#ifdef GFX_ANDROID_CANVAS
IMcGfxOverlay *CreateOverlayAndroidCanvas();
#endif

#ifdef GFX_ANDROID_SURFACE
IMcGfxOverlay *CreateOverlayAndroidSurface();
#endif

#ifdef GFX_ANDROID_OPENCORE
IMcGfxOverlay *CreateOverlayAndroidOCE();
#endif


#ifdef ST_LINUX
IMcGfxOverlay *CreateOverlaySTLnx(bool bExtBuff);
#endif

#ifdef GFX_OPENGLES
IMcGfxOverlay *CreateOverlayOpenGLES();
#endif

#ifdef GFX_ANDROID_STAGEFRIGHT
IMcGfxOverlay *CreateAndroidStageFright();
#endif

#ifdef GFX_ANDROID_ISURFACE_OVERLAY
IMcGfxOverlay *CreateAndroidISurfaceOverlay();
#endif

#ifdef JIASHI_SAMSUNG6410
IMcGfxOverlay *CreateJIASHI_SAMSUNG6410();
#endif

#ifdef GFX_ANDROID_OPENGL_ES_SHADER
IMcGfxOverlay *CreateOverlayAndroidOGL_ES_SHADER();
#endif


#ifdef RMI_CE6
IMcGfxOverlay *CreateOverlayRMI_CE6();
#endif

#ifdef GFX_MSTAR
IMcGfxOverlay *CreateOverlayMSTAR();
#endif


#ifdef GFX_QNX
IMcGfxOverlay *CreateOverlayQNX();
#endif


#ifdef GFX_EGL
IMcGfxOverlay *CreateEGL();
#endif

#endif // _GFXOVERLAY_H_

#ifndef _VIDEOMIXER_H_
#define _VIDEOMIXER_H_

#ifndef MAKE_FOURCC
#define MAKE_FOURCC(c1,c2,c3,c4) ((c4)<<24 | (c3)<<16 | (c2)<<8 | (c1))
#endif

#ifndef MC_PROPID_OFFSET
#define MC_PROPID_OFFSET(groupid)	(groupid<<8)
#endif

#include "windows.h"

struct VM_OpenOptions
{
	DWORD	dwFourCC;	//Output data type.
	DWORD	dwWidth;	//Output data Width
	DWORD	dwHeight;	//Output data Height
};

typedef enum
{
	SURFACELAYER_TOP,
	SURFACELAYER_LAYER1,
	SURFACELAYER_LAYER2,
	SURFACELAYER_LAYER3,
	SURFACELAYER_BOTTOM,
}VM_SURFACE_LAYER_ID;

struct VM_SurfaceOpenOptions
{
	DWORD	dwInputFourCC;	//Input data type.
	DWORD	dwTranColor;
	DWORD	dwWidth;
	DWORD	dwHeight;
};

enum MC_PROPID_VM
{
	MC_PROPID_VM_SURFACE_ORDER = MC_PROPID_OFFSET(0),
	MC_PROPID_VM_SURFACE_ENABLE,
};

#define MAX_SURFACE_NUM	5

DECLARE_INTERFACE(IMcVideoPresenterMixer)
{
	STDMETHOD(Open)(struct VM_OpenOptions* pOptions, DWORD dwOptionSize)  PURE;
	STDMETHOD(Close)()  PURE;
	STDMETHOD(Reset)()  PURE;
	STDMETHOD(Get)(VM_SURFACE_LAYER_ID id, REFGUID guidPropSet, DWORD dwPropID, LPVOID pInstanceData, DWORD cbInstanceData, LPVOID pPropData, DWORD cbPropData, DWORD *pcbReturned)  PURE;
	STDMETHOD(Set)(VM_SURFACE_LAYER_ID id, REFGUID guidPropSet, DWORD dwPropID, LPVOID pInstanceData, DWORD cbInstanceData, LPVOID pPropData, DWORD cbPropData)  PURE;
	STDMETHOD(CreateSurface)(VM_SURFACE_LAYER_ID id, struct VM_SurfaceOpenOptions* pOptions)  PURE;
	STDMETHOD(DestroySurface)(VM_SURFACE_LAYER_ID id)  PURE;
	STDMETHOD(Prepare)(VM_SURFACE_LAYER_ID id, LPBYTE *ppbPlanes, DWORD *pdwStrides, DWORD dwFlags) PURE;
	STDMETHOD(PresentBuffer)(VM_SURFACE_LAYER_ID id, DWORD dwFlags) PURE;
	STDMETHOD(SetInterface)(DWORD dwRoute, REFIID riid, LPUNKNOWN pUnk) PURE;
};


IMcVideoPresenterMixer *CreateFrameMixer();

#endif

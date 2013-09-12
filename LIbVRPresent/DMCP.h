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
// 	Copyright (c) 2009  Cidana, Inc.  All Rights Reserved.
//
//-----------------------------------------------------------------------------

#ifndef _DMCP_H_
#define _DMCP_H_

#ifndef CI_DEFINE_GUID

#ifdef __GNUG__  /* gcc/g++ compiler (Linux, Symbian ARMI) does the equivalent of _declspec(selectany) */
#define ATTRIBUTE_WEAK     __attribute__ ((weak))
#define DECLSPEC_SELECTANY
#elif defined(__ADS__)
#define ATTRIBUTE_WEAK  
#define DECLSPEC_SELECTANY 
#else
#define ATTRIBUTE_WEAK
#if !defined(DECLSPEC_SELECTANY)
#define DECLSPEC_SELECTANY _declspec(selectany)
#endif
#endif
	#define CI_DEFINE_GUID(name, l, w1, w2, b1, b2, b3, b4, b5, b6, b7, b8) \
		 EXTERN_C DECLSPEC_SELECTANY const GUID FAR name ATTRIBUTE_WEAK \
                = { l, w1, w2, { b1, b2,  b3,  b4,  b5,  b6,  b7,  b8 } }                
#endif

// {6230E5B0-A61D-4e42-ABCA-FBA36045103F}
CI_DEFINE_GUID(IID_IDmcpDisplay, 
0x6230e5b0, 0xa61d, 0x4e42, 0xab, 0xca, 0xfb, 0xa3, 0x60, 0x45, 0x10, 0x3f);

// {AC85CB47-4221-4e3f-90B2-DFC9581BF18B}
CI_DEFINE_GUID(IID_IDmcpLibrary, 
0xac85cb47, 0x4221, 0x4e3f, 0x90, 0xb2, 0xdf, 0xc9, 0x58, 0x1b, 0xf1, 0x8b);

// {5CDE0D89-1B1B-4ffe-ADF7-243DBBAD5675}
CI_DEFINE_GUID(CLSID_DmcpLibrary, 
0x5cde0d89, 0x1b1b, 0x4ffe, 0xad, 0xf7, 0x24, 0x3d, 0xbb, 0xad, 0x56, 0x75);

// {53ED1992-DAE9-4c38-BDF0-ACB8AC3B1985} TEST library
CI_DEFINE_GUID(CLSID_DmcpOkLibrary,	
0x53ed1992, 0xdae9, 0x4c38, 0xbd, 0xf0, 0xac, 0xb8, 0xac, 0x3b, 0x19, 0x85);

enum
{
	DMCP_CPFLAG_ACP		= (1<<0),
	DMCP_CPFLAG_CGMSA	= (1<<1),
	DMCP_CPFLAG_HDCP	= (1<<2),
	DMCP_CPFLAG_CLEAR	= (1<<24), // INPUT ONLY: Clear the entire state
};

enum
{
	DMCP_OPENFLAG_CDS = (1<<0),
	DMCP_OPENFLAG_COPP = (1<<1),
	DMCP_OPENFLAG_OMP = (1<<2), // the first 8 bits are reserved for CA methods!!!
	DMCP_OPENFLAG_SYNCHRONOUSRESTORE = (1<<16),	// Restore handled on SAME thread (default, on different thread)
	DMCP_OPENFLAG_INTERNALWINDOW = (1<<17),	// Restore and Display Change checked on different thread
};

typedef void (* LPINFOFUNC)(LPVOID pObj, LPCTSTR szFormat, ...);

struct DMCP_DisplayOpenParams
{
	DWORD dwOpenFlag;			// IN: 0 is default, otherwise specifically open certain DMCP handlers.
	DWORD dwCheckDisableCPFlag;	// IN: use DMCP_CPFLAG arguments to disable strict Copy Protection requirements
	DWORD dwReserved;
	LPINFOFUNC pInfoFunc;		// IN: debug information handler, (*pInfoFunc)(pInfoFuncCtxt,format,...) fprintf style
	LPVOID pInfoFuncCtxt;		// IN: debug information context, (*pInfoFunc)(pInfoFuncCtxt,format,...) fprintf style
};

struct DMCP_DisplayState
{
	DWORD dwSize;				// IN: Size of this structure
	DWORD dwCPFlag;				// IN, OUT: Set, perform those operations; Get: detected fields for ACP, CGMS, HDCP
	DWORD dwErrorCPFlag;		// OUT: Error CP flag; Set gives result; Get returns last set result
	DWORD dwReserved;
	DWORD dwACP;				// IN,OUT: Set ACP/APS state; Get returns the minimum ACP founda for AnalogTVMonitors
	DWORD dwCGMSA;				// IN,OUT: Set CGMSA state; Get returns the minimum CGMSA found for AnalogTVMonitors
	DWORD dwHDCP;				// IN,OUT: Set HDCP state; Get returns the minimum HDCP found for DigitalDVIMonitors
};

struct DMCP_SessionState
{
	DWORD dwSize;
	DWORD dwReserved0;
	DWORD dwReserved1;
	DWORD dwReserved2;
	DWORD dwReserved3;
};

enum
{	// this is the line20 CGMSA data, essentially the 2 bit field + 1, only valid on NTSC TVs (in general)
    DMCP_CGMSA_Disabled = 0,	
    DMCP_CGMSA_CopyFreely = 1,
    DMCP_CGMSA_CopyNoMore = 2,
    DMCP_CGMSA_CopyOneGeneration   = 3,
    DMCP_CGMSA_CopyNever = 4,
};

enum
{	// this is the macrovision analog copy protection, only valid on TVs
    DMCP_ACP_Level0 = 0,	 // disabled
    DMCP_ACP_Level1 = 1,
    DMCP_ACP_Level2 = 2,
    DMCP_ACP_Level3 = 3,
};

enum
{	// this is HDCP, only valid on DVI/HDMI style connectors
    DMCP_HDCP_Level0 = 0,	// disabled
    DMCP_HDCP_Level1 = 1,
};

enum
{	// COPP connector + 1
	DMCP_CONNECTORTYPE_UNKNOWN = 0,
    DMCP_CONNECTORTYPE_VGA = 1,
    DMCP_CONNECTORTYPE_SVideo = 2,
    DMCP_CONNECTORTYPE_CompositeVideo = 3,
    DMCP_CONNECTORTYPE_ComponentVideo = 4,
    DMCP_CONNECTORTYPE_DVI = 5,
    DMCP_CONNECTORTYPE_HDMI = 6,
    DMCP_CONNECTORTYPE_LVDS = 7,
    DMCP_CONNECTORTYPE_TMDS = 8,
    DMCP_CONNECTORTYPE_D_JPN = 9,
    DMCP_CONNECTORTYPE_SDI = 10,
    DMCP_CONNECTORTYPE_DisplayPortExternal = 11,
    DMCP_CONNECTORTYPE_DisplayPortEmbedded = 12,
    DMCP_CONNECTORTYPE_UDIExternal = 13,
    DMCP_CONNECTORTYPE_UDIEmbedded = 14,
};

enum
{
	DMCP_CONNECTORFLAG_TVNOTDETECTED = (1<<0),
	DMCP_CONNECTORFLAG_TVDETECTED = (1<<1),
	DMCP_CONNECTORFLAG_INTERNAL = (1<<2),
	DMCP_CONNECTORFLAG_EXTERNAL = (1<<3),
	DMCP_CONNECTORFLAG_PRIMARY = (1<<4),
	DMCP_CONNECTORFLAG_SECONDARY = (1<<5),
};

struct DMCP_MonitorInfo
{
	DWORD dwSize;				// IN: size of this structure
	DWORD dwConnectorType;		// OUT: ConnectorType
	DWORD dwConnectorFlag;		// OUT: Connector flags
	RECT rDisplay;				// OUT: Display rectangle size (in virtual coordinates)
	TCHAR szName[64];			// OUT: Name of device
};

DECLARE_INTERFACE(IDmcpDisplay)
{
	STDMETHOD(Open)(IN DMCP_DisplayOpenParams *pOpenParams, IN DWORD dwOpenSize) PURE;
	STDMETHOD(Close)() PURE;
	STDMETHOD(GetDisplayState)(IN OUT DMCP_DisplayState *pState) PURE;					// Gets device state, returns S_FALSE if there is a pending Restore
	STDMETHOD(SetDisplayState)(IN OUT DMCP_DisplayState *pState) PURE;					// Sets device state - use this to set copy protection modes
	STDMETHOD(GetNumberMonitors)(OUT DWORD *pdwMonitors) PURE;						// returns S_FALSE if there is a pending Restore
	STDMETHOD(GetMonitorInfo)(IN DWORD dwIndex, OUT DMCP_MonitorInfo *pInfo) PURE; 	// returns S_FALSE if there is a pending Restore
	STDMETHOD(SetTargetRect)(IN RECT *prWindow) PURE;	// target rectangle for video
	STDMETHOD_(BOOL,CanDisplay)(BOOL bDefault) PURE;	// returns TRUE or FALSE if the video can be displayed.  
	STDMETHOD(Restore)() PURE;	 // CAUTION: Due to hang issues, this may occur on a different thread (see OpenFlags parameter)
	STDMETHOD(GetSessionState)(IN DWORD dwIndex, IN OUT DMCP_SessionState *pSession) PURE;
};

DECLARE_INTERFACE(IDmcpLibrary)
{	// DO NOT DIRECTLY USE THIS INTERFACE - IT IS ENCRYPTED (use FindDmcpDisplay() insted)
	STDMETHOD(GetChallenge)(OUT ULONGLONG *pullChallenge) PURE;	
	STDMETHOD(SetResponse)(IN ULONGLONG ullResponse, IN ULONGLONG ullEncrypt) PURE;
	STDMETHOD(FindInterface)(REFIID riid, LPVOID *ppv) PURE;
};

IDmcpDisplay *CreateDmcpDisplay();	// Static library linking

// Dynamic library linking
// Interfaces returned are ENCRYPTED, so please use the access funtions below.
#ifdef WINCE
#define DMCP_ENTRYPOINTNAME _T("DMCP_LibraryEntryPoint")
#else
#define DMCP_ENTRYPOINTNAME "DMCP_LibraryEntryPoint"
#endif

typedef HRESULT (STDMETHODCALLTYPE *DMCP_LIBRARYENTRYPOINT)(IN REFGUID guid, IN OUT LPVOID *ppParam);
extern "C" HRESULT STDMETHODCALLTYPE DMCP_LibraryEntryPoint(IN REFGUID guid, IN OUT LPVOID *ppParam);

#ifdef __linux__
#define DMCP_OneWay(x) x
#define DMCP_MakeRandom() 0
#else
#define DMCP_OneWay(x) ((x)*(ULONGLONG)123982112321^(ULONGLONG)0x123871232128ad11)
#define DMCP_MakeRandom() ((ULONGLONG)(GetTickCount()^rand())<<32 | rand())
#endif

inline IDmcpLibrary *FindDmcpLibrary()
{	// implementation note - the library handle is never freed until process is terminated. --achung
//	int i;
//	HMODULE hLib;
//	IDmcpLibrary *pLib;
	typedef HRESULT (STDAPICALLTYPE *DLLREGISTERSERVER)();
//	static const TCHAR *aszLoadPaths[] =
//	{
//		_T("DMCPDll.dll"),
//		_T("DMCPDll\\DMCPDll.dll"),
//		_T("..\\DMCPDll\\DMCPDll.dll"),
//#ifdef WINCE
//		_T("\\Program Files\\DMCPDll\\DMCPDll.dll"),
//		_T("\\NAND Flash\\DMCPDll\\DMCPDll.dll"),
//#endif
//		0,
//	};

#ifndef __linux__
#ifndef WINCE
	// check if registered by COM
//	hr = CoCreateInstance(CLSID_DmcpLibrary,0,CLSCTX_INPROC,IID_IDmcpLibrary,(LPVOID *)&pLib);
//	if(SUCCEEDED(hr))
//		return pLib;
#endif
#endif
	// if not, then load library
//	for(i=0;aszLoadPaths[i];i++)
//	{
//		if(((hLib = LoadLibrary(aszLoadPaths[i]))))
//		{
//			DLLREGISTERSERVER pDllRegisterServer;
//			DMCP_LIBRARYENTRYPOINT pLep;
//
//#ifdef WINCE
//			pDllRegisterServer = (DLLREGISTERSERVER)GetProcAddress(hLib,_T("DllRegisterServer"));
//#else
//			pDllRegisterServer = (DLLREGISTERSERVER)GetProcAddress(hLib,"DllRegisterServer");
//#endif
//			if(pDllRegisterServer)
//				(*pDllRegisterServer)();	// try to register me for next time.
//			pLep = (DMCP_LIBRARYENTRYPOINT) GetProcAddress(hLib,DMCP_ENTRYPOINTNAME);
//			if(pLep && SUCCEEDED((*pLep)(IID_IDmcpLibrary,(LPVOID *)&pLib)))
//				return pLib;
//			FreeLibrary(hLib);
//		}
//	}
	return 0;
}

inline IDmcpDisplay *FindDmcpDisplay()
{
	IDmcpLibrary *pLib;
	IDmcpDisplay *pDisp = 0;
	ULONGLONG ullC, ullR, ullE;

	pLib = FindDmcpLibrary();
	if(pLib==0)
		return 0;
	pLib->GetChallenge(&ullC);
	ullR = DMCP_OneWay(ullC);
	ullE = DMCP_MakeRandom();
	pLib->SetResponse(ullR,ullE);
	pLib->FindInterface(IID_IDmcpDisplay,(LPVOID *)&pDisp);
	if(pDisp)
		pDisp = (IDmcpDisplay *)((ULONGLONG)pDisp^DMCP_OneWay(ullE^ullC));
	return pDisp;
}

inline const TCHAR *DMCP_ConnectorTypeString(DWORD dwType)
{
	static const TCHAR *String[] =
	{
		_T("UNKNOWN"),
		_T("VGA"),
		_T("SVideo"),
		_T("CompositeVideo"),
		_T("ComponentVideo"),
		_T("DVI"),
		_T("HDMI"),
		_T("LVDS"),
		_T("TMDS"),
		_T("D_JPN"),
		_T("SDI"),
		_T("DisplayPortExternal"),
		_T("DisplayPortEmbedded"),
		_T("UDIExternal"),
		_T("UDIEmbedded"),
	};
	if(dwType>sizeof(String)/sizeof(String[0]))
		return String[0];
	return String[dwType];
}

inline const TCHAR *DMCP_ConnectorFlagString(DWORD dwFlag)
{
	static const TCHAR *String[] =
	{
		_T("TV Not detected"),
		_T("TV Detected"),
		_T("Internal Display"),
		_T("External Display"),
		_T("Primary Display"),
		_T("Secondary Display"),
	};
	unsigned i;
	for(i=0;i<sizeof(String)/sizeof(String[0]);i++)
	{
		if(dwFlag&(1<<i))
			return String[i];
	}
	return _T("Unknown flag");
}

inline const TCHAR *DMCP_CPFlagString(DWORD dwFlag)
{
	static const TCHAR *String[] =
	{
		_T("ACP (Analog Copy Protection - Macrovision)"),
		_T("CGMSA (Copy Generation Management System - Analog)"),
		_T("HDCP (High-bandwidth Digital Content Protection)"),
	};
	unsigned i;

	for(i=0;i<sizeof(String)/sizeof(String[0]);i++)
	{
		if(dwFlag&(1<<i))
			return String[i];
	}
	return _T("Unknown flag");
}

#endif // _DMCP_H_

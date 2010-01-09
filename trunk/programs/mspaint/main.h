/*
 *  Paint (main.h)
 *
 *  Copyright 2008 Katayama Hirofumi MZ <katayama.hirofumi.mz@gmail.com>
 *  Copyright 2010 Austin English
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA
 */

#define MAX_STRING_LEN      255

#define SIZEOF(a) sizeof(a)/sizeof((a)[0])

typedef enum
{
    MODE_NORMAL,
    MODE_RIGHT_EDGE,
    MODE_DOWN_EDGE,
    MODE_LOWER_RIGHT_EDGE,
    MODE_SELECTION,
    MODE_CANVAS
} MODE;

typedef enum
{
    TOOL_POLYSELECT,
    TOOL_BOXSELECT,
    TOOL_ERASER,
    TOOL_FILL,
    TOOL_SPOIT,
    TOOL_MAGNIFIER,
    TOOL_PENCIL,
    TOOL_BRUSH,
    TOOL_AIRBRUSH,
    TOOL_TEXT,
    TOOL_LINE,
    TOOL_CURVE,
    TOOL_BOX,
    TOOL_POLYGON,
    TOOL_ELLIPSE,
    TOOL_ROUNDRECT
} TOOL;

typedef struct
{
    HANDLE  hInstance;

    HWND    hMainWnd;
    HWND    hCanvasWnd;
    HWND    hToolBox;
    HWND    hColorBox;
    HWND    hStatusBar;
    HWND    hTextTool;

    SIZE    sizImage;
    SIZE    sizCanvas;
    HBITMAP hbmImage;
    HBITMAP hbmBuffer;
    HBITMAP hbmZoomBuffer;
    HBITMAP hbmCanvasBuffer;

    BOOL    fCanUndo;
    HBITMAP hbmImageUndo;
    SIZE    sizImageUndo;

    BOOL    fSelect;
    HBITMAP hbmSelect;

    BOOL    fModified;

    INT      cColors;
    COLORREF argbColors[28];
    INT     iForeColor;
    INT     iBackColor;
    COLORREF    rgbFore;
    COLORREF    rgbBack;

    WCHAR   szFileName[MAX_PATH];
    WCHAR   szFileTitle[MAX_PATH];
    WCHAR   szFilter[1024];

    TOOL    iToolSelect;
    TOOL    iToolClicking;
    TOOL    iToolPrev;

    HCURSOR hcurArrow;
    HCURSOR hcurBDiagonal;
    HCURSOR hcurFDiagonal;
    HCURSOR hcurHorizontal;
    HCURSOR hcurVertical;
    HCURSOR hcurPencil;
    HCURSOR hcurFill;
    HCURSOR hcurSpoit;
    HCURSOR hcurAirBrush;
    HCURSOR hcurZoom;
    HCURSOR hcurCross;
    HCURSOR hcurMove;
    HCURSOR hcurCross2;

    UINT    idTimer;
    COLORREF rgbSpoit;

    INT     nZoom;
    BOOL    fShowGrid;

    BOOL    fTransparent;
    INT     nAirBrushRadius;
    INT     nEraserSize;
    INT     nLineWidth;
    INT     iBrushType;
    INT     iFillStyle;

    INT     xScrollPos;
    INT     yScrollPos;

    MODE    mode;
    BOOL    fSwapColor;
    POINT   pt0;
    POINT   pt1;
    POINT   pt2;
    POINT   pt3;
    INT     ipt;
    COLORREF rgbPrev;

    INT     cPolyline;
    POINT  *pPolyline;
} PAINT_GLOBALS;

extern PAINT_GLOBALS Globals;

/* main.c */
VOID SetFileName(LPCWSTR szFileName);
VOID NotSupportedYet(VOID);

/* canvas.c */
LRESULT CALLBACK CanvasWndProc(HWND hWnd, UINT uMsg,
                               WPARAM wParam, LPARAM lParam);
VOID Canvas_Resize(HWND hWnd, SIZE sizNew);
VOID Canvas_Stretch(HWND hWnd, SIZE sizNew);
VOID Canvas_HFlip(HWND hWnd);
VOID Canvas_VFlip(HWND hWnd);
VOID Canvas_Rotate90Degree(HWND hWnd);
VOID Canvas_Rotate180Degree(HWND hWnd);
VOID Canvas_Rotate270Degree(HWND hWnd);
HBITMAP Selection_CreateBitmap(VOID);
VOID Selection_TakeOff(VOID);
VOID Selection_Land(VOID);
VOID Selection_Stretch(HWND hWnd, SIZE sizNew);
VOID Selection_HFlip(HWND hWnd);
VOID Selection_VFlip(HWND hWnd);
VOID Selection_Rotate90Degree(HWND hWnd);
VOID Selection_Rotate180Degree(HWND hWnd);
VOID Selection_Rotate270Degree(HWND hWnd);

/* bitmap.c */
HBITMAP BM_Load(LPCWSTR pszFileName);
BOOL BM_Save(LPCWSTR pszFileName, HBITMAP hbm);
HBITMAP BM_Create(SIZE siz);
HBITMAP BM_CreateResized(HWND hWnd, SIZE sizNew, HBITMAP hbm, SIZE siz);
HBITMAP BM_CreateStretched(HWND hWnd, SIZE sizNew, HBITMAP hbm, SIZE siz);
HBITMAP BM_CreateHFliped(HWND hWnd, HBITMAP hbm, SIZE siz);
HBITMAP BM_CreateVFliped(HWND hWnd, HBITMAP hbm, SIZE siz);
HBITMAP BM_CreateRotated90Degree(HWND hWnd, HBITMAP hbm, SIZE siz);
HBITMAP BM_CreateRotated180Degree(HWND hWnd, HBITMAP hbm, SIZE siz);
HBITMAP BM_CreateRotated270Degree(HWND hWnd, HBITMAP hbm, SIZE siz);
HBITMAP BM_Copy(HBITMAP hbm);
HGLOBAL BM_Pack(HBITMAP hbm);
HBITMAP BM_Unpack(HGLOBAL hPack);

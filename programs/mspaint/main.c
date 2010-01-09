/*
 *  Paint (main.c)
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

#include <windows.h>
#include <commctrl.h>

#include "main.h"
#include "paint.h"
#include "resource.h"

PAINT_GLOBALS Globals;

COLORREF argbDefaultColor[] =
{
    RGB(0, 0, 0), RGB(255, 255, 255),
    RGB(128, 128, 128), RGB(192, 192, 192),
    RGB(128, 0, 0), RGB(255, 0, 0),
    RGB(128, 128, 0), RGB(255, 255, 0),
    RGB(0, 128, 0), RGB(0, 255, 0),
    RGB(0, 128, 128), RGB(0, 255, 255),
    RGB(0, 0, 128), RGB(0, 0, 255),
    RGB(128, 0, 128), RGB(255, 0, 255),
    RGB(128, 128, 64), RGB(255, 255, 128),
    RGB(0, 64, 64), RGB(0, 255, 128),
    RGB(0, 128, 255), RGB(128, 255, 255),
    RGB(0, 64, 128), RGB(128, 128, 255),
    RGB(64, 0, 128), RGB(255, 0, 128),
    RGB(128, 64, 0), RGB(255, 128, 64),
};

COLORREF argbDefaultMono[] =
{
    RGB(0, 0, 0),       RGB(255, 255, 255),
    RGB(9, 9, 9),       RGB(128, 128, 128),
    RGB(18, 18, 18),    RGB(137, 137, 137),
    RGB(27, 27, 27),    RGB(146, 146, 146),
    RGB(37, 37, 37),    RGB(155, 155, 155),
    RGB(46, 46, 46),    RGB(164, 164, 164),
    RGB(55, 55, 55),    RGB(173, 173, 173),
    RGB(63, 63, 63),    RGB(182, 182, 182),
    RGB(73, 73, 73),    RGB(191, 191, 191),
    RGB(82, 82, 82),    RGB(201, 201, 201),
    RGB(92, 92, 92),    RGB(212, 212, 212),
    RGB(101, 101, 101), RGB(222, 222, 222),
    RGB(110, 110, 110), RGB(231, 231, 231),
    RGB(119, 119, 119), RGB(245, 245, 245)
};

COLORREF gargbColorTableMono[] =
{
    RGB(0, 0, 0),
    RGB(255, 255, 255)
};

static const WCHAR paint_reg_key[] = {
    'S','o','f','t','w','a','r','e','\\',
    'M','i','c','r','o','s','o','f','t','\\','W','i','n','d','o','w','s','\\',
    'C','u','r','r','e','n','t','V','e','r','s','i','o','n','\\',
    'A','p','p','l','e','t','s','\\','P','a','i','n','t',0};
static const WCHAR setting[] = {'S','e','t','t','i','n','g','s',0};
static const WCHAR recent_file_list[] = {'R','e','c','e','n','t',' ',
                                        'F','i','l','e',' ','L','i','s','t',0
                                        };
static const WCHAR text[] = {'T','e','x','t',0};

static const WCHAR canvasClassName[] = {'c','a','n','v','a','s',0};
static const WCHAR colorBoxClassName[] =
    {'c','o','l','o','r',' ','b','o','x',0};
static const WCHAR toolBoxClassName[] =
    {'t','o','o','l',' ','b','o','x',0};

VOID SetFileName(LPCWSTR szFileName)
{
    lstrcpyW(Globals.szFileName, szFileName);
    Globals.szFileTitle[0] = 0;
    GetFileTitleW(szFileName, Globals.szFileTitle, SIZEOF(Globals.szFileTitle));
}

VOID NotSupportedYet(VOID)
{
    static const WCHAR not_supported[] = {'N','o','t',' ','s','u','p','p','o',
                                          'r','t','e','d',' ','y','e','t',0};
    MessageBoxW(Globals.hMainWnd, not_supported, NULL, MB_ICONERROR | MB_OK);
}

static VOID PAINT_SaveSettingToRegistry(void)
{
    HKEY hkey, hkey2;
    DWORD disp;
    static const WCHAR recent[] = {'R','e','c','e','n','t',' ',
                                   'F','i','l','e',' ','L','i','s','t',0
                                  };
    static const WCHAR text[] = {'T','e','x','t',0};
    static const WCHAR view[] = {'V','i','e','w',0};
    static const WCHAR placement[] = {'W','i','n','d','o','w',
                                      'P','l','a','c','e','m','e','n','t',0
                                     };
    static const WCHAR BMPHeight[] = {'B','M','P','H','e','i','g','h','t',0};
    static const WCHAR BMPWidth[] = {'B','M','P','W','i','d','t','h',0};

    if (RegCreateKeyExW(HKEY_CURRENT_USER, paint_reg_key, 0, NULL,
                       REG_OPTION_NON_VOLATILE, KEY_ALL_ACCESS, NULL, &hkey, &disp) ==
            ERROR_SUCCESS)
    {
        if (RegCreateKeyExW(hkey, recent, 0, NULL, REG_OPTION_NON_VOLATILE,
                           KEY_ALL_ACCESS, NULL, &hkey2, &disp) == ERROR_SUCCESS)
        {
            /*FIXME: Load recent file list */
            RegCloseKey(hkey2);
        }

        if (RegCreateKeyExW(hkey, text, 0, NULL, REG_OPTION_NON_VOLATILE,
                           KEY_ALL_ACCESS, NULL, &hkey2, &disp) == ERROR_SUCCESS)
        {
            /*FIXME: Load text settings */
            RegCloseKey(hkey2);
        }

        if (RegCreateKeyExW(hkey, view, 0, NULL, REG_OPTION_NON_VOLATILE,
                           KEY_ALL_ACCESS, NULL, &hkey2, &disp) == ERROR_SUCCESS)
        {
            DWORD data;
            WINDOWPLACEMENT wndpl;
            GetWindowPlacement(Globals.hMainWnd, &wndpl);
            RegSetValueExW(hkey2, placement, 0, REG_BINARY, (BYTE*)&wndpl,
                          sizeof(WINDOWPLACEMENT));
            /* FIXME: How do we save width and height? */
            if (Globals.szFileName[0] == '\0')
            {
                data = (DWORD)Globals.sizImage.cx;
                RegSetValueExW(hkey2, BMPWidth, 0, REG_DWORD, (BYTE*)&data, sizeof(DWORD));
                data = (DWORD)Globals.sizImage.cy;
                RegSetValueExW(hkey2, BMPHeight, 0, REG_DWORD, (BYTE*)&data, sizeof(DWORD));
            }
            RegCloseKey(hkey2);
        }
        RegCloseKey(hkey);
    }
}

static VOID PAINT_LoadSettingFromRegistry(void)
{
    HKEY hkey, hkey2;
    DWORD size;
    static const WCHAR view[] = {'V','i','e','w',0};
    static const WCHAR placement[] = {'W','i','n','d','o','w',
                                      'P','l','a','c','e','m','e','n','t',0
                                     };
    static const WCHAR BMPHeight[] = {'B','M','P','H','e','i','g','h','t',0};
    static const WCHAR BMPWidth[] = {'B','M','P','W','i','d','t','h',0};
    if (RegOpenKeyW(HKEY_CURRENT_USER, paint_reg_key, &hkey) == ERROR_SUCCESS)
    {
        if (RegOpenKeyW(hkey, view, &hkey2) == ERROR_SUCCESS)
        {
            DWORD value;
            WINDOWPLACEMENT wndpl;
            size = sizeof(WINDOWPLACEMENT);
            if (RegQueryValueExW(hkey2, placement, 0, NULL, (BYTE*)&wndpl,
                                &size) == ERROR_SUCCESS)
            {
                SetWindowPlacement(Globals.hMainWnd, &wndpl);
            }
            if (RegQueryValueExW(hkey2, BMPWidth, 0, NULL, (BYTE*)&value,
                                &size) == ERROR_SUCCESS)
            {
                Globals.sizImage.cx = (INT)value;
            }
            if (RegQueryValueExW(hkey2, BMPHeight, 0, NULL, (BYTE*)&value,
                                &size) == ERROR_SUCCESS)
            {
                Globals.sizImage.cy = (INT)value;
            }
        }
    }
}

static int PAINT_OnCommand(WPARAM wParam)
{
    switch (wParam)
    {
    case CMD_NEW:                   PAINT_FileNew(); break;
    case CMD_OPEN:                  PAINT_FileOpen(); break;
    case CMD_SAVE:                  PAINT_FileSave(); break;
    case CMD_SAVE_AS:               PAINT_FileSaveAs(); break;
    case CMD_PRINT_PREVIEW:         PAINT_FilePrintPreview(); break;
    case CMD_PRINT:                 PAINT_FilePrint(); break;
    case CMD_PAGE_SETUP:            PAINT_FilePageSetup(); break;
    case CMD_WALLPAPAER_TILED:      PAINT_SetAsWallpaperTiled(); break;
    case CMD_WALLPAPAER_CENTERED:   PAINT_SetAsWallpaperCentered(); break;
    case CMD_EXIT:                  PAINT_FileExit(); break;

    case CMD_UNDO:                  PAINT_EditUndo(); break;
    case CMD_REPEAT:                PAINT_EditRepeat(); break;
    case CMD_CUT:                   PAINT_EditCut(); break;
    case CMD_COPY:                  PAINT_EditCopy(); break;
    case CMD_PASTE:                 PAINT_EditPaste(); break;
    case CMD_DELETE:                PAINT_EditDelete(); break;
    case CMD_SELECT_ALL:            PAINT_EditSelectAll(); break;
    case CMD_COPY_TO:               PAINT_CopyTo(); break;
    case CMD_PASTE_FROM:            PAINT_PasteFrom(); break;

    case CMD_TOOL_BOX:              PAINT_ToolBox(); break;
    case CMD_COLOR_BOX:             PAINT_ColorBox(); break;
    case CMD_STATUS_BAR:            PAINT_StatusBar(); break;
    case CMD_ZOOM_NORMAL:           PAINT_Zoom(1); break;
    case CMD_ZOOM_LARGE:            PAINT_Zoom(4); break;
    case CMD_SHOW_GRID:             PAINT_ShowGrid(); break;
    case CMD_ZOOM_CUSTOM:           PAINT_ZoomCustom(); break;

    case CMD_FLIP_ROTATE:           PAINT_FlipRotate(); break;
    case CMD_STRETCH_SKEW:          PAINT_StretchSkew(); break;
    case CMD_INVERT_COLORS:         PAINT_InvertColors(); break;
    case CMD_ATTRIBUTES:            PAINT_Attributes(); break;
    case CMD_CLEAR_IMAGE:           PAINT_ClearImage(); break;
    case CMD_DRAW_OPAQUE:           break;
    case CMD_CLEAR_SELECTION:       PAINT_ClearSelection(); break;

    case CMD_EDIT_COLOR:            PAINT_EditColor(FALSE); break;

    case CMD_HELP_CONTENTS:         PAINT_HelpContents(); break;
    case CMD_HELP_ON_HELP:          PAINT_HelpHelp(); break;
    case CMD_HELP_ABOUT_PAINT:      PAINT_HelpAboutPaint(); break;
    }
    return 0;
}

static VOID PAINT_InitData(VOID)
{
    WCHAR sz[256];
    LPWSTR p = Globals.szFilter;
    static const WCHAR bmp_files[] = { '*','.','b','m','p',0 };
    static const WCHAR all_files[] = { '*','.','*',0 };

    LoadStringW(Globals.hInstance, STRING_BMP_FILES_BMP, p, MAX_STRING_LEN);
    p += lstrlenW(p) + 1;
    lstrcpyW(p, bmp_files);
    p += lstrlenW(p) + 1;
    LoadStringW(Globals.hInstance, STRING_ALL_FILES, p, MAX_STRING_LEN);
    p += lstrlenW(p) + 1;
    lstrcpyW(p, all_files);
    p += lstrlenW(p) + 1;
    *p = '\0';

    Globals.cColors = 28;
    CopyMemory(Globals.argbColors, argbDefaultColor, sizeof(Globals.argbColors));

    Globals.iForeColor = 0;
    Globals.iBackColor = 1;
    Globals.rgbFore = RGB(0, 0, 0);
    Globals.rgbBack = RGB(255, 255, 255);
    Globals.iToolSelect = TOOL_PENCIL;
    Globals.iToolClicking = -1;

    Globals.hbmImage = NULL;
    Globals.hbmBuffer = NULL;
    Globals.hbmZoomBuffer = NULL;
    Globals.hbmCanvasBuffer = NULL;

    Globals.hbmSelect = NULL;
    Globals.fSelect = FALSE;
    Globals.fModified = FALSE;
    Globals.sizImage.cx = 100;
    Globals.sizImage.cy = 100;
    Globals.sizCanvas.cx = 0;
    Globals.sizCanvas.cy = 0;

    Globals.hcurArrow = LoadCursorW(NULL, (LPCWSTR)IDC_ARROW);
    Globals.hcurHorizontal = LoadCursorW(Globals.hInstance, (LPCWSTR)(1));
    Globals.hcurVertical = LoadCursorW(Globals.hInstance, (LPCWSTR)(2));
    Globals.hcurBDiagonal = LoadCursorW(Globals.hInstance, (LPCWSTR)(3));
    Globals.hcurFDiagonal = LoadCursorW(Globals.hInstance, (LPCWSTR)(4));
    Globals.hcurPencil = LoadCursorW(Globals.hInstance, (LPCWSTR)(5));
    Globals.hcurFill = LoadCursorW(Globals.hInstance, (LPCWSTR)(6));
    Globals.hcurSpoit = LoadCursorW(Globals.hInstance, (LPCWSTR)(7));
    Globals.hcurAirBrush = LoadCursorW(Globals.hInstance, (LPCWSTR)(8));
    Globals.hcurZoom = LoadCursorW(Globals.hInstance, (LPCWSTR)(9));
    Globals.hcurCross = LoadCursorW(Globals.hInstance, (LPCWSTR)(10));
    Globals.hcurMove = LoadCursorW(Globals.hInstance, (LPCWSTR)(11));
    Globals.hcurCross2 = LoadCursorW(Globals.hInstance, (LPCWSTR)(12));

    Globals.fTransparent = FALSE;
    Globals.nAirBrushRadius = 6;
    Globals.nEraserSize = 8;
    Globals.nLineWidth = 1;
    Globals.iBrushType = 1;
    Globals.iFillStyle = 0;

    Globals.nZoom = 1;
    Globals.fShowGrid = FALSE;
    Globals.xScrollPos = Globals.yScrollPos = 0;

    LoadStringW(Globals.hInstance, STRING_READY, sz, 256);
    SendMessageW(Globals.hStatusBar, SB_SETTEXTW, 0 | 0, (LPARAM)sz);

}

static VOID PAINT_OnInitMenuPopup(HMENU hMenu, int index)
{
    CheckMenuItem(hMenu, CMD_TOOL_BOX,
                  IsWindowVisible(Globals.hToolBox) ? MF_CHECKED : MF_UNCHECKED);
    CheckMenuItem(hMenu, CMD_COLOR_BOX,
                  IsWindowVisible(Globals.hColorBox) ? MF_CHECKED : MF_UNCHECKED);
    CheckMenuItem(hMenu, CMD_STATUS_BAR,
                  IsWindowVisible(Globals.hStatusBar) ? MF_CHECKED : MF_UNCHECKED);
    CheckMenuItem(hMenu, CMD_SHOW_GRID,
                  Globals.fShowGrid ? MF_CHECKED : MF_UNCHECKED);
    EnableMenuItem(hMenu, CMD_SHOW_GRID,
                   Globals.nZoom >= 3 ? MF_ENABLED : MF_GRAYED);
    EnableMenuItem(hMenu, CMD_ZOOM_NORMAL,
                   Globals.nZoom != 1 ? MF_ENABLED : MF_GRAYED);
    EnableMenuItem(hMenu, CMD_ZOOM_LARGE,
                   Globals.nZoom != 4 ? MF_ENABLED : MF_GRAYED);
    EnableMenuItem(hMenu, CMD_CLEAR_IMAGE,
                   Globals.fSelect ? MF_GRAYED : MF_ENABLED);
    EnableMenuItem(hMenu, CMD_UNDO,
                   Globals.fCanUndo ? MF_ENABLED : MF_GRAYED);
    EnableMenuItem(hMenu, CMD_REPEAT,
                   !Globals.fCanUndo && Globals.hbmImageUndo ?
                   MF_ENABLED : MF_GRAYED);
    EnableMenuItem(hMenu, CMD_CUT,
                   Globals.fSelect ? MF_ENABLED : MF_GRAYED);
    EnableMenuItem(hMenu, CMD_COPY,
                   Globals.fSelect ? MF_ENABLED : MF_GRAYED);
    EnableMenuItem(hMenu, CMD_PASTE,
                   IsClipboardFormatAvailable(CF_DIB) ? MF_ENABLED : MF_GRAYED);
    EnableMenuItem(hMenu, CMD_DELETE,
                   Globals.fSelect ? MF_ENABLED : MF_GRAYED);
    EnableMenuItem(hMenu, CMD_COPY_TO,
                   Globals.fSelect ? MF_ENABLED : MF_GRAYED);
}

VOID ColorBox_OnPaint(HWND hWnd, HDC hDC)
{
    INT i;
    HBRUSH hbr;
    RECT rc;

    rc.left = 10;
    rc.top = 10;
    rc.right = rc.left + 34;
    rc.bottom = rc.top + 34;
    DrawEdge(hDC, &rc, EDGE_SUNKEN, BF_ADJUST|BF_RECT);
    FillRect(hDC, &rc, (HBRUSH)GetStockObject(WHITE_BRUSH));

    rc.left = 23;
    rc.top = 23;
    rc.right = rc.left + 16;
    rc.bottom = rc.top + 16;
    DrawEdge(hDC, &rc, EDGE_RAISED, BF_ADJUST|BF_RECT);
    hbr = CreateSolidBrush(Globals.rgbBack);
    FillRect(hDC, &rc, hbr);
    DeleteObject(hbr);

    rc.left = 15;
    rc.top = 15;
    rc.right = rc.left + 16;
    rc.bottom = rc.top + 16;
    DrawEdge(hDC, &rc, EDGE_RAISED, BF_ADJUST|BF_RECT);
    hbr = CreateSolidBrush(Globals.rgbFore);
    FillRect(hDC, &rc, hbr);
    DeleteObject(hbr);

    for (i = 0; i < SIZEOF(argbDefaultColor); i++)
    {
        rc.left = 60 + i / 2 * 17;
        rc.top = 10 + (i % 2) * 17;
        rc.right = rc.left + 16;
        rc.bottom = rc.top + 16;
        DrawEdge(hDC, &rc, EDGE_SUNKEN, BF_ADJUST|BF_RECT);
        hbr = CreateSolidBrush(Globals.argbColors[i]);
        FillRect(hDC, &rc, hbr);
        DeleteObject(hbr);
    }
}

VOID ColorBox_OnButtonDown(HWND hWnd, INT x, INT y, BOOL fRight)
{
    INT i;
    POINT pt;
    RECT rc;

    pt.x = x;
    pt.y = y;

    for (i = 0; i < SIZEOF(argbDefaultColor); i++)
    {
        rc.left = 60 + i / 2 * 17;
        rc.top = 10 + (i % 2) * 17;
        rc.right = rc.left + 16;
        rc.bottom = rc.top + 16;

        if (PtInRect(&rc, pt))
        {
            if (fRight)
            {
                Globals.rgbBack = Globals.argbColors[i];
                Globals.iBackColor = i;
            }
            else
            {
                Globals.rgbFore = Globals.argbColors[i];
                Globals.iForeColor = i;
            }
            InvalidateRect(hWnd, NULL, TRUE);
            UpdateWindow(hWnd);
            break;
        }
    }
}

VOID ColorBox_OnButtonDblClk(HWND hWnd, INT x, INT y, BOOL fRight)
{
    INT i;
    POINT pt;
    RECT rc;

    pt.x = x;
    pt.y = y;

    for (i = 0; i < SIZEOF(argbDefaultColor); i++)
    {
        rc.left = 60 + i / 2 * 17;
        rc.top = 10 + (i % 2) * 17;
        rc.right = rc.left + 16;
        rc.bottom = rc.top + 16;

        if (PtInRect(&rc, pt))
        {
            PAINT_EditColor(fRight);
            InvalidateRect(hWnd, NULL, TRUE);
            UpdateWindow(hWnd);
            return;
        }
    }
}

LRESULT CALLBACK ColorBoxWndProc(HWND hWnd, UINT uMsg,
                                 WPARAM wParam, LPARAM lParam)
{
    switch (uMsg)
    {
    case WM_LBUTTONDOWN:
        ColorBox_OnButtonDown(hWnd, (INT)(SHORT)LOWORD(lParam),
                              (INT)(SHORT)HIWORD(lParam), FALSE);
        break;

    case WM_RBUTTONDOWN:
        ColorBox_OnButtonDown(hWnd, (INT)(SHORT)LOWORD(lParam),
                              (INT)(SHORT)HIWORD(lParam), TRUE);
        break;

    case WM_LBUTTONDBLCLK:
        ColorBox_OnButtonDblClk(hWnd, (INT)(SHORT)LOWORD(lParam),
                                (INT)(SHORT)HIWORD(lParam), FALSE);
        break;

    case WM_RBUTTONDBLCLK:
        ColorBox_OnButtonDblClk(hWnd, (INT)(SHORT)LOWORD(lParam),
                                (INT)(SHORT)HIWORD(lParam), TRUE);
        break;

    case WM_PAINT:
    {
        PAINTSTRUCT ps;
        HDC hDC = BeginPaint(hWnd, &ps);
        if (hDC != NULL)
        {
            ColorBox_OnPaint(hWnd, hDC);
            EndPaint(hWnd, &ps);
        }
        break;
    }

    default:
        return DefWindowProcW(hWnd, uMsg, wParam, lParam);
    }
    return 0;
}

VOID ToolBox_OnPaint(HWND hWnd, HDC hDC)
{
    HBITMAP hbm, hbmOld;
    INT i;
    RECT rc;
    POINT pt;
    HDC hdcMem;
    INT cMap;
    COLORMAP aMap[] =
    {
        {RGB(255, 0, 0), 0},
        {RGB(0, 0, 0), RGB(255, 255, 255)},
    };

    aMap[0].to = GetSysColor(COLOR_3DFACE);
    if (GetSysColor(COLOR_3DFACE) == RGB(0, 0, 0))
        cMap = 2;
    else
        cMap = 1;

    hdcMem = CreateCompatibleDC(hDC);
    if (hdcMem != NULL)
    {
        hbm = CreateMappedBitmap(Globals.hInstance, IDB_TOOLS, 0,
                                 aMap, cMap);
        hbmOld = SelectObject(hdcMem, hbm);

        for (i = 0; i < 16; i++)
        {
            rc.left = 3 + i % 2 * 25;
            rc.top  = 3 + i / 2 * 25;
            rc.right = rc.left + 25;
            rc.bottom = rc.top + 25;

            GetCursorPos(&pt);
            ScreenToClient(hWnd, &pt);
            if (Globals.iToolSelect == i || (Globals.iToolClicking == i && PtInRect(&rc, pt)))
            {
                DrawEdge(hDC, &rc, EDGE_SUNKEN, BF_RECT | BF_SOFT);
                BitBlt(hDC, rc.left + 5, rc.top + 5, 16, 16,
                       hdcMem, i * 16, 0, SRCCOPY);
            }
            else
            {
                DrawEdge(hDC, &rc, EDGE_RAISED, BF_RECT | BF_SOFT);
                BitBlt(hDC, rc.left + 4, rc.top + 4, 16, 16,
                       hdcMem, i * 16, 0, SRCCOPY);
            }
        }

        SelectObject(hdcMem, hbmOld);
        DeleteObject(hbm);

        rc.left = 5;
        rc.top = 210;
        rc.right = 49;
        rc.bottom = 290;
        DrawEdge(hDC, &rc, EDGE_SUNKEN, BF_RECT|BF_ADJUST);

        switch (Globals.iToolSelect)
        {
        case TOOL_ERASER:
            hbm = LoadBitmapW(Globals.hInstance, (LPCWSTR)IDB_ERASER);
            hbmOld = SelectObject(hdcMem, hbm);
            BitBlt(hDC, rc.left, rc.top, rc.right - rc.left, rc.bottom - rc.top,
                   hdcMem, 0, 0, SRCCOPY);
            SelectObject(hdcMem, hbmOld);
            DeleteObject(hbm);

            rc.left = 6;
            rc.right = 48;
            switch (Globals.nEraserSize)
            {
            case 4:
                rc.top = 210 + (290 - 210) * 0 / 4;
                rc.bottom = rc.top + (290 - 210) / 4;
                InvertRect(hDC, &rc);
                break;

            case 6:
                rc.top = 210 + (290 - 210) * 1 / 4;
                rc.bottom = rc.top + (290 - 210) / 4;
                InvertRect(hDC, &rc);
                break;

            case 8:
                rc.top = 210 + (290 - 210) * 2 / 4;
                rc.bottom = rc.top + (290 - 210) / 4;
                InvertRect(hDC, &rc);
                break;

            case 10:
                rc.top = 210 + (290 - 210) * 3 / 4;
                rc.bottom = rc.top + (290 - 210) / 4;
                InvertRect(hDC, &rc);
                break;
            }
            break;

        case TOOL_LINE:
        case TOOL_CURVE:
            hbm = LoadBitmapW(Globals.hInstance, (LPCWSTR)IDB_LINE);
            hbmOld = SelectObject(hdcMem, hbm);
            BitBlt(hDC, rc.left, rc.top, rc.right - rc.left, rc.bottom - rc.top,
                   hdcMem, 0, 0, SRCCOPY);
            SelectObject(hdcMem, hbmOld);
            DeleteObject(hbm);

            if (Globals.nLineWidth == 0)
                Globals.nLineWidth = 1;
            rc.left = 6;
            rc.top = 210 + (290 - 210) * (Globals.nLineWidth - 1) / 5;
            rc.right = 48;
            rc.bottom = rc.top + (290 - 210) / 5;
            InvertRect(hDC, &rc);
            break;

        case TOOL_MAGNIFIER:
            hbm = LoadBitmapW(Globals.hInstance, (LPCWSTR)IDB_ZOOM);
            hbmOld = SelectObject(hdcMem, hbm);
            BitBlt(hDC, rc.left, rc.top, rc.right - rc.left, rc.bottom - rc.top,
                   hdcMem, 0, 0, SRCCOPY);
            SelectObject(hdcMem, hbmOld);
            DeleteObject(hbm);

            rc.left = 6;
            rc.right = 48;
            switch (Globals.nZoom)
            {
            case 1:
                rc.top = 210 + (290 - 210) * 0 / 4;
                rc.bottom = rc.top + (290 - 210) / 4;
                InvertRect(hDC, &rc);
                break;

            case 2:
                rc.top = 210 + (290 - 210) * 1 / 4;
                rc.bottom = rc.top + (290 - 210) / 4;
                InvertRect(hDC, &rc);
                break;

            case 6:
                rc.top = 210 + (290 - 210) * 2 / 4;
                rc.bottom = rc.top + (290 - 210) / 4;
                InvertRect(hDC, &rc);
                break;

            case 8:
                rc.top = 210 + (290 - 210) * 3 / 4;
                rc.bottom = rc.top + (290 - 210) / 4;
                InvertRect(hDC, &rc);
                break;
            }
            break;

        case TOOL_SPOIT:
            if (Globals.rgbSpoit != CLR_INVALID)
            {
                HBRUSH hbr = CreateSolidBrush(Globals.rgbSpoit);
                FillRect(hDC, &rc, hbr);
                DeleteObject(hbr);
            }
            break;

        case TOOL_BRUSH:
            hbm = LoadBitmapW(Globals.hInstance, (LPCWSTR)IDB_BRUSH);
            hbmOld = SelectObject(hdcMem, hbm);
            BitBlt(hDC, rc.left, rc.top, rc.right - rc.left, rc.bottom - rc.top,
                   hdcMem, 0, 0, SRCCOPY);
            SelectObject(hdcMem, hbmOld);
            DeleteObject(hbm);

            rc.left = 6 + (48 - 6) * (Globals.iBrushType % 3) / 3;
            rc.right = rc.left + (48 - 6) / 3;
            rc.top = 210 + (290 - 210) * (Globals.iBrushType / 3) / 4;
            rc.bottom = rc.top + (290 - 210) / 4;
            InvertRect(hDC, &rc);
            break;

        case TOOL_BOX:
        case TOOL_POLYGON:
        case TOOL_ROUNDRECT:
        case TOOL_ELLIPSE:
            hbm = LoadBitmapW(Globals.hInstance, (LPCWSTR)IDB_FILL);
            hbmOld = SelectObject(hdcMem, hbm);
            BitBlt(hDC, rc.left, rc.top, rc.right - rc.left, rc.bottom - rc.top,
                   hdcMem, 0, 0, SRCCOPY);
            SelectObject(hdcMem, hbmOld);
            DeleteObject(hbm);

            rc.left = 6;
            rc.top = 210 + (290 - 210) * Globals.iFillStyle / 3;
            rc.right = 48;
            rc.bottom = rc.top + (290 - 210) / 3;
            InvertRect(hDC, &rc);
            break;

        case TOOL_BOXSELECT:
        case TOOL_POLYSELECT:
            hbm = LoadBitmapW(Globals.hInstance, (LPCWSTR)IDB_TRANS);
            hbmOld = SelectObject(hdcMem, hbm);
            BitBlt(hDC, rc.left, rc.top, rc.right - rc.left, rc.bottom - rc.top,
                   hdcMem, 0, 0, SRCCOPY);
            SelectObject(hdcMem, hbmOld);
            DeleteObject(hbm);

            rc.left = 6;
            rc.top = 210 + (290 - 210) * Globals.fTransparent / 2;
            rc.right = 48;
            rc.bottom = rc.top + (290 - 210) / 2;
            InvertRect(hDC, &rc);
            break;

        case TOOL_AIRBRUSH:
            hbm = LoadBitmapW(Globals.hInstance, (LPCWSTR)IDB_AIRBRUSH);
            hbmOld = SelectObject(hdcMem, hbm);
            BitBlt(hDC, rc.left, rc.top, rc.right - rc.left, rc.bottom - rc.top,
                   hdcMem, 0, 0, SRCCOPY);
            SelectObject(hdcMem, hbmOld);
            DeleteObject(hbm);

            switch (Globals.nAirBrushRadius)
            {
            case 6:
                rc.left = 5;
                rc.top = 210;
                rc.right = 27;
                rc.bottom = 250;
                break;

            case 10:
                rc.left = 28;
                rc.top = 210;
                rc.right = 49;
                rc.bottom = 250;
                break;

            case 14:
                rc.left = 5;
                rc.top = 251;
                rc.right = 49;
                rc.bottom = 290;
                break;
            }
            InvertRect(hDC, &rc);
            break;

        default:
            break;
        }
        DeleteDC(hdcMem);
    }
}

void ToolBox_OnLButton(HWND hWnd, int x, int y, BOOL fDown)
{
    RECT rc;
    POINT pt;
    INT i;

    pt.x = x;
    pt.y = y;
    for (i = 0; i < 16; i++)
    {
        rc.left = 3 + i % 2 * 25;
        rc.top  = 3 + i / 2 * 25;
        rc.right = rc.left + 25;
        rc.bottom = rc.top + 25;
        if (PtInRect(&rc, pt))
        {
            if (!fDown && Globals.iToolClicking == i)
            {
                Globals.iToolPrev = Globals.iToolSelect;
                Globals.iToolSelect = i;
                Globals.iToolClicking = -1;
                Globals.ipt = 0;
                if (Globals.pPolyline != NULL)
                    HeapFree(GetProcessHeap(), 0, Globals.pPolyline);
                Globals.pPolyline = NULL;
                Globals.cPolyline = 0;
                Selection_Land();
                SetRectEmpty((RECT*)&Globals.pt0);
                InvalidateRect(Globals.hCanvasWnd, NULL, TRUE);
                UpdateWindow(Globals.hCanvasWnd);

                switch (i)
                {
                case TOOL_SPOIT:
                    Globals.rgbSpoit = CLR_INVALID;
                    break;

                case TOOL_POLYSELECT:
                case TOOL_TEXT:
                    NotSupportedYet();
                    break;

                default:
                    break;
                }
            }
            else if (fDown)
            {
                Globals.iToolClicking = i;
                SetCapture(hWnd);
            }
            InvalidateRect(Globals.hToolBox, NULL, TRUE);
            UpdateWindow(Globals.hToolBox);
            return;
        }
    }

    switch (Globals.iToolSelect)
    {
    case TOOL_BRUSH:
        for (i = 0; i < 12; i++)
        {
            rc.left = 6 + (48 - 6) * (i % 3) / 3;
            rc.right = rc.left + (48 - 6) / 3;
            rc.top = 210 + (290 - 210) * (i / 3) / 4;
            rc.bottom = rc.top + (290 - 210) / 4;

            if (PtInRect(&rc, pt))
            {
                Globals.iBrushType = i;
                InvalidateRect(hWnd, NULL, TRUE);
                UpdateWindow(hWnd);
                break;
            }
        }
        Globals.pt0.x = Globals.pt0.y = 0xFFFFFFFF;
        break;

    case TOOL_BOX:
    case TOOL_ROUNDRECT:
    case TOOL_ELLIPSE:
    case TOOL_POLYGON:
        for (i = 0; i < 3; i++)
        {
            rc.left = 6;
            rc.top = 210 + (290 - 210) * i / 3;
            rc.right = 48;
            rc.bottom = rc.top + (290 - 210) / 3;

            if (PtInRect(&rc, pt))
            {
                Globals.iFillStyle = i;
                InvalidateRect(hWnd, NULL, TRUE);
                UpdateWindow(hWnd);
                break;
            }
        }
        break;

    case TOOL_ERASER:
        rc.left = 6;
        rc.right = 48;
        for (i = 0; i < 4; i++)
        {
            rc.top = 210 + (290 - 210) * i / 4;
            rc.bottom = rc.top + (290 - 210) / 4;
            if (PtInRect(&rc, pt))
            {
                Globals.nEraserSize = 4 + i * 2;
                InvalidateRect(hWnd, NULL, TRUE);
                UpdateWindow(hWnd);
                break;
            }
        }
        break;

    case TOOL_BOXSELECT:
    case TOOL_POLYSELECT:
        rc.left = 6;
        rc.top = 210 + (290 - 210) * 0 / 2;
        rc.right = 48;
        rc.bottom = rc.top + (290 - 210) / 2;
        if (PtInRect(&rc, pt))
        {
            Globals.fTransparent = FALSE;
            InvalidateRect(hWnd, NULL, TRUE);
            UpdateWindow(hWnd);
            break;
        }
        rc.left = 6;
        rc.top = 210 + (290 - 210) * 1 / 2;
        rc.right = 48;
        rc.bottom = rc.top + (290 - 210) / 2;
        if (PtInRect(&rc, pt))
        {
            Globals.fTransparent = TRUE;
            NotSupportedYet();
            InvalidateRect(hWnd, NULL, TRUE);
            UpdateWindow(hWnd);
            break;
        }
        break;

    case TOOL_MAGNIFIER:
        rc.left = 6;
        rc.right = 48;
        for (i = 0; i < 4; i++)
        {
            rc.top = 210 + (290 - 210) * i / 4;
            rc.bottom = rc.top + (290 - 210) / 4;
            if (PtInRect(&rc, pt))
            {
                switch (i)
                {
                case 0:
                    PAINT_Zoom(1);
                    break;
                case 1:
                    PAINT_Zoom(2);
                    break;
                case 2:
                    PAINT_Zoom(6);
                    break;
                case 3:
                    PAINT_Zoom(8);
                    break;
                }
                Globals.iToolSelect = Globals.iToolPrev;
                InvalidateRect(hWnd, NULL, TRUE);
                UpdateWindow(hWnd);
                break;
            }
        }
        break;

    case TOOL_LINE:
    case TOOL_CURVE:
        rc.left = 6;
        rc.right = 48;
        for (i = 0; i < 5; i++)
        {
            rc.top = 210 + (290 - 210) * i / 5;
            rc.bottom = rc.top + (290 - 210) / 5;
            if (PtInRect(&rc, pt))
            {
                Globals.nLineWidth = i + 1;
                InvalidateRect(hWnd, NULL, TRUE);
                UpdateWindow(hWnd);
                break;
            }
        }
        break;

    case TOOL_AIRBRUSH:
        rc.left = 5;
        rc.top = 210;
        rc.right = 27;
        rc.bottom = 250;
        if (PtInRect(&rc, pt))
        {
            Globals.nAirBrushRadius = 6;
            InvalidateRect(Globals.hToolBox, NULL, TRUE);
            UpdateWindow(Globals.hToolBox);
            return;
        }
        rc.left = 28;
        rc.top = 210;
        rc.right = 49;
        rc.bottom = 250;
        if (PtInRect(&rc, pt))
        {
            Globals.nAirBrushRadius = 10;
            InvalidateRect(Globals.hToolBox, NULL, TRUE);
            UpdateWindow(Globals.hToolBox);
            return;
        }
        rc.left = 5;
        rc.top = 251;
        rc.right = 49;
        rc.bottom = 290;
        if (PtInRect(&rc, pt))
        {
            Globals.nAirBrushRadius = 14;
            InvalidateRect(Globals.hToolBox, NULL, TRUE);
            UpdateWindow(Globals.hToolBox);
            return;
        }
        break;

    default:
        rc.left = 6;
        rc.top = 210;
        rc.right = 48;
        rc.bottom = 290;
        if (PtInRect(&rc, pt))
        {
            MessageBeep(0xFFFFFFFF);
        }
    }
}

void ToolBox_OnMouseMove(HWND hWnd, int x, int y, BOOL fDown)
{
    RECT rc;
    POINT pt;
    WCHAR sz[256];
    INT i;
    pt.x = x;
    pt.y = y;

    if (!fDown)
    {
        ReleaseCapture();
        Globals.iToolClicking = -1;
        InvalidateRect(Globals.hToolBox, NULL, FALSE);
        UpdateWindow(Globals.hToolBox);
    }
    else if (Globals.iToolClicking != -1)
    {
        rc.left = 3 + Globals.iToolClicking % 2 * 25;
        rc.top  = 3 + Globals.iToolClicking / 2 * 25;
        rc.right = rc.left + 25;
        rc.bottom = rc.top + 25;
        InvalidateRect(Globals.hToolBox, NULL, FALSE);
        UpdateWindow(Globals.hToolBox);
        return;
    }

    for (i = 0; i < 16; i++)
    {
        rc.left = 3 + i % 2 * 25;
        rc.top  = 3 + i / 2 * 25;
        rc.right = rc.left + 25;
        rc.bottom = rc.top + 25;
        if (PtInRect(&rc, pt))
        {
            LoadStringW(Globals.hInstance, i + STRING_POLYSELECT, sz, 256);
            SendMessageW(Globals.hStatusBar, SB_SETTEXTW, 0 | 0, (LPARAM)sz);
            return;
        }
    }

    LoadStringW(Globals.hInstance, STRING_READY, sz, 256);
    SendMessageW(Globals.hStatusBar, SB_SETTEXTW, 0 | 0, (LPARAM)sz);
}

static LRESULT CALLBACK ToolBoxWndProc(HWND hWnd, UINT uMsg,
                                       WPARAM wParam, LPARAM lParam)
{
    switch (uMsg)
    {
    case WM_LBUTTONDOWN:
        ToolBox_OnLButton(hWnd, LOWORD(lParam), HIWORD(lParam), TRUE);
        break;

    case WM_LBUTTONUP:
        ToolBox_OnLButton(hWnd, LOWORD(lParam), HIWORD(lParam), FALSE);
        break;

    case WM_MOUSEMOVE:
        ToolBox_OnMouseMove(hWnd, LOWORD(lParam), HIWORD(lParam), wParam & MK_LBUTTON);
        break;

    case WM_CAPTURECHANGED:
        Globals.iToolClicking = -1;
        InvalidateRect(Globals.hToolBox, NULL, TRUE);
        UpdateWindow(Globals.hToolBox);
        break;

    case WM_PAINT:
    {
        PAINTSTRUCT ps;
        HDC hDC = BeginPaint(hWnd, &ps);
        if (hDC != NULL)
        {
            ToolBox_OnPaint(hWnd, hDC);
            EndPaint(hWnd, &ps);
        }
        break;
    }

    default:
        return DefWindowProcW(hWnd, uMsg, wParam, lParam);
    }
    return 0;
}

VOID SetParts(HWND hWnd)
{
    INT aWidth[3];
    RECT rc;

    GetClientRect(hWnd, &rc);
    if (rc.right - rc.left < 450)
    {
        aWidth[0] = 250;
        aWidth[1] = 300;
        aWidth[2] = 350;
    }
    else
    {
        aWidth[0] = rc.right - rc.left - 250;
        aWidth[1] = rc.right - rc.left - 125;
        aWidth[2] = rc.right - rc.left - 20;
    }
    SendMessageW(Globals.hStatusBar, SB_SETPARTS, 3, (LPARAM)aWidth);
}

VOID PAINT_OnDestroy(HWND hWnd)
{
    if (Globals.hbmImage != NULL) DeleteObject(Globals.hbmImage);
    if (Globals.hbmBuffer != NULL) DeleteObject(Globals.hbmBuffer);
    if (Globals.hbmZoomBuffer != NULL) DeleteObject(Globals.hbmZoomBuffer);
    if (Globals.hbmCanvasBuffer != NULL) DeleteObject(Globals.hbmCanvasBuffer);
    if (Globals.hbmImageUndo != NULL) DeleteObject(Globals.hbmImageUndo);
    if (Globals.hbmSelect != NULL) DeleteObject(Globals.hbmSelect);
    DestroyCursor(Globals.hcurArrow);
    DestroyCursor(Globals.hcurBDiagonal);
    DestroyCursor(Globals.hcurFDiagonal);
    DestroyCursor(Globals.hcurHorizontal);
    DestroyCursor(Globals.hcurVertical);
    DestroyCursor(Globals.hcurPencil);
    DestroyCursor(Globals.hcurFill);
    DestroyCursor(Globals.hcurSpoit);
    DestroyCursor(Globals.hcurAirBrush);
    DestroyCursor(Globals.hcurZoom);
    DestroyCursor(Globals.hcurCross);
    DestroyCursor(Globals.hcurMove);
    DestroyCursor(Globals.hcurCross2);
    KillTimer(Globals.hCanvasWnd, Globals.idTimer);
    if (Globals.pPolyline != NULL)
        HeapFree(GetProcessHeap(), 0, Globals.pPolyline);
}

static LRESULT CALLBACK PaintWndProc(HWND hWnd, UINT uMsg, WPARAM wParam,
                                     LPARAM lParam)
{
    RECT rc;
    WCHAR sz[MAX_STRING_LEN];
    WCHAR wszTitle[] = {0};

    switch (uMsg)
    {
    case WM_CREATE:
        GetClientRect(hWnd, &rc);
        Globals.hCanvasWnd = CreateWindowExW(WS_EX_CLIENTEDGE, canvasClassName,
                                            wszTitle, WS_CHILD|WS_VISIBLE, 0, 0, 0, 0, hWnd,
                                            NULL, Globals.hInstance, NULL);
        if (Globals.hCanvasWnd == NULL)
            return -1;
        Globals.hColorBox = CreateWindowExW(WS_EX_WINDOWEDGE,
                                           colorBoxClassName, wszTitle, WS_CHILD|WS_VISIBLE,
                                           0, 0, 0, 0, hWnd, NULL, Globals.hInstance, NULL);
        if (Globals.hColorBox == NULL)
            return -1;
        Globals.hStatusBar = CreateStatusWindowW(WS_VISIBLE|WS_CHILD,
                                                wszTitle, hWnd, 3);
        if (Globals.hStatusBar == NULL)
            return -1;
        Globals.hToolBox = CreateWindowExW(WS_EX_WINDOWEDGE, toolBoxClassName,
                                          wszTitle, WS_CHILD|WS_VISIBLE, 0, 0, 0, 0, hWnd,
                                          NULL, Globals.hInstance, NULL);
        if (Globals.hToolBox == NULL)
            return -1;

        SetParts(hWnd);
        break;

    case WM_KEYDOWN:
        SendMessageW(Globals.hCanvasWnd, uMsg, wParam, lParam);
        break;

    case WM_COMMAND:
        PAINT_OnCommand(LOWORD(wParam));
        break;

    case WM_MENUSELECT:
        if ((HIWORD(wParam) & (MF_SYSMENU|MF_POPUP|MF_SEPARATOR)) == 0)
        {
            LoadStringW(Globals.hInstance, LOWORD(wParam) + 0x200, sz, MAX_STRING_LEN);
        }
        else if ((HIWORD(wParam) & (MF_SYSMENU|MF_POPUP|MF_SEPARATOR)) == MF_SYSMENU)
        {
            INT id;
            switch(LOWORD(wParam))
            {
            case SC_SIZE:       id = STRING_SIZE; break;
            case SC_MOVE:       id = STRING_MOVE; break;
            case SC_MINIMIZE:   id = STRING_MINIMIZE; break;
            case SC_MAXIMIZE:   id = STRING_MAXIMIZE; break;
            case SC_NEXTWINDOW: id = STRING_NEXTWINDOW; break;
            case SC_PREVWINDOW: id = STRING_PREVWINDOW; break;
            case SC_CLOSE:      id = STRING_CLOSE; break;
            case SC_RESTORE:    id = STRING_RESTORE; break;
            case SC_TASKLIST:   id = STRING_TASKLIST; break;
            default:            id = STRING_READY;
            }
            LoadStringW(Globals.hInstance, id, sz, MAX_STRING_LEN);
        }
        else
        {
            sz[0] = '\0';
        }
        SendMessageW(Globals.hStatusBar, SB_SETTEXTW, 0 | 0, (LPARAM)sz);
        break;

    case WM_EXITMENULOOP:
        LoadStringW(Globals.hInstance, STRING_READY, sz, 256);
        SendMessageW(Globals.hStatusBar, SB_SETTEXTW, 0 | 0, (LPARAM)sz);
        break;

    case WM_CLOSE:
        if (DoCloseFile())
        {
            DestroyWindow(hWnd);
        }
        break;

    case WM_GETMINMAXINFO:
    {
        MINMAXINFO *pmmi = (MINMAXINFO*)lParam;
        pmmi->ptMinTrackSize.x = 330;
        pmmi->ptMinTrackSize.y = 410;
        break;
    }

    case WM_SIZE:
    {
        RECT rc2;
        INT leftSave;
        HDWP hDwp;

        GetClientRect(hWnd, &rc);

        hDwp = BeginDeferWindowPos(1 +
            !!IsWindowVisible(Globals.hStatusBar) +
            !!IsWindowVisible(Globals.hColorBox) +
            !!IsWindowVisible(Globals.hToolBox));
        if (IsWindowVisible(Globals.hStatusBar))
        {
            PostMessageW(Globals.hStatusBar, WM_SIZE, 0, 0);
            GetWindowRect(Globals.hStatusBar, &rc2);
            DeferWindowPos(hDwp, Globals.hStatusBar, NULL,
                rc2.left, rc2.top,
                rc2.right - rc2.left, rc2.bottom - rc2.top,
                SWP_NOACTIVATE | SWP_NOREPOSITION | SWP_NOZORDER);
            rc.bottom -= (rc2.bottom - rc2.top);
        }
        if (IsWindowVisible(Globals.hColorBox))
        {
            rc.bottom -= 55;
        }
        leftSave = rc.left;
        if (IsWindowVisible(Globals.hToolBox))
        {
            LONG rightSave = rc.right;
            rc.right = rc.left + 60;
            DeferWindowPos(hDwp, Globals.hToolBox, NULL,
                         rc.left, rc.top,
                         rc.right - rc.left, rc.bottom - rc.top,
                         SWP_NOACTIVATE | SWP_NOREPOSITION | SWP_NOZORDER);
            rc.left = rc.right;
            rc.right = rightSave;
        }
        DeferWindowPos(hDwp, Globals.hCanvasWnd, NULL,
                     rc.left, rc.top, rc.right - rc.left, rc.bottom - rc.top,
                     SWP_NOACTIVATE | SWP_NOREPOSITION | SWP_NOZORDER);
        if (IsWindowVisible(Globals.hColorBox))
        {
            rc.left = leftSave;
            rc.top = rc.bottom;
            rc.bottom = rc.top + 55;
            DeferWindowPos(hDwp, Globals.hColorBox, NULL, rc.left, rc.top,
                         rc.right - rc.left, rc.bottom - rc.top,
                         SWP_NOACTIVATE | SWP_NOREPOSITION | SWP_NOZORDER);
        }
        EndDeferWindowPos(hDwp);
        SetParts(hWnd);
        PostMessageW(Globals.hCanvasWnd, WM_SIZE, 0, 0);
        break;
    }

    case WM_QUERYENDSESSION:
        if (DoCloseFile())
            return 1;
        break;

    case WM_DESTROY:
        PAINT_SaveSettingToRegistry();
        PAINT_OnDestroy(hWnd);
        PostQuitMessage(0);
        break;

    case WM_SETFOCUS:
        break;

    case WM_DROPFILES:
    {
        WCHAR szFileName[MAX_PATH];
        HDROP hDrop = (HDROP)wParam;

        DragQueryFileW(hDrop, 0, szFileName, SIZEOF(szFileName));
        DragFinish(hDrop);
        DoOpenFile(szFileName);
        break;
    }

    case WM_INITMENUPOPUP:
        PAINT_OnInitMenuPopup((HMENU)wParam, lParam);
        break;

    default:
        return DefWindowProcW(hWnd, uMsg, wParam, lParam);
    }
    return 0;
}

static int AlertFileDoesNotExist(LPCWSTR szFileName)
{
    int nResult;
    WCHAR szMessage[MAX_STRING_LEN];
    WCHAR szResource[MAX_STRING_LEN];

    LoadStringW(Globals.hInstance, STRING_DOESNOTEXIST, szResource,
               SIZEOF(szResource));
    wsprintfW(szMessage, szResource, szFileName);

    MessageBeep(MB_ICONEXCLAMATION);
    nResult = MessageBoxW(Globals.hMainWnd, szMessage, NULL,
                         MB_ICONEXCLAMATION | MB_YESNO);

    return nResult;
}

static void HandleCommandLine(LPWSTR cmdline)
{
    WCHAR delimiter;
    int opt_print = 0;

    /* skip white space */
    while (*cmdline == ' ') cmdline++;

    /* skip executable name */
    delimiter = (*cmdline == '"' ? '"' : ' ');

    if (*cmdline == delimiter) cmdline++;

    while (*cmdline && *cmdline != delimiter) cmdline++;

    if (*cmdline == delimiter) cmdline++;

    while (*cmdline == ' ' || *cmdline == '-' || *cmdline == '/')
    {
        WCHAR option;

        if (*cmdline++ == ' ') continue;

        option = *cmdline;
        if (option) cmdline++;
        while (*cmdline == ' ') cmdline++;

        switch (option)
        {
        case 'p':
        case 'P':
            opt_print=1;
            break;
        }
    }

    if (*cmdline)
    {
        LPCWSTR file_name;
        BOOL file_exists;
        WCHAR buf[MAX_PATH];

        if (cmdline[0] == '"')
        {
            WCHAR* wc;
            cmdline++;
            wc = cmdline;
            while (*wc && *wc != '"') wc++;
            *wc = 0;
        }

        if (FileExists(cmdline))
        {
            file_exists = TRUE;
            file_name = cmdline;
        }
        else
        {
            static const WCHAR bmpW[] = { '.','b','m','p',0 };

            /* try to find file with ".bmp" extension */
            if (!lstrcmpW(bmpW, cmdline + lstrlenW(cmdline) - lstrlenW(bmpW)))
            {
                file_exists = FALSE;
                file_name = cmdline;
            }
            else
            {
//                lstrcpyW(buf, cmdline, MAX_PATH - lstrlenW(bmpW) - 1);
                lstrcpyW(buf, cmdline);
                lstrcatW(buf, bmpW);
                file_name = buf;
                file_exists = FileExists(buf);
            }
        }

        if (file_exists)
        {
            DoOpenFile(file_name);
            InvalidateRect(Globals.hMainWnd, NULL, FALSE);
            if (opt_print)
                PAINT_FilePrint();
        }
        else
        {
            switch (AlertFileDoesNotExist(file_name))
            {
            case IDYES:
                DoOpenFile(file_name);
                break;

            case IDNO:
                break;
            }
        }
    }
}

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR pszCmdLine, int nCmdShow)
{
    MSG        msg;
    HACCEL      hAccel;
    WNDCLASSEXW wcx;

    static const WCHAR className[] = {'P','a','i','n','t',0};
    static const WCHAR winName[]   = {'P','a','i','n','t',0};

    ZeroMemory(&Globals, sizeof(Globals));
    Globals.hInstance       = hInstance;

    ZeroMemory(&wcx, sizeof(wcx));
    wcx.cbSize        = sizeof(wcx);
    wcx.lpfnWndProc   = PaintWndProc;
    wcx.hInstance     = Globals.hInstance;
    wcx.hIcon         = LoadIconW(Globals.hInstance, (LPCWSTR)IDI_PAINT);
    wcx.hCursor       = LoadCursorW(0, (LPCWSTR)IDC_ARROW);
    wcx.hbrBackground = (HBRUSH)(COLOR_3DDKSHADOW + 1);
    wcx.lpszMenuName  = (LPCWSTR)MAIN_MENU;
    wcx.lpszClassName = className;

    if (!RegisterClassExW(&wcx)) return FALSE;

    wcx.style         = CS_DBLCLKS;
    wcx.lpfnWndProc   = CanvasWndProc;
    wcx.hIcon         = NULL;
    wcx.hbrBackground = NULL;
    wcx.lpszMenuName  = NULL;
    wcx.lpszClassName = canvasClassName;

    if (!RegisterClassExW(&wcx)) return FALSE;

    wcx.lpfnWndProc   = ColorBoxWndProc;
    wcx.hbrBackground = (HBRUSH)(COLOR_3DFACE + 1);
    wcx.lpszClassName = colorBoxClassName;

    if (!RegisterClassExW(&wcx)) return FALSE;

    wcx.style         = 0;
    wcx.lpfnWndProc   = ToolBoxWndProc;
    wcx.lpszClassName = toolBoxClassName;

    if (!RegisterClassExW(&wcx)) return FALSE;

    /* Initialize the Windows Common Controls DLL */
    InitCommonControls();

    Globals.hMainWnd = CreateWindowW(className, winName,
                                    WS_OVERLAPPEDWINDOW|WS_CLIPCHILDREN,
                                    CW_USEDEFAULT, 0, CW_USEDEFAULT, 0, NULL, NULL,
                                    Globals.hInstance, NULL);
    if (Globals.hMainWnd == NULL)
    {
        ShowLastError();
        return 1;
    }

    PAINT_InitData();
    PAINT_LoadSettingFromRegistry();
    PAINT_FileNew();

    ShowWindow(Globals.hMainWnd, nCmdShow);
    UpdateWindow(Globals.hMainWnd);
    DragAcceptFiles(Globals.hMainWnd, TRUE);

    HandleCommandLine(GetCommandLineW());

    hAccel = LoadAcceleratorsW(hInstance, (LPCWSTR)ID_ACCEL);

    while (GetMessageW(&msg, 0, 0, 0))
    {
        if (!TranslateAcceleratorW(Globals.hMainWnd, hAccel, &msg))
        {
            TranslateMessage(&msg);
            DispatchMessageW(&msg);
        }
    }
    return msg.wParam;
}

/*
 *  Paint (paint.c)
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
#include <commdlg.h>
#include <shlwapi.h>
#include <dlgs.h>

#include "main.h"
#include "paint.h"
#include "resource.h"

static const WCHAR helpfileW[] =
    { 'p','a','i','n','t','.','h','l','p',0 };

static const WCHAR desktop_key[] =
    {'C','o','n','t','r','o','l',' ',
     'P','a','n','e','l','\\',
     'D','e','s','k','t','o','p',0
    };
static const WCHAR wallpaper_style[] =
    {'W','a','l','l','p','a','p','e','r',
     'S','t','y','l','e',0
    };
static const WCHAR tile_wallpaper[] =
    {'T','i','l','e',
     'W','a','l','l','p','a','p','e','r',0
    };

COLORREF aCustColors[16] =
{
    RGB(255, 255, 255),
    RGB(255, 255, 255),
    RGB(255, 255, 255),
    RGB(255, 255, 255),
    RGB(255, 255, 255),
    RGB(255, 255, 255),
    RGB(255, 255, 255),
    RGB(255, 255, 255),
    RGB(255, 255, 255),
    RGB(255, 255, 255),
    RGB(255, 255, 255),
    RGB(255, 255, 255),
    RGB(255, 255, 255),
    RGB(255, 255, 255),
    RGB(255, 255, 255),
    RGB(255, 255, 255)
};

VOID ShowLastError(void)
{
    WCHAR szMsg[MAX_STRING_LEN];
    LONG nError = GetLastError();
    if (nError != NO_ERROR)
    {
        if (nError > 0)
        {
            FormatMessageW(
                FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM,
                NULL, nError, 0, szMsg, MAX_STRING_LEN, NULL);
        }
        else
        {
            LoadStringW(Globals.hInstance, -nError, szMsg, MAX_STRING_LEN);
        }
        MessageBeep(MB_ICONERROR);
        MessageBoxW(NULL, szMsg, NULL, MB_OK | MB_ICONERROR);
    }
}

static void UpdateWindowCaption(void)
{
    WCHAR szCaption[MAX_STRING_LEN];
    WCHAR szPaint[MAX_STRING_LEN];
    static const WCHAR hyphenW[] = { ' ','-',' ',0 };

    if (Globals.szFileTitle[0] != '\0')
        lstrcpyW(szCaption, Globals.szFileTitle);
    else
        LoadStringW(Globals.hInstance, STRING_UNTITLED, szCaption,
                   MAX_STRING_LEN);

    LoadStringW(Globals.hInstance, STRING_PAINT, szPaint, MAX_STRING_LEN);
    lstrcatW(szCaption, hyphenW);
    lstrcatW(szCaption, szPaint);

    SetWindowTextW(Globals.hMainWnd, szCaption);
}

int PAINT_StringMsgBox(HWND hParent, int formatId, LPCWSTR szString,
                       UINT uFlags)
{
    WCHAR szMessage[MAX_STRING_LEN];
    WCHAR szResource[MAX_STRING_LEN];

    LoadStringW(Globals.hInstance, formatId, szResource, MAX_STRING_LEN);
    wnsprintfW(szMessage, MAX_STRING_LEN, szResource, szString);

    LoadStringW(Globals.hInstance, STRING_PAINT, szResource, MAX_STRING_LEN);

    if (hParent == NULL)
        hParent = Globals.hMainWnd;

    MessageBeep(uFlags & MB_ICONMASK);
    return MessageBoxW(hParent, szMessage, szResource, uFlags);
}

static void AlertFileNotFound(LPCWSTR szFileName)
{
    PAINT_StringMsgBox(NULL, STRING_NOTFOUND, szFileName,
                       MB_ICONEXCLAMATION | MB_OK);
}

static int AlertFileNotSaved(LPCWSTR szFileName)
{
    WCHAR szUntitled[MAX_STRING_LEN];

    LoadStringW(Globals.hInstance, STRING_UNTITLED, szUntitled, MAX_STRING_LEN);
    return PAINT_StringMsgBox(NULL, STRING_SAVECHANGE,
                              szFileName[0] ? szFileName : szUntitled,
                              MB_ICONWARNING | MB_YESNOCANCEL);
}

BOOL FileExists(LPCWSTR szFileName)
{
    WIN32_FIND_DATAW entry;
    HANDLE hFile;

    hFile = FindFirstFileW(szFileName, &entry);
    FindClose(hFile);

    return (hFile != INVALID_HANDLE_VALUE);
}

static VOID DoSaveFile(VOID)
{
    /* FIXME: Support different BPP */
    /* FIXME: Support GIF, JPEG, PNG files */
    if (BM_Save(Globals.szFileName, Globals.hbmImage))
        Globals.fModified = FALSE;
}

/**
 * Returns:
 *   TRUE  - User agreed to close (both save/don't save)
 *   FALSE - User cancelled close by selecting "Cancel"
 */
BOOL DoCloseFile(void)
{
    int nResult;
    static const WCHAR empty_strW[] = { 0 };

    if (Globals.fModified)
    {
        nResult = AlertFileNotSaved(Globals.szFileName);
        switch (nResult)
        {
        case IDYES:
            if (!PAINT_FileSave())
                return FALSE;
            break;

        case IDNO:
            break;

        case IDCANCEL:
            return FALSE;

        default:
            return FALSE;
        }
    }

    SetFileName(empty_strW);
    UpdateWindowCaption();
    return TRUE;
}

void DoOpenFile(LPCWSTR pszFileName)
{
    HANDLE hFile;
    BOOL fEmpty;
    DWORD filesize;
    BITMAP bm;

    if (!DoCloseFile())
        return;

    if (!FileExists(pszFileName))
    {
        AlertFileNotFound(pszFileName);
        return;
    }

    /* FIXME: Support PCX, ICO, GIF, JPEG, PNG files */
    fEmpty = TRUE;
    hFile = CreateFileW(pszFileName, GENERIC_READ, FILE_SHARE_READ, NULL,
                       OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
    filesize = GetFileSize(hFile, NULL);
    if (filesize != 0)
    {
        fEmpty = FALSE;
    }
    CloseHandle(hFile);

    if (!fEmpty)
    {
        if (Globals.hbmImage != NULL)
            DeleteObject(Globals.hbmImage);
        Globals.hbmImage = BM_Load(pszFileName);
        GetObjectW(Globals.hbmImage, sizeof(BITMAP), &bm);
        Globals.sizImage.cx = bm.bmWidth;
        Globals.sizImage.cy = bm.bmHeight;
    }

    SetFileName(pszFileName);
    UpdateWindowCaption();
    Globals.xScrollPos = Globals.yScrollPos = 0;
    PostMessageW(Globals.hCanvasWnd, WM_SIZE, 0, 0);
    InvalidateRect(Globals.hCanvasWnd, NULL, TRUE);
    UpdateWindow(Globals.hCanvasWnd);
}

VOID PAINT_FileNew(VOID)
{
    HDC hDC, hdcMem;
    HGDIOBJ hbmOld;
    RECT rc;
    SIZE sizZoom;

    if (DoCloseFile())
    {
        hDC = GetDC(Globals.hCanvasWnd);
        hdcMem = CreateCompatibleDC(hDC);
        if (hdcMem != NULL)
        {
            if (Globals.hbmImage != NULL)
                DeleteObject(Globals.hbmImage);
            Globals.hbmImage = BM_Create(Globals.sizImage);

            hbmOld = SelectObject(hdcMem, Globals.hbmImage);
            rc.left = rc.top = 0;
            rc.right = Globals.sizImage.cx;
            rc.bottom = Globals.sizImage.cy;
            FillRect(hdcMem, &rc, (HBRUSH)GetStockObject(WHITE_BRUSH));
            SelectObject(hdcMem, hbmOld);

            if (Globals.hbmBuffer != NULL)
                DeleteObject(Globals.hbmBuffer);
            Globals.hbmBuffer = BM_Copy(Globals.hbmImage);

            if (Globals.hbmZoomBuffer != NULL)
                DeleteObject(Globals.hbmZoomBuffer);
            sizZoom.cx = Globals.sizImage.cx * Globals.nZoom;
            sizZoom.cy = Globals.sizImage.cy * Globals.nZoom;
            Globals.hbmZoomBuffer = BM_Create(sizZoom);
            DeleteDC(hdcMem);
        }
        ReleaseDC(Globals.hCanvasWnd, hDC);
    }

    Globals.xScrollPos = Globals.yScrollPos = 0;
    PostMessageW(Globals.hCanvasWnd, WM_SIZE, 0, 0);
}

VOID PAINT_FileOpen(VOID)
{
    OPENFILENAMEW ofn;
    WCHAR szFileName[MAX_PATH];
    WCHAR szDir[MAX_PATH];
    static const WCHAR szDefaultExt[] = { 'b','m','p',0 };
    static const WCHAR bmp_files[] = { '*','.','b','m','p',0 };

    ZeroMemory(&ofn, sizeof(ofn));

    GetCurrentDirectoryW(MAX_PATH, szDir);
    lstrcpyW(szFileName, bmp_files);

    ofn.lStructSize       = sizeof(ofn);
    ofn.hwndOwner         = Globals.hMainWnd;
    ofn.hInstance         = Globals.hInstance;
    ofn.lpstrFilter       = Globals.szFilter;
    ofn.lpstrFile         = szFileName;
    ofn.nMaxFile          = MAX_PATH;
    ofn.lpstrInitialDir   = szDir;
    ofn.Flags             = OFN_FILEMUSTEXIST | OFN_PATHMUSTEXIST |
                            OFN_HIDEREADONLY;
    ofn.lpstrDefExt       = szDefaultExt;

    if (GetOpenFileNameW(&ofn))
        DoOpenFile(szFileName);
}

BOOL PAINT_FileSave(VOID)
{
    if (Globals.szFileName[0] == '\0')
        return PAINT_FileSaveAs();
    else
        DoSaveFile();
    return TRUE;
}

BOOL PAINT_FileSaveAs(VOID)
{
    OPENFILENAMEW ofn;
    WCHAR szPath[MAX_PATH];
    WCHAR szDir[MAX_PATH];
    static const WCHAR szDefaultExt[] = { 'b','m','p',0 };
    static const WCHAR bmp_files[] = { '*','.','b','m','p',0 };

    ZeroMemory(&ofn, sizeof(ofn));

    GetCurrentDirectoryW(MAX_PATH, szDir);
    lstrcpyW(szPath, bmp_files);

    ofn.lStructSize       = sizeof(OPENFILENAMEW);
    ofn.hwndOwner         = Globals.hMainWnd;
    ofn.hInstance         = Globals.hInstance;
    ofn.lpstrFilter       = Globals.szFilter;
    ofn.lpstrFile         = szPath;
    ofn.nMaxFile          = MAX_PATH;
    ofn.lpstrInitialDir   = szDir;
    ofn.Flags             = OFN_PATHMUSTEXIST | OFN_OVERWRITEPROMPT |
                            OFN_HIDEREADONLY;
    ofn.lpstrDefExt       = szDefaultExt;

    if (GetSaveFileNameW(&ofn))
    {
        SetFileName(szPath);
        UpdateWindowCaption();
        DoSaveFile();
        return TRUE;
    }
    return FALSE;
}

VOID PAINT_FilePrintPreview(VOID)
{
}

VOID PAINT_FilePrint(VOID)
{
}

VOID PAINT_FilePageSetup(VOID)
{
}

VOID PAINT_SetAsWallpaperTiled(VOID)
{
}

VOID PAINT_SetAsWallpaperCentered(VOID)
{
}

VOID PAINT_FileExit(VOID)
{
    PostMessageW(Globals.hMainWnd, WM_CLOSE, 0, 0);
}

VOID PAINT_EditUndo(VOID)
{
    HBITMAP hbm;
    SIZE siz;

    if (Globals.fCanUndo)
    {
        hbm = Globals.hbmImage;
        Globals.hbmImage = Globals.hbmImageUndo;
        Globals.hbmImageUndo = hbm;
        Globals.fCanUndo = FALSE;
        siz = Globals.sizImage;
        Globals.sizImage = Globals.sizImageUndo;
        Globals.sizImageUndo = siz;
        Globals.fSelect = FALSE;
        if (Globals.hbmSelect != NULL)
        {
            DeleteObject(Globals.hbmSelect);
            Globals.hbmSelect = NULL;
        }
        InvalidateRect(Globals.hCanvasWnd, NULL, TRUE);
        UpdateWindow(Globals.hCanvasWnd);
        Globals.fCanUndo = FALSE;
    }
}

VOID PAINT_EditRepeat(VOID)
{
    HBITMAP hbm;
    SIZE siz;

    if (!Globals.fCanUndo && Globals.hbmImageUndo != NULL)
    {
        hbm = Globals.hbmImage;
        Globals.hbmImage = Globals.hbmImageUndo;
        Globals.hbmImageUndo = hbm;
        Globals.fCanUndo = FALSE;
        siz = Globals.sizImage;
        Globals.sizImage = Globals.sizImageUndo;
        Globals.sizImageUndo = siz;
        Globals.fSelect = FALSE;
        if (Globals.hbmSelect != NULL)
        {
            DeleteObject(Globals.hbmSelect);
            Globals.hbmSelect = NULL;
        }
        InvalidateRect(Globals.hCanvasWnd, NULL, TRUE);
        UpdateWindow(Globals.hCanvasWnd);
        Globals.fCanUndo = TRUE;
    }
}

VOID PAINT_EditCut(VOID)
{
    HBITMAP hbm;
    HGLOBAL hPack;
    if (Globals.fSelect)
    {
        Selection_TakeOff();
        hbm = Globals.hbmSelect;
        Globals.hbmSelect = NULL;
        Globals.fSelect = FALSE;
        hPack = BM_Pack(hbm);
        DeleteObject(hbm);
        if (OpenClipboard(Globals.hCanvasWnd))
        {
            EmptyClipboard();
            SetClipboardData(CF_DIB, hPack);
            CloseClipboard();
        }
        InvalidateRect(Globals.hCanvasWnd, NULL, FALSE);
        UpdateWindow(Globals.hCanvasWnd);
    }
}

VOID PAINT_EditCopy(VOID)
{
    HBITMAP hbm;
    HGLOBAL hPack;

    if (Globals.fSelect)
    {
        hbm = Selection_CreateBitmap();
        hPack = BM_Pack(hbm);
        DeleteObject(hbm);
        if (OpenClipboard(Globals.hCanvasWnd))
        {
            EmptyClipboard();
            SetClipboardData(CF_DIB, hPack);
            CloseClipboard();
        }
        InvalidateRect(Globals.hCanvasWnd, NULL, FALSE);
        UpdateWindow(Globals.hCanvasWnd);
    }
}

VOID PAINT_EditPaste(VOID)
{
    HGLOBAL hPack;
    HBITMAP hbm;
    BITMAP bm;
    SIZE siz;

    Selection_Land();
    hPack = NULL;
    if (OpenClipboard(Globals.hCanvasWnd))
    {
        hPack = GetClipboardData(CF_DIB);
        CloseClipboard();
    }
    if (hPack == NULL)
        return;

    Globals.iToolPrev = Globals.iToolSelect;
    Globals.iToolSelect = TOOL_BOXSELECT;
    InvalidateRect(Globals.hToolBox, NULL, TRUE);
    UpdateWindow(Globals.hToolBox);

    hbm = BM_Unpack(hPack);
    if (hbm != NULL)
    {
        Globals.fSelect = TRUE;
        if (Globals.hbmSelect != NULL)
            DeleteObject(Globals.hbmSelect);
        Globals.hbmSelect = hbm;
        GetObjectW(Globals.hbmSelect, sizeof(BITMAP), &bm);
        if (Globals.sizImage.cx < bm.bmWidth ||
            Globals.sizImage.cy < bm.bmHeight)
        {
            siz.cx = bm.bmWidth;
            siz.cy = bm.bmHeight;
            Canvas_Resize(Globals.hCanvasWnd, siz);
            Globals.sizImage = siz;
            Globals.pt0.x   = 0;
            Globals.pt0.y   = 0;
            Globals.pt1.x   = bm.bmWidth;
            Globals.pt1.y   = bm.bmHeight;
        }
        else
        {
            Globals.pt0.x   = Globals.xScrollPos / Globals.nZoom;
            Globals.pt0.y   = Globals.yScrollPos / Globals.nZoom;
            Globals.pt1.x   = Globals.pt0.x + bm.bmWidth;
            Globals.pt1.y   = Globals.pt0.y + bm.bmHeight;
        }

        PostMessageW(Globals.hCanvasWnd, WM_SIZE, 0, 0);
        InvalidateRect(Globals.hCanvasWnd, NULL, TRUE);
        UpdateWindow(Globals.hCanvasWnd);
    }
    else
        ShowLastError();
}

VOID PAINT_EditDelete(VOID)
{
    PAINT_ClearSelection();
}

VOID PAINT_ClearSelection(VOID)
{
    if (Globals.fSelect)
    {
        Selection_TakeOff();
        if (Globals.hbmSelect != NULL)
            DeleteObject(Globals.hbmSelect);
        Globals.hbmSelect = NULL;
        Globals.fSelect = FALSE;
        InvalidateRect(Globals.hCanvasWnd, NULL, FALSE);
        UpdateWindow(Globals.hCanvasWnd);
    }
}

VOID PAINT_CopyTo(VOID)
{
    OPENFILENAMEW ofn;
    WCHAR szFileName[MAX_PATH];
    WCHAR szDir[MAX_PATH];
    BOOL fModified;
    static const WCHAR szDefaultExt[] = { 'b','m','p',0 };
    static const WCHAR bmp_files[] = { '*','.','b','m','p',0 };

    fModified = Globals.fModified;
    Selection_TakeOff();

    ZeroMemory(&ofn, sizeof(ofn));

    GetCurrentDirectoryW(MAX_PATH, szDir);
    lstrcpyW(szFileName, bmp_files);

    ofn.lStructSize       = sizeof(ofn);
    ofn.hwndOwner         = Globals.hMainWnd;
    ofn.hInstance         = Globals.hInstance;
    ofn.lpstrFilter       = Globals.szFilter;
    ofn.lpstrFile         = szFileName;
    ofn.nMaxFile          = MAX_PATH;
    ofn.lpstrInitialDir   = szDir;
    ofn.Flags             = OFN_PATHMUSTEXIST | OFN_OVERWRITEPROMPT |
                            OFN_HIDEREADONLY;
    ofn.lpstrDefExt       = szDefaultExt;

    if (!GetSaveFileNameW(&ofn))
        return;

    BM_Save(szFileName, Globals.hbmSelect);
    Selection_Land();
    Globals.fModified = fModified;

    InvalidateRect(Globals.hCanvasWnd, NULL, TRUE);
    UpdateWindow(Globals.hCanvasWnd);
}

VOID PAINT_PasteFrom(VOID)
{
    OPENFILENAMEW ofn;
    WCHAR szFileName[MAX_PATH];
    WCHAR szDir[MAX_PATH];
    BITMAP bm;
    HBITMAP hbm;
    SIZE siz;
    static const WCHAR szDefaultExt[] = { 'b','m','p',0 };
    static const WCHAR bmp_files[] = { '*','.','b','m','p',0 };

    Selection_Land();

    ZeroMemory(&ofn, sizeof(ofn));

    GetCurrentDirectoryW(MAX_PATH, szDir);
    lstrcpyW(szFileName, bmp_files);

    ofn.lStructSize       = sizeof(ofn);
    ofn.hwndOwner         = Globals.hMainWnd;
    ofn.hInstance         = Globals.hInstance;
    ofn.lpstrFilter       = Globals.szFilter;
    ofn.lpstrFile         = szFileName;
    ofn.nMaxFile          = MAX_PATH;
    ofn.lpstrInitialDir   = szDir;
    ofn.Flags             = OFN_FILEMUSTEXIST | OFN_PATHMUSTEXIST |
                            OFN_HIDEREADONLY;
    ofn.lpstrDefExt       = szDefaultExt;

    if (!GetOpenFileNameW(&ofn))
        return;

    if (!FileExists(szFileName))
    {
        AlertFileNotFound(szFileName);
        return;
    }

    Globals.iToolPrev = Globals.iToolSelect;
    Globals.iToolSelect = TOOL_BOXSELECT;
    InvalidateRect(Globals.hToolBox, NULL, TRUE);
    UpdateWindow(Globals.hToolBox);

    hbm = BM_Load(szFileName);
    if (hbm != NULL)
    {
        Globals.fSelect = TRUE;
        if (Globals.hbmSelect != NULL)
            DeleteObject(Globals.hbmSelect);
        Globals.hbmSelect = hbm;
        GetObjectW(hbm, sizeof(BITMAP), &bm);

        if (Globals.sizImage.cx < bm.bmWidth ||
            Globals.sizImage.cy < bm.bmHeight)
        {
            siz.cx = bm.bmWidth;
            siz.cy = bm.bmHeight;
            Canvas_Resize(Globals.hCanvasWnd, siz);
            Globals.sizImage = siz;
            Globals.pt0.x   = 0;
            Globals.pt0.y   = 0;
            Globals.pt1.x   = bm.bmWidth;
            Globals.pt1.y   = bm.bmHeight;
        }
        else
        {
            Globals.pt0.x   = Globals.xScrollPos / Globals.nZoom;
            Globals.pt0.y   = Globals.yScrollPos / Globals.nZoom;
            Globals.pt1.x   = Globals.pt0.x + bm.bmWidth;
            Globals.pt1.y   = Globals.pt0.y + bm.bmHeight;
        }

        PostMessageW(Globals.hCanvasWnd, WM_SIZE, 0, 0);
        InvalidateRect(Globals.hCanvasWnd, NULL, TRUE);
        UpdateWindow(Globals.hCanvasWnd);
    }
    else
        ShowLastError();
}

VOID PAINT_EditSelectAll(VOID)
{
    Globals.fSelect = TRUE;
    Globals.pt0.x   = 0;
    Globals.pt0.y   = 0;
    Globals.pt1.x   = Globals.sizImage.cx;
    Globals.pt1.y   = Globals.sizImage.cy;
    Globals.iToolSelect     = TOOL_BOXSELECT;
    Globals.hbmSelect       = NULL;
    InvalidateRect(Globals.hToolBox, NULL, TRUE);
    UpdateWindow(Globals.hToolBox);
    InvalidateRect(Globals.hCanvasWnd, NULL, TRUE);
    UpdateWindow(Globals.hCanvasWnd);
}

VOID PAINT_HelpContents(VOID)
{
    WinHelpW(Globals.hMainWnd, helpfileW, HELP_INDEX, 0);
}

VOID PAINT_HelpHelp(VOID)
{
    WinHelpW(Globals.hMainWnd, helpfileW, HELP_HELPONHELP, 0);
}

VOID PAINT_HelpAboutPaint(VOID)
{
    static const WCHAR paintW[] = { 'P','a','i','n','t',0 };
    WCHAR szPaint[MAX_STRING_LEN];
    HICON icon = LoadImageW(Globals.hInstance, (LPCWSTR)IDI_PAINT,
                            IMAGE_ICON, 48, 48, LR_SHARED);

    LoadStringW(Globals.hInstance, STRING_PAINT, szPaint, SIZEOF(szPaint));
    ShellAboutW(Globals.hMainWnd, szPaint, paintW, icon);
}


VOID PAINT_ToolBox(VOID)
{
    if (IsWindowVisible(Globals.hToolBox))
        ShowWindow(Globals.hToolBox, SW_HIDE);
    else
        ShowWindow(Globals.hToolBox, SW_SHOWNORMAL);

    PostMessageW(Globals.hMainWnd, WM_SIZE, 0, 0);
}

VOID PAINT_ColorBox(VOID)
{
    if (IsWindowVisible(Globals.hColorBox))
        ShowWindow(Globals.hColorBox, SW_HIDE);
    else
        ShowWindow(Globals.hColorBox, SW_SHOWNORMAL);

    PostMessageW(Globals.hMainWnd, WM_SIZE, 0, 0);
}

VOID PAINT_StatusBar(VOID)
{
    if (IsWindowVisible(Globals.hStatusBar))
        ShowWindow(Globals.hStatusBar, SW_HIDE);
    else
        ShowWindow(Globals.hStatusBar, SW_SHOWNORMAL);

    PostMessageW(Globals.hMainWnd, WM_SIZE, 0, 0);
}

VOID PAINT_Zoom(INT nZoom)
{
    SIZE siz;
    Globals.nZoom = nZoom;
    Globals.xScrollPos = Globals.yScrollPos = 0;
    PostMessageW(Globals.hCanvasWnd, WM_SIZE, 0, 0);

    if (Globals.hbmZoomBuffer != NULL)
        DeleteObject(Globals.hbmZoomBuffer);
    siz.cx = Globals.nZoom * Globals.sizImage.cx;
    siz.cy = Globals.nZoom * Globals.sizImage.cy;
    Globals.hbmZoomBuffer = BM_Create(siz);

    InvalidateRect(Globals.hCanvasWnd, NULL, TRUE);
    UpdateWindow(Globals.hCanvasWnd);
}

VOID PAINT_Zoom2(INT x, INT y, INT nZoom)
{
    SIZE siz;
    Globals.nZoom = nZoom;
    Globals.xScrollPos = x * nZoom;
    Globals.yScrollPos = y * nZoom;
    PostMessageW(Globals.hCanvasWnd, WM_SIZE, 0, 0);

    if (Globals.hbmZoomBuffer != NULL)
        DeleteObject(Globals.hbmZoomBuffer);
    siz.cx = Globals.nZoom * Globals.sizImage.cx;
    siz.cy = Globals.nZoom * Globals.sizImage.cy;
    Globals.hbmZoomBuffer = BM_Create(siz);

    InvalidateRect(Globals.hCanvasWnd, NULL, TRUE);
    UpdateWindow(Globals.hCanvasWnd);
}

VOID PAINT_ShowGrid(VOID)
{
    Globals.fShowGrid = !Globals.fShowGrid;
    InvalidateRect(Globals.hCanvasWnd, NULL, TRUE);
    UpdateWindow(Globals.hCanvasWnd);
}

VOID PAINT_InvertColors(VOID)
{
    HDC hDC, hdcMem;
    HGDIOBJ hbmOld;
    RECT rc;
    hDC = GetDC(Globals.hCanvasWnd);
    hdcMem = CreateCompatibleDC(hDC);
    if (hdcMem != NULL)
    {
        if (Globals.fSelect)
        {
            Selection_TakeOff();
            hbmOld = SelectObject(hdcMem, Globals.hbmSelect);
            rc.left = rc.top = 0;
            rc.right = Globals.sizImage.cx;
            rc.bottom = Globals.sizImage.cy;
            InvertRect(hdcMem, &rc);
            SelectObject(hdcMem, hbmOld);
        }
        else
        {
            hbmOld = SelectObject(hdcMem, Globals.hbmImage);
            rc.left = rc.top = 0;
            rc.right = Globals.sizImage.cx;
            rc.bottom = Globals.sizImage.cy;
            InvertRect(hdcMem, &rc);
            SelectObject(hdcMem, hbmOld);
        }
        DeleteDC(hdcMem);
    }
    ReleaseDC(Globals.hCanvasWnd, hDC);
    Globals.fModified = TRUE;
    InvalidateRect(Globals.hCanvasWnd, NULL, TRUE);
    UpdateWindow(Globals.hCanvasWnd);
}

VOID PAINT_ClearImage(VOID)
{
    HDC hDC, hdcMem;
    RECT rc;
    hDC = GetDC(Globals.hCanvasWnd);
    hdcMem = CreateCompatibleDC(hDC);
    if (hdcMem != NULL)
    {
        HBRUSH hbr;
        HGDIOBJ hbmOld = SelectObject(hdcMem, Globals.hbmImage);
        rc.left = rc.top = 0;
        rc.right = Globals.sizImage.cx;
        rc.bottom = Globals.sizImage.cy;
        hbr = CreateSolidBrush(Globals.rgbBack);
        FillRect(hdcMem, &rc, hbr);
        DeleteObject(hbr);
        SelectObject(hdcMem, hbmOld);
        DeleteDC(hdcMem);
    }
    ReleaseDC(Globals.hCanvasWnd, hDC);
    Globals.fModified = TRUE;
    InvalidateRect(Globals.hCanvasWnd, NULL, TRUE);
    UpdateWindow(Globals.hCanvasWnd);
}

BOOL CALLBACK ZoomDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
    WCHAR sz[32];
    SIZE siz;
    static const WCHAR format[] = {'%','d','0','0','%','%',0};

    switch (uMsg)
    {
    case WM_INITDIALOG:
        switch (Globals.nZoom)
        {
        case 1:     CheckDlgButton(hDlg, rad1, 1); break;
        case 2:     CheckDlgButton(hDlg, rad2, 1); break;
        case 4:     CheckDlgButton(hDlg, rad3, 1); break;
        case 6:     CheckDlgButton(hDlg, rad4, 1); break;
        case 8:     CheckDlgButton(hDlg, rad5, 1); break;
        }
        wsprintfW(sz, format, Globals.nZoom);
        SetDlgItemTextW(hDlg, stc2, sz);
        return TRUE;

    case WM_COMMAND:
        switch (LOWORD(wParam))
        {
        case IDOK:
            if (IsDlgButtonChecked(hDlg, rad1) & 1)         Globals.nZoom = 1;
            else if (IsDlgButtonChecked(hDlg, rad2) & 1)    Globals.nZoom = 2;
            else if (IsDlgButtonChecked(hDlg, rad3) & 1)    Globals.nZoom = 4;
            else if (IsDlgButtonChecked(hDlg, rad4) & 1)    Globals.nZoom = 6;
            else if (IsDlgButtonChecked(hDlg, rad5) & 1)    Globals.nZoom = 8;

            siz.cx = Globals.nZoom * Globals.sizImage.cx;
            siz.cy = Globals.nZoom * Globals.sizImage.cy;
            if (Globals.hbmZoomBuffer != NULL)
                DeleteObject(Globals.hbmZoomBuffer);
            Globals.hbmZoomBuffer = BM_Create(siz);
            EndDialog(hDlg, IDOK);
            break;

        case IDCANCEL:
            EndDialog(hDlg, IDCANCEL);
            break;
        }
    }
    return FALSE;
}

VOID PAINT_ZoomCustom(VOID)
{
    if (DialogBoxW(Globals.hInstance, (LPCWSTR)IDD_ZOOM,
                  Globals.hMainWnd, (DLGPROC)ZoomDlgProc) == IDOK)
    {
        InvalidateRect(Globals.hCanvasWnd, NULL, TRUE);
        UpdateWindow(Globals.hCanvasWnd);
    }
}

BOOL CALLBACK
StretchSkewDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
    INT cxPercent, cyPercent;
    BOOL fTranslated;
    SIZE sizNew;
    static const WCHAR sz100[] = {'1','0','0',0};
    switch (uMsg)
    {
    case WM_INITDIALOG:
        SetDlgItemTextW(hDlg, edt1, sz100);
        SetDlgItemTextW(hDlg, edt2, sz100);
        return TRUE;

    case WM_COMMAND:
        switch (LOWORD(wParam))
        {
        case IDOK:
            cxPercent = GetDlgItemInt(hDlg, edt1, &fTranslated, FALSE);
            if (!fTranslated || cxPercent <= 0)
            {
                WCHAR sz[MAX_STRING_LEN];
                LoadStringW(Globals.hInstance, STRING_POSITIVE_INT, sz,
                           MAX_STRING_LEN);
                MessageBeep(MB_ICONERROR);
                MessageBoxW(hDlg, sz, NULL, MB_OK|MB_ICONERROR);
                SendDlgItemMessageW(hDlg, edt1, EM_SETSEL, 0, -1);
                SetFocus(GetDlgItem(hDlg, edt1));
                break;
            }
            cyPercent = GetDlgItemInt(hDlg, edt2, &fTranslated, FALSE);
            if (!fTranslated || cyPercent <= 0)
            {
                WCHAR sz[MAX_STRING_LEN];
                LoadStringW(Globals.hInstance, STRING_POSITIVE_INT, sz,
                           MAX_STRING_LEN);
                MessageBeep(MB_ICONERROR);
                MessageBoxW(hDlg, sz, NULL, MB_OK|MB_ICONERROR);
                SendDlgItemMessageW(hDlg, edt2, EM_SETSEL, 0, -1);
                SetFocus(GetDlgItem(hDlg, edt2));
                break;
            }
            if (Globals.fSelect)
            {
                sizNew.cx = MulDiv(Globals.pt1.x - Globals.pt0.x + 1, cxPercent,
                                   100);
                sizNew.cy = MulDiv(Globals.pt1.y - Globals.pt0.y + 1, cyPercent,
                                   100);
                Selection_Stretch(Globals.hCanvasWnd, sizNew);
            }
            else
            {
                sizNew.cx = MulDiv(Globals.sizImage.cx, cxPercent, 100);
                sizNew.cy = MulDiv(Globals.sizImage.cy, cyPercent, 100);
                Canvas_Stretch(Globals.hCanvasWnd, sizNew);
            }

            EndDialog(hDlg, IDOK);
            break;

        case IDCANCEL:
            EndDialog(hDlg, IDCANCEL);
            break;
        }
        break;
    }
    return FALSE;
}

VOID PAINT_StretchSkew(VOID)
{
    if (DialogBoxW(Globals.hInstance, (LPCWSTR)IDD_STRETCH_SKEW,
                  Globals.hMainWnd, (DLGPROC)StretchSkewDlgProc) == IDOK)
    {
        InvalidateRect(Globals.hCanvasWnd, NULL, TRUE);
        UpdateWindow(Globals.hCanvasWnd);
    }
}

BOOL CALLBACK
AttributesDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
    WCHAR sz[128], szSize[64], szDate[32], szTime[32];
    HANDLE hFile;
    DWORD cb;
    FILETIME ft, ft2;
    SYSTEMTIME st;
    BOOL fTranslated;
    SIZE sizNew;
    static SIZE siz;
    static const WCHAR last[] = {'F','i','l','e',' ','l','a','s','t',' ',
                                 's','a','v','e','d',':','\t',
                                 '%','s',' ','%','s',0
                                };
    static const WCHAR size[] = {'S','i','z','e',' ','o','n',' ',
                                 'd','i','s','k',':','\t','%','s',0
                                };
    static const WCHAR no_data[] = {'N','o','t',' ',
                                    'A','v','a','i','l','a','b','l','e',0
                                   };
    static const WCHAR empty[] = {0};
    switch (uMsg)
    {
    case WM_INITDIALOG:
        CheckDlgButton(hDlg, rad3, 1);

        siz = Globals.sizImage;

        SetDlgItemInt(hDlg, edt1, siz.cx, FALSE);
        SetDlgItemInt(hDlg, edt2, siz.cy, FALSE);

        wsprintfW(sz, last, no_data, empty);
        SetDlgItemTextW(hDlg, stc1, sz);
        wsprintfW(sz, size, no_data);
        SetDlgItemTextW(hDlg, stc2, sz);

        hFile = CreateFileW(Globals.szFileName, GENERIC_READ,
                           FILE_SHARE_READ, NULL, OPEN_EXISTING,
                           FILE_ATTRIBUTE_NORMAL, NULL);
        if (hFile != INVALID_HANDLE_VALUE)
        {
            if (GetFileTime(hFile, NULL, NULL, &ft))
            {
                FileTimeToLocalFileTime(&ft, &ft2);
                FileTimeToSystemTime(&ft2, &st);

                GetDateFormatW(LOCALE_USER_DEFAULT, DATE_SHORTDATE, &st, NULL,
                              szDate, 32);
                GetTimeFormatW(LOCALE_USER_DEFAULT, TIME_NOSECONDS, &st, NULL,
                              szTime, 32);
                wsprintfW(sz, last, szDate, szTime);
                SetDlgItemTextW(hDlg, stc1, sz);
            }

            cb = GetFileSize(hFile, NULL);
            if (cb != 0xFFFFFFFF)
            {
                StrFormatByteSizeW(cb, szSize, 64);
                wsprintfW(sz, size, szSize);
                SetDlgItemTextW(hDlg, stc2, sz);
            }
            CloseHandle(hFile);
        }

        CheckDlgButton(hDlg, rad5, 1);
        return TRUE;

    case WM_COMMAND:
        switch (HIWORD(wParam))
        {
        case EN_CHANGE:
            switch (LOWORD(wParam))
            {
            case edt1:
                break;

            case edt2:
                break;
            }
            break;

        case BN_CLICKED:
            switch (LOWORD(wParam))
            {
            case rad1:
                break;

            case rad2:
                break;

            case rad3:
                SetDlgItemInt(hDlg, edt1, siz.cx, FALSE);
                SetDlgItemInt(hDlg, edt2, siz.cy, FALSE);
                break;

            case IDOK:
                sizNew.cx = GetDlgItemInt(hDlg, edt1, &fTranslated, FALSE);
                if (!fTranslated || sizNew.cx <= 0)
                {
                    WCHAR sz[MAX_STRING_LEN];
                    LoadStringW(Globals.hInstance, STRING_POSITIVE_INT, sz,
                               MAX_STRING_LEN);
                    MessageBeep(MB_ICONERROR);
                    MessageBoxW(hDlg, sz, NULL, MB_OK|MB_ICONERROR);
                    SendDlgItemMessageW(hDlg, edt1, EM_SETSEL, 0, -1);
                    SetFocus(GetDlgItem(hDlg, edt1));
                    break;
                }
                sizNew.cy = GetDlgItemInt(hDlg, edt2, &fTranslated, FALSE);
                if (!fTranslated || sizNew.cy <= 0)
                {
                    WCHAR sz[MAX_STRING_LEN];
                    LoadStringW(Globals.hInstance, STRING_POSITIVE_INT, sz,
                               MAX_STRING_LEN);
                    MessageBeep(MB_ICONERROR);
                    MessageBoxW(hDlg, sz, NULL, MB_OK|MB_ICONERROR);
                    SendDlgItemMessageW(hDlg, edt2, EM_SETSEL, 0, -1);
                    SetFocus(GetDlgItem(hDlg, edt2));
                    break;
                }

                Canvas_Resize(Globals.hCanvasWnd, sizNew);
                EndDialog(hDlg, IDOK);
                break;

            case IDCANCEL:
                EndDialog(hDlg, IDCANCEL);
                break;
            }
            break;
        }
        break;
    }
    return FALSE;
}

VOID PAINT_Attributes(VOID)
{
    if (DialogBoxW(Globals.hInstance, (LPCWSTR)IDD_ATTRIBUTES,
                  Globals.hMainWnd, (DLGPROC)AttributesDlgProc) == IDOK)
    {
        InvalidateRect(Globals.hCanvasWnd, NULL, TRUE);
        UpdateWindow(Globals.hCanvasWnd);
    }
}

BOOL CALLBACK
FlipRotateDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
    switch (uMsg)
    {
    case WM_INITDIALOG:
        CheckDlgButton(hDlg, rad1, 1);
        CheckDlgButton(hDlg, rad4, 1);
        return TRUE;

    case WM_COMMAND:
        switch (LOWORD(wParam))
        {
        case rad1:
        case rad2:
            EnableWindow(GetDlgItem(hDlg, rad4), FALSE);
            EnableWindow(GetDlgItem(hDlg, rad5), FALSE);
            EnableWindow(GetDlgItem(hDlg, rad6), FALSE);
            break;

        case rad3:
            EnableWindow(GetDlgItem(hDlg, rad4), TRUE);
            EnableWindow(GetDlgItem(hDlg, rad5), TRUE);
            EnableWindow(GetDlgItem(hDlg, rad6), TRUE);
            break;

        case IDOK:
            if (IsDlgButtonChecked(hDlg, rad1) & 1)
            {
                if (Globals.fSelect)
                    Selection_HFlip(Globals.hCanvasWnd);
                else
                    Canvas_HFlip(Globals.hCanvasWnd);
            }
            else if (IsDlgButtonChecked(hDlg, rad2) & 1)
            {
                if (Globals.fSelect)
                    Selection_VFlip(Globals.hCanvasWnd);
                else
                    Canvas_VFlip(Globals.hCanvasWnd);
            }
            else if (IsDlgButtonChecked(hDlg, rad3) & 1)
            {
                if (IsDlgButtonChecked(hDlg, rad4) & 1)
                {
                    if (Globals.fSelect)
                        Selection_Rotate90Degree(Globals.hCanvasWnd);
                    else
                        Canvas_Rotate90Degree(Globals.hCanvasWnd);
                }
                else if (IsDlgButtonChecked(hDlg, rad5) & 1)
                {
                    if (Globals.fSelect)
                        Selection_Rotate180Degree(Globals.hCanvasWnd);
                    else
                        Canvas_Rotate180Degree(Globals.hCanvasWnd);
                }
                else if (IsDlgButtonChecked(hDlg, rad6) & 1)
                {
                    if (Globals.fSelect)
                        Selection_Rotate270Degree(Globals.hCanvasWnd);
                    else
                        Canvas_Rotate270Degree(Globals.hCanvasWnd);
                }
            }

            EndDialog(hDlg, IDOK);
            break;

        case IDCANCEL:
            EndDialog(hDlg, IDCANCEL);
            break;
        }
        break;
    }
    return FALSE;
}

VOID PAINT_FlipRotate(VOID)
{
    if (DialogBoxW(Globals.hInstance, (LPCWSTR)IDD_FLIP_ROTATE,
                  Globals.hMainWnd, (DLGPROC)FlipRotateDlgProc) == IDOK)
    {
        InvalidateRect(Globals.hCanvasWnd, NULL, TRUE);
        UpdateWindow(Globals.hCanvasWnd);
    }
}

VOID PAINT_EditColor(BOOL fBack)
{
    CHOOSECOLORW cc;

    ZeroMemory(&cc, sizeof(CHOOSECOLORW));
    cc.lStructSize = sizeof(CHOOSECOLORW);
    cc.hwndOwner   = Globals.hMainWnd;
    if (fBack)
        cc.rgbResult = Globals.rgbBack;
    else
        cc.rgbResult = Globals.rgbFore;
    cc.lpCustColors = aCustColors;
    cc.Flags       = CC_RGBINIT;

    if (ChooseColorW(&cc))
    {
        if (fBack)
        {
            Globals.argbColors[Globals.iBackColor] = cc.rgbResult;
            Globals.rgbBack = cc.rgbResult;
        }
        else
        {
            Globals.argbColors[Globals.iForeColor] = cc.rgbResult;
            Globals.rgbFore = cc.rgbResult;
        }
    }
    InvalidateRect(Globals.hColorBox, NULL, TRUE);
    UpdateWindow(Globals.hColorBox);
}

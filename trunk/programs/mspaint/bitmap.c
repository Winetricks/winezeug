/*
 *  Paint (bitmap.c)
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
#include "resource.h"

#define  WIDTHBYTES(x)  (((x) + 31) / 32 * 4)

typedef struct tagBITMAPINFOEX
{
    BITMAPINFOHEADER bmiHeader;
    RGBQUAD          bmiColors[256];
} BITMAPINFOEX, FAR * LPBITMAPINFOEX;

HBITMAP BM_Load(LPCWSTR pszFileName)
{
    HANDLE hFile;
    BITMAPFILEHEADER bf;
    BITMAPINFOEX bi;
    DWORD cb, cbImage;
    DWORD dwError;
    LPVOID pBits, pBits2;
    HDC hDC, hMemDC;
    HBITMAP hbm;
#ifndef LR_LOADREALSIZE
#define LR_LOADREALSIZE 128
#endif
    hbm = (HBITMAP)LoadImageW(NULL, pszFileName, IMAGE_BITMAP, 0, 0,
        LR_LOADFROMFILE | LR_LOADREALSIZE | LR_CREATEDIBSECTION);
    if (hbm != NULL)
        return hbm;

    hFile = CreateFileW(pszFileName, GENERIC_READ, FILE_SHARE_READ, NULL,
                       OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
    if (hFile == INVALID_HANDLE_VALUE)
        return NULL;

    if (!ReadFile(hFile, &bf, sizeof(BITMAPFILEHEADER), &cb, NULL))
    {
        dwError = GetLastError();
        CloseHandle(NULL);
        SetLastError(dwError);
        return NULL;
    }

    pBits = NULL;
    dwError = 0;
    if (bf.bfType == 0x4D42 && bf.bfReserved1 == 0 && bf.bfReserved2 == 0 &&
        bf.bfSize > bf.bfOffBits && bf.bfOffBits > sizeof(BITMAPFILEHEADER) &&
        bf.bfOffBits <= sizeof(BITMAPFILEHEADER) + sizeof(BITMAPINFOEX))
    {
        cbImage = bf.bfSize - bf.bfOffBits;
        pBits = HeapAlloc(GetProcessHeap(), 0, cbImage);
        if (pBits != NULL)
        {
            if (ReadFile(hFile, &bi, bf.bfOffBits -
                         sizeof(BITMAPFILEHEADER), &cb, NULL) &&
                ReadFile(hFile, pBits, cbImage, &cb, NULL))
            {
                ;
            }
            else
            {
                dwError = GetLastError();
                HeapFree(GetProcessHeap(), 0, pBits);
                pBits = NULL;
            }
        }
        else
            dwError = GetLastError();
    }
    else
        dwError = -STRING_INVALID_BM;

    CloseHandle(hFile);

    if (pBits == NULL)
    {
        SetLastError(dwError);
        return NULL;
    }

    hbm = NULL;
    dwError = 0;
    hDC = GetDC(NULL);
    if (hDC != NULL)
    {
        hMemDC = CreateCompatibleDC(hDC);
        if (hMemDC != NULL)
        {
            hbm = CreateDIBSection(hMemDC, (BITMAPINFO*)&bi, DIB_RGB_COLORS,
                                   &pBits2, NULL, 0);
            if (hbm != NULL)
            {
                if (SetDIBits(hMemDC, hbm, 0, abs(bi.bmiHeader.biHeight),
                              pBits, (BITMAPINFO*)&bi, DIB_RGB_COLORS))
                {
                    ;
                }
                else
                {
                    dwError = GetLastError();
                    DeleteObject(hbm);
                    hbm = NULL;
                }
            }
            else
                dwError = GetLastError();

            DeleteDC(hMemDC);
        }
        else
            dwError = GetLastError();

        ReleaseDC(NULL, hDC);
    }
    else
        dwError = GetLastError();

    HeapFree(GetProcessHeap(), 0, pBits);
    SetLastError(dwError);

    return hbm;
}

BOOL BM_Save(LPCWSTR pszFileName, HBITMAP hbm)
{
    BOOL f;
    DWORD dwError;
    BITMAPFILEHEADER bf;
    BITMAPINFOEX bi;
    DWORD cb;
    DWORD cColors, cbColors;
    HDC hDC;
    HANDLE hFile;
    LPVOID pBits;
    BITMAP bm;
    BITMAPINFOHEADER *pbmih = &bi.bmiHeader;

    if (!GetObjectW(hbm, sizeof(BITMAP), &bm))
        return FALSE;

    ZeroMemory(pbmih, sizeof(BITMAPINFOHEADER));
    pbmih->biSize             = sizeof(BITMAPINFOHEADER);
    pbmih->biWidth            = bm.bmWidth;
    pbmih->biHeight           = bm.bmHeight;
    pbmih->biPlanes           = 1;
    pbmih->biBitCount         = bm.bmBitsPixel;
    pbmih->biCompression      = BI_RGB;
    pbmih->biSizeImage        = bm.bmWidthBytes * bm.bmHeight;

    if (bm.bmBitsPixel < 16)
        cColors = 1 << bm.bmBitsPixel;
    else
        cColors = 0;
    cbColors = cColors * sizeof(RGBQUAD);

    bf.bfType = 0x4d42;
    bf.bfReserved1 = 0;
    bf.bfReserved2 = 0;
    cb = sizeof(BITMAPFILEHEADER) + pbmih->biSize + cbColors;
    bf.bfOffBits = cb;
    bf.bfSize = cb + pbmih->biSizeImage;

    pBits = HeapAlloc(GetProcessHeap(), 0, pbmih->biSizeImage);
    if (pBits == NULL)
        return FALSE;

    f = FALSE;
    dwError = 0;
    hDC = GetDC(NULL);
    if (hDC != NULL)
    {
        if (GetDIBits(hDC, hbm, 0, bm.bmHeight, pBits, (BITMAPINFO*)&bi,
            DIB_RGB_COLORS))
        {
            hFile = CreateFileW(pszFileName, GENERIC_WRITE, FILE_SHARE_READ, NULL,
                               CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL |
                               FILE_FLAG_WRITE_THROUGH, NULL);
            if (hFile != INVALID_HANDLE_VALUE)
            {
                f = WriteFile(hFile, &bf, sizeof(BITMAPFILEHEADER), &cb, NULL) &&
                    WriteFile(hFile, &bi, sizeof(BITMAPINFOHEADER), &cb, NULL) &&
                    WriteFile(hFile, &bi.bmiColors, cbColors, &cb, NULL) &&
                    WriteFile(hFile, pBits, pbmih->biSizeImage, &cb, NULL);
                if (!f)
                    dwError = GetLastError();
                CloseHandle(hFile);

                if (!f)
                    DeleteFileW(pszFileName);
            }
            else
                dwError = GetLastError();
        }
        else
            dwError = GetLastError();
        ReleaseDC(NULL, hDC);
    }
    else
        dwError = GetLastError();

    HeapFree(GetProcessHeap(), 0, pBits);
    SetLastError(dwError);
    return f;
}

HBITMAP BM_Create(SIZE siz)
{
    BITMAPINFO bi;
    VOID *pBits;
    ZeroMemory(&bi.bmiHeader, sizeof(BITMAPINFOHEADER));
    bi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
    bi.bmiHeader.biWidth = siz.cx;
    bi.bmiHeader.biHeight = -siz.cy;
    bi.bmiHeader.biPlanes = 1;
    bi.bmiHeader.biBitCount = 24;
    bi.bmiHeader.biCompression = BI_RGB;
    return CreateDIBSection(NULL, &bi, DIB_RGB_COLORS, &pBits, NULL, 0);
}

HBITMAP BM_CreateResized(HWND hWnd, SIZE sizNew, HBITMAP hbm, SIZE siz)
{
    DWORD dwError;
    HDC hDC, hdcMem1, hdcMem2;
    HBITMAP hbmNew, hbmOld1, hbmOld2;
    RECT rc;

    hbmNew = BM_Create(sizNew);
    if (hbmNew != NULL)
    {
        dwError = 0;
        hDC = GetDC(hWnd);
        hdcMem1 = CreateCompatibleDC(hDC);
        if (hdcMem1 != NULL)
        {
            hbmOld1 = SelectObject(hdcMem1, hbmNew);

            rc.left = rc.top = 0;
            rc.right = sizNew.cx;
            rc.bottom = sizNew.cy;
            FillRect(hdcMem1, &rc, (HBRUSH)GetStockObject(WHITE_BRUSH));

            hdcMem2 = CreateCompatibleDC(hDC);
            if (hdcMem2 != NULL)
            {
                hbmOld2 = SelectObject(hdcMem2, hbm);
                BitBlt(hdcMem1, 0, 0, siz.cx, siz.cy,
                       hdcMem2, 0, 0, SRCCOPY);
                SelectObject(hdcMem2, hbmOld2);
                DeleteDC(hdcMem2);
            }
            else
                dwError = GetLastError();
            SelectObject(hdcMem1, hbmOld1);

            DeleteDC(hdcMem1);
        }
        else
            dwError = GetLastError();
        ReleaseDC(hWnd, hDC);
        SetLastError(dwError);
    }

    return hbmNew;
}

HBITMAP BM_CreateStretched(HWND hWnd, SIZE sizNew, HBITMAP hbm, SIZE siz)
{
    DWORD dwError;
    HDC hDC, hdcMem1, hdcMem2;
    HBITMAP hbmNew, hbmOld1, hbmOld2;

    hbmNew = BM_Create(sizNew);
    if (hbmNew != NULL)
    {
        dwError = 0;
        hDC = GetDC(hWnd);
        hdcMem1 = CreateCompatibleDC(hDC);
        if (hdcMem1 != NULL)
        {
            hbmOld1 = SelectObject(hdcMem1, hbmNew);

            hdcMem2 = CreateCompatibleDC(hDC);
            if (hdcMem2 != NULL)
            {
                hbmOld2 = SelectObject(hdcMem2, hbm);
                SetStretchBltMode(hdcMem1, COLORONCOLOR);
                StretchBlt(hdcMem1, 0, 0, sizNew.cx, sizNew.cy,
                           hdcMem2, 0, 0, siz.cx, siz.cy, SRCCOPY);
                SelectObject(hdcMem2, hbmOld2);
                DeleteDC(hdcMem2);
            }
            else
                dwError = GetLastError();
            SelectObject(hdcMem1, hbmOld1);

            DeleteDC(hdcMem1);
        }
        else
            dwError = GetLastError();
        ReleaseDC(hWnd, hDC);
        SetLastError(dwError);
    }

    return hbmNew;
}

HBITMAP BM_CreateHFliped(HWND hWnd, HBITMAP hbm, SIZE siz)
{
    DWORD dwError;
    HDC hDC, hdcMem1, hdcMem2;
    HBITMAP hbmNew, hbmOld1, hbmOld2;

    hbmNew = BM_Create(siz);
    if (hbmNew != NULL)
    {
        dwError = 0;
        hDC = GetDC(hWnd);
        hdcMem1 = CreateCompatibleDC(hDC);
        if (hdcMem1 != NULL)
        {
            hbmOld1 = SelectObject(hdcMem1, hbmNew);

            hdcMem2 = CreateCompatibleDC(hDC);
            if (hdcMem2 != NULL)
            {
                hbmOld2 = SelectObject(hdcMem2, hbm);
                StretchBlt(hdcMem1, siz.cx - 1, 0, -siz.cx, siz.cy,
                           hdcMem2, 0, 0, siz.cx, siz.cy, SRCCOPY);
                SelectObject(hdcMem2, hbmOld2);
                DeleteDC(hdcMem2);
            }
            else
                dwError = GetLastError();
            SelectObject(hdcMem1, hbmOld1);

            DeleteDC(hdcMem1);
        }
        else
            dwError = GetLastError();
        ReleaseDC(hWnd, hDC);
        SetLastError(dwError);
    }

    return hbmNew;
}

HBITMAP BM_CreateVFliped(HWND hWnd, HBITMAP hbm, SIZE siz)
{
    DWORD dwError;
    HDC hDC, hdcMem1, hdcMem2;
    HBITMAP hbmNew, hbmOld1, hbmOld2;

    hbmNew = BM_Create(siz);
    if (hbmNew != NULL)
    {
        dwError = 0;
        hDC = GetDC(hWnd);
        hdcMem1 = CreateCompatibleDC(hDC);
        if (hdcMem1 != NULL)
        {
            hbmOld1 = SelectObject(hdcMem1, hbmNew);

            hdcMem2 = CreateCompatibleDC(hDC);
            if (hdcMem2 != NULL)
            {
                hbmOld2 = SelectObject(hdcMem2, hbm);
                StretchBlt(hdcMem1, 0, siz.cy - 1, siz.cx, -siz.cy,
                           hdcMem2, 0, 0, siz.cx, siz.cy, SRCCOPY);
                SelectObject(hdcMem2, hbmOld2);
                DeleteDC(hdcMem2);
            }
            else
                dwError = GetLastError();
            SelectObject(hdcMem1, hbmOld1);

            DeleteDC(hdcMem1);
        }
        else
            dwError = GetLastError();
        ReleaseDC(hWnd, hDC);
        SetLastError(dwError);
    }

    return hbmNew;
}

HBITMAP BM_CreateXYSwaped(HWND hWnd, HBITMAP hbm, SIZE siz)
{
    DWORD dwError;
    HDC hDC, hdcMem1, hdcMem2;
    HBITMAP hbmNew, hbmOld1, hbmOld2;
    INT x, y;
    SIZE siz2;
    siz2.cx = siz.cy;
    siz2.cy = siz.cx;

    hbmNew = BM_Create(siz2);
    if (hbmNew != NULL)
    {
        dwError = 0;
        hDC = GetDC(hWnd);
        hdcMem1 = CreateCompatibleDC(hDC);
        if (hdcMem1 != NULL)
        {
            hbmOld1 = SelectObject(hdcMem1, hbmNew);

            hdcMem2 = CreateCompatibleDC(hDC);
            if (hdcMem2 != NULL)
            {
                hbmOld2 = SelectObject(hdcMem2, hbm);

                for (y = 0; y < siz2.cy; y++)
                {
                    for (x = 0; x < siz2.cx; x++)
                    {
                        SetPixel(hdcMem1, x, y, GetPixel(hdcMem2, y, x));
                    }
                }

                SelectObject(hdcMem2, hbmOld2);
                DeleteDC(hdcMem2);
            }
            else
                dwError = GetLastError();
            SelectObject(hdcMem1, hbmOld1);

            DeleteDC(hdcMem1);
        }
        else
            dwError = GetLastError();
        ReleaseDC(hWnd, hDC);
        SetLastError(dwError);
    }

    return hbmNew;
}

HBITMAP BM_CreateRotated90Degree(HWND hWnd, HBITMAP hbm, SIZE siz)
{
    DWORD dwError;
    HBITMAP hbmNew1, hbmNew2;
    SIZE siz2;
    siz2.cx = siz.cy;
    siz2.cy = siz.cx;
    hbmNew1 = BM_CreateXYSwaped(hWnd, hbm, siz);
    hbmNew2 = NULL;
    if (hbmNew1 != NULL)
    {
        dwError = 0;
        hbmNew2 = BM_CreateHFliped(hWnd, hbmNew1, siz2);
        if (hbmNew2 == NULL)
            dwError = GetLastError();
        DeleteObject(hbmNew1);
        SetLastError(dwError);
    }
    return hbmNew2;
}

HBITMAP BM_CreateRotated180Degree(HWND hWnd, HBITMAP hbm, SIZE siz)
{
    DWORD dwError;
    HBITMAP hbmNew1, hbmNew2;
    hbmNew1 = BM_CreateHFliped(hWnd, hbm, siz);
    hbmNew2 = NULL;
    if (hbmNew1 != NULL)
    {
        dwError = 0;
        hbmNew2 = BM_CreateVFliped(hWnd, hbmNew1, siz);
        if (hbmNew2 == NULL)
            dwError = GetLastError();
        DeleteObject(hbmNew1);
        SetLastError(dwError);
    }
    return hbmNew2;
}

HBITMAP BM_CreateRotated270Degree(HWND hWnd, HBITMAP hbm, SIZE siz)
{
    DWORD dwError;
    HBITMAP hbmNew1, hbmNew2;
    hbmNew1 = BM_CreateHFliped(hWnd, hbm, siz);
    hbmNew2 = NULL;
    if (hbmNew1 != NULL)
    {
        dwError = 0;
        hbmNew2 = BM_CreateXYSwaped(hWnd, hbmNew1, siz);
        if (hbmNew2 == NULL)
            dwError = GetLastError();
        DeleteObject(hbmNew1);
        SetLastError(dwError);
    }
    return hbmNew2;
}

HBITMAP BM_Copy(HBITMAP hbm)
{
    HBITMAP ret;
    
    ret = CopyImage(hbm, IMAGE_BITMAP, 0, 0, LR_COPYRETURNORG);
    return ret;
}

HGLOBAL BM_Pack(HBITMAP hbm)
{
    BOOL f;
    DWORD dwError;
    HGLOBAL hPack;
    BITMAPINFOEX bi;
    DWORD cb, cbPack, cColors, cbColors;
    HDC hDC;
    LPVOID pPack, pBits;
    BITMAP bm;
    BITMAPINFOHEADER *pbmih = &bi.bmiHeader;

    if (!GetObjectW(hbm, sizeof(BITMAP), &bm))
        return FALSE;

    ZeroMemory(pbmih, sizeof(BITMAPINFOHEADER));
    pbmih->biSize             = sizeof(BITMAPINFOHEADER);
    pbmih->biWidth            = bm.bmWidth;
    pbmih->biHeight           = bm.bmHeight;
    pbmih->biPlanes           = 1;
    pbmih->biBitCount         = bm.bmBitsPixel;
    pbmih->biCompression      = BI_RGB;
    pbmih->biSizeImage        = bm.bmWidthBytes * bm.bmHeight;

    if (bm.bmBitsPixel < 16)
        cColors = 1 << bm.bmBitsPixel;
    else
        cColors = 0;
    cbColors = cColors * sizeof(RGBQUAD);

    cb = pbmih->biSize + cbColors;
    cbPack = cb + pbmih->biSizeImage;

    hPack = GlobalAlloc(GMEM_DDESHARE|GHND, cbPack);
    pPack = GlobalLock(hPack);
    if (pPack == NULL)
        return NULL;

    f = FALSE;
    dwError = 0;
    pBits = HeapAlloc(GetProcessHeap(), 0, pbmih->biSizeImage);
    if (pBits != NULL)
    {
        hDC = GetDC(NULL);
        if (hDC != NULL)
        {
            if (GetDIBits(hDC, hbm, 0, bm.bmHeight, pBits, (BITMAPINFO*)&bi,
                DIB_RGB_COLORS))
            {
                CopyMemory(pPack, &bi, sizeof(BITMAPINFOHEADER));
                CopyMemory((LPBYTE)pPack + sizeof(BITMAPINFOHEADER), &bi.bmiColors, cbColors);
                CopyMemory((LPBYTE)pPack + cb, pBits, pbmih->biSizeImage);
                f = TRUE;
            }
            else
                dwError = GetLastError();
            ReleaseDC(NULL, hDC);
        }
        else
            dwError = GetLastError();

        HeapFree(GetProcessHeap(), 0, pBits);
    }

    GlobalUnlock(hPack);
    if (!f)
    {
        GlobalFree(hPack);
        hPack = NULL;
    }

    SetLastError(dwError);
    return hPack;
}

HBITMAP BM_Unpack(HGLOBAL hPack)
{
    HBITMAP hbm;
    DWORD dwError;
    BITMAPINFOEX bi;
    DWORD cb, cColors, cbColors;
    HDC hDC, hMemDC;
    LPVOID pPack, pBits;
    BITMAPINFOHEADER *pbmih = &bi.bmiHeader;

    pPack = GlobalLock(hPack);
    if (pPack == NULL)
        return NULL;

    CopyMemory(pbmih, pPack, sizeof(BITMAPINFOHEADER));
    pbmih->biSizeImage = WIDTHBYTES(pbmih->biWidth * pbmih->biBitCount) *
                         abs(pbmih->biHeight);
    if (pbmih->biClrUsed != 0)
        cColors = pbmih->biClrUsed;
    else if (pbmih->biBitCount < 16)
        cColors = 1 << pbmih->biBitCount;
    else
        cColors = 0;

    cbColors = cColors * sizeof(RGBQUAD);
    cb = pbmih->biSize + cbColors;
    CopyMemory(&bi, pPack, cb);

    hbm = NULL;
    dwError = 0;
    hDC = GetDC(NULL);
    if (hDC != NULL)
    {
        hMemDC = CreateCompatibleDC(hDC);
        if (hMemDC != NULL)
        {
            hbm = CreateDIBSection(hMemDC, (BITMAPINFO*)&bi, DIB_RGB_COLORS,
                                   &pBits, NULL, 0);
            if (hbm != NULL)
            {
                CopyMemory(pBits, (LPBYTE)pPack + cb, pbmih->biSizeImage);

                if (SetDIBits(hMemDC, hbm, 0, abs(bi.bmiHeader.biHeight),
                              pBits, (BITMAPINFO*)&bi, DIB_RGB_COLORS))
                {
                    ;
                }
                else
                {
                    dwError = GetLastError();
                    DeleteObject(hbm);
                    hbm = NULL;
                }
            }
            else
                dwError = GetLastError();

            DeleteDC(hMemDC);
        }
        else
            dwError = GetLastError();
    }
    else
        dwError = GetLastError();

    GlobalUnlock(hPack);
    SetLastError(dwError);
    return hbm;
}

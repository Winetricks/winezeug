/*
 *  Paint (canvas.c)
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
#include <math.h>

#include "main.h"
#include "paint.h"
#include "resource.h"

static const WCHAR empty[] = {0};

VOID CanvasToImage(POINT *ppt)
{
    ppt->x = (ppt->x + Globals.xScrollPos - 4) / Globals.nZoom;
    ppt->y = (ppt->y + Globals.yScrollPos - 4) / Globals.nZoom;
}

VOID ImageToCanvas(POINT *ppt)
{
    ppt->x = ppt->x * Globals.nZoom + 4 - Globals.xScrollPos;
    ppt->y = ppt->y * Globals.nZoom + 4 - Globals.yScrollPos;
}

VOID ImageToCanvas2(POINT *ppt)
{
    ppt->x = ppt->x * Globals.nZoom + 4;
    ppt->y = ppt->y * Globals.nZoom + 4;
}

VOID NormalizeRect(RECT *prc)
{
    LONG n;

    if (prc->left > prc->right)
    {
        n = prc->left;
        prc->left = prc->right;
        prc->right = n;
    }
    if (prc->top > prc->bottom)
    {
        n = prc->top;
        prc->top = prc->bottom;
        prc->bottom = n;
    }
}

INT sgn(INT x)
{
    if (x > 0) return 1;
    if (x < 0) return -1;
    return 0;
}

VOID Regularize(POINT pt0, LPPOINT ppt1)
{
    INT cx = abs(ppt1->x - pt0.x);
    INT cy = abs(ppt1->y - pt0.y);
    INT m = min(cx, cy);
    ppt1->x = pt0.x + sgn(ppt1->x - pt0.x) * m;
    ppt1->y = pt0.y + sgn(ppt1->y - pt0.y) * m;
}

HBITMAP Selection_CreateBitmap(VOID)
{
    HDC hDC, hMemDC1, hMemDC2;
    HGDIOBJ hbmOld1, hbmOld2;
    HBITMAP hbmNew;
    SIZE siz;

    hbmNew = NULL;
    hDC = GetDC(Globals.hCanvasWnd);
    if (hDC != NULL)
    {
        hMemDC1 = CreateCompatibleDC(hDC);
        if (hMemDC1 != NULL)
        {
            hbmOld1 = SelectObject(hMemDC1, Globals.hbmImage);
            hMemDC2 = CreateCompatibleDC(hDC);
            if (hMemDC2 != NULL)
            {
                siz.cx = Globals.pt1.x - Globals.pt0.x;
                siz.cy = Globals.pt1.y - Globals.pt0.y;
                hbmNew = BM_Create(siz);
                if (hbmNew != NULL)
                {
                    hbmOld2 = SelectObject(hMemDC2, hbmNew);
                    BitBlt(hMemDC2, 0, 0, siz.cx, siz.cy,
                           hMemDC1, Globals.pt0.x, Globals.pt0.y,
                           SRCCOPY);
                    SelectObject(hMemDC1, hbmOld2);
                }
                DeleteDC(hMemDC2);
            }
            SelectObject(hMemDC1, hbmOld1);
        }
        ReleaseDC(Globals.hCanvasWnd, hDC);
    }

    return hbmNew;
}

VOID PrepareForUndo(VOID)
{
    Globals.fCanUndo = TRUE;
    if (Globals.hbmImageUndo != NULL)
        DeleteObject(Globals.hbmImageUndo);
    Globals.hbmImageUndo = BM_Copy(Globals.hbmImage);
    Globals.sizImageUndo = Globals.sizImage;
}

VOID Selection_TakeOff(VOID)
{
    HDC hDC, hMemDC1;
    HGDIOBJ hbmOld1;
    HBITMAP hbmNew;
    HBRUSH hbr;

    if (Globals.fSelect && Globals.hbmSelect == NULL)
    {
        hbmNew = Selection_CreateBitmap();
        hDC = GetDC(Globals.hCanvasWnd);
        if (hDC != NULL)
        {
            hMemDC1 = CreateCompatibleDC(hDC);
            if (hMemDC1 != NULL)
            {
                hbmOld1 = SelectObject(hMemDC1, Globals.hbmImage);
                hbr = CreateSolidBrush(Globals.rgbBack);
                FillRect(hMemDC1, (RECT*)&Globals.pt0, hbr);
                DeleteObject(hbr);
                SelectObject(hMemDC1, hbmOld1);
                DeleteDC(hMemDC1);
                Globals.fModified = TRUE;
            }
            ReleaseDC(Globals.hCanvasWnd, hDC);
        }
        Globals.hbmSelect = hbmNew;
    }
}

VOID Selection_Land(VOID)
{
    HDC hDC, hMemDC1, hMemDC2;
    HGDIOBJ hbmOld1, hbmOld2;

    if (Globals.fSelect && Globals.hbmSelect)
    {
        hDC = GetDC(Globals.hCanvasWnd);
        hMemDC1 = CreateCompatibleDC(hDC);
        if (hMemDC1 != NULL)
        {
            hbmOld1 = SelectObject(hMemDC1, Globals.hbmImage);
            hMemDC2 = CreateCompatibleDC(hDC);
            if (hMemDC2 != NULL)
            {
                hbmOld2 = SelectObject(hMemDC2, Globals.hbmSelect);
                BitBlt(hMemDC1, Globals.pt0.x, Globals.pt0.y,
                       Globals.pt1.x - Globals.pt0.x,
                       Globals.pt1.y - Globals.pt0.y,
                       hMemDC2, 0, 0, SRCCOPY);
                SelectObject(hMemDC1, hbmOld2);
                DeleteDC(hMemDC2);
            }
            SelectObject(hMemDC1, hbmOld1);
            DeleteDC(hMemDC1);
        }
        ReleaseDC(Globals.hCanvasWnd, hDC);
        DeleteObject(Globals.hbmSelect);
        Globals.hbmSelect = NULL;
    }
    Globals.fSelect = FALSE;
}

VOID DrawBrush(HDC hMemDC, INT x, INT y, COLORREF rgb)
{
    switch (Globals.iBrushType)
    {
    case 0:
        Ellipse(hMemDC, x - 3, y - 3, x + 4, y + 4);
        break;

    case 1:
        Ellipse(hMemDC, x - 2, y - 2, x + 2, y + 2);
        break;

    case 2:
        SetPixel(hMemDC, x, y, rgb);
        break;

    case 3:
        Rectangle(hMemDC, x - 4, y - 4, x + 4, y + 4);
        break;

    case 4:
        Rectangle(hMemDC, x - 2, y - 2, x + 3, y + 3);
        break;

    case 5:
        Rectangle(hMemDC, x - 1, y - 1, x + 1, y + 1);
        break;

    case 6:
        MoveToEx(hMemDC, x + 4, y - 4, NULL);
        LineTo(hMemDC, x - 4, y + 4);
        break;

    case 7:
        MoveToEx(hMemDC, x + 2, y - 2, NULL);
        LineTo(hMemDC, x - 3, y + 3);
        break;

    case 8:
        MoveToEx(hMemDC, x + 1, y - 1, NULL);
        LineTo(hMemDC, x - 1, y + 1);
        break;

    case 9:
        MoveToEx(hMemDC, x - 4, y - 4, NULL);
        LineTo(hMemDC, x + 4, y + 4);
        break;

    case 10:
        MoveToEx(hMemDC, x - 2, y - 2, NULL);
        LineTo(hMemDC, x + 3, y + 3);
        break;

    case 11:
        MoveToEx(hMemDC, x - 1, y - 1, NULL);
        LineTo(hMemDC, x + 1, y + 1);
        break;
    }
}

VOID CALLBACK ForeBrushDDAProc(INT x, INT y, LPARAM lParam)
{
    HBRUSH hbr;
    HPEN hPen;
    HGDIOBJ hbrOld, hpenOld;
    HDC hMemDC = (HDC)lParam;
    hPen = CreatePen(PS_SOLID, 0, Globals.rgbFore);
    hbr = CreateSolidBrush(Globals.rgbFore);
    hpenOld = SelectObject(hMemDC, hPen);
    hbrOld = SelectObject(hMemDC, hbr);
    DrawBrush(hMemDC, x, y, Globals.rgbFore);
    SelectObject(hMemDC, hpenOld);
    SelectObject(hMemDC, hbrOld);
    DeleteObject(hPen);
    DeleteObject(hbr);
}

VOID CALLBACK BackBrushDDAProc(INT x, INT y, LPARAM lParam)
{
    HBRUSH hbr;
    HPEN hPen;
    HGDIOBJ hbrOld, hpenOld;
    HDC hMemDC = (HDC)lParam;
    hPen = CreatePen(PS_SOLID, 0, Globals.rgbBack);
    hbr = CreateSolidBrush(Globals.rgbBack);
    hpenOld = SelectObject(hMemDC, hPen);
    hbrOld = SelectObject(hMemDC, hbr);
    DrawBrush(hMemDC, x, y, Globals.rgbBack);
    SelectObject(hMemDC, hpenOld);
    SelectObject(hMemDC, hbrOld);
    DeleteObject(hPen);
    DeleteObject(hbr);
}

VOID Canvas_DrawBuffer(HDC hDC)
{
    HDC hMemDC;
    HPEN hPen;
    HBRUSH hbr;
    HGDIOBJ hbmOld, hpenOld, hbrOld;

    switch(Globals.iToolSelect)
    {
    case TOOL_BOXSELECT:
        hMemDC = CreateCompatibleDC(hDC);
        if (hMemDC != NULL)
        {
            hbmOld = SelectObject(hMemDC, Globals.hbmSelect);
            BitBlt(hDC, Globals.pt0.x, Globals.pt0.y,
                   Globals.pt1.x - Globals.pt0.x,
                   Globals.pt1.y - Globals.pt0.y,
                   hMemDC, 0, 0, SRCCOPY);
            SelectObject(hMemDC, hbmOld);
            DeleteDC(hMemDC);
        }

        if (Globals.mode == MODE_CANVAS)
        {
            hPen = CreatePen(PS_DOT, 1, 0);
            hbr = (HBRUSH)GetStockObject(NULL_BRUSH);
            hbrOld = SelectObject(hDC, hbr);
            hpenOld = SelectObject(hDC, hPen);
            SetROP2(hDC, R2_XORPEN);
            Rectangle(hDC, Globals.pt0.x, Globals.pt0.y,
                      Globals.pt1.x, Globals.pt1.y);
            SetROP2(hDC, R2_COPYPEN);
            SelectObject(hDC, hbrOld);
            SelectObject(hDC, hpenOld);
            DeleteObject(hPen);
        }
        break;

    case TOOL_ERASER:
        {
            POINT pt;
            RECT rc;
            GetCursorPos(&pt);
            ScreenToClient(Globals.hCanvasWnd, &pt);
            CanvasToImage(&pt);
            rc.left = rc.top = 0;
            rc.right = Globals.sizImage.cx;
            rc.bottom = Globals.sizImage.cy;
            if (PtInRect(&rc, pt))
            {
                SelectObject(hDC, GetStockObject(WHITE_BRUSH));
                SelectObject(hDC, GetStockObject(BLACK_PEN));
                Rectangle(hDC,
                          pt.x - Globals.nEraserSize / 2,
                          pt.y - Globals.nEraserSize / 2,
                          pt.x + Globals.nEraserSize / 2,
                          pt.y + Globals.nEraserSize / 2);
            }
        }
        break;

    case TOOL_CURVE:
        hPen = CreatePen(PS_SOLID, Globals.nLineWidth, Globals.fSwapColor ?
                         Globals.rgbBack : Globals.rgbFore);
        hpenOld = SelectObject(hDC, hPen);
        PolyBezier(hDC, &Globals.pt0, 4);
        SelectObject(hDC, hpenOld);
        DeleteObject(hPen);
        break;

    case TOOL_POLYGON:
        Polyline(hDC, Globals.pPolyline, Globals.cPolyline);
        break;

    case TOOL_LINE:
        hPen = CreatePen(PS_SOLID, Globals.nLineWidth, Globals.fSwapColor ?
                         Globals.rgbBack : Globals.rgbFore);
        hpenOld = SelectObject(hDC, hPen);
        MoveToEx(hDC, Globals.pt0.x, Globals.pt0.y, NULL);
        LineTo(hDC, Globals.pt1.x, Globals.pt1.y);
        SetPixel(hDC, Globals.pt1.x, Globals.pt1.y, Globals.fSwapColor ?
                 Globals.rgbBack : Globals.rgbFore);
        SelectObject(hDC, hpenOld);
        DeleteObject(hPen);
        break;

    case TOOL_BRUSH:
        if (Globals.fSwapColor)
            BackBrushDDAProc(Globals.pt0.x, Globals.pt0.y, (LPARAM)hDC);
        else
            ForeBrushDDAProc(Globals.pt0.x, Globals.pt0.y, (LPARAM)hDC);
        break;

    case TOOL_BOX:
    case TOOL_ELLIPSE:
    case TOOL_ROUNDRECT:
        if (Globals.fSwapColor)
        {
            switch (Globals.iFillStyle)
            {
            case 0:
                hPen = CreatePen(PS_SOLID, Globals.nLineWidth,
                                 Globals.rgbBack);
                hbr = (HBRUSH)GetStockObject(NULL_BRUSH);
                break;

            case 1:
                hPen = CreatePen(PS_SOLID, Globals.nLineWidth,
                                 Globals.rgbBack);
                hbr = CreateSolidBrush(Globals.rgbFore);
                break;

            default:
                hPen = CreatePen(PS_SOLID, Globals.nLineWidth,
                                 Globals.rgbBack);
                hbr = CreateSolidBrush(Globals.rgbBack);
            }
        }
        else
        {
            switch (Globals.iFillStyle)
            {
            case 0:
                hPen = CreatePen(PS_SOLID, Globals.nLineWidth,
                                 Globals.rgbFore);
                hbr = (HBRUSH)GetStockObject(NULL_BRUSH);
                break;

            case 1:
                hPen = CreatePen(PS_SOLID, Globals.nLineWidth,
                                 Globals.rgbFore);
                hbr = CreateSolidBrush(Globals.rgbBack);
                break;

            default:
                hPen = CreatePen(PS_SOLID, Globals.nLineWidth,
                                 Globals.rgbFore);
                hbr = CreateSolidBrush(Globals.rgbFore);
            }
        }
        hpenOld = SelectObject(hDC, hPen);
        hbrOld = SelectObject(hDC, hbr);
        if (GetKeyState(VK_SHIFT) < 0)
            Regularize(Globals.pt0, &Globals.pt1);
        switch(Globals.iToolSelect)
        {
        case TOOL_BOX:
            Rectangle(hDC, Globals.pt0.x, Globals.pt0.y, Globals.pt1.x, Globals.pt1.y);
            break;

        case TOOL_ELLIPSE:
            Ellipse(hDC, Globals.pt0.x, Globals.pt0.y, Globals.pt1.x, Globals.pt1.y);
            break;

        default:
            RoundRect(hDC, Globals.pt0.x, Globals.pt0.y, Globals.pt1.x, Globals.pt1.y, 16, 16);
        }
        SelectObject(hDC, hpenOld);
        SelectObject(hDC, hbrOld);
        DeleteObject(hPen);
        DeleteObject(hbr);
        break;

    case TOOL_MAGNIFIER:
        if (Globals.nZoom == 1)
        {
            POINT pt, pt0, pt1;
            RECT rc;
            GetCursorPos(&pt);
            ScreenToClient(Globals.hCanvasWnd, &pt);
            CanvasToImage(&pt);
            rc.left = rc.top = 0;
            rc.right = Globals.sizImage.cx;
            rc.bottom = Globals.sizImage.cy;
            if (PtInRect(&rc, pt))
            {
                GetClientRect(Globals.hCanvasWnd, &rc);
                hPen = CreatePen(PS_SOLID, 1, RGB(255, 255, 255));
                hbr = (HBRUSH)GetStockObject(NULL_BRUSH);
                hbrOld = SelectObject(hDC, hbr);
                hpenOld = SelectObject(hDC, hPen);
                SetROP2(hDC, R2_XORPEN);

                pt0.x = pt.x - (rc.right - rc.left) / 4 / 2;
                if (pt0.x < 0)
                    pt0.x = 0;
                if (pt.x + (rc.right - rc.left) / 4 / 2 > Globals.sizImage.cx)
                    pt0.x = Globals.sizImage.cx - (rc.right - rc.left) / 4;
                if (pt0.x < 0)
                {
                    pt0.x = 0;
                    pt1.x = Globals.sizImage.cx;
                }
                else
                {
                    pt1.x = pt0.x + (rc.right - rc.left) / 4;
                }

                pt0.y = pt.y - (rc.bottom - rc.top) / 4 / 2;
                if (pt0.y < 0)
                    pt0.y = 0;
                if (pt.y + (rc.bottom - rc.top) / 4 / 2 > Globals.sizImage.cy)
                    pt0.y = Globals.sizImage.cy - (rc.bottom - rc.top) / 4;
                if (pt0.y < 0)
                {
                    pt0.y = 0;
                    pt1.y = Globals.sizImage.cy;
                }
                else
                {
                    pt1.y = pt0.y + (rc.bottom - rc.top) / 4;
                }

                Rectangle(hDC, pt0.x, pt0.y, pt1.x, pt1.y);
                SetROP2(hDC, R2_COPYPEN);
                SelectObject(hDC, hbrOld);
                SelectObject(hDC, hpenOld);
                DeleteObject(hPen);
            }
        }
        break;

    default:
        break;
    }
}

VOID Canvas_OnPaint(HWND hWnd, HDC hDC)
{
    HBRUSH hbr;
    HGDIOBJ hbmOld1, hbmOld2, hpenOld, hbrOld;
    HDC hMemDC1, hMemDC2;
    RECT rc;
    INT x, y;

    SetWindowOrgEx(hDC, Globals.xScrollPos, Globals.yScrollPos, NULL);

    hMemDC1 = CreateCompatibleDC(hDC);
    if (hMemDC1 != NULL)
    {
        hMemDC2 = CreateCompatibleDC(hDC);
        if (hMemDC2 != NULL)
        {
            hbmOld1 = SelectObject(hMemDC1, Globals.hbmImage);
            hbmOld2 = SelectObject(hMemDC2, Globals.hbmBuffer);
            BitBlt(hMemDC2, 0, 0, Globals.sizImage.cx, Globals.sizImage.cy,
                   hMemDC1, 0, 0, SRCCOPY);
            SelectObject(hMemDC1, hbmOld1);
            Canvas_DrawBuffer(hMemDC2);

            /* FIXME: speed up by smaller buffer */
            hbmOld1 = SelectObject(hMemDC1, Globals.hbmZoomBuffer);
            SetStretchBltMode(hDC, COLORONCOLOR);
            StretchBlt(hMemDC1, 0, 0, Globals.sizImage.cx * Globals.nZoom,
                       Globals.sizImage.cy * Globals.nZoom, hMemDC2,
                       0, 0, Globals.sizImage.cx, Globals.sizImage.cy, SRCCOPY);
            SelectObject(hMemDC2, hbmOld2);

            if (Globals.fShowGrid && Globals.nZoom >= 3)
            {
                LOGBRUSH lb;
                HPEN hPen1, hPen2;
                hPen1 = CreatePen(PS_SOLID, 1, RGB(192, 192, 192));
                hpenOld = SelectObject(hMemDC1, hPen1);
                for (x = 0; x < Globals.sizImage.cx; x++)
                {
                    MoveToEx(hMemDC1, x * Globals.nZoom, 0, NULL);
                    LineTo(hMemDC1, x * Globals.nZoom,
                           Globals.sizImage.cy * Globals.nZoom);
                }
                for (y = 0; y < Globals.sizImage.cy; y++)
                {
                    MoveToEx(hMemDC1, 0, y * Globals.nZoom, NULL);
                    LineTo(hMemDC1, Globals.sizImage.cx * Globals.nZoom,
                           y * Globals.nZoom);
                }
                lb.lbColor = RGB(128, 128, 128);
                lb.lbStyle = BS_SOLID;
                hPen2 = ExtCreatePen(PS_COSMETIC|PS_ALTERNATE|PS_ENDCAP_SQUARE|PS_JOIN_BEVEL, 1, &lb, 0, NULL);
                SelectObject(hMemDC1, hPen2);
                for (x = 0; x < Globals.sizImage.cx; x++)
                {
                    MoveToEx(hMemDC1, x * Globals.nZoom, 0, NULL);
                    LineTo(hMemDC1, x * Globals.nZoom,
                           Globals.sizImage.cy * Globals.nZoom);
                }
                for (y = 0; y < Globals.sizImage.cy; y++)
                {
                    MoveToEx(hMemDC1, 0, y * Globals.nZoom, NULL);
                    LineTo(hMemDC1, Globals.sizImage.cx * Globals.nZoom,
                           y * Globals.nZoom);
                }
                SelectObject(hMemDC1, hpenOld);
                DeleteObject(hPen1);
                DeleteObject(hPen2);
            }

            if (GetSysColor(COLOR_3DFACE) == RGB(0, 0, 0))
                hbr = CreateSolidBrush(RGB(0, 0, 0));
            else
                hbr = CreateSolidBrush(RGB(123, 125, 123));

            hbmOld2 = SelectObject(hMemDC2, Globals.hbmCanvasBuffer);
            GetClientRect(hWnd, &rc);
            FillRect(hMemDC2, &rc, hbr);
            DeleteObject(hbr);
            BitBlt(hMemDC2, 4 - Globals.xScrollPos, 4 - Globals.yScrollPos,
                   Globals.sizImage.cx * Globals.nZoom,
                   Globals.sizImage.cy * Globals.nZoom,
                   hMemDC1, 0, 0, SRCCOPY);
            SelectObject(hMemDC1, hbmOld1);

            if (Globals.fSelect && Globals.mode == MODE_NORMAL)
            {
                POINT pt0, pt1;
                HPEN hPen = CreatePen(PS_DOT, 1, GetSysColor(COLOR_HIGHLIGHT));
                hbr = (HBRUSH)GetStockObject(NULL_BRUSH);
                hbrOld = SelectObject(hMemDC2, hbr);
                hpenOld = SelectObject(hMemDC2, hPen);
                pt0 = Globals.pt0;
                ImageToCanvas2(&pt0);
                pt1 = Globals.pt1;
                ImageToCanvas2(&pt1);
                Rectangle(hMemDC2,
                    pt0.x - Globals.xScrollPos, pt0.y - Globals.yScrollPos,
                    pt1.x - Globals.xScrollPos, pt1.y - Globals.yScrollPos);
                SelectObject(hMemDC2, hbrOld);
                SelectObject(hMemDC2, hpenOld);
                DeleteObject(hPen);
            }

            BitBlt(hDC, Globals.xScrollPos, Globals.yScrollPos,
                   Globals.sizCanvas.cx, Globals.sizCanvas.cy,
                   hMemDC2, 0, 0, SRCCOPY);
            SelectObject(hMemDC2, hbmOld2);
        }
    }

    if (!Globals.fSelect)
    {
        rc.left = 0;
        rc.top = 0;
        rc.right = rc.left + 3;
        rc.bottom = rc.top + 3;
        FillRect(hDC, &rc, (HBRUSH)GetStockObject(WHITE_BRUSH));
        rc.left = 4 + Globals.sizImage.cx * Globals.nZoom / 2 - 2;
        rc.top = 0;
        rc.right = rc.left + 3;
        rc.bottom = rc.top + 3;
        FillRect(hDC, &rc, (HBRUSH)GetStockObject(WHITE_BRUSH));
        rc.left = 0;
        rc.top = 4 + Globals.sizImage.cy * Globals.nZoom / 2 - 2;
        rc.right = rc.left + 3;
        rc.bottom = rc.top + 3;
        FillRect(hDC, &rc, (HBRUSH)GetStockObject(WHITE_BRUSH));
        rc.left = 0;
        rc.top = 4 + Globals.sizImage.cy * Globals.nZoom + 1;
        rc.right = rc.left + 3;
        rc.bottom = rc.top + 3;
        FillRect(hDC, &rc, (HBRUSH)GetStockObject(WHITE_BRUSH));
        rc.left = 4 + Globals.sizImage.cx * Globals.nZoom + 1;
        rc.top = 0;
        rc.right = rc.left + 3;
        rc.bottom = rc.top + 3;
        FillRect(hDC, &rc, (HBRUSH)GetStockObject(WHITE_BRUSH));

        hbr = CreateSolidBrush(GetSysColor(COLOR_HIGHLIGHT));
        rc.left = 4 + Globals.sizImage.cx * Globals.nZoom + 1;
        rc.top = 4 + Globals.sizImage.cy * Globals.nZoom / 2 - 2;
        rc.right = rc.left + 3;
        rc.bottom = rc.top + 3;
        FillRect(hDC, &rc, hbr);
        rc.left = 4 + Globals.sizImage.cx * Globals.nZoom / 2 - 2;
        rc.top = 4 + Globals.sizImage.cy * Globals.nZoom + 1;
        rc.right = rc.left + 3;
        rc.bottom = rc.top + 3;
        FillRect(hDC, &rc, hbr);
        rc.left = 4 + Globals.sizImage.cx * Globals.nZoom + 1;
        rc.top = 4 + Globals.sizImage.cy * Globals.nZoom + 1;
        rc.right = rc.left + 3;
        rc.bottom = rc.top + 3;
        FillRect(hDC, &rc, hbr);
        DeleteObject(hbr);
    }
}

VOID Canvas_OnButtonDown(HWND hWnd, INT x, INT y, BOOL fRight)
{
    POINT pt, pt0;
    RECT rc;
    HDC hDC, hMemDC;
    HGDIOBJ hbmOld, hbrOld;
    HBRUSH hbr;
    pt.x = x;
    pt.y = y;

    if (!fRight)
    {
        rc.left = 4 + Globals.sizImage.cx * Globals.nZoom + 1 - Globals.xScrollPos;
        rc.top = 4 + Globals.sizImage.cy * Globals.nZoom / 2 - 2 - Globals.yScrollPos;
        rc.right = rc.left + 3;
        rc.bottom = rc.top + 3;
        if (PtInRect(&rc, pt))
        {
            SetCursor(Globals.hcurHorizontal);
            Globals.mode = MODE_RIGHT_EDGE;
            SetCapture(hWnd);
            Globals.pt0 = pt;
            SetRectEmpty((RECT*)&Globals.pt0);
            return;
        }

        rc.left = 4 + Globals.sizImage.cx * Globals.nZoom / 2 - 2 - Globals.xScrollPos;
        rc.top = 4 + Globals.sizImage.cy * Globals.nZoom + 1 - Globals.yScrollPos;
        rc.right = rc.left + 3;
        rc.bottom = rc.top + 3;
        if (PtInRect(&rc, pt))
        {
            SetCursor(Globals.hcurVertical);
            Globals.mode = MODE_DOWN_EDGE;
            SetCapture(hWnd);
            Globals.pt0 = pt;
            SetRectEmpty((RECT*)&Globals.pt0);
            return;
        }

        rc.left = 4 + Globals.sizImage.cx * Globals.nZoom + 1 - Globals.xScrollPos;
        rc.top = 4 + Globals.sizImage.cy * Globals.nZoom + 1 - Globals.yScrollPos;
        rc.right = rc.left + 3;
        rc.bottom = rc.top + 3;
        if (PtInRect(&rc, pt))
        {
            SetCursor(Globals.hcurBDiagonal);
            Globals.mode = MODE_LOWER_RIGHT_EDGE;
            SetCapture(hWnd);
            Globals.pt0 = pt;
            SetRectEmpty((RECT*)&Globals.pt0);
            return;
        }
    }

    rc.left = 4;
    rc.top = 4;
    rc.right = 4 + Globals.sizImage.cx * Globals.nZoom;
    rc.bottom = 4 + Globals.sizImage.cy * Globals.nZoom;

    if (PtInRect(&rc, pt))
    {
        switch (Globals.iToolSelect)
        {
        case TOOL_MAGNIFIER:
            CanvasToImage(&pt);
            GetClientRect(hWnd, &rc);

            pt0.x = pt.x - (rc.right - rc.left) / 4 / 2;
            if (pt0.x < 0)
                pt0.x = 0;
            if (pt.x + (rc.right - rc.left) / 4 / 2 > Globals.sizImage.cx)
                pt0.x = Globals.sizImage.cx - (rc.right - rc.left) / 4;
            if (pt0.x < 0)
            {
                pt0.x = 0;
            }

            pt0.y = pt.y - (rc.bottom - rc.top) / 4 / 2;
            if (pt0.y < 0)
                pt0.y = 0;
            if (pt.y + (rc.bottom - rc.top) / 4 / 2 > Globals.sizImage.cy)
                pt0.y = Globals.sizImage.cy - (rc.bottom - rc.top) / 4;
            if (pt0.y < 0)
            {
                pt0.y = 0;
            }
            Globals.iToolSelect = Globals.iToolPrev;
            Globals.iToolClicking = -1;
            Globals.ipt = 0;
            if (Globals.pPolyline != NULL)
                HeapFree(GetProcessHeap(), 0, Globals.pPolyline);
            Globals.pPolyline = NULL;
            Globals.cPolyline = 0;
            InvalidateRect(Globals.hToolBox, NULL, TRUE);
            UpdateWindow(Globals.hToolBox);

            if (Globals.nZoom == 1)
            {
                if (rc.right - rc.left < Globals.sizImage.cx) pt.x = 0;
                if (rc.bottom - rc.top < Globals.sizImage.cy) pt.y = 0;
                PAINT_Zoom2(pt0.x, pt0.y, 4);
            }
            else
                PAINT_Zoom(1);
            break;

        case TOOL_BOXSELECT:
            if (fRight)
            {
                HMENU hMenu, hSubMenu;
                Globals.mode = MODE_NORMAL;
                ReleaseCapture();
                hMenu = LoadMenuW(Globals.hInstance, (LPCWSTR)SELECTION_MENU);
                hSubMenu = GetSubMenu(hMenu, 0);
                GetCursorPos(&pt);

                SetForegroundWindow(Globals.hMainWnd);
                TrackPopupMenu(hSubMenu, TPM_LEFTALIGN|TPM_RIGHTBUTTON,
                               pt.x, pt.y, 0, Globals.hMainWnd, NULL);
                PostMessageW(Globals.hMainWnd, WM_NULL, 0, 0);
                DestroyMenu(hMenu);
            }
            else
            {
                CanvasToImage(&pt);
                if (Globals.fSelect)
                {
                    if (PtInRect((RECT*)&Globals.pt0, pt))
                    {
                        SetCursor(Globals.hcurMove);
                        Globals.mode = MODE_SELECTION;
                        SetCapture(hWnd);
                        NormalizeRect((RECT*)&Globals.pt0);
                        Globals.pt2.x = pt.x - Globals.pt0.x;
                        Globals.pt2.y = pt.y - Globals.pt0.y;
                        PrepareForUndo();
                        Selection_TakeOff();
                        InvalidateRect(hWnd, NULL, TRUE);
                        UpdateWindow(hWnd);
                    }
                    else
                    {
                        SetCursor(Globals.hcurCross2);
                        Globals.mode = MODE_CANVAS;
                        SetCapture(hWnd);
                        Selection_Land();
                        Globals.fSelect = FALSE;
                        Globals.pt0 = Globals.pt1 = pt;
                    }
                }
                else
                {
                    SetCursor(Globals.hcurCross2);
                    Globals.mode = MODE_CANVAS;
                    SetCapture(hWnd);
                    Globals.fSelect = FALSE;
                    Globals.pt0 = Globals.pt1 = pt;
                }
            }
            break;

        case TOOL_ERASER:
            if (!fRight)
            {
                Globals.mode = MODE_CANVAS;
                SetCapture(hWnd);
                SetCursor(NULL);
                CanvasToImage(&pt);
                PrepareForUndo();
                hDC = GetDC(hWnd);
                if (hDC != NULL)
                {
                    hMemDC = CreateCompatibleDC(hDC);
                    if (hMemDC != NULL)
                    {
                        hbmOld = SelectObject(hMemDC, Globals.hbmImage);
                        rc.left = pt.x - Globals.nEraserSize / 2;
                        rc.top = pt.y - Globals.nEraserSize / 2;
                        rc.right = rc.left + Globals.nEraserSize;
                        rc.bottom = rc.top + Globals.nEraserSize;
                        hbr = CreateSolidBrush(Globals.rgbBack);
                        FillRect(hMemDC, &rc, hbr);
                        DeleteObject(hbr);
                        SelectObject(hMemDC, hbmOld);
                        DeleteDC(hMemDC);
                        Globals.fModified = TRUE;
                    }
                    ReleaseDC(hWnd, hDC);
                }
                Globals.pt0 = pt;
            }
            break;

        case TOOL_BRUSH:
            SetCursor(Globals.hcurCross);
            Globals.mode = MODE_CANVAS;
            SetCapture(hWnd);
            CanvasToImage(&pt);
            PrepareForUndo();
            hDC = GetDC(hWnd);
            hMemDC = CreateCompatibleDC(hDC);
            if (hMemDC != NULL)
            {
                hbmOld = SelectObject(hMemDC, Globals.hbmImage);
                if (fRight)
                    BackBrushDDAProc(pt.x, pt.y, (LPARAM)hMemDC);
                else
                    ForeBrushDDAProc(pt.x, pt.y, (LPARAM)hMemDC);
                SelectObject(hMemDC, hbmOld);
                DeleteDC(hMemDC);
                Globals.fModified = TRUE;
            }
            ReleaseDC(hWnd, hDC);
            Globals.pt0 = pt;
            break;

        case TOOL_FILL:
            SetCursor(Globals.hcurFill);
            CanvasToImage(&pt);
            PrepareForUndo();
            hDC = GetDC(hWnd);
            hMemDC = CreateCompatibleDC(hDC);
            if (hMemDC != NULL)
            {
                hbr = CreateSolidBrush(fRight ? Globals.rgbBack :
                                              Globals.rgbFore);
                hbmOld = SelectObject(hMemDC, Globals.hbmImage);
                hbrOld = SelectObject(hMemDC, hbr);
                ExtFloodFill(hMemDC, pt.x, pt.y,
                             GetPixel(hMemDC, pt.x, pt.y),
                             FLOODFILLSURFACE);
                SelectObject(hMemDC, hbrOld);
                SelectObject(hMemDC, hbmOld);
                DeleteObject(hbr);
                DeleteDC(hMemDC);
                Globals.fModified = TRUE;
            }
            ReleaseDC(hWnd, hDC);
            InvalidateRect(hWnd, NULL, FALSE);
            UpdateWindow(hWnd);
            break;

        case TOOL_PENCIL:
            SetCursor(Globals.hcurPencil);
            Globals.mode = MODE_CANVAS;
            SetCapture(hWnd);
            CanvasToImage(&pt);
            PrepareForUndo();
            hDC = GetDC(hWnd);
            hMemDC = CreateCompatibleDC(hDC);
            if (hMemDC != NULL)
            {
                hbmOld = SelectObject(hMemDC, Globals.hbmImage);
                SetPixelV(hMemDC, pt.x, pt.y,
                          fRight ? Globals.rgbBack : Globals.rgbFore);
                SelectObject(hMemDC, hbmOld);
                DeleteDC(hMemDC);
                Globals.fModified = TRUE;
            }
            ReleaseDC(hWnd, hDC);
            InvalidateRect(hWnd, NULL, FALSE);
            UpdateWindow(hWnd);
            Globals.pt0 = pt;
            break;

        case TOOL_AIRBRUSH:
            SetCursor(Globals.hcurAirBrush);
            Globals.mode = MODE_CANVAS;
            SetCapture(hWnd);
            PrepareForUndo();
            KillTimer(hWnd, Globals.idTimer);
            Globals.idTimer = SetTimer(hWnd, 1, 30, NULL);
            Globals.fModified = TRUE;
            break;

        case TOOL_SPOIT:
            SetCursor(Globals.hcurSpoit);
            Globals.mode = MODE_CANVAS;
            SetCapture(hWnd);
            CanvasToImage(&pt);
            hDC = GetDC(hWnd);
            if (hDC != NULL)
            {
                hMemDC = CreateCompatibleDC(hDC);
                if (hMemDC != NULL)
                {
                    hbmOld = SelectObject(hMemDC, Globals.hbmImage);
                    Globals.rgbSpoit = GetPixel(hMemDC, pt.x, pt.y);
                    SelectObject(hMemDC, hbmOld);
                    DeleteDC(hMemDC);
                }
                ReleaseDC(hWnd, hDC);
            }
            InvalidateRect(Globals.hToolBox, NULL, FALSE);
            UpdateWindow(Globals.hToolBox);
            break;

        case TOOL_POLYGON:
            SetCursor(Globals.hcurCross2);
            Globals.mode = MODE_CANVAS;
            SetCapture(hWnd);
            CanvasToImage(&pt);
            if (Globals.cPolyline == 0)
            {
                Globals.cPolyline = 2;
                Globals.pPolyline = (POINT*)HeapAlloc(GetProcessHeap(), 0,
                                                      2 * sizeof(POINT));

                Globals.pPolyline[0] = Globals.pPolyline[1] = pt;
            }
            else
            {
                DWORD cb;
                Globals.cPolyline++;
                cb = Globals.cPolyline * sizeof(POINT);
                Globals.pPolyline = (POINT*)HeapReAlloc(GetProcessHeap(), 0,
                                                        Globals.pPolyline, cb);
                Globals.pPolyline[Globals.cPolyline - 1] = pt;
            }
            InvalidateRect(hWnd, NULL, FALSE);
            UpdateWindow(hWnd);
            break;

        case TOOL_CURVE:
            SetCursor(Globals.hcurCross2);
            Globals.mode = MODE_CANVAS;
            SetCapture(hWnd);
            CanvasToImage(&pt);
            switch (Globals.ipt)
            {
            case 0:
                Globals.pt0 = Globals.pt1 = Globals.pt2 = Globals.pt3 = pt;
                Globals.ipt = 1;
                break;

            case 1:
                Globals.pt2 = Globals.pt3 = pt;
                break;

            case 2:
                Globals.pt1 = pt;
                break;

            case 3:
                Globals.pt2 = pt;
                break;
            }
            InvalidateRect(hWnd, NULL, FALSE);
            UpdateWindow(hWnd);
            break;

        case TOOL_LINE:
        case TOOL_BOX:
        case TOOL_ELLIPSE:
        case TOOL_ROUNDRECT:
            SetCursor(Globals.hcurCross2);
            Globals.mode = MODE_CANVAS;
            SetCapture(hWnd);
            CanvasToImage(&pt);
            Globals.pt0 = Globals.pt1 = pt;
            break;

        default:
            break;
        }
    }
    else
    {
        if (Globals.iToolSelect == TOOL_BOXSELECT)
        {
            CanvasToImage(&pt);
            if (Globals.fSelect && PtInRect((RECT*)&Globals.pt0, pt))
            {
                SetCursor(Globals.hcurMove);
                NormalizeRect((RECT*)&Globals.pt0);
                Globals.pt2.x = pt.x - Globals.pt0.x;
                Globals.pt2.y = pt.y - Globals.pt0.y;
                Selection_TakeOff();
                SetCapture(hWnd);
                Globals.mode = MODE_SELECTION;
                InvalidateRect(hWnd, NULL, TRUE);
                UpdateWindow(hWnd);
            }
            else
            {
                SetCursor(Globals.hcurCross2);
                Selection_Land();
                Globals.fSelect = FALSE;
            }
        }
    }
}

VOID CALLBACK EraserDDAProc(INT x, INT y, LPARAM lParam)
{
    RECT rc;
    HDC hMemDC = (HDC)lParam;
    HBRUSH hbr;
    rc.left = x - Globals.nEraserSize / 2;
    rc.top = y - Globals.nEraserSize / 2;
    rc.right = rc.left + Globals.nEraserSize;
    rc.bottom = rc.top + Globals.nEraserSize;
    hbr = CreateSolidBrush(Globals.rgbBack);
    FillRect(hMemDC, &rc, hbr);
    DeleteObject(hbr);
}

VOID ShowPos(POINT pt)
{
    WCHAR sz[64];
    static const WCHAR format[] = {'%','d',',','%','d',0};
    wsprintfW(sz, format, pt.x, pt.y);
    SendMessageW(Globals.hStatusBar, SB_SETTEXTW, 1 | 0, (LPARAM)sz);
}

VOID ShowSize(INT cx, INT cy)
{
    WCHAR sz[64];
    static const WCHAR format[] = {'%','d','x','%','d',0};
    wsprintfW(sz, format, cx, cy);
    SendMessageW(Globals.hStatusBar, SB_SETTEXTW, 2 | 0, (LPARAM)sz);
}

VOID ShowNoSize(VOID)
{
    SendMessageW(Globals.hStatusBar, SB_SETTEXTW, 2 | 0, (LPARAM)empty);
}

VOID Canvas_OnMouseMove(HWND hWnd, INT x, INT y, BOOL fLeftDown, BOOL fRightDown)
{
    POINT pt;
    RECT rc;
    HDC hDC, hMemDC;
    WCHAR sz[256];
    pt.x = x;
    pt.y = y;

    LoadStringW(Globals.hInstance, STRING_READY, sz, 256);
    SendMessageW(Globals.hStatusBar, SB_SETTEXTW, 0 | 0, (LPARAM)sz);

    if (fLeftDown)
    {
        rc.left = 4;
        rc.top = 4;
        Globals.fSwapColor = FALSE;
        switch (Globals.mode)
        {
        case MODE_RIGHT_EDGE:
            SetCursor(Globals.hcurHorizontal);
            CanvasToImage(&pt);
            ShowSize(pt.x, Globals.sizImage.cy);
            ImageToCanvas(&pt);
            rc.right = pt.x;
            rc.bottom = Globals.sizImage.cy * Globals.nZoom + 4;
            InvalidateRect(hWnd, NULL, FALSE);
            UpdateWindow(hWnd);
            hDC = GetDC(hWnd);
            if (hDC != NULL)
            {
                DrawFocusRect(hDC, &rc);
                ReleaseDC(hWnd, hDC);
            }
            break;

        case MODE_DOWN_EDGE:
            SetCursor(Globals.hcurVertical);
            CanvasToImage(&pt);
            ShowSize(Globals.sizImage.cx, pt.y);
            ImageToCanvas(&pt);
            rc.right = Globals.sizImage.cx * Globals.nZoom + 4;
            rc.bottom = pt.y;
            InvalidateRect(hWnd, NULL, FALSE);
            UpdateWindow(hWnd);
            hDC = GetDC(hWnd);
            if (hDC != NULL)
            {
                DrawFocusRect(hDC, &rc);
                ReleaseDC(hWnd, hDC);
            }
            break;

        case MODE_LOWER_RIGHT_EDGE:
            SetCursor(Globals.hcurBDiagonal);
            CanvasToImage(&pt);
            ShowSize(pt.x, pt.y);
            ImageToCanvas(&pt);
            rc.right = pt.x;
            rc.bottom = pt.y;
            InvalidateRect(hWnd, NULL, FALSE);
            UpdateWindow(hWnd);
            hDC = GetDC(hWnd);
            if (hDC != NULL)
            {
                DrawFocusRect(hDC, &rc);
                ReleaseDC(hWnd, hDC);
            }
            break;

        case MODE_SELECTION:
            SetCursor(Globals.hcurMove);
            CanvasToImage(&pt);
            ShowPos(pt);
            ShowNoSize();
            OffsetRect((RECT*)&Globals.pt0,
                       pt.x - Globals.pt0.x - Globals.pt2.x,
                       pt.y - Globals.pt0.y - Globals.pt2.y);
            InvalidateRect(hWnd, NULL, FALSE);
            UpdateWindow(hWnd);
            break;

        case MODE_CANVAS:
            switch (Globals.iToolSelect)
            {
            case TOOL_BOXSELECT:
                SetCursor(Globals.hcurCross2);
                CanvasToImage(&pt);
                Globals.pt1 = pt;
                ShowSize(Globals.pt1.x - Globals.pt0.x,
                         Globals.pt1.y - Globals.pt0.x);
                InvalidateRect(hWnd, NULL, FALSE);
                UpdateWindow(hWnd);
                break;

            case TOOL_BRUSH:
                SetCursor(Globals.hcurCross);
                CanvasToImage(&pt);
                hDC = GetDC(hWnd);
                if (hDC != NULL)
                {
                    hMemDC = CreateCompatibleDC(hDC);
                    if (hMemDC != NULL)
                    {
                        HGDIOBJ hbmOld = SelectObject(hMemDC, Globals.hbmImage);
                        LineDDA(Globals.pt0.x, Globals.pt0.y, pt.x, pt.y,
                                ForeBrushDDAProc, (LPARAM)hMemDC);
                        SelectObject(hMemDC, hbmOld);
                        DeleteDC(hMemDC);
                    }
                    ReleaseDC(hWnd, hDC);
                }
                Globals.pt0 = pt;
                ShowPos(pt);
                ShowNoSize();
                InvalidateRect(hWnd, NULL, FALSE);
                UpdateWindow(hWnd);
                break;

            case TOOL_ERASER:
                SetCursor(NULL);
                CanvasToImage(&pt);
                hDC = GetDC(hWnd);
                if (hDC != NULL)
                {
                    hMemDC = CreateCompatibleDC(hDC);
                    if (hMemDC != NULL)
                    {
                        HGDIOBJ hbmOld = SelectObject(hMemDC, Globals.hbmImage);
                        LineDDA(Globals.pt0.x, Globals.pt0.y, pt.x, pt.y,
                                EraserDDAProc, (LPARAM)hMemDC);
                        SelectObject(hMemDC, hbmOld);
                        DeleteDC(hMemDC);
                        Globals.fModified = TRUE;
                    }
                    ReleaseDC(hWnd, hDC);
                }
                Globals.pt0 = pt;
                ShowPos(pt);
                ShowNoSize();
                InvalidateRect(hWnd, NULL, FALSE);
                UpdateWindow(hWnd);
                break;

            case TOOL_POLYGON:
                SetCursor(Globals.hcurCross2);
                CanvasToImage(&pt);
                Globals.pPolyline[Globals.cPolyline - 1] = pt;
                InvalidateRect(hWnd, NULL, FALSE);
                UpdateWindow(hWnd);
                break;

            case TOOL_CURVE:
                SetCursor(Globals.hcurCross2);
                CanvasToImage(&pt);
                if (Globals.ipt == 1)
                {
                    Globals.pt2 = Globals.pt3 = pt;
                }
                else if (Globals.ipt == 2)
                {
                    Globals.pt1 = pt;
                }
                else if (Globals.ipt == 3)
                {
                    Globals.pt2 = pt;
                }
                InvalidateRect(hWnd, NULL, FALSE);
                UpdateWindow(hWnd);
                break;

            case TOOL_LINE:
                SetCursor(Globals.hcurCross2);
                CanvasToImage(&pt);
                Globals.pt1 = pt;
                ShowSize(Globals.pt1.x - Globals.pt0.x,
                         Globals.pt1.y - Globals.pt0.y);
                InvalidateRect(hWnd, NULL, FALSE);
                UpdateWindow(hWnd);
                break;

            case TOOL_BOX:
            case TOOL_ELLIPSE:
            case TOOL_ROUNDRECT:
                SetCursor(Globals.hcurCross2);
                CanvasToImage(&pt);
                Globals.pt1 = pt;
                ShowSize(Globals.pt1.x - Globals.pt0.x,
                         Globals.pt1.y - Globals.pt0.y);
                InvalidateRect(hWnd, NULL, FALSE);
                UpdateWindow(hWnd);
                break;

            case TOOL_SPOIT:
                SetCursor(Globals.hcurSpoit);
                CanvasToImage(&pt);
                ShowPos(pt);
                ShowNoSize();
                hDC = GetDC(hWnd);
                if (hDC != NULL)
                {
                    hMemDC = CreateCompatibleDC(hDC);
                    if (hMemDC != NULL)
                    {
                        HGDIOBJ hbmOld = SelectObject(hMemDC, Globals.hbmImage);
                        Globals.rgbSpoit = GetPixel(hMemDC, pt.x, pt.y);
                        SelectObject(hMemDC, hbmOld);
                        DeleteDC(hMemDC);
                    }
                    ReleaseDC(hWnd, hDC);
                }
                InvalidateRect(Globals.hToolBox, NULL, FALSE);
                UpdateWindow(Globals.hToolBox);
                break;

            case TOOL_PENCIL:
                SetCursor(Globals.hcurPencil);
                CanvasToImage(&pt);
                ShowPos(pt);
                ShowNoSize();
                hDC = GetDC(hWnd);
                hMemDC = CreateCompatibleDC(hDC);
                if (hMemDC != NULL)
                {
                    HPEN hPen = CreatePen(PS_SOLID, 0, Globals.rgbFore);
                    HGDIOBJ hbmOld = SelectObject(hMemDC, Globals.hbmImage);
                    HGDIOBJ hpenOld = SelectObject(hMemDC, hPen);
                    MoveToEx(hMemDC, Globals.pt0.x, Globals.pt0.y, NULL);
                    LineTo(hMemDC, pt.x, pt.y);
                    SetPixelV(hMemDC, pt.x, pt.y, Globals.rgbFore);
                    SelectObject(hMemDC, hbmOld);
                    SelectObject(hMemDC, hpenOld);
                    DeleteObject(hPen);
                    DeleteDC(hMemDC);
                    Globals.fModified = TRUE;
                }
                ReleaseDC(hWnd, hDC);
                Globals.pt0 = pt;
                InvalidateRect(hWnd, NULL, FALSE);
                UpdateWindow(hWnd);
                break;

            default:
                break;
            }
            break;

        default:
            break;
        }
    }
    else if (fRightDown)
    {
        Globals.fSwapColor = TRUE;
        if (Globals.mode == MODE_CANVAS)
        {
            switch (Globals.iToolSelect)
            {
            case TOOL_BRUSH:
                SetCursor(Globals.hcurCross);
                CanvasToImage(&pt);
                hDC = GetDC(hWnd);
                hMemDC = CreateCompatibleDC(hDC);
                if (hMemDC != NULL)
                {
                    HGDIOBJ hbmOld = SelectObject(hMemDC, Globals.hbmImage);
                    LineDDA(Globals.pt0.x, Globals.pt0.y, pt.x, pt.y,
                            BackBrushDDAProc, (LPARAM)hMemDC);
                    SelectObject(hMemDC, hbmOld);
                    DeleteDC(hMemDC);
                }
                ReleaseDC(hWnd, hDC);
                Globals.pt0 = pt;
                InvalidateRect(hWnd, NULL, FALSE);
                UpdateWindow(hWnd);
                break;

            case TOOL_POLYGON:
                SetCursor(Globals.hcurCross2);
                CanvasToImage(&pt);
                Globals.pPolyline[Globals.cPolyline - 1] = pt;
                InvalidateRect(hWnd, NULL, FALSE);
                UpdateWindow(hWnd);
                break;

            case TOOL_CURVE:
                SetCursor(Globals.hcurCross2);
                CanvasToImage(&pt);
                if (Globals.ipt == 1)
                {
                    Globals.pt2 = Globals.pt3 = pt;
                }
                else if (Globals.ipt == 2)
                {
                    Globals.pt1 = pt;
                }
                else if (Globals.ipt == 3)
                {
                    Globals.pt2 = pt;
                }
                InvalidateRect(hWnd, NULL, FALSE);
                UpdateWindow(hWnd);
                break;

            case TOOL_LINE:
            case TOOL_BOX:
            case TOOL_ELLIPSE:
            case TOOL_ROUNDRECT:
                SetCursor(Globals.hcurCross2);
                CanvasToImage(&pt);
                Globals.pt1 = pt;
                InvalidateRect(hWnd, NULL, FALSE);
                UpdateWindow(hWnd);
                break;

            case TOOL_SPOIT:
                SetCursor(Globals.hcurSpoit);
                CanvasToImage(&pt);
                hDC = GetDC(hWnd);
                if (hDC != NULL)
                {
                    hMemDC = CreateCompatibleDC(hDC);
                    if (hMemDC != NULL)
                    {
                        HGDIOBJ hbmOld = SelectObject(hMemDC, Globals.hbmImage);
                        Globals.rgbSpoit = GetPixel(hMemDC, pt.x, pt.y);
                        SelectObject(hMemDC, hbmOld);
                        DeleteDC(hMemDC);
                    }
                    ReleaseDC(hWnd, hDC);
                }
                InvalidateRect(Globals.hToolBox, NULL, FALSE);
                UpdateWindow(Globals.hToolBox);
                break;

            case TOOL_PENCIL:
                SetCursor(Globals.hcurPencil);
                CanvasToImage(&pt);
                hDC = GetDC(hWnd);
                hMemDC = CreateCompatibleDC(hDC);
                if (hMemDC != NULL)
                {
                    HPEN hPen = CreatePen(PS_SOLID, 0, Globals.rgbBack);
                    HGDIOBJ hbmOld = SelectObject(hMemDC, Globals.hbmImage);
                    HGDIOBJ hpenOld = SelectObject(hMemDC, hPen);
                    MoveToEx(hMemDC, Globals.pt0.x, Globals.pt0.y, NULL);
                    LineTo(hMemDC, pt.x, pt.y);
                    SetPixelV(hMemDC, pt.x, pt.y, Globals.rgbBack);
                    SelectObject(hMemDC, hbmOld);
                    SelectObject(hMemDC, hpenOld);
                    DeleteObject(hPen);
                    DeleteDC(hMemDC);
                    Globals.fModified = TRUE;
                }
                ReleaseDC(hWnd, hDC);
                Globals.pt0 = pt;
                InvalidateRect(hWnd, NULL, FALSE);
                UpdateWindow(hWnd);
                break;

            default:
                break;
            }
        }
    }
    else
    {
        Globals.fSwapColor = FALSE;
        Globals.mode = MODE_NORMAL;
        ReleaseCapture();
        rc.left = 4 + Globals.sizImage.cx * Globals.nZoom + 1 - Globals.xScrollPos;
        rc.top = 4 + Globals.sizImage.cy * Globals.nZoom / 2 - 2 - Globals.yScrollPos;
        rc.right = rc.left + 3;
        rc.bottom = rc.top + 3;
        if (PtInRect(&rc, pt))
        {
            SetCursor(Globals.hcurHorizontal);
            return;
        }

        rc.left = 4 + Globals.sizImage.cx * Globals.nZoom / 2 - 2 - Globals.xScrollPos;
        rc.top = 4 + Globals.sizImage.cy * Globals.nZoom + 1 - Globals.yScrollPos;
        rc.right = rc.left + 3;
        rc.bottom = rc.top + 3;
        if (PtInRect(&rc, pt))
        {
            SetCursor(Globals.hcurVertical);
            return;
        }

        rc.left = 4 + Globals.sizImage.cx * Globals.nZoom + 1 - Globals.xScrollPos;
        rc.top = 4 + Globals.sizImage.cy * Globals.nZoom + 1 - Globals.yScrollPos;
        rc.right = rc.left + 3;
        rc.bottom = rc.top + 3;
        if (PtInRect(&rc, pt))
        {
            SetCursor(Globals.hcurBDiagonal);
            return;
        }

        rc.left = 4 + Globals.xScrollPos;
        rc.top = 4 + Globals.yScrollPos;
        rc.right = 4 + Globals.sizImage.cx * Globals.nZoom + Globals.xScrollPos;
        rc.bottom = 4 + Globals.sizImage.cy * Globals.nZoom + Globals.yScrollPos;

        if (PtInRect(&rc, pt))
        {
            switch (Globals.iToolSelect)
            {
            case TOOL_BOXSELECT:
                if (Globals.fSelect && PtInRect((RECT*)&Globals.pt0, pt))
                {
                    SetCursor(Globals.hcurMove);
                }
                else
                {
                    SetCursor(Globals.hcurCross2);
                }
                CanvasToImage(&pt);
                ShowPos(pt);
                ShowNoSize();
                break;

            case TOOL_MAGNIFIER:
                SetCursor(Globals.hcurZoom);
                CanvasToImage(&pt);
                Globals.pt0 = pt;
                ShowPos(pt);
                ShowNoSize();
                InvalidateRect(hWnd, NULL, FALSE);
                UpdateWindow(hWnd);
                break;

            case TOOL_BRUSH:
                SetCursor(Globals.hcurCross);
                CanvasToImage(&pt);
                Globals.pt0 = pt;
                ShowPos(pt);
                ShowNoSize();
                InvalidateRect(hWnd, NULL, FALSE);
                UpdateWindow(hWnd);
                break;

            case TOOL_ERASER:
                SetCursor(NULL);
                CanvasToImage(&pt);
                Globals.pt0 = pt;
                ShowPos(pt);
                ShowNoSize();
                InvalidateRect(hWnd, NULL, FALSE);
                UpdateWindow(hWnd);
                break;

            case TOOL_FILL:
                SetCursor(Globals.hcurFill);
                CanvasToImage(&pt);
                ShowPos(pt);
                ShowNoSize();
                break;

            case TOOL_SPOIT:
                SetCursor(Globals.hcurSpoit);
                CanvasToImage(&pt);
                ShowPos(pt);
                ShowNoSize();
                break;

            case TOOL_PENCIL:
                SetCursor(Globals.hcurPencil);
                CanvasToImage(&pt);
                ShowPos(pt);
                ShowNoSize();
                break;

            case TOOL_AIRBRUSH:
                SetCursor(Globals.hcurAirBrush);
                CanvasToImage(&pt);
                ShowPos(pt);
                ShowNoSize();
                break;

            default:
                SetCursor(Globals.hcurCross2);
                CanvasToImage(&pt);
                ShowPos(pt);
                ShowNoSize();
                break;
            }
        }
        else
        {
            SendMessageW(Globals.hStatusBar, SB_SETTEXTW, 1 | 0, (LPARAM)empty);
            if (Globals.fSelect && PtInRect((RECT*)&Globals.pt0, pt))
            {
                SetCursor(Globals.hcurMove);
            }
            else
            {
                SetCursor(Globals.hcurArrow);
                if (Globals.iToolSelect == TOOL_MAGNIFIER || Globals.iToolSelect == TOOL_ERASER)
                {
                    InvalidateRect(hWnd, NULL, FALSE);
                    UpdateWindow(hWnd);
                }
            }
            return;
        }
    }
}

VOID Canvas_Resize(HWND hWnd, SIZE sizNew)
{
    HBITMAP hbmNew = BM_CreateResized(hWnd, sizNew, Globals.hbmImage,
                                       Globals.sizImage);
    if (hbmNew != NULL)
    {
        if (Globals.hbmImage != NULL)
            DeleteObject(Globals.hbmImage);
        Globals.hbmImage = hbmNew;
        Globals.sizImage = sizNew;

        if (Globals.hbmBuffer != NULL)
            DeleteObject(Globals.hbmBuffer);
        Globals.hbmBuffer = BM_Copy(Globals.hbmImage);
        if (Globals.hbmZoomBuffer != NULL)
            DeleteObject(Globals.hbmZoomBuffer);
        sizNew.cx *= Globals.nZoom;
        sizNew.cy *= Globals.nZoom;
        Globals.hbmZoomBuffer = BM_Create(sizNew);
        Globals.fModified = TRUE;
        Globals.xScrollPos = Globals.yScrollPos = 0;
        PostMessageW(hWnd, WM_SIZE, 0, 0);
        InvalidateRect(hWnd, NULL, TRUE);
        UpdateWindow(hWnd);
    }
    else
        ShowLastError();
}

VOID Selection_Stretch(HWND hWnd, SIZE sizNew)
{
    HBITMAP hbmNew;
    SIZE siz;
    Selection_TakeOff();
    siz.cx = Globals.pt1.x - Globals.pt0.x;
    siz.cy = Globals.pt1.y - Globals.pt0.y;
    hbmNew = BM_CreateStretched(hWnd, sizNew, Globals.hbmSelect, siz);
    if (hbmNew != NULL)
    {
        if (Globals.hbmSelect != NULL)
            DeleteObject(Globals.hbmSelect);
        Globals.hbmSelect = hbmNew;
        Globals.pt1.x = Globals.pt0.x + sizNew.cx;
        Globals.pt1.y = Globals.pt0.y + sizNew.cy;
        Globals.fModified = TRUE;
        InvalidateRect(hWnd, NULL, TRUE);
        UpdateWindow(hWnd);
    }
    else
        ShowLastError();
}

VOID Canvas_Stretch(HWND hWnd, SIZE sizNew)
{
    HBITMAP hbmNew = BM_CreateStretched(hWnd, sizNew,
                                         Globals.hbmImage, Globals.sizImage);
    if (hbmNew != NULL)
    {
        if (Globals.hbmImage != NULL)
            DeleteObject(Globals.hbmImage);
        Globals.hbmImage = hbmNew;
        Globals.sizImage = sizNew;

        if (Globals.hbmBuffer != NULL)
            DeleteObject(Globals.hbmBuffer);
        Globals.hbmBuffer = BM_Copy(Globals.hbmImage);
        if (Globals.hbmZoomBuffer != NULL)
            DeleteObject(Globals.hbmZoomBuffer);
        sizNew.cx *= Globals.nZoom;
        sizNew.cy *= Globals.nZoom;
        Globals.hbmZoomBuffer = BM_Create(sizNew);
        Globals.fModified = TRUE;
        Globals.xScrollPos = Globals.yScrollPos = 0;
        PostMessageW(hWnd, WM_SIZE, 0, 0);
        InvalidateRect(hWnd, NULL, TRUE);
        UpdateWindow(hWnd);
    }
    else
        ShowLastError();
}

VOID Selection_HFlip(HWND hWnd)
{
    HBITMAP hbmNew;
    SIZE siz;
    Selection_TakeOff();
    siz.cx = Globals.pt1.x - Globals.pt0.x;
    siz.cy = Globals.pt1.y - Globals.pt0.y;
    hbmNew = BM_CreateHFliped(hWnd, Globals.hbmSelect, siz);
    if (hbmNew != NULL)
    {
        if (Globals.hbmSelect != NULL)
            DeleteObject(Globals.hbmSelect);
        Globals.hbmSelect = hbmNew;
        Globals.fModified = TRUE;
        InvalidateRect(hWnd, NULL, TRUE);
        UpdateWindow(hWnd);
    }
    else
        ShowLastError();
}

VOID Canvas_HFlip(HWND hWnd)
{
    HBITMAP hbmNew = BM_CreateHFliped(hWnd, Globals.hbmImage,
                                       Globals.sizImage);
    if (hbmNew != NULL)
    {
        if (Globals.hbmImage != NULL)
            DeleteObject(Globals.hbmImage);
        Globals.hbmImage = hbmNew;
        Globals.fModified = TRUE;
        InvalidateRect(hWnd, NULL, TRUE);
        UpdateWindow(hWnd);
    }
    else
        ShowLastError();
}

VOID Selection_VFlip(HWND hWnd)
{
    HBITMAP hbmNew;
    SIZE siz;
    Selection_TakeOff();
    siz.cx = Globals.pt1.x - Globals.pt0.x;
    siz.cy = Globals.pt1.y - Globals.pt0.y;
    hbmNew = BM_CreateVFliped(hWnd, Globals.hbmSelect, siz);
    if (hbmNew != NULL)
    {
        if (Globals.hbmSelect != NULL)
            DeleteObject(Globals.hbmSelect);
        Globals.hbmSelect = hbmNew;
        Globals.fModified = TRUE;
        InvalidateRect(hWnd, NULL, TRUE);
        UpdateWindow(hWnd);
    }
    else
        ShowLastError();
}

VOID Canvas_VFlip(HWND hWnd)
{
    HBITMAP hbmNew = BM_CreateVFliped(Globals.hCanvasWnd,
                                       Globals.hbmImage, Globals.sizImage);
    if (hbmNew != NULL)
    {
        if (Globals.hbmImage != NULL)
            DeleteObject(Globals.hbmImage);
        Globals.hbmImage = hbmNew;
        Globals.fModified = TRUE;
        InvalidateRect(hWnd, NULL, TRUE);
        UpdateWindow(hWnd);
    }
    else
        ShowLastError();
}

VOID Selection_Rotate90Degree(HWND hWnd)
{
    SIZE siz;
    HBITMAP hbmNew;
    Selection_TakeOff();
    siz.cx = Globals.pt1.x - Globals.pt0.x;
    siz.cy = Globals.pt1.y - Globals.pt0.y;
    hbmNew = BM_CreateRotated90Degree(hWnd,
                                       Globals.hbmSelect, siz);
    if (hbmNew != NULL)
    {
        if (Globals.hbmSelect != NULL)
            DeleteObject(Globals.hbmSelect);
        Globals.hbmSelect = hbmNew;
        Globals.pt1.x = Globals.pt0.x + siz.cy;
        Globals.pt1.y = Globals.pt0.y + siz.cx;
        Globals.fModified = TRUE;
        InvalidateRect(hWnd, NULL, TRUE);
        UpdateWindow(hWnd);
    }
    else
        ShowLastError();
}

VOID Canvas_Rotate90Degree(HWND hWnd)
{
    SIZE siz;
    HBITMAP hbmNew = BM_CreateRotated90Degree(hWnd,
                     Globals.hbmImage, Globals.sizImage);
    if (hbmNew != NULL)
    {
        if (Globals.hbmImage != NULL)
            DeleteObject(Globals.hbmImage);
        Globals.hbmImage = hbmNew;
        siz.cx = Globals.sizImage.cy;
        siz.cy = Globals.sizImage.cx;
        Globals.sizImage = siz;
        if (Globals.hbmBuffer != NULL)
            DeleteObject(Globals.hbmBuffer);
        Globals.hbmBuffer = BM_Copy(Globals.hbmImage);
        if (Globals.hbmZoomBuffer != NULL)
            DeleteObject(Globals.hbmZoomBuffer);
        siz.cx *= Globals.nZoom;
        siz.cy *= Globals.nZoom;
        Globals.hbmZoomBuffer = BM_Create(siz);
        Globals.fModified = TRUE;
        Globals.xScrollPos = Globals.yScrollPos = 0;
        PostMessageW(hWnd, WM_SIZE, 0, 0);
        InvalidateRect(hWnd, NULL, TRUE);
        UpdateWindow(hWnd);
    }
    else
        ShowLastError();
}

VOID Selection_Rotate180Degree(HWND hWnd)
{
    HBITMAP hbmNew;
    SIZE siz;
    Selection_TakeOff();
    siz.cx = Globals.pt1.x - Globals.pt0.x;
    siz.cy = Globals.pt1.y - Globals.pt0.y;
    hbmNew = BM_CreateRotated180Degree(hWnd,
                                        Globals.hbmSelect, siz);
    if (hbmNew != NULL)
    {
        if (Globals.hbmSelect != NULL)
            DeleteObject(Globals.hbmSelect);
        Globals.hbmSelect = hbmNew;
        Globals.fModified = TRUE;
        InvalidateRect(hWnd, NULL, TRUE);
        UpdateWindow(hWnd);
    }
    else
        ShowLastError();
}

VOID Canvas_Rotate180Degree(HWND hWnd)
{
    HBITMAP hbmNew = BM_CreateRotated180Degree(hWnd,
                     Globals.hbmImage, Globals.sizImage);
    if (hbmNew != NULL)
    {
        if (Globals.hbmImage != NULL)
            DeleteObject(Globals.hbmImage);
        Globals.hbmImage = hbmNew;
        if (Globals.hbmBuffer != NULL)
            DeleteObject(Globals.hbmBuffer);
        Globals.hbmBuffer = BM_Copy(Globals.hbmImage);
        Globals.fModified = TRUE;
        InvalidateRect(hWnd, NULL, TRUE);
        UpdateWindow(hWnd);
    }
    else
        ShowLastError();
}

VOID Selection_Rotate270Degree(HWND hWnd)
{
    SIZE siz;
    HBITMAP hbmNew;
    Selection_TakeOff();
    siz.cx = Globals.pt1.x - Globals.pt0.x;
    siz.cy = Globals.pt1.y - Globals.pt0.y;
    hbmNew = BM_CreateRotated270Degree(hWnd,
                                        Globals.hbmSelect, siz);
    if (hbmNew != NULL)
    {
        if (Globals.hbmSelect != NULL)
            DeleteObject(Globals.hbmSelect);
        Globals.hbmSelect = hbmNew;
        Globals.pt1.x = Globals.pt0.x + siz.cy;
        Globals.pt1.y = Globals.pt0.y + siz.cx;
        Globals.fModified = TRUE;
        InvalidateRect(hWnd, NULL, TRUE);
        UpdateWindow(hWnd);
    }
    else
        ShowLastError();
}

VOID Canvas_Rotate270Degree(HWND hWnd)
{
    SIZE siz;
    HBITMAP hbmNew = BM_CreateRotated270Degree(hWnd,
                     Globals.hbmImage, Globals.sizImage);
    if (hbmNew != NULL)
    {
        if (Globals.hbmImage != NULL)
            DeleteObject(Globals.hbmImage);
        Globals.hbmImage = hbmNew;
        siz.cx = Globals.sizImage.cy;
        siz.cy = Globals.sizImage.cx;
        Globals.sizImage = siz;
        if (Globals.hbmBuffer != NULL)
            DeleteObject(Globals.hbmBuffer);
        Globals.hbmBuffer = BM_Copy(Globals.hbmImage);
        if (Globals.hbmZoomBuffer != NULL)
            DeleteObject(Globals.hbmZoomBuffer);
        siz.cx *= Globals.nZoom;
        siz.cy *= Globals.nZoom;
        Globals.hbmZoomBuffer = BM_Create(siz);
        Globals.fModified = TRUE;
        Globals.xScrollPos = Globals.yScrollPos = 0;
        PostMessageW(hWnd, WM_SIZE, 0, 0);
        InvalidateRect(hWnd, NULL, TRUE);
        UpdateWindow(hWnd);
    }
    else
        ShowLastError();
}

VOID Canvas_OnButtonDblClk(HWND hWnd, INT x, INT y, BOOL fRight)
{
    HDC hDC, hMemDC;
    POINT pt;
    pt.x = x;
    pt.y = y;

    switch (Globals.iToolSelect)
    {
    case TOOL_POLYGON:
        SetCursor(Globals.hcurCross2);
        CanvasToImage(&pt);
        hDC = GetDC(hWnd);
        if (hDC != NULL)
        {
            hMemDC = CreateCompatibleDC(hDC);
            if (hMemDC != NULL)
            {
                HPEN hPen;
                HBRUSH hbr;
                HGDIOBJ hpenOld, hbrOld, hbmOld;
                hbmOld = SelectObject(hMemDC, Globals.hbmImage);
                if (fRight)
                {
                    switch (Globals.iFillStyle)
                    {
                    case 0:
                        hPen = CreatePen(PS_SOLID, Globals.nLineWidth,
                                         Globals.rgbBack);
                        hbr = (HBRUSH)GetStockObject(NULL_BRUSH);
                        break;

                    case 1:
                        hPen = CreatePen(PS_SOLID, Globals.nLineWidth,
                                         Globals.rgbBack);
                        hbr = CreateSolidBrush(Globals.rgbFore);
                        break;

                    default:
                        hPen = CreatePen(PS_SOLID, Globals.nLineWidth,
                                         Globals.rgbBack);
                        hbr = CreateSolidBrush(Globals.rgbBack);
                        break;
                    }
                }
                else
                {
                    switch (Globals.iFillStyle)
                    {
                    case 0:
                        hPen = CreatePen(PS_SOLID, Globals.nLineWidth,
                                         Globals.rgbFore);
                        hbr = (HBRUSH)GetStockObject(NULL_BRUSH);
                        break;

                    case 1:
                        hPen = CreatePen(PS_SOLID, Globals.nLineWidth,
                                         Globals.rgbFore);
                        hbr = CreateSolidBrush(Globals.rgbBack);
                        break;

                    default:
                        hPen = CreatePen(PS_SOLID, Globals.nLineWidth,
                                         Globals.rgbFore);
                        hbr = CreateSolidBrush(Globals.rgbFore);
                        break;
                    }
                }
                hpenOld = SelectObject(hMemDC, hPen);
                hbrOld = SelectObject(hMemDC, hbr);
                Polygon(hMemDC, Globals.pPolyline, Globals.cPolyline);
                SelectObject(hMemDC, hpenOld);
                SelectObject(hMemDC, hbrOld);
                SelectObject(hMemDC, hbmOld);
                DeleteObject(hPen);
                DeleteObject(hbr);
                DeleteDC(hMemDC);
            }
            ReleaseDC(hWnd, hDC);
        }
        HeapFree(GetProcessHeap(), 0, Globals.pPolyline);
        Globals.pPolyline = NULL;
        Globals.cPolyline = 0;
        Globals.fModified = TRUE;
        InvalidateRect(hWnd, NULL, FALSE);
        UpdateWindow(hWnd);
        break;

    default:
        break;
    }
}

VOID Canvas_OnButtonUp(HWND hWnd, INT x, INT y, BOOL fRight)
{
    HDC hDC, hMemDC;
    HGDIOBJ hbmOld;
    POINT pt;
    SIZE siz;
    RECT rc;
    pt.x = x;
    pt.y = y;

    switch (Globals.mode)
    {
    case MODE_RIGHT_EDGE:
        CanvasToImage(&pt);
        PrepareForUndo();
        Globals.fModified = TRUE;
        siz.cx = pt.x;
        siz.cy = Globals.sizImage.cy;
        if (siz.cx < 1) siz.cx = 1;
        Canvas_Resize(hWnd, siz);
        ReleaseCapture();
        Globals.mode = MODE_NORMAL;
        InvalidateRect(hWnd, NULL, TRUE);
        UpdateWindow(hWnd);
        break;

    case MODE_DOWN_EDGE:
        CanvasToImage(&pt);
        PrepareForUndo();
        Globals.fModified = TRUE;
        siz.cx = Globals.sizImage.cx;
        siz.cy = pt.y;
        if (siz.cy < 1) siz.cy = 1;
        Canvas_Resize(hWnd, siz);
        ReleaseCapture();
        Globals.mode = MODE_NORMAL;
        InvalidateRect(hWnd, NULL, TRUE);
        UpdateWindow(hWnd);
        break;

    case MODE_LOWER_RIGHT_EDGE:
        CanvasToImage(&pt);
        PrepareForUndo();
        Globals.fModified = TRUE;
        siz.cx = pt.x;
        siz.cy = pt.y;
        if (siz.cx < 1) siz.cx = 1;
        if (siz.cy < 1) siz.cy = 1;
        Canvas_Resize(hWnd, siz);
        ReleaseCapture();
        Globals.mode = MODE_NORMAL;
        InvalidateRect(hWnd, NULL, TRUE);
        UpdateWindow(hWnd);
        break;

    case MODE_SELECTION:
        ReleaseCapture();
        Globals.mode = MODE_NORMAL;
        break;

    case MODE_CANVAS:
        ReleaseCapture();
        Globals.mode = MODE_NORMAL;
        switch (Globals.iToolSelect)
        {
        case TOOL_BOXSELECT:
            SetCursor(Globals.hcurCross2);
            CanvasToImage(&pt);
            Globals.pt1 = pt;
            NormalizeRect((RECT*)&Globals.pt0);
            rc.left = rc.top = 0;
            rc.right = Globals.sizImage.cx;
            rc.bottom = Globals.sizImage.cy;
            IntersectRect((RECT*)&Globals.pt0, (RECT*)&Globals.pt0, &rc);
            Globals.fSelect = !IsRectEmpty((RECT*)&Globals.pt0);
            Globals.hbmSelect = NULL;
            InvalidateRect(hWnd, NULL, TRUE);
            UpdateWindow(hWnd);
            break;

        case TOOL_POLYGON:
            SetCursor(Globals.hcurCross2);
            CanvasToImage(&pt);
            Globals.pPolyline[Globals.cPolyline - 1] = pt;
            InvalidateRect(hWnd, NULL, FALSE);
            UpdateWindow(hWnd);
            break;

        case TOOL_CURVE:
            SetCursor(Globals.hcurCross2);
            CanvasToImage(&pt);
            if (Globals.ipt == 1)
            {
                Globals.pt2 = Globals.pt3 = pt;
                Globals.ipt = 2;
            }
            else if (Globals.ipt == 2)
            {
                Globals.pt1 = pt;
                Globals.ipt = 3;
            }
            else if (Globals.ipt == 3)
            {
                Globals.pt2 = pt;
                Globals.ipt = 0;
                PrepareForUndo();
                hDC = GetDC(hWnd);
                if (hDC != NULL)
                {
                    hMemDC = CreateCompatibleDC(hDC);
                    if (hMemDC != NULL)
                    {
                        HPEN hPen;
                        hPen = CreatePen(PS_SOLID, Globals.nLineWidth,
                                         fRight ? Globals.rgbBack : Globals.rgbFore);
                        hbmOld = SelectObject(hMemDC, Globals.hbmImage);
                        SelectObject(hMemDC, hPen);
                        PolyBezier(hMemDC, &Globals.pt0, 4);
                        SelectObject(hMemDC, hbmOld);
                        DeleteDC(hMemDC);
                        DeleteObject(hPen);
                        Globals.fModified = TRUE;
                    }
                    ReleaseDC(hWnd, hDC);
                }
                InvalidateRect(hWnd, NULL, FALSE);
                UpdateWindow(hWnd);
            }
            break;

        case TOOL_PENCIL:
            CanvasToImage(&pt);
            hDC = GetDC(hWnd);
            if (hDC != NULL)
            {
                hMemDC = CreateCompatibleDC(hDC);
                if (hMemDC != NULL)
                {
                    HPEN hPen;
                    HGDIOBJ hpenOld;
                    hbmOld = SelectObject(hMemDC, Globals.hbmImage);
                    hPen = CreatePen(PS_SOLID, 1, fRight ? Globals.rgbBack :
                                     Globals.rgbFore);
                    hpenOld = SelectObject(hMemDC, hPen);
                    MoveToEx(hMemDC, Globals.pt0.x, Globals.pt0.y, NULL);
                    LineTo(hMemDC, pt.x, pt.y);
                    SetPixel(hMemDC, pt.x, pt.y, fRight ?
                             Globals.rgbBack : Globals.rgbFore);
                    SelectObject(hMemDC, hbmOld);
                    SelectObject(hMemDC, hpenOld);
                    DeleteObject(hPen);
                    DeleteDC(hMemDC);
                    Globals.fModified = TRUE;
                }
                ReleaseDC(hWnd, hDC);
            }
            InvalidateRect(hWnd, NULL, FALSE);
            UpdateWindow(hWnd);
            break;

        case TOOL_AIRBRUSH:
            SetCursor(Globals.hcurAirBrush);
            KillTimer(hWnd, Globals.idTimer);
            break;

        case TOOL_BOX:
        case TOOL_ELLIPSE:
        case TOOL_ROUNDRECT:
            CanvasToImage(&pt);
            PrepareForUndo();
            hDC = GetDC(hWnd);
            if (hDC != NULL)
            {
                hMemDC = CreateCompatibleDC(hDC);
                if (hMemDC != NULL)
                {
                    HGDIOBJ hpenOld, hbrOld, hbmOld;
                    HPEN hPen;
                    HBRUSH hbr;

                    if (Globals.fSwapColor)
                    {
                        switch (Globals.iFillStyle)
                        {
                        case 0:
                            hPen = CreatePen(PS_SOLID, Globals.nLineWidth,
                                             Globals.rgbBack);
                            hbr = (HBRUSH)GetStockObject(NULL_BRUSH);
                            break;

                        case 1:
                            hPen = CreatePen(PS_SOLID, Globals.nLineWidth,
                                             Globals.rgbBack);
                            hbr = CreateSolidBrush(Globals.rgbFore);
                            break;

                        default:
                            hPen = CreatePen(PS_SOLID, Globals.nLineWidth,
                                             Globals.rgbBack);
                            hbr = CreateSolidBrush(Globals.rgbBack);
                        }
                    }
                    else
                    {
                        switch (Globals.iFillStyle)
                        {
                        case 0:
                            hPen = CreatePen(PS_SOLID, Globals.nLineWidth,
                                             Globals.rgbFore);
                            hbr = (HBRUSH)GetStockObject(NULL_BRUSH);
                            break;

                        case 1:
                            hPen = CreatePen(PS_SOLID, Globals.nLineWidth,
                                             Globals.rgbFore);
                            hbr = CreateSolidBrush(Globals.rgbBack);
                            break;

                        default:
                            hPen = CreatePen(PS_SOLID, Globals.nLineWidth,
                                             Globals.rgbFore);
                            hbr = CreateSolidBrush(Globals.rgbFore);
                        }
                    }

                    hbmOld = SelectObject(hMemDC, Globals.hbmImage);
                    hpenOld = SelectObject(hMemDC, hPen);
                    hbrOld = SelectObject(hMemDC, hbr);
                    if (GetKeyState(VK_SHIFT) < 0)
                        Regularize(Globals.pt0, &pt);
                    switch(Globals.iToolSelect)
                    {
                    case TOOL_BOX:
                        Rectangle(hMemDC, Globals.pt0.x, Globals.pt0.y,
                                  pt.x, pt.y);
                        break;

                    case TOOL_ELLIPSE:
                        Ellipse(hMemDC, Globals.pt0.x, Globals.pt0.y,
                                pt.x, pt.y);
                        break;

                    default:
                        RoundRect(hMemDC, Globals.pt0.x, Globals.pt0.y,
                                  pt.x, pt.y, 16, 16);
                    }
                    SelectObject(hMemDC, hpenOld);
                    SelectObject(hMemDC, hbrOld);
                    SelectObject(hMemDC, hbmOld);
                    DeleteObject(hPen);
                    DeleteObject(hbr);
                    DeleteDC(hMemDC);
                    Globals.fModified = TRUE;
                }
                ReleaseDC(hWnd, hDC);
            }
            SetRectEmpty((RECT*)&Globals.pt0);
            break;

        case TOOL_SPOIT:
            Globals.iToolSelect = Globals.iToolPrev;
            if (fRight)
                Globals.rgbBack = Globals.rgbSpoit;
            else
                Globals.rgbFore = Globals.rgbSpoit;
            InvalidateRect(Globals.hToolBox, NULL, TRUE);
            UpdateWindow(Globals.hToolBox);
            InvalidateRect(Globals.hColorBox, NULL, TRUE);
            UpdateWindow(Globals.hColorBox);
            break;

        case TOOL_LINE:
            CanvasToImage(&pt);
            PrepareForUndo();
            hDC = GetDC(hWnd);
            if (hDC != NULL)
            {
                hMemDC = CreateCompatibleDC(hDC);
                if (hMemDC != NULL)
                {
                    HPEN hPen = CreatePen(PS_SOLID, Globals.nLineWidth, fRight ?
                                          Globals.rgbBack : Globals.rgbFore);
                    HGDIOBJ hpenOld = SelectObject(hMemDC, hPen);
                    HGDIOBJ hbmOld = SelectObject(hMemDC, Globals.hbmImage);
                    MoveToEx(hMemDC, Globals.pt0.x , Globals.pt0.y, NULL);
                    LineTo(hMemDC, pt.x, pt.y);
                    SetPixel(hMemDC, pt.x, pt.y, fRight ? Globals.rgbBack :
                             Globals.rgbFore);
                    SelectObject(hMemDC, hbmOld);
                    SelectObject(hMemDC, hpenOld);
                    DeleteObject(hPen);
                    DeleteDC(hMemDC);
                    Globals.fModified = TRUE;
                }
                ReleaseDC(hWnd, hDC);
            }
            break;

        default:
            break;
        }
        break;

    default:
        break;
    }
    InvalidateRect(hWnd, NULL, FALSE);
    UpdateWindow(hWnd);
}

VOID Canvas_OnSize(HWND hWnd)
{
    RECT rc;
    SIZE siz;

    GetClientRect(hWnd, &rc);
    siz.cx = rc.right - rc.left;
    siz.cy = rc.bottom - rc.top;
    if (siz.cx < Globals.sizImage.cx * Globals.nZoom + 8)
    {
        SCROLLINFO si;
        EnableScrollBar(hWnd, SB_HORZ, ESB_ENABLE_BOTH);
        si.cbSize = sizeof(si);
        si.fMask = SIF_ALL;
        si.nMin = 0;
        si.nMax = Globals.sizImage.cx * Globals.nZoom + 8;
        si.nPage = siz.cx;
        si.nPos = Globals.xScrollPos;
        SetScrollInfo(hWnd, SB_HORZ, &si, TRUE);
        ShowScrollBar(hWnd, SB_HORZ, TRUE);
    }
    else
    {
        EnableScrollBar(hWnd, SB_HORZ, ESB_DISABLE_BOTH);
        ShowScrollBar(hWnd, SB_HORZ, FALSE);
    }

    if (siz.cy < Globals.sizImage.cy * Globals.nZoom + 8)
    {
        SCROLLINFO si;
        EnableScrollBar(hWnd, SB_VERT, ESB_ENABLE_BOTH);
        si.cbSize = sizeof(si);
        si.fMask = SIF_ALL;
        si.nMin = 0;
        si.nMax = Globals.sizImage.cy * Globals.nZoom + 8;
        si.nPage = siz.cy;
        si.nPos = Globals.yScrollPos;
        SetScrollInfo(hWnd, SB_VERT, &si, TRUE);
        ShowScrollBar(hWnd, SB_VERT, TRUE);
    }
    else
    {
        EnableScrollBar(hWnd, SB_VERT, ESB_DISABLE_BOTH);
        ShowScrollBar(hWnd, SB_VERT, FALSE);
    }

    if (Globals.hbmCanvasBuffer == NULL ||
        siz.cx + 100 < Globals.sizCanvas.cx ||
        Globals.sizCanvas.cx < siz.cx ||
        siz.cy + 100 < Globals.sizCanvas.cy ||
        Globals.sizCanvas.cy < siz.cy)
    {
        if (Globals.hbmCanvasBuffer != NULL)
            DeleteObject(Globals.hbmCanvasBuffer);
        siz.cx += 50;
        siz.cy += 50;
        Globals.hbmCanvasBuffer = BM_Create(siz);
        Globals.sizCanvas = siz;
    }
}

LRESULT CALLBACK CanvasWndProc(HWND hWnd, UINT uMsg,
                               WPARAM wParam, LPARAM lParam)
{
    INT c, c2;
    RECT rc;

    switch (uMsg)
    {
    case WM_LBUTTONDOWN:
        Canvas_OnButtonDown(hWnd, (INT)(SHORT)LOWORD(lParam),
                            (INT)(SHORT)HIWORD(lParam), FALSE);
        break;
    case WM_RBUTTONDOWN:
        Canvas_OnButtonDown(hWnd, (INT)(SHORT)LOWORD(lParam),
                            (INT)(SHORT)HIWORD(lParam), TRUE);
        break;

    case WM_LBUTTONDBLCLK:
        Canvas_OnButtonDblClk(hWnd, (INT)(SHORT)LOWORD(lParam),
                              (INT)(SHORT)HIWORD(lParam), FALSE);
        break;

    case WM_RBUTTONDBLCLK:
        Canvas_OnButtonDblClk(hWnd, (INT)(SHORT)LOWORD(lParam),
                              (INT)(SHORT)HIWORD(lParam), TRUE);
        break;

    case WM_LBUTTONUP:
        Canvas_OnButtonUp(hWnd, (INT)(SHORT)LOWORD(lParam),
                          (INT)(SHORT)HIWORD(lParam), FALSE);
        break;

    case WM_RBUTTONUP:
        Canvas_OnButtonUp(hWnd, (INT)(SHORT)LOWORD(lParam),
                          (INT)(SHORT)HIWORD(lParam), TRUE);
        break;

    case WM_MOUSEMOVE:
        Canvas_OnMouseMove(hWnd, (INT)(SHORT)LOWORD(lParam),
                           (INT)(SHORT)HIWORD(lParam), wParam & MK_LBUTTON,
                           wParam & MK_RBUTTON);
        break;

    case WM_KEYDOWN:
        switch ((INT)wParam)
        {
        case VK_ESCAPE:
            if (Globals.mode != MODE_NORMAL)
            {
                ReleaseCapture();
                Globals.mode = MODE_NORMAL;
                Globals.ipt = 0;
                if (Globals.pPolyline != NULL)
                    HeapFree(GetProcessHeap(), 0, Globals.pPolyline);
                Globals.pPolyline = NULL;
                Globals.cPolyline = 0;
                InvalidateRect(hWnd, NULL, FALSE);
                UpdateWindow(hWnd);
            }
        }
        break;

    case WM_TIMER:
    {
        HDC hDC = GetDC(hWnd);
        HDC hMemDC = CreateCompatibleDC(hDC);
        if (hMemDC != NULL)
        {
            POINT pt;
            INT i, j, n;
            HGDIOBJ hbmOld = SelectObject(hMemDC, Globals.hbmImage);
            GetCursorPos(&pt);
            ScreenToClient(hWnd, &pt);
            CanvasToImage(&pt);
            ShowPos(pt);
            ShowNoSize();

            n = Globals.nAirBrushRadius;
            for (i = 0; i < 5; i++)
            {
                j = rand();
                SetPixelV(hMemDC, pt.x + n / 2 - cos(j) * (rand() % n),
                          pt.y + n / 2 - sin(j) * (rand() % n),
                          (GetKeyState(VK_RBUTTON) < 0) ? Globals.rgbBack :
                          Globals.rgbFore);
            }
            Globals.fModified = TRUE;
            SelectObject(hMemDC, hbmOld);
            DeleteDC(hMemDC);
        }
        ReleaseDC(hWnd, hDC);
        InvalidateRect(hWnd, NULL, FALSE);
        UpdateWindow(hWnd);
        break;
    }

    case WM_PAINT:
    {
        PAINTSTRUCT ps;
        HDC hDC = BeginPaint(hWnd, &ps);
        if (hDC != NULL)
        {
            Canvas_OnPaint(hWnd, hDC);
            EndPaint(hWnd, &ps);
        }
        break;
    }

    case WM_ERASEBKGND:
        break;

    case WM_SIZE:
        Canvas_OnSize(hWnd);
        break;

    case WM_HSCROLL:
        switch (LOWORD(wParam))
        {
        case SB_PAGELEFT:
            GetClientRect(hWnd, &rc);
            Globals.xScrollPos -= rc.right - rc.left;
            if (Globals.xScrollPos < 0)
                Globals.xScrollPos = 0;
            InvalidateRect(hWnd, NULL, TRUE);
            UpdateWindow(hWnd);
            SetScrollPos(hWnd, SB_HORZ, Globals.xScrollPos, TRUE);
            break;

        case SB_PAGERIGHT:
            GetClientRect(hWnd, &rc);
            c = rc.right - rc.left;
            Globals.xScrollPos += c;
            c2 = Globals.sizImage.cx * Globals.nZoom + 8 - c;
            if (Globals.xScrollPos > c2)
                Globals.xScrollPos = c2;
            InvalidateRect(hWnd, NULL, TRUE);
            UpdateWindow(hWnd);
            SetScrollPos(hWnd, SB_HORZ, Globals.xScrollPos, TRUE);
            break;

        case SB_LINELEFT:
            Globals.xScrollPos -= Globals.nZoom;
            if (Globals.xScrollPos < 0)
                Globals.xScrollPos = 0;
            InvalidateRect(hWnd, NULL, TRUE);
            UpdateWindow(hWnd);
            SetScrollPos(hWnd, SB_HORZ, Globals.xScrollPos, TRUE);
            break;

        case SB_LINERIGHT:
            GetClientRect(hWnd, &rc);
            c = rc.right - rc.left;
            Globals.xScrollPos += Globals.nZoom;
            c2 = Globals.sizImage.cx * Globals.nZoom + 8 - c;
            if (Globals.xScrollPos > c2)
                Globals.xScrollPos = c2;
            InvalidateRect(hWnd, NULL, TRUE);
            UpdateWindow(hWnd);
            SetScrollPos(hWnd, SB_HORZ, Globals.xScrollPos, TRUE);
            break;

        case SB_THUMBPOSITION:
        case SB_THUMBTRACK:
            Globals.xScrollPos = (SHORT)HIWORD(wParam);
            InvalidateRect(hWnd, NULL, TRUE);
            UpdateWindow(hWnd);
            SetScrollPos(hWnd, SB_HORZ, (SHORT)HIWORD(wParam), TRUE);
            break;
        }
        break;

    case WM_VSCROLL:
        switch (LOWORD(wParam))
        {
        case SB_PAGEUP:
            GetClientRect(hWnd, &rc);
            Globals.yScrollPos -= rc.bottom - rc.top;
            if (Globals.yScrollPos < 0)
                Globals.yScrollPos = 0;
            InvalidateRect(hWnd, NULL, TRUE);
            UpdateWindow(hWnd);
            SetScrollPos(hWnd, SB_VERT, Globals.yScrollPos, TRUE);
            break;

        case SB_PAGEDOWN:
            GetClientRect(hWnd, &rc);
            c = rc.bottom - rc.top;
            Globals.yScrollPos += c;
            c2 = Globals.sizImage.cy * Globals.nZoom + 8 - c;
            if (Globals.yScrollPos > c2)
                Globals.yScrollPos = c2;
            InvalidateRect(hWnd, NULL, TRUE);
            UpdateWindow(hWnd);
            SetScrollPos(hWnd, SB_VERT, Globals.yScrollPos, TRUE);
            break;

        case SB_LINEUP:
            Globals.yScrollPos -= Globals.nZoom;
            if (Globals.yScrollPos < 0)
                Globals.yScrollPos = 0;
            InvalidateRect(hWnd, NULL, TRUE);
            UpdateWindow(hWnd);
            SetScrollPos(hWnd, SB_VERT, Globals.yScrollPos, TRUE);
            break;

        case SB_LINEDOWN:
            GetClientRect(hWnd, &rc);
            c = rc.bottom - rc.top;
            Globals.yScrollPos += Globals.nZoom;
            c2 = Globals.sizImage.cy * Globals.nZoom + 8 - c;
            if (Globals.yScrollPos > c2)
                Globals.yScrollPos = c2;
            InvalidateRect(hWnd, NULL, TRUE);
            UpdateWindow(hWnd);
            SetScrollPos(hWnd, SB_VERT, Globals.yScrollPos, TRUE);
            break;

        case SB_THUMBPOSITION:
        case SB_THUMBTRACK:
            Globals.yScrollPos = (SHORT)HIWORD(wParam);
            InvalidateRect(hWnd, NULL, TRUE);
            UpdateWindow(hWnd);
            SetScrollPos(hWnd, SB_VERT, (SHORT)HIWORD(wParam), TRUE);
            break;
        }
        break;

    default:
        return DefWindowProcW(hWnd, uMsg, wParam, lParam);
    }
    return 0;
}

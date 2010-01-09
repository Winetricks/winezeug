/*
 *  Paint (paint.h)
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

VOID PAINT_FileNew(VOID);
VOID PAINT_FileOpen(VOID);
BOOL PAINT_FileSave(VOID);
BOOL PAINT_FileSaveAs(VOID);
VOID PAINT_FilePrintPreview(VOID);
VOID PAINT_FilePrint(VOID);
VOID PAINT_FilePageSetup(VOID);
VOID PAINT_FilePrinterSetup(VOID);
VOID PAINT_SetAsWallpaperTiled(VOID);
VOID PAINT_SetAsWallpaperCentered(VOID);
VOID PAINT_FileExit(VOID);

VOID PAINT_EditUndo(VOID);
VOID PAINT_EditRepeat(VOID);
VOID PAINT_EditCut(VOID);
VOID PAINT_EditCopy(VOID);
VOID PAINT_EditPaste(VOID);
VOID PAINT_EditDelete(VOID);
VOID PAINT_EditSelectAll(VOID);
VOID PAINT_CopyTo(VOID);
VOID PAINT_PasteFrom(VOID);

VOID PAINT_ClearSelection(VOID);

VOID PAINT_HelpContents(VOID);
VOID PAINT_HelpHelp(VOID);
VOID PAINT_HelpAboutPaint(VOID);

VOID PAINT_ToolBox(VOID);
VOID PAINT_ColorBox(VOID);
VOID PAINT_StatusBar(VOID);
VOID PAINT_Zoom(INT nZoom);
VOID PAINT_Zoom2(INT x, INT y, INT nZoom);
VOID PAINT_ShowGrid(VOID);
VOID PAINT_ZoomCustom(VOID);

VOID PAINT_FlipRotate(VOID);
VOID PAINT_StretchSkew(VOID);
VOID PAINT_InvertColors(VOID);
VOID PAINT_Attributes(VOID);
VOID PAINT_ClearImage(VOID);

VOID PAINT_EditColor(BOOL fBack);

int PAINT_StringMsgBox(HWND hParent, int formatId, LPCWSTR szString, UINT uFlags);

/* utility functions */
VOID ShowLastError(void);
BOOL FileExists(LPCWSTR szFilename);
BOOL DoCloseFile(void);
void DoOpenFile(LPCWSTR szFileName);

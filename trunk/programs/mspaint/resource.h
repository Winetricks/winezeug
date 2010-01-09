/*
 *  Constants, used in resources.
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

#include <windef.h>
#include <winbase.h>
#include <winuser.h>
#include <winnls.h>
#include <commctrl.h>
#include <dlgs.h>

#define MAIN_MENU               0x201
#define TEXT_MENU               0x202
#define SELECTION_MENU          0x203
#define ID_ACCEL                0x204
#define IDB_TOOLS               0x205
#define IDB_AIRBRUSH            0x206
#define IDB_ERASER              0x20B
#define IDB_ZOOM                0x20C
#define IDB_LINE                0x20D
#define IDB_BRUSH               0x20E
#define IDB_FILL                0x20F
#define IDB_TRANS               0x210
#define IDD_ZOOM                0x207
#define IDD_STRETCH_SKEW        0x208
#define IDD_ATTRIBUTES          0x209
#define IDD_FLIP_ROTATE         0x20A
#define IDI_PAINT               0x1

/* Commands */
#define CMD_NEW                 0x100
#define CMD_OPEN                0x101
#define CMD_SAVE                0x102
#define CMD_SAVE_AS             0x103
#define CMD_PRINT_PREVIEW       0x104
#define CMD_PRINT               0x105
#define CMD_PAGE_SETUP          0x106
#define CMD_EXIT                0x107
#define CMD_WALLPAPAER_TILED    0x108
#define CMD_WALLPAPAER_CENTERED 0x109
#define CMD_UNDO                0x10A
#define CMD_CUT                 0x10B
#define CMD_COPY                0x10C
#define CMD_PASTE               0x10D
#define CMD_DELETE              0x10E
#define CMD_SELECT_ALL          0x10F
#define CMD_REPEAT              0x110
#define CMD_COPY_TO             0x111
#define CMD_PASTE_FROM          0x112
#define CMD_TOOL_BOX            0x113
#define CMD_COLOR_BOX           0x114
#define CMD_STATUS_BAR          0x115
#define CMD_TEXT_TOOL           0x116
#define CMD_ZOOM_NORMAL         0x117
#define CMD_ZOOM_LARGE          0x118
#define CMD_ZOOM_CUSTOM         0x119
#define CMD_SHOW_GRID           0x11A
#define CMD_VIEW_BITMAP         0x11B
#define CMD_SHOW_THUMBNAIL      0x11C
#define CMD_FLIP_ROTATE         0x11D
#define CMD_STRETCH_SKEW        0x11E
#define CMD_INVERT_COLORS       0x12F
#define CMD_ATTRIBUTES          0x120
#define CMD_CLEAR_IMAGE         0x121
#define CMD_DRAW_OPAQUE         0x122
#define CMD_CLEAR_SELECTION     0x123
#define CMD_EDIT_COLOR          0x124
#define CMD_GET_COLORS          0x125
#define CMD_SAVE_COLORS         0x126
#define CMD_HELP_CONTENTS       0x127
#define CMD_HELP_ON_HELP        0x128
#define CMD_HELP_ABOUT_PAINT    0x129

#define IDC_STATIC -1

#define STRING_PAINT            0x170
#define STRING_UNTITLED         0x174
#define STRING_ALL_FILES        0x175
#define STRING_BMP_FILES_BMP    0x176
#define STRING_DOESNOTEXIST     0x179
#define STRING_SAVECHANGE       0x17A
#define STRING_NOTFOUND         0x17B

#define STRING_POLYSELECT       0x200
#define STRING_BOXSELECT        0x201
#define STRING_ERASER           0x202
#define STRING_FLOODFILL        0x203
#define STRING_SPOIT            0x204
#define STRING_MAGNIFIER        0x205
#define STRING_PENCIL           0x206
#define STRING_BRUSH            0x207
#define STRING_AIRBRUSH         0x208
#define STRING_TEXT             0x209
#define STRING_LINE             0x20A
#define STRING_CURVE            0x20B
#define STRING_BOX              0x20C
#define STRING_POLYGON          0x20D
#define STRING_ELLIPSE          0x20E
#define STRING_ROUNDRECT        0x20F
#define STRING_READY            0x210
#define STRING_POSITIVE_INT     0x211
#define STRING_INVALID_BM       0x212
#define STRING_LOSS_COLOR       0x213
#define STRING_MONOCROME_BM     0x215
#define STRING_16COLOR_BM       0x216
#define STRING_256COLOR_BM      0x217
#define STRING_24BIT_BM         0x218
#define STRING_JPEG_FILES       0x219
#define STRING_GIF_FILES        0x21A
#define STRING_TIFF_FILES       0x21B
#define STRING_PNG_FILES        0x21C
#define STRING_ICON_FILES       0x21D
#define STRING_PCX_FILES        0x21E
#define STRING_ALL_PICTURE      0x21F
#define STRING_PALETTE          0x220
#define STRING_NEW                  0x300
#define STRING_OPEN                 0x301
#define STRING_SAVE                 0x302
#define STRING_SAVE_AS              0x303
#define STRING_PRINT_PREVIEW        0x304
#define STRING_PAGE_SETUP           0x305
#define STRING_PRINT                0x306
#define STRING_EXIT                 0x307
#define STRING_WALLPAPAER_TILED     0x308
#define STRING_WALLPAPAER_CENTERED  0x309
#define STRING_UNDO                 0x30A
#define STRING_CUT                  0x30B
#define STRING_COPY                 0x30C
#define STRING_PASTE                0x30D
#define STRING_DELETE               0x30E
#define STRING_SELECT_ALL           0x30F
#define STRING_REPEAT               0x310
#define STRING_COPY_TO              0x311
#define STRING_PASTE_FROM           0x312
#define STRING_TOOL_BOX             0x313
#define STRING_COLOR_BOX            0x314
#define STRING_STATUS_BAR           0x315
#define STRING_TEXT_TOOL            0x316
#define STRING_ZOOM_NORMAL          0x317
#define STRING_ZOOM_LARGE           0x318
#define STRING_ZOOM_CUSTOM          0x319
#define STRING_SHOW_GRID            0x31A
#define STRING_VIEW_BITMAP          0x31B
#define STRING_SHOW_THUMBNAIL       0x31C
#define STRING_FLIP_ROTATE          0x31D
#define STRING_STRETCH_SKEW         0x31E
#define STRING_INVERT_COLORS        0x32F
#define STRING_ATTRIBUTES           0x320
#define STRING_CLEAR_IMAGE          0x321
#define STRING_DRAW_OPAQUE          0x322
#define STRING_CLEAR_SELECTION      0x323
#define STRING_EDIT_COLOR           0x324
#define STRING_GET_COLORS           0x325
#define STRING_SAVE_COLORS          0x326
#define STRING_HELP_CONTENTS        0x327
#define STRING_HELP_ON_HELP         0x328
#define STRING_HELP_ABOUT_PAINT     0x329
#define STRING_SIZE                 0x400
#define STRING_MOVE                 0x401
#define STRING_MINIMIZE             0x402
#define STRING_MAXIMIZE             0x403
#define STRING_NEXTWINDOW           0x404
#define STRING_PREVWINDOW           0x405
#define STRING_CLOSE                0x406
#define STRING_RESTORE              0x407
#define STRING_TASKLIST             0x408

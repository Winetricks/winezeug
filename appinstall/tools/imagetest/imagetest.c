/*
* Gdiplus image loading test program
* 
* Copyright (c) 2009 Vincent Povirk for CodeWeavers
* 
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
* 
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
* 
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

/* To build:
* i586-mingw32msvc-gcc -Wall -I/path/to/wine/source/include -c test.c
* /path/to/wine/source/wine/tools/winegcc/winegcc -b i586-mingw32msvc -B/path/to/wine/source/tools/winebuild --sysroot=/path/to/wine/source test.o -o imagetest.exe -lgdiplus -lole32 -luser32 -lgdi32 -lkernel32
*/

#include "windows.h"
#include "stdio.h"
#include "gdiplus.h"

GpImage *image;

static LRESULT CALLBACK testwindow_wndproc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam)
{
    switch(msg)
    {
        case WM_PAINT:
        {
            PAINTSTRUCT ps;
            GpGraphics *graphics;

            BeginPaint(hwnd, &ps);
            GdipCreateFromHDC(ps.hdc, &graphics);

            GdipDrawImage(graphics, image, 0.0, 0.0);

            GdipDeleteGraphics(graphics);
            EndPaint(hwnd, &ps);
            return 0;
        }
        case WM_LBUTTONDOWN:
            InvalidateRect(hwnd, NULL, FALSE);
            break;
        case WM_DESTROY:
            PostQuitMessage(0);
            break;
    }

    return DefWindowProc(hwnd, msg, wparam, lparam);
}

static void loop(void)
{
    MSG msg;

    while (GetMessageA(&msg, NULL, 0, 0))
    {
        TranslateMessage(&msg);
        DispatchMessageA(&msg);
    }
}

static void register_testwindow_class(void)
{
    WNDCLASSEXA cls;

    ZeroMemory(&cls, sizeof(cls));
    cls.cbSize = sizeof(cls);
    cls.style = 0;
    cls.lpfnWndProc = testwindow_wndproc;
    cls.hInstance = NULL;
    cls.hCursor = LoadCursor(0, IDC_ARROW);
    cls.hbrBackground = (HBRUSH) COLOR_WINDOW;
    cls.lpszClassName = "testwindow";

    RegisterClassExA(&cls);
}

static HWND create_window(void)
{
    register_testwindow_class();
    
    return CreateWindowExA(0, "testwindow", "test window", WS_OVERLAPPEDWINDOW|WS_VISIBLE, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, NULL, NULL, NULL, NULL);
}

int main(int argc, char* argv[])
{
    struct GdiplusStartupInput input;
    ULONG_PTR token;
    GpStatus stat;
    LPWSTR filename;
    int filename_len;

    input.GdiplusVersion = 1;
    input.DebugEventCallback = NULL;
    input.SuppressBackgroundThread = FALSE;
    input.SuppressExternalCodecs = TRUE;
    GdiplusStartup(&token, &input, NULL);

    if (argc < 2)
    {
        printf("Usage: imagetest.exe filename\n");
        return 2;
    }

    filename_len = MultiByteToWideChar(CP_ACP, 0, argv[1], -1, NULL, 0);

    filename = HeapAlloc(GetProcessHeap(), 0, sizeof(WCHAR) * filename_len);

    MultiByteToWideChar(CP_ACP, 0, argv[1], -1, filename, filename_len);

    stat = GdipLoadImageFromFile(filename, &image);
    if (stat != Ok)
    {
        printf("GdipLoadImageFromFile returned %i\n", stat);
        return 3;
    }

    create_window();
    
    loop();

    GdipDisposeImage(image);

    GdiplusShutdown(token);

    return 0;
}

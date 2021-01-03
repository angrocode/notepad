
import time
import win32ui
import win32gui
import win32con
import win32api
from PIL import Image
from pprint import pprint


duhwnd = win32gui.FindWindow('', '')

win32gui.MoveWindow(duhwnd, 10, 10, 1280, 768, True)
win32gui.SendMessage(duhwnd, win32con.WM_ACTIVATE, win32api.MAKELONG(win32con.WA_CLICKACTIVE, 0x0), 0x0)
win32gui.SendMessage(duhwnd, win32con.WM_LBUTTONDOWN, win32con.MK_LBUTTON, win32api.MAKELONG(10, 10))
time.sleep(.1)
win32gui.SendMessage(duhwnd, win32con.WM_LBUTTONUP, 0x0, win32api.MAKELONG(10, 10))



def cycle():
    sleepz = 1
    start_time = time.time()
    time.sleep(sleepz)

    close(duhwnd, 0)

    print('')
    print('time work:', (time.time() - start_time) - sleepz)



def close(hwnd, lvl):

    while True:
        grid, scl = state(hwnd)
        open_lvl = [[n for n, i in enumerate(grid) if i[1] and i[0] == l] for l in range(10)]
        if not len(open_lvl[lvl]): break
        open_lvl.reverse()
        for l in open_lvl:
            l.reverse()
            for i in l:
                mouse(hwnd, grid[i][3], 'l')
            if len(l): break

        time.sleep(.25)


def scroll(hwnd, ud):

    grid, scl = state(hwnd); print(scl)
    hview, hscl, upline, downline, pos = scl
    if not hscl: return
    x, y = pos
    mshift = 10

    if ud == 'd':
        shift = round((y + (hscl / hview) * downline) + (hscl / 25))
    elif ud == 'u':
        shift = 120
    else:
        shift = 0

    win32gui.SendMessage(hwnd, win32con.WM_MOUSEMOVE, 0x0, win32api.MAKELONG(x, y + mshift))

    win32gui.SendMessage(hwnd, win32con.WM_LBUTTONDOWN, win32con.MK_LBUTTON, win32api.MAKELONG(x, y + mshift))
    time.sleep(.1)
    win32gui.SendMessage(hwnd, win32con.WM_MOUSEMOVE, win32con.MK_LBUTTON, win32api.MAKELONG(x, shift + mshift))
    time.sleep(.1)
    win32gui.SendMessage(hwnd, win32con.WM_LBUTTONUP, 0x0, win32api.MAKELONG(x, shift + mshift))

    # win32gui.SendMessage(hwnd, win32con.WM_MOUSEMOVE, 0x0, win32api.MAKELONG(x + 5, shift))


def state(hwnd):

    c_line = (0x142027, 0x1C343C)
    c_arrow = (0xBB9F5B, 0xC0A765, 0xC2AC6A)
    c_bg = (0x000000, 0x142027, 0x1C343C)
    c_scl = (0x547A87, 0xB6DFED)
    x_item = 360
    field = (243, 418, 120, 680)  # sx, ex, sy, ey
    x_line = (7, 11, 15, 19, 23, 27, 31, 35, 39, 43, 47)
    # ! magic number str 80, str 125

    rawimg = screen(hwnd, field)
    w = field[1] - field[0]; h = field[3] - field[2]
    img = Image.frombytes('RGB', (w, h), rawimg[2], 'raw', 'BGRX')
    # img.show()

    rawpx = tuple(map(lambda p: int('%02x%02x%02x' % (p[0], p[1], p[2]), 16), img.getdata()))
    rows = tuple([rawpx[i:i+w] for i in range(0, len(rawpx), w)])

    # bottom lines
    bottom_lines = list(); add = False
    for rpos, row in enumerate(rows):
        row = row[:-25:-1]
        if len(set(c_line) & set(row)) > 0:
            add = True
        elif add:
            add = False
            bottom_lines.append(rpos - 1)

    if len(bottom_lines) == 0:
        print('no detect menu')
        exit(1)

    grig_lines = bottom_lines.copy()
    if bottom_lines[0] < 15: bottom_lines.pop(0) # height 0 item
    if grig_lines[0] >= 15: grig_lines.insert(0, 0)
    grid_menu = tuple(zip(map(lambda p: p + 1 if p > 0 else p, grig_lines), grig_lines[1:]))
    pix_menu = tuple([rawpx[a * w:b * w + 1] for a, b in grid_menu])

    # the nesting level of the menu
    rlevel = list()
    for nl, l in enumerate(bottom_lines):
        if len(set(c_line) & set(rows[l])):
            for np, p in enumerate(rows[l]):
                if p in c_line: rlevel.append(x_line.index(np)); break
        # else:
        #     raise Exception('bottom line level')

    # item bool
    ritem = list()
    for m in pix_menu:
        ritem.append(bool(not len(set(c_arrow) & set(m))))


    # open menu bool
    ropen = list()
    for m in pix_menu:
        if len(set(c_arrow) & set(m)):
            for c in c_arrow:
                if c in m:
                    i = m.index(c)
                    p = len([p for p in m[i - 4:i + 5] if p in c_bg])
                    if p == 7: ropen.append(False); break
                    if p == 5: ropen.append(True); break
                    if p != 7 and p != 5: raise Exception('open menu')
                    break
        else:
            ropen.append(False)

    if len({len(bottom_lines), len(rlevel), len(ritem), len(ropen)}) > 1: raise Exception('Length of the array')

    rx = list(map(lambda l, i: x_item if i else field[0] + x_line[l] + 7, rlevel, ritem))
    ry = list(map(lambda b: field[2] + (b - 12), bottom_lines))

    rcoord = tuple(zip(rx, ry))
    rgrid = tuple(zip(rlevel, ropen, ritem, rcoord))

    # scroll
    scl = [row[-10:-11:-1][0] for row in rows] # prepare scroll pix
    scl = scl[4:-7] # up, down

    for n, c in enumerate(scl):
        if c in c_scl:
            rpos = (408, field[2] + n + 4)
            break
        else:
            rpos = (408, field[2])

    rhview = len(scl) + 4
    rhscl = len([p for p in scl if p in c_scl])
    rupline = bottom_lines[0]
    rdownline = bottom_lines[len(bottom_lines) - 1]

    rscroll = (rhview, rhscl, rupline, rdownline, rpos)

    return rgrid, rscroll


def mouse(hwnd, coord, key, ud='', step=0):
    x, y = coord

    if  key == 'l':
        down = win32con.WM_LBUTTONDOWN
        up = win32con.WM_LBUTTONUP
        wparam = win32con.MK_LBUTTON
    elif key == 'r':
        down = win32con.WM_RBUTTONDOWN
        up = win32con.WM_RBUTTONUP
        wparam = win32con.MK_RBUTTON
    elif key == 'm':
        down = win32con.WM_MBUTTONDOWN
        up = win32con.WM_MBUTTONUP
        wparam = win32con.MK_MBUTTON
    elif key == 'w':
        if  ud == 'u':
            wparam = 0xFF880000
        elif ud == 'd':
            wparam = 0x780000
        else:
            wparam = 0x0
    else:
        return

    lparam = win32api.MAKELONG(x, y)

    win32gui.SendMessage(hwnd, win32con.WM_MOUSEMOVE, 0x0, lparam)


    if key != 'w':
        win32gui.SendMessage(hwnd, down, wparam, lparam)
        time.sleep(0.1)
        win32gui.SendMessage(hwnd, up, 0x0, lparam)

    if key == 'w':
        for s in range(0, step):
            time.sleep(0.1)
            win32gui.SendMessage(hwnd, win32con.WM_MOUSEWHEEL, wparam, lparam)


def screen(hwnd, coord):

    sx, ex, sy, ey = coord
    retlist = list()

    wDC = win32gui.GetDC(hwnd)
    dcObj = win32ui.CreateDCFromHandle(wDC)
    cDC = dcObj.CreateCompatibleDC()
    srcBitMap = win32ui.CreateBitmap()
    srcBitMap.CreateCompatibleBitmap(dcObj, ex - sx, ey - sy)
    cDC.SelectObject(srcBitMap)
    cDC.BitBlt((0, 0), (ex - sx, ey - sy), dcObj, (sx, sy), win32con.SRCCOPY)

    retlist.append(ex - sx)
    retlist.append(ey - sy)
    retlist.append(srcBitMap.GetBitmapBits(True))

    dcObj.DeleteDC()
    cDC.DeleteDC()
    win32gui.ReleaseDC(hwnd, wDC)
    win32gui.DeleteObject(srcBitMap.GetHandle())

    return retlist # width, height, bin image


if __name__ == '__main__':
    cycle()


import time
import win32ui
import win32gui
import win32con
import win32api
from PIL import Image, ImageColor

duhwnd = win32gui.FindWindow('', '')

win32gui.MoveWindow(duhwnd, 10, 10, 1280, 768, True)
win32gui.SendMessage(duhwnd, win32con.WM_ACTIVATE, win32api.MAKELONG(win32con.WA_CLICKACTIVE, 0x0), 0x0)
win32gui.SendMessage(duhwnd, win32con.WM_LBUTTONDOWN, win32con.MK_LBUTTON, win32api.MAKELONG(10, 10))
time.sleep(.1)
win32gui.SendMessage(duhwnd, win32con.WM_LBUTTONUP, 0x0, win32api.MAKELONG(10, 10))

statedb = {l: list() for l in range(10)}
scrolldb = dict()

def cycle():

    state(duhwnd)

    
def close(hwnd, lvl):

    while True:
        state(hwnd)
        if len([z[2] for z in statedb[lvl] if z[0]]) == 0: break
        for i in range(len(statedb) - 1, -1, -1):
            action = ([z[2] for z in statedb[i] if z[0]])
            if len(action) > 0:
                print(i)
                for x, y in action:
                    mouse(hwnd, (x, y), 'l')
                    if i == 0: mouse(hwnd, (x - 10, y), 'l')
                break
            action.clear()

        time.sleep(.15)
        
        
def state(hwnd):

    c_line = (0x142027, 0x1C343C)
    c_arrow = (0xBB9F5B, 0xC0A765, 0xC2AC6A)
    c_bg = (0x000000, 0x142027, 0x1C343C)
    c_sud = (0xB6DFED, )
    c_sp = (0x547A87, 0xB6DFED)
    x_item = 360
    x_scroll = 408
    field = (243, 418, 120, 680)  # sx, ex, sy, ey
    x_line = (7, 11, 15, 19, 23, 27, 31, 35, 39, 43, 47)

    rawimg = screen(hwnd, field)
    w = field[1] - field[0]; h = field[3] - field[2]
    img = Image.frombytes('RGB', (w, h), rawimg[2], 'raw', 'BGRX')
    # img.show()

    rawpx = tuple(map(lambda p: int('%02x%02x%02x' % (p[0], p[1], p[2]), 16), img.getdata()))
    rows = tuple([rawpx[i:i+w] for i in range(0, len(rawpx), w)])

    # bottom lines
    linepos = list(); add = False
    for rpos, row in enumerate(rows):
        row = row[:-25:-1]
        if len(set(c_line) & set(row)) > 0:
            add = True
        elif len(set(c_line) & set(row)) == 0 and add:
            add = False
            linepos.append(rpos - 1)

    if len(linepos) == 0:
        print('no detect menu')
        exit(1)

    # the nesting level of the menu
    zlevel = list()
    for l in linepos:
        for c in c_line:
            if c in rows[l]:
                zlevel.append(x_line.index(rows[l].index(c)))
                break

    templine = linepos.copy()
    if linepos[0] > 15: templine.insert(0, 0)
    gridmenu = tuple(zip(map(lambda p: p + 1 if p > 0 else p, templine), templine[1:]))
    pixmenu = tuple([rawpx[a*w:b*w+1] for a, b in gridmenu])

    # item bool
    zitem = list()
    for m in pixmenu:
        zitem.append(bool(not len(set(c_arrow) & set(m))))

    # open menu bool
    zopen = list()
    for m in pixmenu:
        if len(set(c_arrow) & set(m)):
            i = [p for p, k in enumerate(m) if k in c_arrow][0]
            vfr = len([p for p in m[i - 4:i + 5] if p in c_bg])
            if vfr == 7: zopen.append(False)
            if vfr == 5: zopen.append(True)
            if vfr != 7 and vfr != 5: raise Exception('Detect open')
        else:
            zopen.append(False)

    # scroll
    up = False; down = False; spos = False
    scl = [row[-10:-11:-1][0] for row in rows]

    if c_sp[0] in scl or c_sp[1] in scl:

        for i in range(0, len(scl)):
            if scl[i] in c_sud: up = i; break
            if scl[i] in c_sp: up = i; break

        for i in range(len(scl) - 1, 0, -1):
            if scl[i] in c_sud: down = i; break
            if scl[i] in c_sp: down = i; break

        if not up or not down: raise Exception('Scroll range')

        for i in range(0, len(scl)):
            if scl[i] in c_sp and scl[i + 1] in c_sp and scl[i + 2] in c_sp: spos = i; break

        zscroll = {
            'scl': len([p for p in scl if p in c_sp]),
            'vpos': (field[2] + up, field[2] + down),
            'spos': (x_scroll, field[2] + spos),
            'topl': linepos[0],
            'bottoml': linepos[len(linepos) - 1]
        }

    else:

        zscroll = {
            'scl': 0,
            'vpos': (field[2], field[3]),
            'spos': (x_scroll, field[2]),
            'topl': linepos[0],
            'bottoml': linepos[len(linepos) - 1]
        }

    if len({len(linepos), len(zlevel), len(zopen), len(zitem)}) > 1: raise Exception('Length of the array')

    global statedb
    global scrolldb

    for k in statedb.keys():
        statedb[k].clear()

    for i, y in enumerate(linepos):
        x = x_item if zitem[i] else field[0] + x_line[zlevel[i]] + 7
        y = field[2] + (y - 12)
        statedb[zlevel[i]].append((zopen[i], zitem[i], (x, y)))

    scrolldb.clear()
    scrolldb = zscroll


def get_img(hwnd, coord):

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

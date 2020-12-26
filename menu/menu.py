
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


def cycle():

    start_time = time.time()

    state(duhwnd)

    # time.sleep(1)


def state_new(hwnd):

    c_line = (0x142027,)
    c_arrow = (0xBB9F5B, 0xC0A765)
    c_bg = (0x000000, 0x142027)
    c_sud = 0xB6DFED
    c_sp = 0x547A87
    x_item = 360
    field = (243, 418, 120, 680)  # sx, ex, sy, ey
    x_line = (7, 11, 15, 19, 23, 27, 31, 35, 39, 43, 47)

    rawimg = get_img(hwnd, field)
    w = field[1] - field[0]; h = field[3] - field[2]
    img = Image.frombytes('RGB', (w, h), rawimg[2], 'raw', 'BGRX')
    # img.show()

    rawpx = tuple(map(lambda p: int('%02x%02x%02x' % (p[0], p[1], p[2]), 16), img.getdata()))
    rows = tuple([rawpx[i:i+w] for i in range(0, len(rawpx), w)])

    # bottom lines
    linepos = list(); add = False
    for rpos, row in enumerate(rows):
        row = row[:-25:-1]
        for c in c_line:
            if c in row:
                add = True
            elif add:
                add = False
                linepos.append(rpos - 1)

    if linepos[0] < 15:
        linepos.pop(0)
        print('0 position not available')

    # the nesting level of the menu
    zlevel = list()
    for l in linepos:
        for c in c_line:
            if c in rows[l]:
                zlevel.append(x_line.index(rows[l].index(c)))
                break

    templine = linepos.copy()
    templine.insert(0, 0)
    hmenuitm = tuple(zip(map(lambda p: p + 1 if p > 0 else p, templine), templine[1:]))

    # menu or item
    zitem = list(); pnext = False; flagitem = False
    for height in hmenuitm:
        for l in rows[height[0]:height[1] + 1]:
            for c in c_arrow:
                if c in l:
                    flagitem = False
                    pnext = True
                    break
                else:
                    flagitem = True

            if pnext:
                pnext = False
                break

        zitem.append(flagitem)

    # open menu
    zopen = list(); pnext = False; flagopen = False
    for height in hmenuitm:
        # print('====')
        for l in rows[height[0]:height[1] + 1]:
            for c in c_arrow:
                if c in l:
                    i = l.index(c)
                    vfr = len([p for p in l[i - 4:i + 5] if p in c_bg])
                    if vfr == 7: flagopen = False
                    if vfr == 5: flagopen = True
                    if vfr != 7 and vfr != 5: raise Exception('Detect open')
                    pnext = True
                    break
                else:
                    flagopen = False

            if pnext:
                pnext = False
                break

        zopen.append(flagopen)

    # scroll
    up = False; down = False
    scl = [row[-10:-11:-1][0] for row in rows]
    # print(scl)

    if c_sp in scl:

        for i in range(0, len(scl)):
            if scl[i] == c_sud: up = i; break
            if scl[i] == c_sp: up = i; break

        for i in range(len(scl) - 1, 0, -1):
            if scl[i] == c_sud: down = i; break
            if scl[i] == c_sp: down = i; break

        if not up or not down: raise Exception('Scroll range')

        scroll = {'scl': len([p for p in scl if p == c_sp]), 'view': down - up}

    else:

        scroll = {'scl': 0, 'view': field[3] - field[2]}


    if len(zlevel) != len(zitem) or len(zitem) != len(zopen) or len(zlevel) != len(zopen):
        raise Exception('Length of the array 1')
    if len(linepos) != (len(zlevel) or len(zitem) or len(zopen)):
        raise Exception('Length of the array 2')

    print(linepos)

    retdict = {}
    for pos, pix in enumerate(linepos):
        pass



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

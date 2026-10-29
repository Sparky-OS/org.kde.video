#!/usr/bin/python3
"""Screenshot the whole workspace through KWin's ScreenShot2 D-Bus API.

Used by session-smoke.sh, where Spectacle hangs in a headless nested KWin.
KWin must run with KWIN_SCREENSHOT_NO_PERMISSION_CHECKS=1.
Usage: screenshot.py OUTPUT.png
"""
import os
import sys

import dbus
from PIL import Image

read_fd, write_fd = os.pipe()
screenshot = dbus.Interface(
    dbus.SessionBus().get_object("org.kde.KWin", "/org/kde/KWin/ScreenShot2"),
    "org.kde.KWin.ScreenShot2",
)
meta = screenshot.CaptureWorkspace({"native-resolution": True}, dbus.types.UnixFd(write_fd))
os.close(write_fd)

with os.fdopen(read_fd, "rb") as pipe:
    data = pipe.read()

# KWin sends QImage::Format_ARGB32 / RGB32 data, which is BGRA in memory on little-endian.
width, height, stride = int(meta["width"]), int(meta["height"]), int(meta["stride"])
Image.frombuffer("RGBA", (width, height), data, "raw", "BGRA", stride, 1).convert("RGB").save(sys.argv[1])

# org.kde.video

A video wallpaper and lock screen for KDE Plasma 6. I learned how to do it from a [KDE Forum discussion](https://forum.kde.org/viewtopic.php?f=289&t=131783), and contributors have added to it since.

Feel free to use and add to this project!

Still on Plasma 5? The last Plasma 5 version is commit [`0e71b41`](https://github.com/Sparky-OS/org.kde.video/tree/0e71b41).

## Example

[![Flaming Plasma lockscreen](http://i3.ytimg.com/vi/T7cHWc-OOvE/hqdefault.jpg)](https://youtu.be/T7cHWc-OOvE)

## Instructions

Clone this repository and install it with `kpackagetool6`:

```sh
git clone https://github.com/Sparky-OS/org.kde.video.git
kpackagetool6 --type Plasma/Wallpaper --install org.kde.video
```

Use `--upgrade` instead of `--install` to update. Then go into the wallpaper or lock screen settings and choose "Video" instead of "Image".

SparkyLinux users can install it from APTus instead.

## FAQ

<b>The wallpaper is black, or plays sound but no picture. How can I solve it?</b>

Qt 6 plays video through FFmpeg, so it can only play what your FFmpeg build can decode. Fedora's default `ffmpeg-free` leaves out H.264 and HEVC; installing the full FFmpeg from RPM Fusion fixes that. To see the actual error, run `journalctl --user -u plasma-plasmashell -f` and look for lines starting with `org.kde.video:`.

## Playlists

Choose an `.m3u` or `.m3u8` file instead of a video to play several videos in a row, in order or shuffled. Each line is a video path or URL; lines starting with `#` are ignored. Relative paths are relative to the playlist's folder, and spaces in names are fine.

Playlists need Plasma's `org.kde.plasma.plasma5support` QML module, which most Plasma 6 installs already have.

## Development

`ci/check.sh` runs the same checks as CI: `qmllint`, the QML tests in `tests/`, and a test install with `kpackagetool6`. It needs Qt 6 and Plasma 6 development tools; CI runs it in a Fedora container (see `.github/workflows/check.yml`).

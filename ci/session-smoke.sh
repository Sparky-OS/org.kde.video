#!/bin/bash
# Runs the wallpaper for real: plasmashell in a headless nested KWin, playing a
# playlist of three coloured clips, with screenshots taken as it advances.
# Run from the repository root, inside a Plasma 6 container (see check.yml):
#   ci/session-smoke.sh OUTPUT_DIR
# With a GPU render node (podman --device /dev/dri) it also saves screenshots.
set -euo pipefail

out=$(realpath "${1:?output dir}")
mkdir -p "$out"
work=$(mktemp -d)
export HOME="$work/home" XDG_RUNTIME_DIR="$work/run"
mkdir -p "$HOME" "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

# Three 3-second VP9 clips (ffmpeg-free can encode these), in a folder with a
# space, listed by an m3u with relative entries.
vids="$work/my videos"
mkdir -p "$vids"
for c in red green blue; do
    ffmpeg -loglevel error -f lavfi -i "color=c=$c:s=640x360:d=3:r=25" \
        -vf "drawtext=text='$c %{n}':fontsize=60:fontcolor=white:x=40:y=40" \
        -c:v libvpx-vp9 -b:v 200k "$vids/clip $c.webm"
done
cp "$vids/clip green.webm" "$vids/single.webm"
printf '#EXTM3U\nclip red.webm\nclip green.webm\nclip blue.webm\n' > "$vids/list.m3u"

kpackagetool6 --type Plasma/Wallpaper --install . >/dev/null

cat > "$work/session.sh" <<EOF
#!/bin/bash
exec > "$out/session.log" 2>&1
set -x
# Started here rather than by D-Bus activation, which runs before KWin has
# set WAYLAND_DISPLAY and makes it abort.
/usr/libexec/kactivitymanagerd &
plasmashell --no-respawn > "$out/plasmashell.log" 2>&1 &
for i in \$(seq 60); do
    qdbus-qt6 org.kde.plasmashell /PlasmaShell >/dev/null 2>&1 && break
    sleep 0.5
done
sleep 3
qdbus-qt6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
    desktops().forEach(d => {
        d.wallpaperPlugin = "org.kde.video";
        d.currentConfigGroup = ["Wallpaper", "org.kde.video", "General"];
        d.writeConfig("Video", "file://$vids/list.m3u");
        d.writeConfig("Muted", true);
    });'
for t in 01 02 03 04 05 06 07 08 09 10 11 12; do
    sleep 1
    timeout 8 python3 "$PWD/ci/screenshot.py" "$out/t\$t.png"
done
# Change the existing wallpaper in place, after the playlist has wrapped. A
# stale isPlaylist binding used to leave this single video stopped.
qdbus-qt6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
    desktops().forEach(d => {
        d.currentConfigGroup = ["Wallpaper", "org.kde.video", "General"];
        d.writeConfig("Video", "file://$vids/single.webm");
    });'
sleep 3
EOF
chmod +x "$work/session.sh"

# kwin_wayland carries a file capability (cap_sys_nice) that unprivileged
# containers refuse to exec; a plain copy drops it.
cp "$(command -v kwin_wayland)" "$work/kwin_wayland"

KWIN_SCREENSHOT_NO_PERMISSION_CHECKS=1 dbus-run-session -- "$work/kwin_wayland" --virtual --no-lockscreen \
    --width 640 --height 360 --exit-with-session "$work/session.sh" \
    > "$out/kwin.log" 2>&1 || true

echo "== wallpaper warnings"
grep "org.kde.video" "$out/plasmashell.log" || echo "(none)"

# FFmpeg logs each file it opens. The playlist must play in order and wrap.
echo "== files played"
played=$(grep -o "clip [a-z]*\.webm" "$out/plasmashell.log" | tr '\n' ' ')
echo "$played"
[[ $played == "clip red.webm clip green.webm clip blue.webm clip red.webm"* ]]
# Match a decoder file-open trace, not a configuration or error message.
grep -Eq "(from |Opening ).*/single\.webm" "$out/plasmashell.log"

# Screenshots need OpenGL compositing, i.e. a /dev/dri render node; CI has none.
if ls "$out"/t*.png >/dev/null 2>&1; then
    echo "== screenshots in $out"
else
    echo "== no screenshots (no GPU render node?)"
fi

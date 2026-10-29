.pragma library

// Qt 6 removed the QML Playlist type, so playlist handling lives here.
// Pure functions only, so tests/tst_playlist.qml can cover them.

function isPlaylist(url) {
    return /\.m3u8?$/i.test(String(url));
}

// Local file URL -> path, for display and for reading the file.
function toLocalPath(url) {
    var s = String(url);
    if (s.indexOf("file://") !== 0) {
        return s;
    }
    s = s.substring("file://".length);
    try {
        return decodeURIComponent(s);
    } catch (e) {
        return s; // already decoded, e.g. a literal '%' in "100% fun.mp4"
    }
}

// Parse m3u/m3u8 text into a list of URLs. Comment lines (#EXTM3U, #EXTINF...)
// and blank lines are skipped. Relative entries resolve against the playlist's
// own folder. Unlike the Plasma 5 version, paths may contain spaces.
function parseM3u(text, playlistUrl) {
    var base = String(playlistUrl);
    if (base.indexOf("file://") === 0) {
        // Config URLs are stored decoded ("my folder"), so re-encode the base;
        // otherwise a '#' or '?' in a folder name would end the path.
        base = "file://" + encodePath(toLocalPath(base));
    }
    base = base.substring(0, base.lastIndexOf("/") + 1);

    var urls = [];
    var lines = String(text).split(/\r?\n/);
    for (var i = 0; i < lines.length; i++) {
        var line = lines[i].trim();
        if (line === "" || line.charAt(0) === "#") {
            continue;
        }
        if (/^[a-z][a-z0-9+.-]*:\/\//i.test(line)) {
            urls.push(line); // already a URL
        } else if (line.charAt(0) === "/") {
            urls.push("file://" + encodePath(line));
        } else {
            urls.push(base + encodePath(line));
        }
    }
    return urls;
}

function encodePath(path) {
    return path.split("/").map(encodeURIComponent).join("/");
}

// Fisher-Yates. Returns a new array; random is injectable for tests.
function shuffled(list, random) {
    random = random || Math.random;
    var out = list.slice();
    for (var i = out.length - 1; i > 0; i--) {
        var j = Math.floor(random() * (i + 1));
        var tmp = out[i];
        out[i] = out[j];
        out[j] = tmp;
    }
    return out;
}

// Single-quote a string for /bin/sh.
function shellQuote(s) {
    return "'" + String(s).replace(/'/g, "'\\''") + "'";
}

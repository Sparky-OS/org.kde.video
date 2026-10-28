import QtQuick
import QtTest

import "../contents/ui/Playlist.js" as Playlist

TestCase {
    name: "Playlist"

    function test_isPlaylist() {
        verify(Playlist.isPlaylist("file:///v/list.m3u"));
        verify(Playlist.isPlaylist("file:///v/LIST.M3U8"));
        verify(!Playlist.isPlaylist("file:///v/clip.mp4"));
        verify(!Playlist.isPlaylist("file:///v/m3u.mkv"));
        verify(!Playlist.isPlaylist(""));
    }

    function test_toLocalPath() {
        compare(Playlist.toLocalPath("file:///home/me/my%20clip.mp4"), "/home/me/my clip.mp4");
        compare(Playlist.toLocalPath("/already/a/path"), "/already/a/path");
        compare(Playlist.toLocalPath("file:///v/100% fun.mp4"), "/v/100% fun.mp4");
    }

    function test_parseM3u() {
        const text = "#EXTM3U\n#EXTINF:10,First\nfirst clip.mp4\r\n\n  \n/abs/second.mkv\nhttps://example.com/third.webm\n";
        compare(Playlist.parseM3u(text, "file:///home/me/vids/list.m3u"), [
            "file:///home/me/vids/first%20clip.mp4",
            "file:///abs/second.mkv",
            "https://example.com/third.webm"
        ]);
    }

    function test_parseM3uWithDecodedBaseAndAwkwardNames() {
        // FileDialog URLs end up in the config decoded, with literal spaces.
        const text = "clip #2.mp4\nwhat?.mkv\n";
        compare(Playlist.parseM3u(text, "file:///home/me/my vids/list.m3u"), [
            "file:///home/me/my%20vids/clip%20%232.mp4",
            "file:///home/me/my%20vids/what%3F.mkv"
        ]);
    }

    function test_parseEmpty() {
        compare(Playlist.parseM3u("", "file:///x/list.m3u"), []);
        compare(Playlist.parseM3u("#EXTM3U\n", "file:///x/list.m3u"), []);
    }

    function test_shuffledKeepsEveryItem() {
        const list = ["a", "b", "c", "d", "e"];
        const out = Playlist.shuffled(list);
        compare(out.length, list.length);
        compare(out.slice().sort(), list);
        compare(list, ["a", "b", "c", "d", "e"]); // input untouched
    }

    function test_shuffledIsDeterministicWithInjectedRandom() {
        compare(Playlist.shuffled(["a", "b", "c"], () => 0), ["b", "c", "a"]);
    }

    function test_shellQuote() {
        compare(Playlist.shellQuote("it's here"), "'it'\\''s here'");
        compare(Playlist.shellQuote("$(rm -rf ~)"), "'$(rm -rf ~)'");
    }
}

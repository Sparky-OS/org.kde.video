import QtQuick
import QtTest

import "../contents/ui"
import "../contents/ui/Playlist.js" as Playlist

// Reads a real playlist file from disk through the same path the wallpaper uses.
TestCase {
    name: "M3uReader"

    M3uReader {
        id: reader
    }

    SignalSpy {
        id: finishedSpy
        target: reader
        signalName: "finished"
    }

    SignalSpy {
        id: failedSpy
        target: reader
        signalName: "failed"
    }

    function init() {
        finishedSpy.clear();
        failedSpy.clear();
    }

    function test_readsFileWithAwkwardPath() {
        // Spaces and a single quote in the path exercise the shell quoting.
        const url = Qt.resolvedUrl("data/it's a folder/my list.m3u").toString();
        reader.read(url);
        finishedSpy.wait(5000);
        compare(failedSpy.count, 0);

        const urls = Playlist.parseM3u(finishedSpy.signalArguments[0][1], url);
        compare(urls.length, 3);
        verify(urls[0].endsWith("/it's%20a%20folder/first%20clip.mp4"), urls[0]);
        compare(urls[1], "file:///abs/path/second.mkv");
        compare(urls[2], "https://example.com/third.webm");
    }

    function test_missingFileFails() {
        reader.read(Qt.resolvedUrl("data/does not exist.m3u").toString());
        failedSpy.wait(5000);
        compare(finishedSpy.count, 0);
    }
}

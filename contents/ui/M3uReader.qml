import QtQuick
import org.kde.plasma.plasma5support as P5Support

import "Playlist.js" as Playlist

// Reads a playlist file's text. Qt 6 blocks XMLHttpRequest on local files, so
// this goes through Plasma5Support's executable engine instead. main.qml loads
// it with a Loader, so a missing plasma5support only breaks playlists.
P5Support.DataSource {
    id: reader

    signal finished(string playlistUrl, string text)
    signal failed(string playlistUrl, string message)

    property var pending: ({}) // command -> playlist URL

    function read(playlistUrl) {
        const command = "cat -- " + Playlist.shellQuote(Playlist.toLocalPath(playlistUrl));
        pending[command] = String(playlistUrl);
        connectSource(command);
    }

    engine: "executable"

    onNewData: (sourceName, data) => {
        const playlistUrl = pending[sourceName];
        delete pending[sourceName];
        disconnectSource(sourceName);

        if (data["exit code"] === 0) {
            finished(playlistUrl, data["stdout"]);
        } else {
            failed(playlistUrl, data["stderr"]);
        }
    }
}

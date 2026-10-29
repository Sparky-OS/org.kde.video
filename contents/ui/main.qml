import QtQuick
import QtMultimedia
import org.kde.plasma.plasmoid

import "Playlist.js" as Playlist

WallpaperItem {
    id: root

    // Config keys are unchanged from the Plasma 5 version, so existing settings carry over.
    readonly property string videoUrl: configuration.Video
    readonly property bool shuffle: configuration.Shuffle
    readonly property bool isPlaylist: Playlist.isPlaylist(videoUrl)

    property var queue: []          // playlist URLs, in play order
    property int queueIndex: -1
    property int failuresInARow: 0  // stops a playlist of broken files from spinning

    onVideoUrlChanged: Qt.callLater(load)
    onShuffleChanged: if (isPlaylist) Qt.callLater(load)
    Component.onCompleted: Qt.callLater(load)

    // This is what Qt's Video element is made of. Video doesn't expose
    // mediaStatus, which the playlist needs to know when a video has ended.
    VideoOutput {
        id: videoOutput
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
    }

    MediaPlayer {
        id: player
        videoOutput: videoOutput
        audioOutput: AudioOutput {
            muted: root.configuration.Muted
        }

        playbackRate: root.configuration.Rate

        // A single video loops inside the player, which avoids reloading the file
        // (and the black flash that came with it) on every pass.
        loops: root.isPlaylist ? 1 : MediaPlayer.Infinite

        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.EndOfMedia && root.isPlaylist) {
                root.failuresInARow = 0;
                root.playNext();
            }
        }

        onErrorOccurred: (error, errorString) => {
            console.warn("org.kde.video:", source, errorString);
            if (root.isPlaylist && ++root.failuresInARow < root.queue.length) {
                root.playNext();
            }
        }
    }

    Loader {
        id: m3uReader
        active: root.isPlaylist
        source: "M3uReader.qml"
        onLoaded: item.read(root.videoUrl)
        onStatusChanged: {
            if (status === Loader.Error) {
                console.warn("org.kde.video: playlists need the org.kde.plasma.plasma5support QML module");
            }
        }
    }

    Connections {
        target: m3uReader.item
        function onFinished(playlistUrl, text) {
            if (playlistUrl !== root.videoUrl) {
                return; // the setting changed while we were reading
            }
            const urls = Playlist.parseM3u(text, playlistUrl);
            root.queue = root.shuffle ? Playlist.shuffled(urls) : urls;
            root.queueIndex = -1;
            root.failuresInARow = 0;
            root.playNext();
        }
        function onFailed(playlistUrl, message) {
            console.warn("org.kde.video: cannot read playlist", playlistUrl, message);
        }
    }

    function load() {
        player.stop();
        queue = [];
        queueIndex = -1;

        if (videoUrl === "") {
            player.source = "";
        } else if (isPlaylist) {
            // If the Loader isn't ready yet, its onLoaded does the read. A repeat
            // read of the same file while one is pending is a no-op in DataSource.
            if (m3uReader.item) {
                m3uReader.item.read(videoUrl);
            }
        } else {
            player.source = videoUrl;
            player.play();
        }
    }

    function playNext() {
        if (queue.length === 0) {
            return;
        }
        queueIndex = (queueIndex + 1) % queue.length;
        if (queueIndex === 0 && shuffle && queue.length > 1) {
            queue = Playlist.shuffled(queue);
        }
        player.source = queue[queueIndex];
        player.play();
    }
}

/* Advice: */
// Q: How to debug this beautiful thing?
// A: Watch plasmashell's log while you change settings:
//    journalctl --user -u plasma-plasmashell -f

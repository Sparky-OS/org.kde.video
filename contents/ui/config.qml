import QtCore
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Dialogs as QtDialogs
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

import "Playlist.js" as Playlist

Kirigami.FormLayout {
    id: root
    twinFormLayouts: parentLayout

    property alias formLayout: root

    property string cfg_Video
    property string cfg_VideoDefault
    property string cfg_Folder
    property string cfg_FolderDefault
    property alias cfg_Muted: mutedCheckBox.checked
    property bool cfg_MutedDefault
    property alias cfg_Shuffle: shuffleCheckBox.checked
    property bool cfg_ShuffleDefault
    property alias cfg_Rate: rateSlider.value
    property real cfg_RateDefault

    readonly property string domain: "plasma_wallpaper_org.kde.video"

    RowLayout {
        Kirigami.FormData.label: i18nd(root.domain, "Video or playlist:")

        QQC2.TextField {
            Layout.minimumWidth: Kirigami.Units.gridUnit * 16
            readOnly: true
            placeholderText: i18nd(root.domain, "No file selected")
            text: Playlist.toLocalPath(root.cfg_Video)
        }

        QQC2.Button {
            icon.name: "document-open"
            text: i18nd(root.domain, "Browse…")
            onClicked: fileDialog.open()
        }
    }

    QQC2.CheckBox {
        id: mutedCheckBox
        Kirigami.FormData.label: i18nd(root.domain, "Audio:")
        text: i18nd(root.domain, "Muted")
    }

    QQC2.CheckBox {
        id: shuffleCheckBox
        Kirigami.FormData.label: i18nd(root.domain, "Playlist:")
        text: i18nd(root.domain, "Shuffle")
        enabled: Playlist.isPlaylist(root.cfg_Video)
    }

    RowLayout {
        Kirigami.FormData.label: i18nd(root.domain, "Playback rate:")

        QQC2.Slider {
            id: rateSlider
            Layout.preferredWidth: Kirigami.Units.gridUnit * 12
            // The Plasma 5 slider went down to 0, which froze the video.
            from: 0.1
            to: 1.0
            stepSize: 0.05
        }

        QQC2.Label {
            text: i18nd(root.domain, "%1×", rateSlider.value.toFixed(2))
        }
    }

    QtDialogs.FileDialog {
        id: fileDialog
        title: i18nd(root.domain, "Choose a Video or Playlist")
        currentFolder: root.cfg_Folder !== ""
            ? root.cfg_Folder
            : StandardPaths.writableLocation(StandardPaths.MoviesLocation)
        nameFilters: [
            i18nd(root.domain, "Videos and playlists (%1)",
                  "*.mp4 *.m4v *.mkv *.webm *.mov *.avi *.mpg *.mpeg *.ogv *.ogg *.flv *.m3u *.m3u8"),
            i18nd(root.domain, "All files (*)")
        ]
        onAccepted: {
            root.cfg_Video = selectedFile.toString();
            root.cfg_Folder = currentFolder.toString();
        }
    }
}

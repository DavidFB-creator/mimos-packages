// Packaged as mimos-welcome-live. Live context only (ADR-093). No Settings:
// the Live session is ephemeral and this window stores nothing.
import QtQuick
import QtQuick.Controls

ApplicationWindow {
    id: window

    objectName: "welcomeLiveWindow"
    visible: true
    width: 960
    height: 680
    minimumWidth: 760
    minimumHeight: 540
    title: "Centro de MimOS"
    color: centro.ground
    readonly property bool liveEnvironment:
        Qt.application.arguments.indexOf("--mimos-context=live") !== -1
    readonly property bool darkAppearance:
        Qt.application.arguments.indexOf("--mimos-appearance=oscuro") !== -1

    onActiveChanged: {
        if (active) {
            Qt.callLater(centro.forceActiveFocus)
        }
    }

    Main {
        id: centro
        anchors.fill: parent
        darkAppearance: window.darkAppearance
        onCloseRequested: window.close()
        onInstallerRequested: {
            if (window.liveEnvironment) {
                Qt.exit(10)
            }
        }
    }
}

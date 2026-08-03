// Packaged as mimos-welcome.
import QtCore
import QtQuick
import QtQuick.Controls

ApplicationWindow {
    id: window

    objectName: "welcomeWindow"
    visible: true
    width: 960
    height: 680
    minimumWidth: 760
    minimumHeight: 540
    title: "Centro de MimOS"
    color: "#151320"
    readonly property bool liveEnvironment:
        Qt.application.arguments.indexOf("--mimos-context=live") !== -1

    Settings {
        location: StandardPaths.writableLocation(StandardPaths.ConfigLocation)
                  + "/mimos/centro.conf"
        category: "Privacy"
        property alias showAfterUpdates: centro.showAfterUpdates
        property alias includeHardwareDetails: centro.includeHardwareDetails
        property alias includeRecentLogs: centro.includeRecentLogs
    }

    onActiveChanged: {
        if (active) {
            Qt.callLater(centro.focusCurrentPage)
        }
    }

    Main {
        id: centro
        anchors.fill: parent
        liveEnvironment: window.liveEnvironment
        onCloseRequested: window.close()
        onInstallerRequested: {
            if (window.liveEnvironment) {
                Qt.exit(10)
            }
        }
    }
}

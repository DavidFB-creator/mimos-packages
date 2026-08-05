// Packaged as mimos-welcome. Installed context only (ADR-093).
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
    color: centro.ground
    readonly property bool installedContext:
        Qt.application.arguments.indexOf("--mimos-context=installed") !== -1
    readonly property bool darkAppearance:
        Qt.application.arguments.indexOf("--mimos-appearance=oscuro") !== -1

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
        darkAppearance: window.darkAppearance
        onCloseRequested: window.close()
        onThemeRequested: variant => {
            // The exits are the whole action channel: the launcher applies
            // the Global Theme and relaunches (ADR-093). Fail closed on the
            // context flag, mirroring the Live installer gate.
            if (window.installedContext) {
                Qt.exit(variant === "oscuro" ? 12 : 11)
            }
        }
        onDiscoverRequested: {
            if (window.installedContext) {
                Qt.exit(13)
            }
        }
    }
}

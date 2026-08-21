// Packaged as mimos-welcome. Tienda de MimOS shell (ADR-152): translates
// the view's signals into the exit statuses the launcher acts on, and
// persists the pending selection through Settings so the launcher can
// read it back -- the same file-as-shared-contract pattern the Centro
// uses for showAfterUpdates (ADR-093).
import QtCore
import QtQuick
import QtQuick.Controls

ApplicationWindow {
    id: window

    objectName: "tiendaWindow"
    visible: true
    width: 900
    height: 640
    minimumWidth: 720
    minimumHeight: 520
    title: "Tienda de MimOS"
    color: tienda.ground
    readonly property bool installedContext:
        Qt.application.arguments.indexOf("--mimos-context=installed") !== -1
    readonly property bool darkAppearance:
        Qt.application.arguments.indexOf("--mimos-appearance=oscuro") !== -1
    readonly property string instaladas: {
        for (const argumento of Qt.application.arguments) {
            if (argumento.startsWith("--mimos-instaladas=")) {
                return argumento.slice("--mimos-instaladas=".length);
            }
        }
        return "";
    }

    Settings {
        location: StandardPaths.writableLocation(StandardPaths.ConfigLocation)
                  + "/mimos/tienda.conf"
        category: "Seleccion"
        property alias paquetes: tienda.seleccionPendiente
    }

    TiendaMain {
        id: tienda
        anchors.fill: parent
        darkAppearance: window.darkAppearance
        instaladas: window.instaladas
        onCloseRequested: window.close()
        onInstalarRequested: {
            // The exit is the whole action channel: the launcher re-reads
            // the persisted selection and validates every token against
            // the shipped allowlist before pacman sees a single name.
            if (window.installedContext) {
                Qt.exit(14)
            }
        }
        onBusquedaAvanzadaRequested: {
            if (window.installedContext) {
                Qt.exit(15)
            }
        }
    }
}

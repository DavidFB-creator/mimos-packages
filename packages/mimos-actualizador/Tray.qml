// The MimOS updater's tray icon.
//
// Purely presentational, and deliberately incapable: no Process, no network,
// no file access, no dynamic code. It is handed three numbers by its runner
// and hands back an exit status. Everything that touches the system lives in
// mimos-actualizador, which the contract can read in one sitting. See
// ADR-104 and, for the pattern, ADR-093.
import QtQuick
import Qt.labs.platform

SystemTrayIcon {
    id: bandeja

    // Breeze's own update icon, which follows the colour scheme, so the tray
    // stays legible in Claro and Oscuro alike. That was the whole of ADR-096:
    // an icon that does not follow the scheme disappears in one of them.
    icon.name: 'system-software-update'
    visible: true

    // Declared and required, not read from a context property. Context
    // properties are unqualified lookups, which qmllint rejects and which
    // hide typos until runtime -- a tray that silently showed zero because a
    // name was misspelled would look exactly like a system with no updates.
    // The runner supplies these through setInitialProperties.
    required property int oficiales
    required property int aur
    required property int flatpak

    readonly property int total: oficiales + aur + flatpak

    // Counts written out as whole sentences rather than assembled from
    // fragments, because "1 actualizaciones" is the kind of thing that makes
    // a system feel machine-made. Each form is its own translatable string:
    // MimOS ships Spanish and Catalan (ADR-159), and both split at exactly
    // one, so a singular/plural pair is the honest shape -- Qt's %n plural
    // machinery would need a catalogue for the SOURCE language too, since an
    // untranslated %n string has no plural forms of its own.
    readonly property string resumen: total === 1
        ? qsTr("Hay 1 actualización disponible")
        : qsTr("Hay %1 actualizaciones disponibles").arg(total)

    readonly property string detalle: {
        var partes = [];
        if (oficiales > 0) {
            partes.push(oficiales === 1
                ? qsTr("1 oficial")
                : qsTr("%1 oficiales").arg(oficiales));
        }
        if (aur > 0) {
            partes.push(qsTr("%1 del AUR").arg(aur));
        }
        if (flatpak > 0) {
            partes.push(flatpak === 1
                ? qsTr("1 Flatpak")
                : qsTr("%1 de Flatpak").arg(flatpak));
        }
        return partes.join(' · ');
    }

    tooltip: resumen + (detalle.length > 0 ? '\n' + detalle : '')

    menu: Menu {
        MenuItem {
            text: qsTr("Actualizar ahora")
            onTriggered: Qt.exit(20)
        }
        MenuItem {
            text: qsTr("Volver a comprobar")
            onTriggered: Qt.exit(21)
        }
        MenuSeparator {}
        MenuItem {
            text: qsTr("Ocultar hasta la próxima")
            onTriggered: Qt.exit(0)
        }
    }

    // Clicking the icon is the shortest path to the thing the icon is for.
    onActivated: function (reason) {
        if (reason === SystemTrayIcon.Trigger) {
            Qt.exit(20);
        }
    }

    // Told once, when the process appears -- which the launcher arranges to
    // happen exactly when the counts change, never on a timer.
    Component.onCompleted: {
        if (total > 0) {
            bandeja.showMessage(
                resumen,
                detalle.length > 0
                    ? detalle + "\n" + qsTr("Pulsa para actualizar tu MimOS.")
                    : qsTr("Pulsa para actualizar tu MimOS."));
        }
    }
}

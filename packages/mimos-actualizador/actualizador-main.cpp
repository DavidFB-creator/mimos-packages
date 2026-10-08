// MimOS updater runner.
//
// It exists for the same reason Centro de MimOS's does (ADR-093): the generic
// qml6 tool declares its own identity, so the notification would arrive from
// "qml" wearing a Qt logo. Here it matters more than for a window, because a
// notification about updating the operating system is exactly the shape a
// person should be able to trust at a glance -- an unrecognisable sender is
// how people learn to click things they should not.
//
// It also carries the three counts into QML as initial properties, which is
// what keeps the QML incapable: without this the tray would have to read a
// file or run a command to learn anything, and the contract forbids both.
// QApplication, not QGuiApplication, and the difference is the whole reason
// the tray icon has never appeared on a MimOS desktop.
//
// Inside a KDE session -- signalled by KDE_FULL_SESSION or
// XDG_CURRENT_DESKTOP=KDE, both of which Plasma sets -- Qt loads
// KDEPlasmaPlatformTheme, and Qt.labs.platform's SystemTrayIcon stops using
// its own implementation and delegates to KStatusNotifierItem. That builds a
// QMenu, a QMenu is a QWidget, and a QWidget under a bare guiapplication is
// a qFatal. Measured from the core dump rather than guessed:
//
//   #6  QMenu::QMenu(QWidget*)                     libQt6Widgets
//   #8  KStatusNotifierItem::KStatusNotifierItem   libKF6StatusNotifierItem
//   #9  KDEPlasmaPlatformTheme6.so
//   #10 libQt6LabsPlatform.so.6
//
// Outside a KDE session none of that loads, Qt uses its own tray, no QMenu
// is built and the process runs perfectly -- which is why every hand launch
// worked and the only configuration anybody actually has crashed. The defect
// hid behind ADR-120 for its whole life: the checker could not count, so the
// daemon never launched this, so nothing ever ran it where it breaks.
// See ADR-121.
#include <QApplication>
#include <QCoreApplication>
#include <QIcon>
#include <QLocale>
#include <QQmlApplicationEngine>
#include <QTranslator>
#include <QUrl>

namespace {

// Refuses anything that is not a plain non-negative number, and clamps.
// The values come from our own launcher, so this is not a trust boundary --
// it is a guard against a future caller passing something surprising into a
// string that a person reads.
int leerCuenta(const QString &texto)
{
    bool ok = false;
    const int valor = texto.toInt(&ok);
    if (!ok || valor < 0) {
        return 0;
    }
    return valor > 9999 ? 9999 : valor;
}

} // namespace

int main(int argc, char **argv)
{
    QApplication app(argc, argv);
    QApplication::setDesktopFileName(QStringLiteral("mimos-actualizador"));
    // The session's language, installed before the QML loads (ADR-159): the
    // tray's sentences and the notification are qsTr() strings, and the
    // Catalan half lives in actualizador_ca.qm. No catalogue means Spanish.
    QTranslator traductor;
    if (traductor.load(QLocale(), QStringLiteral("actualizador"),
                       QStringLiteral("_"),
                       QStringLiteral(TRADUCCIONES_DIR))) {
        QCoreApplication::installTranslator(&traductor);
    }
    QApplication::setApplicationName(
        QCoreApplication::translate("Actualizador", "Actualizar MimOS"));
    QApplication::setWindowIcon(
        QIcon::fromTheme(QStringLiteral("system-software-update")));
    // A tray-only application: without this the process would exit the moment
    // it noticed it had no windows, and the icon would appear and vanish.
    QApplication::setQuitOnLastWindowClosed(false);

    int oficiales = 0;
    int aur = 0;
    int flatpak = 0;
    const QStringList argumentos = QApplication::arguments();
    for (int i = 1; i + 1 < argumentos.size(); ++i) {
        const QString &clave = argumentos.at(i);
        if (clave == QStringLiteral("--oficiales")) {
            oficiales = leerCuenta(argumentos.at(i + 1));
        } else if (clave == QStringLiteral("--aur")) {
            aur = leerCuenta(argumentos.at(i + 1));
        } else if (clave == QStringLiteral("--flatpak")) {
            flatpak = leerCuenta(argumentos.at(i + 1));
        }
    }

    // setInitialProperties rather than context properties: the QML declares
    // these as `required`, so a name that stops matching is a load-time error
    // instead of a tray that quietly reports zero updates -- which is
    // indistinguishable from a system that has none.
    QQmlApplicationEngine engine;
    engine.setInitialProperties({
        {QStringLiteral("oficiales"), oficiales},
        {QStringLiteral("aur"), aur},
        {QStringLiteral("flatpak"), flatpak},
    });

    engine.load(QUrl::fromLocalFile(QStringLiteral(ACTUALIZADOR_TRAY_QML)));
    if (engine.rootObjects().isEmpty()) {
        return 1;
    }
    return QApplication::exec();
}

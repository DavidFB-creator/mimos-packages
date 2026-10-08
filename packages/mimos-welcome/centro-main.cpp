// Centro de MimOS runner. The generic qml6 tool declares its own identity —
// desktopFileName org.qt-project.qml and the Qt "Qr" window icon, delivered
// over the Wayland toplevel-icon protocol — and KWin honours the window's
// own icon over any desktop-file match, so the title bar wore a Qr no rule
// could remove. This runner exists to own that identity: it names the real
// desktop entry and takes MIMI from the icon theme, then loads the same
// process-free QML the contract governs (ADR-093).
//
// It also owns the language (ADR-159). The QML is written in Spanish and
// asks for every string through qsTr(); this runner installs the catalogue
// for the session's locale before the QML loads, so a Catalan session gets
// the Catalan Centro and a Spanish one gets the source strings untouched.
// QLocale() reads LANG/LANGUAGE from the environment -- measured: a
// LANG=ca_ES.UTF-8 whose locale is not even generated still loads
// centro_ca.qm. A missing catalogue is not an error; it is Spanish.
#include <QCoreApplication>
#include <QGuiApplication>
#include <QIcon>
#include <QLocale>
#include <QQmlApplicationEngine>
#include <QTranslator>
#include <QUrl>

int main(int argc, char **argv)
{
    QGuiApplication app(argc, argv);
    QGuiApplication::setDesktopFileName(QStringLiteral("mimos-welcome"));
    QGuiApplication::setWindowIcon(
        QIcon::fromTheme(QStringLiteral("mimos-centro")));

    QTranslator traductor;
    if (traductor.load(QLocale(), QStringLiteral("centro"), QStringLiteral("_"),
                       QStringLiteral(TRADUCCIONES_DIR))) {
        QCoreApplication::installTranslator(&traductor);
    }
    // After the translator, so the name a notification or a task switcher
    // shows is in the session's language too.
    QGuiApplication::setApplicationName(
        QCoreApplication::translate("Centro", "Centro de MimOS"));

    QQmlApplicationEngine engine;
    engine.load(QUrl::fromLocalFile(QStringLiteral(CENTRO_WINDOW_QML)));
    if (engine.rootObjects().isEmpty()) {
        return 1;
    }
    return QGuiApplication::exec();
}

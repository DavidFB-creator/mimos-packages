// Tienda de MimOS runner. Exists for the same reason centro-mimos does
// (ADR-093): the generic qml6 tool declares desktopFileName
// org.qt-project.qml and its own Qr icon over the Wayland toplevel-icon
// protocol, which KWin honours over any desktop-file match. This runner
// names the real desktop entry, then loads the same process-free QML the
// contract governs. The icon is the Tienda's own since David chose D5
// from rendered candidates: MIMI hugging the rim of an open gift box.
#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QUrl>

int main(int argc, char **argv)
{
    QGuiApplication app(argc, argv);
    QGuiApplication::setDesktopFileName(QStringLiteral("mimos-tienda"));
    QGuiApplication::setApplicationName(QStringLiteral("Tienda de MimOS"));
    QGuiApplication::setWindowIcon(
        QIcon::fromTheme(QStringLiteral("mimos-tienda")));

    QQmlApplicationEngine engine;
    engine.load(QUrl::fromLocalFile(QStringLiteral(TIENDA_WINDOW_QML)));
    if (engine.rootObjects().isEmpty()) {
        return 1;
    }
    return QGuiApplication::exec();
}

// Centro de MimOS runner. The generic qml6 tool declares its own identity —
// desktopFileName org.qt-project.qml and the Qt "Qr" window icon, delivered
// over the Wayland toplevel-icon protocol — and KWin honours the window's
// own icon over any desktop-file match, so the title bar wore a Qr no rule
// could remove. This runner exists to own that identity: it names the real
// desktop entry and takes MIMI from the icon theme, then loads the same
// process-free QML the contract governs (ADR-093).
#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QUrl>

int main(int argc, char **argv)
{
    QGuiApplication app(argc, argv);
    QGuiApplication::setDesktopFileName(QStringLiteral("mimos-welcome"));
    QGuiApplication::setApplicationName(QStringLiteral("Centro de MimOS"));
    QGuiApplication::setWindowIcon(
        QIcon::fromTheme(QStringLiteral("mimos-centro")));

    QQmlApplicationEngine engine;
    engine.load(QUrl::fromLocalFile(QStringLiteral(CENTRO_WINDOW_QML)));
    if (engine.rootObjects().isEmpty()) {
        return 1;
    }
    return QGuiApplication::exec();
}

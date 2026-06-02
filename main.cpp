#include <QApplication>
#include <QProcess>
#include <QThread>
#include <QRegularExpression>
#include <QString>

#include "MudletInstaller.h"

#ifdef Q_OS_WINDOWS
#include "windows.h"
#include <iostream>

void msys2QtMessageHandler(QtMsgType type, const QMessageLogContext& context, const QString& msg)
{
    Q_UNUSED(context)
    switch (type) {
    case QtDebugMsg:
    case QtInfoMsg:
        std::cout << msg.toUtf8().constData() << std::endl;
        break;
    case QtWarningMsg:
    case QtCriticalMsg:
    case QtFatalMsg:
        std::cerr << msg.toUtf8().constData() << std::endl;
    }
}
#endif

int main(int argc, char *argv[]) {
    QApplication a(argc, argv);

#ifdef Q_OS_WINDOWS
    if (AttachConsole(ATTACH_PARENT_PROCESS)) {
        if (qgetenv("MSYSTEM").isNull()) {
            // print stdout to console if Mudlet is started in a console in Windows
            // credit to https://stackoverflow.com/a/41701133 for the workaround
            freopen("CONOUT$", "w", stdout);
            freopen("CONOUT$", "w", stderr);
        } else {
            // simply print qt logs into stdout and stderr if it's MSYS2
            qInstallMessageHandler(msys2QtMessageHandler);
        }
    }
#endif

    qDebug() << "Starting MudletDownloader...";

    MudletInstaller app;
    app.start();

    return a.exec();
}

#include <QApplication>
#include <QProcess>
#include <QThread>
#include <QRegularExpression>
#include <QString>

#include "MudletInstaller.h"

int main(int argc, char *argv[]) {
    QApplication a(argc, argv);

    qDebug() << "Starting MudletDownloader...";

    MudletInstaller app;
    app.start();

    return a.exec();
}

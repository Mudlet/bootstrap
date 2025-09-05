#ifndef MUDLETDOWNLOADER_H
#define MUDLETDOWNLOADER_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QWidget>
#include <QProgressBar>
#include <QLabel>
#include <QStateMachine>
#include <QState>
#include <QFinalState>

struct DownloadInfo {
    QString url;
    QString appName;
    QString sha256;
};

class MudletBootstrap : public QObject {
    Q_OBJECT

public:
    explicit MudletBootstrap(QObject *parent = nullptr);
    void start();

private slots:
    void fetchPlatformFeed();
    void onFetchPlatformFeedFinished();
    void checkExistingFile();
    void startDownload();
    void onDownloadProgress(qint64 bytesReceived, qint64 bytesTotal);
    void onDownloadFinished();
    void onDownloadError(QNetworkReply::NetworkError error);
    void verifyHash();
    void installApplication();
    void handleError();
    void cleanup();
    void retryDownload();

signals:
    void feedFetched();
    void fileExists();
    void fileNotExists();
    void downloadComplete();
    void hashValid();
    void hashInvalid();
    void installComplete();
    void errorOccurred();
    void finished();

private:
    QNetworkAccessManager networkManager;
    QNetworkReply *currentReply;
    void initStateMachine();
    
    QWidget *progressWindow;
    QProgressBar *progressBar;
    QLabel *statusLabel;

    QString fetchedHtml;
    QString downloadLink;
    QString outputFile;

    DownloadInfo info;
    int retryCount;
    qint64 bytesAlreadyDownloaded;
    static const int MAX_RETRIES = 3;
    QString gameName;

    QStateMachine *m_stateMachine;
    QState *m_downloadFeedState;
    QState *m_checkExistingState;
    QState *m_downloadState;
    QState *m_retryState;
    QState *m_verifyHashState;
    QState *m_installState;
    QState *m_errorState;
    QFinalState *m_doneState;

};

#endif

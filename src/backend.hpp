#pragma once

#include <QCoreApplication>
#include <QDrag>
#include <QPoint>
#include <QTimer>
#include <QtGui/qwindowdefs.h>
#include <chrono>

#include "Util/util.hpp"
#include "path.hpp"

class Backend : public QObject {
	Q_OBJECT
	QML_ELEMENT
	QML_SINGLETON
public:
	QML_CPP_SINGLETON(Backend)

	void quit_delayed(const std::chrono::milliseconds delay = 100ms);
	void drag_paths(const std::vector<Path> &paths);
	void print_hyperlinks(const std::vector<Path> &paths);
	void send_drag_notification(const std::vector<Path> &uris);
	void copy_to_clipboard(const std::vector<Path> &paths);

	void hide_terminal();
	void restore_terminal();

	void exec_frontend(const std::vector<Path> &paths);
	Q_INVOKABLE QPoint get_mouse_pos() const;
	Q_INVOKABLE void handle_dropped_urls(const QList<QUrl> &urls);
	Q_INVOKABLE void handle_dropped_data(const QList<QUrl> &urls, const QByteArray &portal_data);
	Q_INVOKABLE QByteArray portal_transfer_data(const QString &uri_list);
signals:
	void drag_finished(Qt::DropAction dropAction);
private:
	QDrag *drag = nullptr;
	QMimeData *qml_portal_mime_data = nullptr;
	WId last_window = 0;
};

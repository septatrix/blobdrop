#include "backend.hpp"

#include <KNotification>
#include <KUrlMimeData>
#include <KWindowSystem>
#include <KX11Extras>
#include <QClipboard>
#include <QCursor>
#include <QGuiApplication>
#include <QIcon>
#include <QMimeData>
#include <QPixmap>
#include <QRegularExpression>

#include "path_registry.hpp"
#include "settings.hpp"
#include "stdin.hpp"
#include "stdout.hpp"

void Backend::quit_delayed(const std::chrono::milliseconds delay) {
	// cancel any pending drags
	if (drag) {
		drag->cancel();
	}
	// remove the possibly set keep-below hint, as we want to quit now
	Backend::get()->restore_terminal();

	Settings::get()->suppress_always_on_bottom = true;
	QTimer::singleShot(delay, qGuiApp, QGuiApplication::quit);
}

void Backend::drag_paths(const std::vector<Path> &paths) {
	hide_terminal();
	// needed for intercept mode
	Settings::get()->setHideGui(true);

	// Not a memory leak, Qt takes ownership both over the QDrag as well as the QMimeData
	drag = new QDrag(this);
	auto mimedata = new QMimeData();

	QList<QUrl> urls;
	for (auto &i : paths) {
		urls.push_back(i.get_url());
	}

	mimedata->setUrls(urls);
	KUrlMimeData::exportUrlsToPortal(mimedata);
	drag->setMimeData(mimedata);

	constexpr const int cursor_size = 24;
	QPixmap pixmap;
	if (paths.size() == 1) {
		const auto p = paths.front();
		if (!p.thumbnail.isEmpty()) {
			// try using the thumbnail first
			constexpr const int max_size = 128;
			pixmap = QPixmap(p.thumbnail.toLocalFile());
			if (std::max(pixmap.width(), pixmap.height()) > max_size) {
				pixmap = pixmap.scaled(QSize(max_size, max_size), Qt::KeepAspectRatio, Qt::SmoothTransformation);
			}
		}
		if (pixmap.isNull()) {
			// fallback to mime type icon
			pixmap = QIcon::fromTheme(QString::fromStdString(p.iconName)).pixmap(cursor_size);
		}
	} else {
		// show a collective pseudo thumbnail of all files
		pixmap = QIcon::fromTheme("emblem-documents").pixmap(cursor_size);
	}
	if (!pixmap.isNull()) {
		drag->setPixmap(pixmap);
	}

	const auto drop_action = drag->exec();
	restore_terminal();
	drag->deleteLater();
	drag = nullptr;
	emit drag_finished(drop_action);
}

void Backend::print_hyperlinks(const std::vector<Path> &paths) {
	for (auto &i : paths) {
		Stdout::print_osc8_link(i.get_uri(), i.pretty_print());
	}
}

void Backend::send_drag_notification(const std::vector<Path> &uris) {
	if (uris.empty()) {
		return;
	}

	QList<QUrl> urls;
	for (const auto &u : uris) {
		urls.push_back(u.get_url());
	}

	QString title = "Drag file";
	if (uris.size() > 1) {
		title += "s";
	}
	auto *notification = new KNotification(
		QStringLiteral("notification"), KNotification::CloseOnTimeout | KNotification::DefaultEvent);
	notification->setTitle(title);
	notification->setIconName(QStringLiteral("cursor-arrow"));
	notification->setUrls(urls);
	notification->sendEvent();
}

void Backend::copy_to_clipboard(const std::vector<Path> &paths) {
	// not a memory leak, ownership is later transferred to Qt with setMimeData()
	auto *mime = new QMimeData;

	QList<QUrl> urls;
	for (auto &i : paths) {
		urls.push_back(i.get_url());
	}

	mime->setUrls(urls);
	auto *clip = QGuiApplication::clipboard();
	clip->setMimeData(mime);
}

void Backend::hide_terminal() {
#if defined(Q_OS_UNIX) && !defined(Q_OS_DARWIN)
	if (Settings::get()->suppress_always_on_bottom || Settings::get()->intercept || !Stdin::get()->is_tty || !KWindowSystem::isPlatformX11()) {
		return;
	}

	last_window = KX11Extras::activeWindow();
	if (last_window) {
		KX11Extras::setState(last_window, NET::KeepBelow);
	}
#endif
}

void Backend::restore_terminal() {
#if defined(Q_OS_UNIX) && !defined(Q_OS_DARWIN)
	if (!last_window) {
		return;
	}

	KX11Extras::clearState(last_window, NET::KeepBelow);
	last_window = 0;
#endif
}

void Backend::exec_frontend(const std::vector<Path> &paths) {
	const auto f = Settings::get()->effective_frontend(true);
	if (f == Settings::Frontend::Immediate) {
		Backend::get()->drag_paths(paths);
	} else if (f == Settings::Frontend::Stdout) {
		Backend::get()->print_hyperlinks(paths);
	} else if (f == Settings::Frontend::Notification) {
		Backend::get()->send_drag_notification(paths);
	} else if (f == Settings::Frontend::Clipboard) {
		Backend::get()->copy_to_clipboard(paths);
	}
}

QPoint Backend::get_mouse_pos() const {
	return QCursor::pos();
}

QByteArray Backend::portal_transfer_data(const QString &uri_list) {
	QList<QUrl> urls;
	for (const auto &line : uri_list.split(QRegularExpression("[\\r\\n]+"), Qt::SkipEmptyParts)) {
		urls.push_back(QUrl(line));
	}
	delete qml_portal_mime_data;
	qml_portal_mime_data = new QMimeData;
	qml_portal_mime_data->setParent(this);
	qml_portal_mime_data->setUrls(urls);
	if (!KUrlMimeData::exportUrlsToPortal(qml_portal_mime_data)) {
		return {};
	}
	return qml_portal_mime_data->data("application/vnd.portal.filetransfer");
}

void Backend::handle_dropped_urls(const QList<QUrl> &urls) {
	std::vector<Path> paths;
	for (auto &u : urls) {
		auto url = u.toString().toStdString();
		if (url.starts_with("file://")) {
			url = url.substr(7);
		}
		paths.push_back(url);
	}

	if (Settings::get()->keep_dropped_files) {
		for (auto &i : paths) {
			PathRegistry::get()->add_path(i);
		}
	}

	if (Settings::get()->intercept) {
		QTimer::singleShot(0, qGuiApp, [this, paths]() { exec_frontend(paths); });
	} else {
		Backend::get()->print_hyperlinks(paths);
	}

	if (Settings::get()->auto_quit_behavior == Settings::AutoQuitBehavior::First && Settings::get()->effective_frontend(true) != Settings::Frontend::Immediate) {
		Backend::get()->quit_delayed();
	}
}

void Backend::handle_dropped_data(const QList<QUrl> &urls, const QByteArray &portal_data) {
	QMimeData mime_data;
	mime_data.setUrls(urls);
	if (!portal_data.isEmpty()) {
		mime_data.setData("application/vnd.portal.filetransfer", portal_data);
	}
	handle_dropped_urls(KUrlMimeData::urlsFromMimeData(&mime_data, KUrlMimeData::PreferLocalUrls));
}

#include <QApplication>
#include <QIcon>
#include <QQmlApplicationEngine>

#ifdef Q_OS_UNIX
#include <KSignalHandler>
#include <csignal>
#endif

#include "backend.hpp"
#include "getopts.hpp"
#include "version.hpp"

int main(int argc, char *argv[]) {
	QCoreApplication::setOrganizationName("blobdrop");
	QCoreApplication::setApplicationName("blobdrop");
	QCoreApplication::setApplicationVersion(Version::version_string());
	QApplication app(argc, argv);

#ifdef Q_OS_UNIX
	// Relay termination signals through the event loop so shutdown restores the tty.
	auto *signal_handler = KSignalHandler::self();
	for (const int signal : {SIGINT, SIGHUP, SIGTERM, SIGQUIT}) {
		signal_handler->watchSignal(signal);
	}
	QObject::connect(signal_handler, &KSignalHandler::signalReceived, &app, [](int) { Backend::get()->quit_delayed(0ms); });
#endif

	const auto &args = Getopts::setup_args(argc, argv);
	if (!Getopts::parse(args)) {
		return EXIT_FAILURE;
	}

	QGuiApplication::setWindowIcon(QIcon::fromTheme("blobdrop", QIcon(":/blobdrop")));

	QQmlApplicationEngine engine;

	engine.loadFromModule("Backend", "Main");
	if (engine.rootObjects().isEmpty()) {
		return EXIT_FAILURE;
	}

	return app.exec();
}

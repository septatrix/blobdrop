#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>

#include "Util/termination_signals.hpp"
#include "backend.hpp"
#include "getopts.hpp"
#include "version.hpp"

int main(int argc, char *argv[]) {
	QCoreApplication::setOrganizationName("blobdrop");
	QCoreApplication::setApplicationName("blobdrop");
	QCoreApplication::setApplicationVersion(Version::version_string());
	QGuiApplication app(argc, argv);

#ifdef Q_OS_UNIX
	// handle unix signals
	Util::TerminationSignals signal_handler {[] { Backend::get()->quit_delayed(0ms); }};
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

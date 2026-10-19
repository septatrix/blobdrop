#include <QScopeGuard>
#include <QTest>

#include "Util/termination_signals.hpp"
#include "Util/util.hpp"
#include "getopts.hpp"
#include "path.hpp"

class PathTest : public QObject {
	Q_OBJECT
private:
	std::string pwd;
private slots:
	void initTestCase() {
		pwd = Util::pwd();
	}

	void test_path_uris() {
		QVERIFY(!pwd.empty());
		const std::string filename = "test.txt";
		const auto path = pwd + "/" + filename;
		const auto uri = "file://" + path;

		// relative path
		QCOMPARE(Path(filename).get_uri(), uri);
		// absolute path
		QCOMPARE(Path(path).get_uri(), uri);
	}

	void test_environment_arguments_data() {
		QTest::addColumn<QByteArray>("environment");
		QTest::addColumn<QStringList>("expected");
		QTest::newRow("unset") << QByteArray() << QStringList {"blobdrop", "-x", "never", "a file.png"};
		QTest::newRow("empty") << QByteArray("") << QStringList {"blobdrop", "-x", "never", "a file.png"};
		QTest::newRow("defaults") << QByteArray("-f gui -p") << QStringList {"blobdrop", "-f", "gui", "-p", "-x", "never", "a file.png"};
	}

	void test_environment_arguments() {
		QFETCH(QByteArray, environment);
		QFETCH(QStringList, expected);
		const auto original = qgetenv("BLOBDROP_ARGS");
		const auto restore = qScopeGuard([original] {
			if (original.isNull()) {
				qunsetenv("BLOBDROP_ARGS");
			} else {
				qputenv("BLOBDROP_ARGS", original);
			}
		});
		if (environment.isNull()) {
			qunsetenv("BLOBDROP_ARGS");
		} else {
			qputenv("BLOBDROP_ARGS", environment);
		}
		char program[] = "blobdrop";
		char option[] = "-x";
		char value[] = "never";
		char filename[] = "a file.png";
		char *argv[] = {program, option, value, filename};
		QCOMPARE(Getopts::setup_args(4, argv), expected);
		QVERIFY(Getopts::setup_args(0, nullptr).isEmpty());
	}

#ifdef Q_OS_UNIX
	void test_termination_signals() {
		bool handled = false;
		Util::TerminationSignals handler {[&handled] { handled = true; }};
		for (const int signal : {SIGINT, SIGHUP, SIGTERM, SIGQUIT}) {
			handled = false;
			QCOMPARE(raise(signal), 0);
			QVERIFY(!handled);
			QTRY_VERIFY(handled);
		}
	}
#endif
};

QTEST_MAIN(PathTest)
#include "path_test.moc"

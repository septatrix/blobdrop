#pragma once

#include <qglobal.h>

#ifdef Q_OS_UNIX

#include <QObject>
#include <QSocketNotifier>
#include <array>
#include <functional>
#include <signal.h>

namespace Util {

// Relay termination signals to the Qt event loop so shutdown can restore the tty.
class TerminationSignals : public QObject {
public:
	explicit TerminationSignals(std::function<void()> callback);
	~TerminationSignals() override;
private:
	static void handle_signal(int signal);
	static inline volatile sig_atomic_t write_fd = -1;
	static constexpr std::array signals_to_handle {SIGINT, SIGHUP, SIGTERM, SIGQUIT};
	std::array<struct sigaction, signals_to_handle.size()> previous_actions {};
	int read_fd = -1;
	QSocketNotifier *notifier = nullptr;
};

}

#endif

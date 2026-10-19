#include "termination_signals.hpp"

#ifdef Q_OS_UNIX

#include <cerrno>
#include <fcntl.h>
#include <unistd.h>
#include <utility>

namespace Util {

TerminationSignals::TerminationSignals(std::function<void()> callback) {
	int fds[2];
	if (pipe(fds) != 0) {
		qFatal("Cannot create termination signal pipe");
	}
	for (const int fd : fds) {
		if (fcntl(fd, F_SETFL, O_NONBLOCK) == -1 || fcntl(fd, F_SETFD, FD_CLOEXEC) == -1) {
			qFatal("Cannot configure termination signal pipe");
		}
	}
	read_fd = fds[0];
	write_fd = fds[1];
	notifier = new QSocketNotifier(read_fd, QSocketNotifier::Read, this);
	connect(notifier, &QSocketNotifier::activated, this, [this, callback = std::move(callback)] {
		char buffer[64];
		while (read(read_fd, buffer, sizeof(buffer)) > 0) {
		}
		callback();
	});

	struct sigaction action {};
	action.sa_handler = handle_signal;
	sigemptyset(&action.sa_mask);
	action.sa_flags = SA_RESTART;
	for (size_t i = 0; i < signals_to_handle.size(); ++i) {
		if (sigaction(signals_to_handle[i], &action, &previous_actions[i]) == -1) {
			qFatal("Cannot install termination signal handler");
		}
	}
}

TerminationSignals::~TerminationSignals() {
	for (size_t i = 0; i < signals_to_handle.size(); ++i) {
		sigaction(signals_to_handle[i], &previous_actions[i], nullptr);
	}
	notifier->setEnabled(false);
	const int fd = write_fd;
	write_fd = -1;
	close(fd);
	close(read_fd);
}

void TerminationSignals::handle_signal(int) {
	// write() is async-signal-safe; a full pipe already has a pending notification.
	const int saved_errno = errno;
	const char byte = 0;
	const int fd = write_fd;
	if (fd != -1) {
		std::ignore = write(fd, &byte, sizeof(byte));
	}
	errno = saved_errno;
}

}

#endif

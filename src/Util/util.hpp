#pragma once

#include <QJSEngine>
#include <filesystem>
#include <qglobal.h>
#include <qqml.h>
#include <string>

using namespace std::chrono_literals;

// Share the C++ instance with QML rather than letting the engine own a second one.
#define SINGLETON(TYPE) \
	static TYPE *get() { \
		static TYPE instance; \
		return &instance; \
	}

#define QML_CPP_SINGLETON(TYPE) \
	TYPE() = delete; \
	explicit TYPE(bool) { \
	} \
	static TYPE *get() { \
		static TYPE instance {true}; \
		return &instance; \
	} \
	static TYPE *create(QQmlEngine *, QJSEngine *) { \
		auto *instance = get(); \
		QJSEngine::setObjectOwnership(instance, QJSEngine::CppOwnership); \
		return instance; \
	}

namespace Util {

bool is_wayland();
const char *home_dir();
std::string pwd();
}

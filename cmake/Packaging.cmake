# Only AppImage packages bundle Qt. Native packages use distribution libraries.
set(deploy_content [=[
		qt_deploy_qml_imports(TARGET blobdrop PLUGINS_FOUND qml_plugins)
		# Kirigami's style selector also looks for QML files on disk, even when
		# qmldir prefers embedded resources. Preserve these without replacing
		# the plugin binaries that Qt has already deployed and patched.
		file(COPY "@BLOBDROP_KIRIGAMI_QML_ROOT@/org/kde/kirigami"
			DESTINATION "${QT_DEPLOY_PREFIX}/${QT_DEPLOY_QML_DIR}/org/kde"
			PATTERN "*.so*" EXCLUDE)
		# Qt may deploy only its default platform (often xcb). Include available
		# Wayland backends and offscreen support, including with Qt 6.9.
		file(GLOB platform_plugins
			"@QT6_INSTALL_PREFIX@/@QT6_INSTALL_PLUGINS@/platforms/libqwayland*.so"
			"@QT6_INSTALL_PREFIX@/@QT6_INSTALL_PLUGINS@/platforms/libqoffscreen.so")
		foreach(plugin IN LISTS platform_plugins)
			file(INSTALL "${plugin}" TYPE SHARED_LIBRARY
				DESTINATION "${QT_DEPLOY_PREFIX}/${QT_DEPLOY_PLUGINS_DIR}/platforms")
			get_filename_component(plugin_name "${plugin}" NAME)
			list(APPEND qml_plugins "${QT_DEPLOY_PLUGINS_DIR}/platforms/${plugin_name}")
		endforeach()
		# KWindowSystem selects its X11 or Wayland backend at runtime.
		file(GLOB kwindowsystem_plugins
			"@BLOBDROP_KWINDOWSYSTEM_PLUGIN_ROOT@/kf6/kwindowsystem/*.so")
		foreach(plugin IN LISTS kwindowsystem_plugins)
			file(INSTALL "${plugin}" TYPE SHARED_LIBRARY
				DESTINATION "${QT_DEPLOY_PREFIX}/${QT_DEPLOY_PLUGINS_DIR}/kf6/kwindowsystem")
			get_filename_component(plugin_name "${plugin}" NAME)
			list(APPEND qml_plugins "${QT_DEPLOY_PLUGINS_DIR}/kf6/kwindowsystem/${plugin_name}")
		endforeach()
		qt_deploy_runtime_dependencies(
			EXECUTABLE "$<TARGET_FILE:blobdrop>"
			ADDITIONAL_MODULES ${qml_plugins}
			GENERATE_QT_CONF
			NO_TRANSLATIONS
			POST_EXCLUDE_REGEXES
				[[.*/ld-linux[^/]*]]
				[[.*/lib(anl|BrokenLocale|c|cidn|dl|m|mvec|nss_[^/]+|pthread|resolv|rt|thread_db|util)[.]so[.].*]]
				# Keep the host compiler runtime and graphics drivers, as recommended
				# by AppImage's pkg2appimage excludelist.
				[[.*/lib(gcc_s|stdc[+][+])[.]so[.].*]]
				[[.*/lib(EGL|GL|GLX|OpenGL|GLdispatch|drm[^/]*|gbm|glapi|wayland-client)[.]so[.].*]]
		)
	]=])
string(CONFIGURE "${deploy_content}" deploy_content @ONLY)
qt6_generate_deploy_script(
	TARGET blobdrop
	OUTPUT_SCRIPT deploy_script
	CONTENT "${deploy_content}"
)
configure_file("${CMAKE_CURRENT_LIST_DIR}/AppRun.in" "${PROJECT_BINARY_DIR}/AppRun" @ONLY)
install(CODE "
	if (BLOBDROP_DEPLOY_RUNTIME)
		include(\"${deploy_script}\")
		file(INSTALL \"${PROJECT_BINARY_DIR}/AppRun\"
			DESTINATION \"\${CMAKE_INSTALL_PREFIX}\" TYPE PROGRAM)
	endif()
")

set(CPACK_PACKAGE_NAME "blobdrop")
set(CPACK_PACKAGE_VENDOR "Blobdrop contributors")
if (NOT CPACK_PACKAGE_CONTACT)
	set(CPACK_PACKAGE_CONTACT "Blobdrop maintainers")
endif()
set(CPACK_PACKAGE_VERSION "${PROJECT_VERSION}")
set(CPACK_PACKAGE_FILE_NAME "blobdrop-${PROJECT_VERSION}-${CMAKE_SYSTEM_PROCESSOR}")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "${PROJECT_DESCRIPTION}")
set(CPACK_PACKAGE_HOMEPAGE_URL "https://github.com/vimpostor/blobdrop")
set(CPACK_RESOURCE_FILE_LICENSE "${PROJECT_SOURCE_DIR}/LICENSE.txt")
set(CPACK_PACKAGE_ICON "blobdrop.svg")
set(CPACK_PACKAGING_INSTALL_PREFIX "/usr")
set(CPACK_PACKAGE_CHECKSUM SHA256)
if (NOT CPACK_GENERATOR)
	set(CPACK_GENERATOR "TGZ")
endif()

set(CPACK_APPIMAGE_DESKTOP_FILE "blobdrop.desktop")
set(CPACK_APPIMAGE_NO_APPSTREAM ON)
set(CPACK_APPIMAGE_PATCHELF_EXECUTABLE "${QT_DEPLOY_PATCHELF_EXECUTABLE}")

set(CPACK_DEBIAN_FILE_NAME DEB-DEFAULT)
set(CPACK_DEBIAN_PACKAGE_SECTION utils)
set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)
# QML imports and platform/image plugins are loaded dynamically, so shlibdeps
# cannot discover them from the executable's ELF dependencies.
set(CPACK_DEBIAN_PACKAGE_DEPENDS
	"qml6-module-org-kde-kirigami (>= 6.0), qml6-module-qtquick (>= 6.9), qml6-module-qtquick-controls (>= 6.9), qml6-module-qtquick-shapes (>= 6.9), qml6-module-qtquick-templates (>= 6.9), qml6-module-qtquick-window (>= 6.9), qml6-module-qtqml-models (>= 6.9), qml6-module-qtqml-workerscript (>= 6.9), qt6-qpa-plugins (>= 6.9), qt6-svg-plugins (>= 6.9)"
)

set(CPACK_RPM_FILE_NAME RPM-DEFAULT)
set(CPACK_RPM_PACKAGE_LICENSE "GPL-3.0-only")
set(CPACK_RPM_PACKAGE_GROUP "Applications/Utilities")
# Fedora package names; other RPM distributions can override this with cpack -D.
set(CPACK_RPM_PACKAGE_REQUIRES "kf6-kirigami >= 6.0, qt6-qtdeclarative >= 6.9, qt6-qtbase-gui >= 6.9, qt6-qtsvg >= 6.9")
set(CPACK_RPM_EXCLUDE_FROM_AUTO_FILELIST_ADDITION
	/usr/share/applications
	/usr/share/bash-completion /usr/share/bash-completion/completions
	/usr/share/fish /usr/share/fish/vendor_completions.d
	/usr/share/icons /usr/share/icons/hicolor
	/usr/share/icons/hicolor/scalable /usr/share/icons/hicolor/scalable/apps
	/usr/share/man /usr/share/man/man1
	/usr/share/zsh /usr/share/zsh/site-functions
)

configure_file("${CMAKE_CURRENT_LIST_DIR}/CPackOptions.cmake.in"
	"${PROJECT_BINARY_DIR}/CPackOptions.cmake" @ONLY)
set(CPACK_PROJECT_CONFIG_FILE "${PROJECT_BINARY_DIR}/CPackOptions.cmake")
include(CPack)

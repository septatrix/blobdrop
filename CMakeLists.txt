cmake_minimum_required(VERSION 3.31)
project(blobdrop VERSION 2.2 DESCRIPTION "Drag and drop files directly out of the terminal")

option(BUILD_TESTING "Build the testing tree.")

find_package(ECM 6.0 REQUIRED NO_MODULE)
list(APPEND CMAKE_MODULE_PATH ${ECM_MODULE_PATH})
include(KDEInstallDirs6)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

list(APPEND QT_MODULES Core Qml Quick QuickControls2 Widgets DBus Svg)
# AppImage deployment needs to add RPATHs even to distro libraries with none.
# Resolve patchelf at packaging time, keeping ordinary builds independent of it.
if (CMAKE_SYSTEM_NAME STREQUAL "Linux")
	set(QT_DEPLOY_USE_PATCHELF ON)
	if (NOT QT_DEPLOY_PATCHELF_EXECUTABLE)
		set(QT_DEPLOY_PATCHELF_EXECUTABLE patchelf)
	endif()
endif()
find_package(Qt6 6.9 COMPONENTS ${QT_MODULES} REQUIRED)
# Shared Kirigami plugins load at runtime and do not export CMake link targets.
# Skip Qt's static-plugin linking pass for shared Qt, while retaining the
# separate QML import scan used by deployment and AppImage packaging.
get_target_property(qml_library_type Qt6::Qml TYPE)
if (qml_library_type STREQUAL "SHARED_LIBRARY")
	get_target_property(qml_finalizers Qt6::Qml INTERFACE_QT_EXECUTABLE_FINALIZERS)
	list(REMOVE_ITEM qml_finalizers qt6_import_qml_plugins)
	set_property(TARGET Qt6::Qml PROPERTY INTERFACE_QT_EXECUTABLE_FINALIZERS "${qml_finalizers}")
endif()
qt_standard_project_setup(REQUIRES ${Qt6_VERSION})
find_package(KF6Kirigami 6.0 REQUIRED)
find_package(KF6CoreAddons 6.0 REQUIRED)
find_package(KF6Notifications 6.0 REQUIRED)
find_package(KF6WindowSystem 6.0 REQUIRED)
include(FeatureSummary)
include(ECMFindQmlModule)
# Qt and KDE can live in separate prefixes (for example, with Nix).
file(TO_CMAKE_PATH "$ENV{QML_IMPORT_PATH}" qml_import_paths)
file(TO_CMAKE_PATH "$ENV{QML2_IMPORT_PATH}" qml2_import_paths)
find_path(BLOBDROP_KIRIGAMI_QML_ROOT org/kde/kirigami/qmldir
	HINTS ${Kirigami_INSTALL_PREFIX} ${QT6_INSTALL_PREFIX} ${QML_IMPORT_PATH} ${qml_import_paths} ${qml2_import_paths}
	PATH_SUFFIXES ${KDE_INSTALL_QMLDIR} ${QT6_INSTALL_QML} lib/qt6/qml lib64/qt6/qml lib/qml
	REQUIRED)
block()
	set(KDE_INSTALL_FULL_QMLDIR "${BLOBDROP_KIRIGAMI_QML_ROOT}")
	ecm_find_qmlmodule(org.kde.kirigami REQUIRED)
endblock()
list(TRANSFORM QT_MODULES PREPEND "Qt6::")

list(APPEND LINK_LIBS ${QT_MODULES} KF6::CoreAddons KF6::Notifications KF6::WindowSystem)

include_directories("src" "src/Models")
add_compile_definitions(BLOBDROP_VERSION="${PROJECT_VERSION}")

file(GLOB_RECURSE SRCS "src/*.cpp")
file(GLOB_RECURSE HDRS "src/*.hpp")
file(GLOB_RECURSE QMLS RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" "src/qml/*.qml")

qt_add_resources(RESOURCES "${CMAKE_SOURCE_DIR}/icons.qrc")

qt_add_executable(${PROJECT_NAME} ${SRCS} ${RESOURCES})

qt_add_qml_module(${PROJECT_NAME} URI "Backend" VERSION "${PROJECT_VERSION}" QML_FILES ${QMLS} SOURCES "src/Models/path_model.cpp" IMPORT_PATH "${BLOBDROP_KIRIGAMI_QML_ROOT}")
set_target_properties(${PROJECT_NAME} PROPERTIES QT_QMLCACHEGEN_ARGUMENTS "--only-bytecode")

target_link_libraries(${PROJECT_NAME} PRIVATE ${LINK_LIBS})

# install
install(TARGETS ${PROJECT_NAME} ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
install(DIRECTORY "${CMAKE_SOURCE_DIR}/doc/man/" DESTINATION "${KDE_INSTALL_MANDIR}")
install(DIRECTORY "${CMAKE_SOURCE_DIR}/assets/completions/" DESTINATION "${KDE_INSTALL_DATADIR}")
install(FILES LICENSE.txt DESTINATION "${KDE_INSTALL_DATAROOTDIR}/doc/blobdrop" RENAME copyright)

if (CMAKE_SYSTEM_NAME STREQUAL "Linux")
	get_filename_component(KF6_WINDOWSYSTEM_PREFIX "${KF6WindowSystem_DIR}/../../.." ABSOLUTE)
	find_path(BLOBDROP_KWINDOWSYSTEM_PLUGIN_ROOT kf6/kwindowsystem/KF6WindowSystemX11Plugin.so
		HINTS ${KF6_WINDOWSYSTEM_PREFIX} ${QT6_INSTALL_PREFIX}
		PATH_SUFFIXES ${QT6_INSTALL_PLUGINS} lib/qt6/plugins lib64/qt6/plugins
		REQUIRED)
	install(FILES assets/blobdrop.desktop DESTINATION "${KDE_INSTALL_APPDIR}")
	install(FILES assets/blobdrop.svg DESTINATION "${KDE_INSTALL_ICONDIR}/hicolor/scalable/apps")
	include(cmake/Packaging.cmake)
endif()

# testing
if (BUILD_TESTING)
	enable_testing()
	add_subdirectory(tests)
endif()

feature_summary(WHAT REQUIRED_PACKAGES_NOT_FOUND FATAL_ON_MISSING_REQUIRED_PACKAGES)

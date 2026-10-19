cmake_minimum_required(VERSION 3.31)
project(blobdrop VERSION 2.1 DESCRIPTION "Drag and drop files directly out of the terminal")

option(BUILD_TESTING "Build the testing tree.")

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

list(APPEND QT_MODULES Core Qml Quick QuickControls2 DBus Svg)
# AppImage deployment needs to add RPATHs even to distro libraries with none.
# Resolve patchelf at packaging time, keeping ordinary builds independent of it.
if (CMAKE_SYSTEM_NAME STREQUAL "Linux")
	set(QT_DEPLOY_USE_PATCHELF ON)
	if (NOT QT_DEPLOY_PATCHELF_EXECUTABLE)
		set(QT_DEPLOY_PATCHELF_EXECUTABLE patchelf)
	endif()
endif()
find_package(Qt6 6.9 COMPONENTS ${QT_MODULES} REQUIRED)
qt_standard_project_setup(REQUIRES ${Qt6_VERSION})
list(TRANSFORM QT_MODULES PREPEND "Qt6::")

list(APPEND LINK_LIBS ${QT_MODULES})

if (UNIX AND NOT APPLE)
	find_package(PkgConfig QUIET)
	if (PkgConfig_FOUND)
		pkg_check_modules(XCB QUIET IMPORTED_TARGET xcb xcb-ewmh)
	endif()
	if (TARGET PkgConfig::XCB)
		list(APPEND LINK_LIBS PkgConfig::XCB)
		add_compile_definitions(BLOBDROP_WITH_X11)
		message(STATUS "X11 terminal lowering enabled")
	else()
		message(STATUS "X11 terminal lowering disabled (requires xcb and xcb-ewmh)")
	endif()
endif()

include_directories("src" "src/Models")
add_compile_definitions(BLOBDROP_VERSION="${PROJECT_VERSION}")

file(GLOB_RECURSE SRCS "src/*.cpp")
file(GLOB_RECURSE HDRS "src/*.hpp")
file(GLOB_RECURSE QMLS RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" "src/qml/*.qml")

qt_add_resources(RESOURCES "${CMAKE_SOURCE_DIR}/icons.qrc")

qt_add_executable(${PROJECT_NAME} ${SRCS} ${RESOURCES})

qt_add_qml_module(${PROJECT_NAME} URI "Backend" VERSION "${PROJECT_VERSION}" QML_FILES ${QMLS} SOURCES "src/Models/path_model.cpp")
set_target_properties(${PROJECT_NAME} PROPERTIES QT_QMLCACHEGEN_ARGUMENTS "--only-bytecode")

target_link_libraries(${PROJECT_NAME} PRIVATE ${LINK_LIBS})

# install
install(TARGETS ${PROJECT_NAME} RUNTIME)
install(DIRECTORY "${CMAKE_SOURCE_DIR}/doc/man/" TYPE MAN)
install(DIRECTORY "${CMAKE_SOURCE_DIR}/assets/completions/" DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}")
install(FILES LICENSE.txt DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/doc/blobdrop" RENAME copyright)

if (CMAKE_SYSTEM_NAME STREQUAL "Linux")
	install(FILES assets/blobdrop.desktop DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/applications")
	install(FILES assets/blobdrop.svg DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/icons/hicolor/scalable/apps")
	include(cmake/Packaging.cmake)
endif()

# testing
if (BUILD_TESTING)
	enable_testing()
	add_subdirectory(tests)
endif()

set(TESTING_TARGET tests)
file(GLOB_RECURSE TESTING_SRCS "*.cpp")

find_package(Qt6Test REQUIRED)

list(REMOVE_ITEM SRCS "${CMAKE_SOURCE_DIR}/src/main.cpp")
qt_add_executable("${TESTING_TARGET}" ${TESTING_SRCS} ${SRCS})
add_test(NAME "${TESTING_TARGET}" COMMAND "${TESTING_TARGET}")
list(APPEND LINK_LIBS Qt6::Test)
target_link_libraries("${TESTING_TARGET}" PRIVATE ${LINK_LIBS})

add_test(NAME qml-drag COMMAND Qt6::qmltestrunner -input "${CMAKE_CURRENT_SOURCE_DIR}/qml")
set_tests_properties(qml-drag PROPERTIES ENVIRONMENT "QT_QPA_PLATFORM=offscreen;QT_QUICK_BACKEND=software")

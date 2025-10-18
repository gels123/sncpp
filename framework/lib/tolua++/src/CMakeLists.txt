set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/src/lib")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/src/lib")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/src/bin")

SET(CMAKE_MODULE_PATH "${CMAKE_BINARY_DIR}")
message("CMAKE_MODULE_PATH=${CMAKE_MODULE_PATH}")

find_package(liblua REQUIRED)

if("${LUA_VERSION_STRING}" VERSION_LESS "5.2.0")
	message(FATAL_ERROR "lua 5.2.0 or later is required, but found ${LUA_VERSION_STRING}.")
endif()

if(UNIX AND NOT APPLE)
	find_library(DL_LIBRARY dl)
	list(APPEND LUA_LIBRARIES ${DL_LIBRARY})
	find_library(M_LIBRARY m)
    list(APPEND LUA_LIBRARIES ${M_LIBRARY})
    message("after append LUA_LIBRARIES=${LUA_LIBRARIES}")
endif()

include_directories(
	"${PROJECT_SOURCE_DIR}/include"
	"${LUA_INCLUDE_DIR}"
)

add_subdirectory(lib)
add_subdirectory(bin)
add_subdirectory(tests)

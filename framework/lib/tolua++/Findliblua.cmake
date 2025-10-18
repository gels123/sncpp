set(LUA_VERSION_STRING "5.4.0")
set(LUA_INCLUDE_DIR "${CMAKE_BINARY_DIR}/../../skynet/3rd/lua")

find_library(
    LUA_LIBRARIES names liblua.a
    PATHS "${CMAKE_BINARY_DIR}/../../skynet/3rd/lua"
)

message("Using FindlibLua.cmake LUA_VERSION_STRING=${LUA_VERSION_STRING}" "  LUA_INCLUDE_DIR=${LUA_INCLUDE_DIR}" "  LUA_LIBRARIES=${LUA_LIBRARIES}")
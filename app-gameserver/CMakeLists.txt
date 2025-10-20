cmake_minimum_required(VERSION 2.8)
project(sn-game-server)

set(CMAKE_CXX_STANDARD 11)

add_executable(testmain testmain.cpp)

add_subdirectory(game/lib/lua-enet)


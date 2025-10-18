cmake_minimum_required(VERSION 2.8.12...3.20)
project(socket-server)

include(CheckFunctionExists)
check_function_exists("atomic_init" HAS_STDC_ATOMICS)
if (HAS_STDC_ATOMICS)
else ()
    add_definitions(-D__STDC_NO_ATOMICS__=1)
endif ()

set(CMAKE_C_FLAGS "-std=gnu99")

add_library(socket_server socket_server.c)

add_executable(testtcpsvr
        socket_server.c
        testtcpsvr.c)
target_link_libraries(testtcpsvr pthread)

add_executable(testtcpclient
        socket_server.c
        testtcpclient.c)
target_link_libraries(testtcpclient pthread)

add_executable(testudpserver
        testudpserver.c
        socket_server.c)
target_link_libraries(testudpserver pthread)

add_executable(testdupclient
        testdupclient.c
        socket_server.c)
target_link_libraries(testdupclient pthread)

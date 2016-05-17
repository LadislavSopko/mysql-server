# Copyright (c) 2010, 2016, Oracle and/or its affiliates. All rights reserved.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA 

# This file includes Windows specific hacks, mostly around compiler flags

INCLUDE (CheckCSourceCompiles)
INCLUDE (CheckCXXSourceCompiles)
INCLUDE (CheckStructHasMember)
INCLUDE (CheckLibraryExists)
INCLUDE (CheckFunctionExists)
INCLUDE (CheckCCompilerFlag)
INCLUDE (CheckCSourceRuns)
INCLUDE (CheckSymbolExists)
INCLUDE (CheckTypeSize)

# Optionally read user configuration, generated by configure.js.
# This is left for backward compatibility reasons only.
INCLUDE(${CMAKE_BINARY_DIR}/win/configure.data OPTIONAL)

# avoid running system checks by using pre-cached check results
# system checks are expensive on VS since every tiny program is to be compiled in 
# a VC solution.
GET_FILENAME_COMPONENT(_SCRIPT_DIR ${CMAKE_CURRENT_LIST_FILE} PATH)
INCLUDE(${_SCRIPT_DIR}/WindowsCache.cmake)

# We require at least Visual Studio 2013 (aka 12.0) which has version nr 1800.
IF(NOT FORCE_UNSUPPORTED_COMPILER AND MSVC_VERSION LESS 1800)
  MESSAGE(FATAL_ERROR "Visual Studio 2013 or newer is required!")
ENDIF()

# OS display name (version_compile_os etc).
# Used by the test suite to ignore bugs on some platforms, 
IF(CMAKE_SIZEOF_VOID_P MATCHES 8)
  SET(SYSTEM_TYPE "Win64")
  SET(MYSQL_MACHINE_TYPE "x86_64")
ELSE()
  SET(SYSTEM_TYPE "Win32")
ENDIF()

# Target Windows 7 / Windows Server 2008 R2 or later, i.e _WIN32_WINNT_WIN7
ADD_DEFINITIONS(-D_WIN32_WINNT=0x0601)
SET(CMAKE_REQUIRED_FLAGS "${CMAKE_REQUIRED_FLAGS} -D_WIN32_WINNT=0x0601")

# Speed up build process excluding unused header files
ADD_DEFINITIONS(-DWIN32_LEAN_AND_MEAN -DNOGDI)

# We want to use std::min/std::max, not the windows.h macros
ADD_DEFINITIONS(-DNOMINMAX)

IF(WITH_MSCRT_DEBUG)
  ADD_DEFINITIONS(-DMY_MSCRT_DEBUG)
  ADD_DEFINITIONS(-D_CRTDBG_MAP_ALLOC)
ENDIF()
  
OPTION(WIN_DEBUG_NO_INLINE "Disable inlining for debug builds on Windows" OFF)

IF(MSVC)
  # Enable debug info also in Release build,
  # and create PDB to be able to analyze crashes.
  FOREACH(type EXE SHARED MODULE)
   SET(CMAKE_{type}_LINKER_FLAGS_RELEASE
     "${CMAKE_${type}_LINKER_FLAGS_RELEASE} /debug")
  ENDFOREACH()
  
  # For release types Debug Release RelWithDebInfo (but not MinSizeRel):
  # - Force static runtime libraries
  # - Choose C++ exception handling:
  #     If /EH is not specified, the compiler will catch structured and
  #     C++ exceptions, but will not destroy C++ objects that will go out of
  #     scope as a result of the exception.
  #     /EHsc catches C++ exceptions only and tells the compiler to assume that
  #     extern C functions never throw a C++ exception.
  # - Choose debugging information:
  #     /Z7
  #     Produces an .obj file containing full symbolic debugging
  #     information for use with the debugger. The symbolic debugging
  #     information includes the names and types of variables, as well as
  #     functions and line numbers. No .pdb file is produced by the compiler.
  # - Enable explicit inline:
  #     /Ob1
  #     Expands explicitly inlined functions. By default /Ob0 is used,
  #     meaning no inlining. But this impacts test execution time.
  #     Allowing inline reduces test time using the debug server by
  #     30% or so. If you do want to keep inlining off, set the
  #     cmake flag WIN_DEBUG_NO_INLINE.
  FOREACH(lang C CXX)
    SET(CMAKE_${lang}_FLAGS_RELEASE "${CMAKE_${lang}_FLAGS_RELEASE} /Z7")
  ENDFOREACH()
  IF(NOT WINDOWS_RUNTIME_MD)
    FOREACH(flag 
     CMAKE_C_FLAGS_RELEASE    CMAKE_C_FLAGS_RELWITHDEBINFO 
     CMAKE_C_FLAGS_DEBUG      CMAKE_C_FLAGS_DEBUG_INIT 
     CMAKE_CXX_FLAGS_RELEASE  CMAKE_CXX_FLAGS_RELWITHDEBINFO
     CMAKE_CXX_FLAGS_DEBUG    CMAKE_CXX_FLAGS_DEBUG_INIT)
     STRING(REPLACE "/MD"  "/MT" "${flag}" "${${flag}}")
     STRING(REPLACE "/Zi"  "/Z7" "${flag}" "${${flag}}")
     IF (NOT WIN_DEBUG_NO_INLINE)
       STRING(REPLACE "/Ob0"  "/Ob1" "${flag}" "${${flag}}")
     ENDIF()
     SET("${flag}" "${${flag}} /EHsc")
    ENDFOREACH()
  ENDIF()
  
  # Fix CMake's predefined huge stack size
  FOREACH(type EXE SHARED MODULE)
   STRING(REGEX REPLACE "/STACK:([^ ]+)" "" CMAKE_${type}_LINKER_FLAGS "${CMAKE_${type}_LINKER_FLAGS}")
   STRING(REGEX REPLACE "/INCREMENTAL:([^ ]+)" "" CMAKE_${type}_LINKER_FLAGS_RELWITHDEBINFO "${CMAKE_${type}_LINKER_FLAGS_RELWITHDEBINFO}")
  ENDFOREACH()
  
  # Mark 32 bit executables large address aware so they can 
  # use > 2GB address space
  IF(CMAKE_SIZEOF_VOID_P MATCHES 4)
    SET(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} /LARGEADDRESSAWARE")
  ENDIF()
  
  # Speed up multiprocessor build
  SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /MP")
  SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /MP")
  
  # debug build
  SET(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} /bigobj")
  SET(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} /bigobj")
  
  #TODO: update the code and remove the disabled warnings
  SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /wd4800 /wd4805 /wd4996")
  SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /wd4800 /wd4805 /wd4996 /we4099")
ENDIF()

# Always link with socket library
LINK_LIBRARIES(ws2_32)
# ..also for tests
SET(CMAKE_REQUIRED_LIBRARIES ws2_32)

# IPv6 constants appeared in Vista SDK first. We need to define them in any case if they are 
# not in headers, to handle dual mode sockets correctly.
CHECK_SYMBOL_EXISTS(IPPROTO_IPV6 "winsock2.h" HAVE_IPPROTO_IPV6)
IF(NOT HAVE_IPPROTO_IPV6)
  SET(HAVE_IPPROTO_IPV6 41)
ENDIF()
CHECK_SYMBOL_EXISTS(IPV6_V6ONLY  "winsock2.h;ws2ipdef.h" HAVE_IPV6_V6ONLY)
IF(NOT HAVE_IPV6_V6ONLY)
  SET(IPV6_V6ONLY 27)
ENDIF()

SET(FN_NO_CASE_SENSE 1)

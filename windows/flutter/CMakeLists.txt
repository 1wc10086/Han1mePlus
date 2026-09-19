cmake_minimum_required(VERSION 3.14)

set(EPHEMERAL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/ephemeral")
include(${EPHEMERAL_DIR}/generated_config.cmake)

set(WRAPPER_ROOT "${EPHEMERAL_DIR}/cpp_client_wrapper")
if(NOT DEFINED FLUTTER_TARGET_PLATFORM)
  set(FLUTTER_TARGET_PLATFORM "windows-x64")
endif()

set(FLUTTER_LIBRARY "${EPHEMERAL_DIR}/flutter_windows.dll")
set(FLUTTER_LIBRARY ${FLUTTER_LIBRARY} PARENT_SCOPE)
set(FLUTTER_ICU_DATA_FILE "${EPHEMERAL_DIR}/icudtl.dat" PARENT_SCOPE)
set(PROJECT_BUILD_DIR "${PROJECT_DIR}/build/" PARENT_SCOPE)
set(AOT_LIBRARY "${PROJECT_DIR}/build/windows/app.so" PARENT_SCOPE)

set(FLUTTER_LIBRARY_HEADERS
  "${EPHEMERAL_DIR}/flutter_export.h"
  "${EPHEMERAL_DIR}/flutter_windows.h"
  "${EPHEMERAL_DIR}/flutter_messenger.h"
  "${EPHEMERAL_DIR}/flutter_plugin_registrar.h"
  "${EPHEMERAL_DIR}/flutter_texture_registrar.h"
)
add_library(flutter INTERFACE)
target_include_directories(flutter INTERFACE "${EPHEMERAL_DIR}")
target_link_libraries(flutter INTERFACE "${FLUTTER_LIBRARY}.lib")
add_dependencies(flutter flutter_assemble)

set(CPP_WRAPPER_SOURCES_CORE
  "${WRAPPER_ROOT}/core_implementations.cc"
  "${WRAPPER_ROOT}/standard_codec.cc"
)
set(CPP_WRAPPER_SOURCES_APP
  "${WRAPPER_ROOT}/core_implementations.cc"
  "${WRAPPER_ROOT}/flutter_engine.cc"
  "${WRAPPER_ROOT}/flutter_view_controller.cc"
  "${WRAPPER_ROOT}/standard_codec.cc"
)
set(CPP_WRAPPER_SOURCES_PLUGIN
  "${WRAPPER_ROOT}/core_implementations.cc"
  "${WRAPPER_ROOT}/plugin_registrar.cc"
  "${WRAPPER_ROOT}/standard_codec.cc"
)

add_library(flutter_wrapper_app STATIC ${CPP_WRAPPER_SOURCES_APP})
apply_standard_settings(flutter_wrapper_app)
target_link_libraries(flutter_wrapper_app PUBLIC flutter)
target_include_directories(flutter_wrapper_app PUBLIC "${WRAPPER_ROOT}/include")
add_dependencies(flutter_wrapper_app flutter_assemble)

add_library(flutter_wrapper_plugin STATIC ${CPP_WRAPPER_SOURCES_PLUGIN})
apply_standard_settings(flutter_wrapper_plugin)
target_link_libraries(flutter_wrapper_plugin PUBLIC flutter)
target_include_directories(flutter_wrapper_plugin PUBLIC "${WRAPPER_ROOT}/include")
add_dependencies(flutter_wrapper_plugin flutter_assemble)

set(PHONY_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/_phony_")
set_source_files_properties("${PHONY_OUTPUT}" PROPERTIES SYMBOLIC TRUE)
add_custom_command(
  OUTPUT ${FLUTTER_LIBRARY} ${FLUTTER_LIBRARY_HEADERS} ${CPP_WRAPPER_SOURCES_CORE} ${CPP_WRAPPER_SOURCES_APP} ${CPP_WRAPPER_SOURCES_PLUGIN} ${PHONY_OUTPUT}
  COMMAND ${CMAKE_COMMAND} -E env ${FLUTTER_TOOL_ENVIRONMENT} "${FLUTTER_ROOT}/packages/flutter_tools/bin/tool_backend.bat" ${FLUTTER_TARGET_PLATFORM} $<CONFIG>
  VERBATIM
)
add_custom_target(flutter_assemble DEPENDS "${FLUTTER_LIBRARY}" ${FLUTTER_LIBRARY_HEADERS} ${CPP_WRAPPER_SOURCES_CORE} ${CPP_WRAPPER_SOURCES_APP} ${CPP_WRAPPER_SOURCES_PLUGIN})

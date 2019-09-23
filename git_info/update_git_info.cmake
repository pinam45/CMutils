# Required variables:
# WORKING_DIRECTORY
# GIT_EXECUTABLE
# GIT_STATE_FILE
# TARGET_NAME
# PRE_CPP
# PRE_HPP
# POST_CPP
# POST_HPP

# Check variables
foreach(var IN ITEMS WORKING_DIRECTORY GIT_EXECUTABLE GIT_STATE_FILE TARGET_NAME PRE_CPP PRE_HPP POST_CPP POST_HPP)
	if(NOT DEFINED ${var})
		message(FATAL_ERROR "Missing variable ${var}")
		return()
	endif()
endforeach()

# Paths to absolute
foreach(var IN ITEMS WORKING_DIRECTORY GIT_EXECUTABLE GIT_STATE_FILE PRE_CPP PRE_HPP POST_CPP POST_HPP)
	get_filename_component(${var} "${${var}}" ABSOLUTE)
endforeach()

# Get the hash
set(success "true")
execute_process(COMMAND
  "${GIT_EXECUTABLE}" rev-parse --verify HEAD
  WORKING_DIRECTORY "${WORKING_DIRECTORY}"
  RESULT_VARIABLE result
  OUTPUT_VARIABLE hash
  ERROR_QUIET
  OUTPUT_STRIP_TRAILING_WHITESPACE)
if(NOT result EQUAL 0)
	set(success "false")
	set(hashvar "error")
endif()

# Get whether or not the working tree is dirty
execute_process(COMMAND
  "${GIT_EXECUTABLE}" status --porcelain
  WORKING_DIRECTORY "${WORKING_DIRECTORY}"
  RESULT_VARIABLE result
  OUTPUT_VARIABLE out
  ERROR_QUIET
  OUTPUT_STRIP_TRAILING_WHITESPACE)
if(NOT result EQUAL 0)
	set(success "false")
	set(dirty "false")
else()
	if(NOT "${out}" STREQUAL "")
		set(dirty "true")
	else()
		set(dirty "false")
	endif()
endif()

# Check if the state has changed from save
set(state ${success} ${hash} ${dirty})
set(state_changed ON)
if(EXISTS "${GIT_STATE_FILE}")
	file(READ "${GIT_STATE_FILE}" old_state)
	if(old_state STREQUAL "${state}")
		set(state_changed OFF)
	endif()
endif()

# Update state save
if(state_changed OR NOT EXISTS "${POST_CPP}" OR NOT EXISTS "${POST_HPP}")
	file(WRITE "${GIT_STATE_FILE}" "${state}")
	set(GIT_RETRIEVED_STATE "${success}")
	set(GIT_HEAD_SHA1 "${hash}")
	set(GIT_IS_DIRTY "${dirty}")
	configure_file("${PRE_CPP}" "${POST_CPP}" @ONLY)
	configure_file("${PRE_HPP}" "${POST_HPP}" @ONLY)
endif()

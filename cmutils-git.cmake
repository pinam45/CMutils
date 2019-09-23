##################################################################################
# MIT License                                                                    #
#                                                                                #
# Copyright (c) 2018 Maxime Pinard                                               #
#                                                                                #
# Permission is hereby granted, free of charge, to any person obtaining a copy   #
# of this software and associated documentation files (the "Software"), to deal  #
# in the Software without restriction, including without limitation the rights   #
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell      #
# copies of the Software, and to permit persons to whom the Software is          #
# furnished to do so, subject to the following conditions:                       #
#                                                                                #
# The above copyright notice and this permission notice shall be included in all #
# copies or substantial portions of the Software.                                #
#                                                                                #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR     #
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,       #
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE    #
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER         #
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,  #
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE  #
# SOFTWARE.                                                                      #
##################################################################################

# Functions summary:
# - cmutils_create_git_info_target(target_name git_directory)

# include guard
if(CMUTILS_GIT_INCLUDED)
	return()
endif()
set(CMUTILS_GIT_INCLUDED ON)

# dependencies
include(${CMAKE_CURRENT_LIST_DIR}/cmutils-targets.cmake)

# global variables
set(CMUTILS_GIT_INFO_FOLDER_PATH "${CMAKE_CURRENT_LIST_DIR}/git_info")

## cmutils_generate_git_info_target(target_name git_directory)
# Generate a git information target (${target_name}) related to a directory. Linking to this target
# makes available the header ${target_name}.hpp which defines 3 static variables:
# ${target_name}::retrieved_state (bool), true if the git state was successfully retrieved, false otherwise
# ${target_name}::head_sha1 (std::string), sha1 of the commit pointed by HEAD
# ${target_name}::is_dirty (bool), true if the working tree have uncommitted modifications
#   {value} [in] target_name:     Name of the target to generate (also name of the header and namespace)
#   {value} [in] git_directory:   Directory in which git commands will be run to retrieve information
function(cmutils_generate_git_info_target target_name git_directory)
	if(ARGC GREATER 2)
		message(FATAL_ERROR "Too many arguments")
	endif()
	if(TARGET ${target_name})
		message(FATAL_ERROR "${format-target} already exists")
	endif()

	find_package(Git QUIET)
	if(NOT GIT_FOUND)
		message(WARNING "[cmutils] git not found, git information target ${target_name} not generated")
		return()
	else()
		message(STATUS "[cmutils] git found: ${GIT_EXECUTABLE}")
	endif()

	# Set variables
	get_filename_component(TARGET_DIR ${CMAKE_CURRENT_BINARY_DIR}/${target_name} ABSOLUTE)
	set(PRE_INFO_BASE_FOLDER "${CMUTILS_GIT_INFO_FOLDER_PATH}/")
	set(POST_INFO_BASE_FOLDER "${TARGET_DIR}/")
	set(PRE_CPP "${PRE_INFO_BASE_FOLDER}/src/${target_name}.cpp.in")
	set(PRE_HPP "${PRE_INFO_BASE_FOLDER}/include/${target_name}.hpp.in")
	set(POST_CPP "${POST_INFO_BASE_FOLDER}/src/${target_name}.cpp")
	set(POST_HPP "${POST_INFO_BASE_FOLDER}/include/${target_name}.hpp")
	set(GIT_STATE_FILE "${TARGET_DIR}/git-state.txt")
	set(SCRIPT_FILE "${CMUTILS_GIT_INFO_FOLDER_PATH}/update_git_info.cmake")

	# Create target directories
	set(directories "${TARGET_DIR}" "${TARGET_DIR}/src" "${TARGET_DIR}/include")
	foreach(directory ${directories})
		if(NOT EXISTS ${directory})
			file(MAKE_DIRECTORY "${directory}")
		endif()
	endforeach()

	# Create update_target
	if(TARGET update_${target_name})
		message(FATAL_ERROR "update_${target_name} already exists")
	endif()
	add_custom_target(
		update_${target_name}
		ALL
		DEPENDS "${PRE_CPP}" "${PRE_HPP}"
		BYPRODUCTS "${POST_CPP}" "${POST_HPP}"
		COMMENT "Update git repository information for ${target_name}"
		COMMAND
		${CMAKE_COMMAND}
		-DWORKING_DIRECTORY=${git_directory}
		-DGIT_EXECUTABLE=${GIT_EXECUTABLE}
		-DGIT_STATE_FILE=${GIT_STATE_FILE}
		-DTARGET_NAME=${target_name}
		-DPRE_CPP=${PRE_CPP}
		-DPRE_HPP=${PRE_HPP}
		-DPOST_CPP=${POST_CPP}
		-DPOST_HPP=${POST_HPP}
		-P "${SCRIPT_FILE}"
	)
	cmutils_target_set_ide_folder(update_${target_name} "git")

	# Create target
	add_library(${target_name} STATIC)
	target_sources(${target_name} PUBLIC "${POST_CPP}" "${POST_HPP}")
	target_include_directories(${target_name} SYSTEM PUBLIC "${TARGET_DIR}/include")
	add_dependencies(${target_name} update_${target_name})
	cmutils_target_disable_warnings(${target_name})
	cmutils_target_set_standard(${target_name} CXX 98)
	cmutils_target_source_group(${target_name} "${TARGET_DIR}")
	cmutils_target_set_ide_folder(${target_name} "git")

	message(STATUS "[cmutils] Generated git version target ${target_name}")
endfunction()

# Makefile for Vali to build mesa targets
# sudo pip install prettytable Mako pyaml dateutils --upgrade
# - Util
# - mApi
# - gallium
# - mesa
# llvmpipe

ifndef CROSS
$(error CROSS is not set)
endif

CC := $(CROSS)/bin/clang
CXX := $(CROSS)/bin/clang++
LD := $(CROSS)/bin/lld-link
LIB := $(CROSS)/bin/llvm-lib
AS := nasm

ifndef VALI_ARCH
$(error VALI_ARCH is not set)
endif

ifndef VALI_SDK_PATH
$(error VALI_SDK_PATH is not set)
endif

ifndef VALI_INSTALL_PREFIX
$(error VALI_INSTALL_PREFIX is not set)
endif

VALI_INCLUDES = -I$(VALI_DEPS_PATH)/include
VALI_LIBRARIES = -libpath:$(VALI_DEPS_PATH)/lib -libpath:$(VALI_SDK_PATH)/lib
VALI_SDK_CLIBS = c.dll.lib m.dll.lib libcrt.lib librt.lib 
VALI_SDK_CXXLIBS = $(VALI_SDK_CLIBS) c++.dll.lib c++abi.dll.lib unwind.dll.lib

# Setup default build rules
include config/$(VALI_ARCH).mk

VALI_LFLAGS = -lldmap -lldvpe $(VALI_LIBRARIES)
VALI_CFLAGS = $(arch_flags) -fms-extensions
VALI_CXXFLAGS = $(arch_flags) -fms-extensions -std=c++17

MESA_BUILD_PATH := build/vali-$(VALI_ARCH)
MESA_VERSION = `cat VERSION`


DISABLE_WARNINGS_C = -Wno-unused-private-field -Wno-sometimes-uninitialized -Wno-return-type -Wno-unknown-attributes
DISABLE_WARNINGS_CXX = -Wno-delete-non-virtual-dtor -Wno-overloaded-virtual $(DISABLE_WARNINGS_C)
CONFIGFLAGS = -DLLVM_AVAILABLE -DDRAW_LLVM_AVAILABLE -DMESA_LLVM_VERSION_STRING=\"14.0\" -DLLVM_IS_SHARED=0 -DHAVE_LLVM=0x1400 \
			  -DPACKAGE_VERSION="\"$(MESA_VERSION)\"" -DPACKAGE_BUGREPORT="\"https://bugs.freedesktop.org/enter_bug.cgi?product=Mesa\"" \
			  -DDEFAULT_DRIVER_DIR=\"\$$lib/dri\" -DHAVE_STRUCT_TIMESPEC -DHAVE_THRD_CREATE

# USE_X86_ASM USE_MMX_ASM USE_3DNOW_ASM USE_SSE_ASM
# USE_X86_64_ASM
# USE_ARM_ASM
# USE_AARCH64_ASM
# USE_SPARC_ASM
# USE_PPC64LE_ASM
ifeq ($(VALI_ARCH),amd64)
MDEFINES = -mssse3 -msse4.1 -DUSE_X86_64_ASM
else
MDEFINES = -mstackrealign -msse -msse2 -mfpmath=sse -mssse3 -msse4.1 -DUSE_X86_ASM -DUSE_MMX_ASM -DUSE_3DNOW_ASM -DUSE_SSE_ASM
endif

CFLAGS = $(VALI_CFLAGS) -O3 $(MDEFINES) $(DISABLE_WARNINGS_C) -DNDEBUG $(CONFIGFLAGS) $(VALI_INCLUDES)
CXXFLAGS = $(VALI_CXXFLAGS) -O3 $(MDEFINES) $(DISABLE_WARNINGS_CXX) -DNDEBUG $(CONFIGFLAGS) $(VALI_INCLUDES)
LDLIB = /lib
LDAPP = $(VALI_LFLAGS) $(VALI_SDK_CXXLIBS)
LDSO = $(VALI_LFLAGS) /dll $(VALI_SDK_CXXLIBS)

INSTALL_DLL = $(wildcard $(MESA_BUILD_PATH)/*.dll)
INSTALL_APP = $(wildcard $(MESA_BUILD_PATH)/*.run)
INSTALL_MAP = $(wildcard $(MESA_BUILD_PATH)/*.map)
INSTALL_LIB = $(INSTALL_DLL:.dll=.lib)

#############################################
# Sources for zlib library
#############################################
ZLIB_SOURCES_C = $(wildcard config/zlib/*.c)
ZLIB_INCLUDES = -Iconfig/zlib
ZLIB_OBJECTS_C = $(ZLIB_SOURCES_C:.c=.o)

#############################################
# Sources for util library
#############################################
UTIL_SOURCES_GEN_H = src/util/format/u_format_pack.h
UTIL_SOURCES_GEN_C = src/util/format_srgb.c src/util/format/u_format_table.c
UTIL_SOURCES_GEN_CXX = 
UTIL_SOURCES_IGNORE_C = src/util/xmlconfig.c $(UTIL_SOURCES_GEN_C) $(wildcard src/util/*test.c)
UTIL_SOURCES_C = $(filter-out $(UTIL_SOURCES_IGNORE_C), $(wildcard src/util/*.c) $(wildcard src/util/sha1/*.c) $(wildcard src/util/format/*.c))
UTIL_SOURCES_CXX = 
UTIL_INCLUDES = -Iinclude -Isrc -Isrc/mesa -Isrc/mapi -Isrc/gallium/auxiliary -Isrc/gallium/include -Isrc/util
UTIL_OBJECTS_C = $(UTIL_SOURCES_C:.c=.o) $(UTIL_SOURCES_GEN_C:.c=.o)
UTIL_OBJECTS_CXX = $(UTIL_SOURCES_CXX:.cpp=.o) $(UTIL_SOURCES_GEN_CXX:.cpp=.o)
UTIL_LIBRARIES = 

#############################################
# Sources for compiler library
#############################################
COMPILER_SOURCES_GEN_H =
COMPILER_SOURCES_GEN_C =
COMPILER_SOURCES_GEN_CXX =
COMPILER_SOURCES_C = $(wildcard src/compiler/*.c)
COMPILER_SOURCES_CXX = $(wildcard src/compiler/*.cpp)
COMPILER_INCLUDES = -Iinclude -Isrc -Isrc/mesa -Isrc/mapi -Isrc/gallium/auxiliary -Isrc/gallium/include -Isrc/util -Isrc/compiler
COMPILER_OBJECTS_C = $(COMPILER_SOURCES_C:.c=.o) $(COMPILER_SOURCES_GEN_C:.c=.o)
COMPILER_OBJECTS_CXX = $(COMPILER_SOURCES_CXX:.cpp=.o) $(COMPILER_SOURCES_GEN_CXX:.cpp=.o)
COMPILER_LIBRARIES = 

#############################################
# Sources for compiler-glsl library
#############################################
COMPILER_GLSL_SOURCES_GEN_H = src/compiler/glsl/ir_expression_operation.h src/compiler/glsl/ir_expression_operation_constant.h src/compiler/glsl/ir_expression_operation_strings.h src/compiler/glsl/float64_glsl.h
COMPILER_GLSL_SOURCES_GEN_C = src/compiler/glsl/glcpp/glcpp-lex.c src/compiler/glsl/glcpp/glcpp-parse.c src/compiler/glsl/extensions_table.c src/compiler/glsl/symbol_table.c src/compiler/glsl/dummy_errors.c
COMPILER_GLSL_SOURCES_GEN_CXX = src/compiler/glsl/glcpp/glsl_lexer.cpp src/compiler/glsl/glcpp/glsl_parser.cpp
COMPILER_GLSL_SOURCES_C = $(filter-out $(COMPILER_GLSL_SOURCES_GEN_C), $(wildcard src/compiler/glsl/*.c)) src/compiler/glsl/glcpp/pp.c
COMPILER_GLSL_SOURCES_CXX = $(filter-out src/compiler/glsl/main.cpp src/compiler/glsl/ir_builder_print_visitor.cpp src/compiler/glsl/standalone_scaffolding.cpp src/compiler/glsl/standalone.cpp $(COMPILER_GLSL_SOURCES_GEN_CXX), $(wildcard src/compiler/glsl/*.cpp))
COMPILER_GLSL_INCLUDES = -Iinclude -Isrc -Isrc/mesa -Isrc/mesa/program -Isrc/mesa/main -Isrc/mapi -Isrc/gallium/auxiliary -Isrc/gallium/include -Isrc/util -Isrc/compiler -Isrc/compiler/nir -Isrc/compiler/glsl -Isrc/compiler/glsl/glcpp
COMPILER_GLSL_OBJECTS_C = $(COMPILER_GLSL_SOURCES_C:.c=.o) $(COMPILER_GLSL_SOURCES_GEN_C:.c=.o)
COMPILER_GLSL_OBJECTS_CXX = $(COMPILER_GLSL_SOURCES_CXX:.cpp=.o) $(COMPILER_GLSL_SOURCES_GEN_CXX:.cpp=.o)
COMPILER_GLSL_LIBRARIES =

#############################################
# Sources for compiler-glsl application
#############################################
COMPILER_GLSL_APP_SOURCES_GEN_H =
COMPILER_GLSL_APP_SOURCES_GEN_C = 
COMPILER_GLSL_APP_SOURCES_GEN_CXX = 
COMPILER_GLSL_APP_SOURCES_C = src/compiler/glsl/glcpp/pp_standalone_scaffolding.c
COMPILER_GLSL_APP_SOURCES_CXX = src/compiler/glsl/main.cpp src/compiler/glsl/ir_builder_print_visitor.cpp src/compiler/glsl/standalone_scaffolding.cpp src/compiler/glsl/standalone.cpp
COMPILER_GLSL_APP_INCLUDES = -Iinclude -Isrc -Isrc/mesa -Isrc/mesa/program -Isrc/mesa/main -Isrc/mapi -Isrc/gallium/auxiliary -Isrc/gallium/include -Isrc/util -Isrc/compiler -Isrc/compiler/glsl
COMPILER_GLSL_APP_OBJECTS_C = $(COMPILER_GLSL_APP_SOURCES_C:.c=.o) $(COMPILER_GLSL_APP_SOURCES_GEN_C:.c=.o)
COMPILER_GLSL_APP_OBJECTS_CXX = $(COMPILER_GLSL_APP_SOURCES_CXX:.cpp=.o) $(COMPILER_GLSL_APP_SOURCES_GEN_CXX:.cpp=.o)
COMPILER_GLSL_APP_LIBRARIES = $(MESA_BUILD_PATH)/util.lib $(MESA_BUILD_PATH)/compiler.lib $(MESA_BUILD_PATH)/compiler-glsl.lib

#############################################
# Sources for glcpp application
#############################################
GLCPP_APP_SOURCES_GEN_H =
GLCPP_APP_SOURCES_GEN_C = 
GLCPP_APP_SOURCES_GEN_CXX = 
GLCPP_APP_SOURCES_C = src/compiler/glsl/glcpp/glcpp.c src/compiler/glsl/glcpp/pp_standalone_scaffolding.c
GLCPP_APP_SOURCES_CXX = 
GLCPP_APP_INCLUDES = -Iinclude -Isrc -Isrc/mesa -Isrc/mesa/program -Isrc/mesa/main -Isrc/mapi -Isrc/gallium/auxiliary -Isrc/gallium/include -Isrc/util -Isrc/compiler -Isrc/compiler/glsl
GLCPP_APP_OBJECTS_C = $(GLCPP_APP_SOURCES_C:.c=.o) $(GLCPP_APP_SOURCES_GEN_C:.c=.o)
GLCPP_APP_OBJECTS_CXX = $(GLCPP_APP_SOURCES_CXX:.cpp=.o) $(GLCPP_APP_SOURCES_GEN_CXX:.cpp=.o)
GLCPP_APP_LIBRARIES = $(MESA_BUILD_PATH)/util.lib $(MESA_BUILD_PATH)/compiler.lib $(MESA_BUILD_PATH)/compiler-glsl.lib

#############################################
# Sources for compiler-nir library
#############################################
COMPILER_NIR_SOURCES_GEN_H = src/compiler/nir/nir_builder_opcodes.h src/compiler/nir/nir_opcodes.h src/compiler/nir/nir_intrinsics.h src/compiler/nir/nir_intrinsics_indices.h
COMPILER_NIR_SOURCES_GEN_C = src/compiler/nir/nir_constant_expressions.c src/compiler/nir/nir_opcodes.c src/compiler/nir/nir_intrinsics.c src/compiler/nir/nir_opt_algebraic.c
COMPILER_NIR_SOURCES_GEN_CXX =
COMPILER_NIR_SOURCES_C = $(filter-out $(COMPILER_NIR_SOURCES_GEN_C), $(wildcard src/compiler/nir/*.c))
COMPILER_NIR_SOURCES_CXX = $(filter-out $(COMPILER_NIR_SOURCES_GEN_CXX), $(wildcard src/compiler/nir/*.cpp))
COMPILER_NIR_INCLUDES = -Iinclude -Isrc -Isrc/mesa -Isrc/mesa/program -Isrc/mesa/main -Isrc/mapi -Isrc/gallium/auxiliary -Isrc/gallium/include -Isrc/util -Isrc/compiler -Isrc/compiler/nir
COMPILER_NIR_OBJECTS_C = $(COMPILER_NIR_SOURCES_C:.c=.o) $(COMPILER_NIR_SOURCES_GEN_C:.c=.o)
COMPILER_NIR_OBJECTS_CXX = $(COMPILER_NIR_SOURCES_CXX:.cpp=.o) $(COMPILER_NIR_SOURCES_GEN_CXX:.cpp=.o)
COMPILER_NIR_LIBRARIES = 

#############################################
# Sources for compiler-spirv library
#############################################
COMPILER_SPIRV_SOURCES_GEN_H = src/compiler/spirv/vtn_generator_ids.h
COMPILER_SPIRV_SOURCES_GEN_C = src/compiler/spirv/spirv_info.c src/compiler/spirv/vtn_gather_types.c
COMPILER_SPIRV_SOURCES_GEN_CXX =
COMPILER_SPIRV_SOURCES_C = $(filter-out $(COMPILER_SPIRV_SOURCES_GEN_C) src/compiler/spirv/spirv2nir.c, $(wildcard src/compiler/spirv/*.c))
COMPILER_SPIRV_SOURCES_CXX = $(filter-out $(COMPILER_SPIRV_SOURCES_GEN_CXX), $(wildcard src/compiler/spirv/*.cpp))
COMPILER_SPIRV_INCLUDES = -Iinclude -Isrc -Isrc/mesa -Isrc/mesa/program -Isrc/mesa/main -Isrc/mapi -Isrc/gallium/auxiliary -Isrc/gallium/include -Isrc/util -Isrc/compiler -Isrc/compiler/nir -Isrc/compiler/spirv
COMPILER_SPIRV_OBJECTS_C = $(COMPILER_SPIRV_SOURCES_C:.c=.o) $(COMPILER_SPIRV_SOURCES_GEN_C:.c=.o)
COMPILER_SPIRV_OBJECTS_CXX = $(COMPILER_SPIRV_SOURCES_CXX:.cpp=.o) $(COMPILER_SPIRV_SOURCES_GEN_CXX:.cpp=.o)
COMPILER_SPIRV_LIBRARIES = 

#############################################
# Sources for loader library
#############################################
LOADER_SOURCES_GEN_H = 
LOADER_SOURCES_GEN_C = 
LOADER_SOURCES_GEN_CXX =
LOADER_SOURCES_C = src/loader/loader.c src/loader/pci_id_driver_map.c
LOADER_SOURCES_CXX = 
LOADER_INCLUDES = -Iinclude -Isrc -Isrc/mesa -Isrc/mesa/program -Isrc/mesa/main -Isrc/mapi -Isrc/gallium/auxiliary -Isrc/gallium/include -Isrc/util -Isrc/compiler -Isrc/loader
LOADER_OBJECTS_C = $(LOADER_SOURCES_C:.c=.o) $(LOADER_SOURCES_GEN_C:.c=.o)
LOADER_OBJECTS_CXX = $(LOADER_SOURCES_CXX:.cpp=.o) $(LOADER_SOURCES_GEN_CXX:.cpp=.o)
LOADER_LIBRARIES = 

#############################################
# Sources for mapi-glapi library
#############################################
MAPI_GLAPI_SOURCES_GEN_H = src/mesa/main/dispatch.h src/mapi/glapi/glapitable.h src/mapi/glapi/glapitemp.h src/mapi/glapi/glprocs.h src/mesa/main/remap_helper.h
MAPI_GLAPI_SOURCES_GEN_C = src/mesa/main/enums.c src/mesa/main/api_exec.c
MAPI_GLAPI_SOURCES_GEN_S = src/mapi/glapi/glapi_x86.S src/mapi/glapi/glapi_x86-64.S
MAPI_GLAPI_SOURCES_GEN_CXX = 
MAPI_GLAPI_SOURCES_C = $(wildcard src/mapi/glapi/*.c) src/mapi/u_current.c src/mapi/u_execmem.c
MAPI_GLAPI_SOURCES_CXX = 
MAPI_GLAPI_INCLUDES = -DMAPI_MODE_UTIL -DBUILD_GL32 -D_GLAPI_DLL_EXPORTS -DKHRONOS_DLL_EXPORTS -Iinclude -Isrc -Isrc/mesa -Isrc/mesa/program -Isrc/mesa/main -Isrc/mapi -Isrc/gallium/auxiliary -Isrc/gallium/include -Isrc/util -Isrc/compiler -Isrc/mapi -Isrc/mapi/glapi
ifeq ($(VALI_ARCH),amd64)
MAPI_GLAPI_OBJECTS_S = src/mapi/glapi/glapi_x86-64.o
else
MAPI_GLAPI_OBJECTS_S = src/mapi/glapi/glapi_x86.o
endif

MAPI_GLAPI_OBJECTS_C = $(MAPI_GLAPI_SOURCES_C:.c=.o) $(MAPI_GLAPI_SOURCES_GEN_C:.c=.o)
MAPI_GLAPI_OBJECTS_CXX = $(MAPI_GLAPI_SOURCES_CXX:.cpp=.o) $(MAPI_GLAPI_SOURCES_GEN_CXX:.cpp=.o)
MAPI_GLAPI_LIBRARIES = 

#############################################
# Sources for mesa library
#############################################
MESA_SOURCES_GEN_H = src/mesa/main/marshal_generated.h src/mesa/main/get_hash.h src/mesa/main/format_info.h
MESA_SOURCES_GEN_C = src/mesa/main/marshal_generated0.c src/mesa/main/marshal_generated1.c src/mesa/main/marshal_generated2.c \
					 src/mesa/main/marshal_generated3.c src/mesa/main/marshal_generated4.c src/mesa/main/marshal_generated5.c \
					 src/mesa/main/marshal_generated6.c src/mesa/main/marshal_generated7.c src/mesa/main/format_fallback.c \
					 src/mesa/main/format_pack.c src/mesa/program/lex.yy.c \
					 src/mesa/program/program_parse.tab.c
MESA_SOURCES_GEN_S =
MESA_SOURCES_GEN_CXX = 
ifeq ($(VALI_ARCH),amd64)
MESA_SOURCES_S = $(wildcard src/mesa/x86-64/*.S)
else
MESA_SOURCES_S = $(wildcard src/mesa/x86/*.S)
endif
MESA_SOURCES_C = $(filter-out src/mesa/main/enums.c src/mesa/main/api_exec.c $(MESA_SOURCES_GEN_C), $(wildcard src/mesa/main/*.c)) \
				 $(filter-out src/mesa/program/lex.yy.c src/mesa/program/program_parse.tab.c, $(wildcard src/mesa/program/*.c)) \
				 $(wildcard src/mesa/state_tracker/*.c) \
				 $(wildcard src/mesa/math/*.c) \
				 $(wildcard src/mesa/vbo/*.c) \
				 $(wildcard src/mesa/tnl/*.c) \
				 $(wildcard src/mesa/swrast/*.c) \
				 $(wildcard src/mesa/swrast_setup/*.c) \
				 $(wildcard src/mesa/drivers/common/*.c) \
				 $(wildcard src/mesa/sparc/*.c) \
				 $(wildcard src/mesa/x86/*.c) \
				 $(wildcard src/mesa/x86/rtasm/*.c) \
				 $(wildcard src/mesa/x86-64/*.c)
MESA_SOURCES_CXX = $(wildcard src/mesa/main/*.cpp) \
				   $(wildcard src/mesa/program/*.cpp) \
				   $(wildcard src/mesa/state_tracker/*.cpp)
MESA_INCLUDES = -DBUILD_GL32 -D_GLAPI_NO_EXPORTS -Iinclude -Isrc -Isrc/mesa -Isrc/mesa/program -Isrc/mesa/main -Isrc/mapi -Isrc/gallium/auxiliary -Isrc/gallium/include -Isrc/util -Isrc/compiler -Isrc/mapi -Isrc/mapi/glapi
MESA_OBJECTS_S = $(MESA_SOURCES_S:.S=.o)
MESA_OBJECTS_C = $(MESA_SOURCES_C:.c=.o) $(MESA_SOURCES_GEN_C:.c=.o)
MESA_OBJECTS_CXX = $(MESA_SOURCES_CXX:.cpp=.o) $(MESA_SOURCES_GEN_CXX:.cpp=.o)
MESA_LIBRARIES = 

#############################################
# Sources for glapi shared library
#############################################
GLAPI_DLL_SOURCES_GEN_H = src/mapi/shared-glapi-tmp.h
GLAPI_DLL_SOURCES_GEN_C = src/mapi/gl_entry.c src/mapi/gl_mapi_glapi.c src/mapi/gl_stub.c src/mapi/gl_table.c src/mapi/gl_u_current.c src/mapi/gl_u_execmem.c
GLAPI_DLL_SOURCES_GEN_CXX = src/mapi/gl_main.cpp
GLAPI_DLL_SOURCES_C = 
GLAPI_DLL_SOURCES_CXX = 
GLAPI_DLL_INCLUDES = -DMAPI_ABI_HEADER="\"shared-glapi-tmp.h\"" -D_GLAPI_DLL_EXPORTS -DMAPI_MODE_GLAPI -Iinclude -Isrc -Isrc/mesa -Isrc/mesa/program -Isrc/mesa/main -Isrc/mapi -Isrc/gallium/auxiliary -Isrc/gallium/include -Isrc/util -Isrc/compiler -Isrc/compiler/glsl
GLAPI_DLL_OBJECTS_C = $(GLAPI_DLL_SOURCES_C:.c=.o) $(GLAPI_DLL_SOURCES_GEN_C:.c=.o)
GLAPI_DLL_OBJECTS_CXX = $(GLAPI_DLL_SOURCES_CXX:.cpp=.o) $(GLAPI_DLL_SOURCES_GEN_CXX:.cpp=.o)
GLAPI_DLL_LIBRARIES = $(MESA_BUILD_PATH)/mesa.lib $(MESA_BUILD_PATH)/util.lib $(MESA_BUILD_PATH)/compiler.lib $(MESA_BUILD_PATH)/compiler-glsl.lib

#############################################
# Sources for GLESv1 shared library
#############################################
GLESV1_DLL_SOURCES_GEN_H = src/mapi/es1api-tmp.h
GLESV1_DLL_SOURCES_GEN_C = src/mapi/gl1_entry.c
GLESV1_DLL_SOURCES_GEN_CXX = src/mapi/gl1_main.cpp
GLESV1_DLL_SOURCES_C = 
GLESV1_DLL_SOURCES_CXX = 
GLESV1_DLL_INCLUDES = -DMAPI_ABI_HEADER="\"es1api-tmp.h\"" -DBUILD_GL32 -DMAPI_MODE_BRIDGE -Iinclude -Isrc -Isrc/mesa -Isrc/mesa/program -Isrc/mesa/main -Isrc/mapi -Isrc/gallium/auxiliary -Isrc/gallium/include -Isrc/util -Isrc/compiler -Isrc/compiler/glsl
GLESV1_DLL_OBJECTS_C = $(GLESV1_DLL_SOURCES_C:.c=.o) $(GLESV1_DLL_SOURCES_GEN_C:.c=.o)
GLESV1_DLL_OBJECTS_CXX = $(GLESV1_DLL_SOURCES_CXX:.cpp=.o) $(GLESV1_DLL_SOURCES_GEN_CXX:.cpp=.o)
GLESV1_DLL_LIBRARIES = $(MESA_BUILD_PATH)/mesa.lib $(MESA_BUILD_PATH)/util.lib $(MESA_BUILD_PATH)/compiler.lib $(MESA_BUILD_PATH)/compiler-glsl.lib $(MESA_BUILD_PATH)/glapi.lib

#############################################
# Sources for GLESv2 shared library
#############################################
GLESV2_DLL_SOURCES_GEN_H = src/mapi/es2api-tmp.h
GLESV2_DLL_SOURCES_GEN_C = src/mapi/gl2_entry.c
GLESV2_DLL_SOURCES_GEN_CXX = src/mapi/gl2_main.cpp
GLESV2_DLL_SOURCES_C = 
GLESV2_DLL_SOURCES_CXX = 
GLESV2_DLL_INCLUDES = -DMAPI_ABI_HEADER="\"es2api-tmp.h\"" -DBUILD_GL32 -DMAPI_MODE_BRIDGE -Iinclude -Isrc -Isrc/mesa -Isrc/mesa/program -Isrc/mesa/main -Isrc/mapi -Isrc/gallium/auxiliary -Isrc/gallium/include -Isrc/util -Isrc/compiler -Isrc/compiler/glsl
GLESV2_DLL_OBJECTS_C = $(GLESV2_DLL_SOURCES_C:.c=.o) $(GLESV2_DLL_SOURCES_GEN_C:.c=.o)
GLESV2_DLL_OBJECTS_CXX = $(GLESV2_DLL_SOURCES_CXX:.cpp=.o) $(GLESV2_DLL_SOURCES_GEN_CXX:.cpp=.o)
GLESV2_DLL_LIBRARIES = $(MESA_BUILD_PATH)/mesa.lib $(MESA_BUILD_PATH)/util.lib $(MESA_BUILD_PATH)/compiler.lib $(MESA_BUILD_PATH)/compiler-glsl.lib $(MESA_BUILD_PATH)/glapi.lib

#############################################
# Sources for gallium-aux library
#############################################
GAAUX_SOURCES_GEN_H =
GAAUX_SOURCES_GEN_C = src/gallium/auxiliary/indices/u_indices_gen.c src/gallium/auxiliary/indices/u_unfilled_gen.c
GAAUX_SOURCES_GEN_S =
GAAUX_SOURCES_GEN_CXX = 
GAAUX_SOURCES_C = $(wildcard src/gallium/auxiliary/cso_cache/*.c) \
				  $(wildcard src/gallium/auxiliary/draw/*.c) \
				  $(wildcard src/gallium/auxiliary/driver_ddebug/*.c) \
				  $(wildcard src/gallium/auxiliary/driver_noop/*.c) \
				  $(wildcard src/gallium/auxiliary/driver_rbug/*.c) \
				  $(wildcard src/gallium/auxiliary/driver_trace/*.c) \
				  $(wildcard src/gallium/auxiliary/hud/*.c) \
				  src/gallium/auxiliary/indices/u_primconvert.c \
				  $(wildcard src/gallium/auxiliary/os/*.c) \
				  $(wildcard src/gallium/auxiliary/pipebuffer/*.c) \
				  $(wildcard src/gallium/auxiliary/postprocess/*.c) \
				  $(wildcard src/gallium/auxiliary/rbug/*.c) \
				  $(wildcard src/gallium/auxiliary/rtasm/*.c) \
				  $(wildcard src/gallium/auxiliary/tgsi/*.c) \
				  $(wildcard src/gallium/auxiliary/translate/*.c) \
				  $(wildcard src/gallium/auxiliary/util/*.c) \
				  $(wildcard src/gallium/auxiliary/nir/*.c) \
				  $(wildcard src/gallium/auxiliary/tessellator/*.c) \
				  $(wildcard src/gallium/auxiliary/gallivm/*.c) \
				  src/gallium/auxiliary/vl/vl_bicubic_filter.c src/gallium/auxiliary/vl/vl_compositor.c \
				  src/gallium/auxiliary/vl/vl_compositor_gfx.c src/gallium/auxiliary/vl/vl_compositor_cs.c \
				  src/gallium/auxiliary/vl/vl_csc.c src/gallium/auxiliary/vl/vl_decoder.c src/gallium/auxiliary/vl/vl_deint_filter.c \
				  src/gallium/auxiliary/vl/vl_idct.c src/gallium/auxiliary/vl/vl_matrix_filter.c \
				  src/gallium/auxiliary/vl/vl_mc.c src/gallium/auxiliary/vl/vl_median_filter.c src/gallium/auxiliary/vl/vl_mpeg12_bitstream.c \
				  src/gallium/auxiliary/vl/vl_mpeg12_decoder.c \
				  src/gallium/auxiliary/vl/vl_vertex_buffers.c src/gallium/auxiliary/vl/vl_video_buffer.c \
				  src/gallium/auxiliary/vl/vl_zscan.c
GAAUX_SOURCES_CXX = $(wildcard src/gallium/auxiliary/tessellator/*.cpp) \
					src/gallium/auxiliary/gallivm/lp_bld_debug.cpp src/gallium/auxiliary/gallivm/lp_bld_misc.cpp
GAAUX_INCLUDES = -fno-rtti -Iinclude -Isrc -Isrc/gallium/include -Isrc/gallium/auxiliary -Isrc/compiler/nir
GAAUX_OBJECTS_S =
GAAUX_OBJECTS_C = $(GAAUX_SOURCES_C:.c=.o) $(GAAUX_SOURCES_GEN_C:.c=.o)
GAAUX_OBJECTS_CXX = $(GAAUX_SOURCES_CXX:.cpp=.o) $(GAAUX_SOURCES_GEN_CXX:.cpp=.o)
GAAUX_LIBRARIES = 

#############################################
# Sources for gallium-pipe library
#############################################
GAPIPE_SOURCES_GEN_H =
GAPIPE_SOURCES_GEN_C =
GAPIPE_SOURCES_GEN_S =
GAPIPE_SOURCES_GEN_CXX = 
GAPIPE_SOURCES_C = src/gallium/auxiliary/pipe-loader/pipe_loader.c src/gallium/auxiliary/pipe-loader/pipe_loader_sw.c
GAPIPE_SOURCES_CXX = 
GAPIPE_INCLUDES = -DGALLIUM_STATIC_TARGETS=1 -DDROP_PIPE_LOADER_MISC=1 -DHAVE_PIPE_LOADER_DRI=1 -Iinclude -Isrc -Isrc/gallium/include -Isrc/gallium/auxiliary -Isrc/gallium/winsys
GAPIPE_OBJECTS_S =
GAPIPE_OBJECTS_C = $(GAPIPE_SOURCES_C:.c=.o) $(GAPIPE_SOURCES_GEN_C:.c=.o)
GAPIPE_OBJECTS_CXX = $(GAPIPE_SOURCES_CXX:.cpp=.o) $(GAPIPE_SOURCES_GEN_CXX:.cpp=.o)
GAPIPE_LIBRARIES = 

#############################################
# Sources for gallium driver (llvmpipe) library
#############################################
GALLVMPIPE_SOURCES_GEN_H =
GALLVMPIPE_SOURCES_GEN_C =
GALLVMPIPE_SOURCES_GEN_S =
GALLVMPIPE_SOURCES_GEN_CXX = 
GALLVMPIPE_SOURCES_C = $(filter-out $(wildcard *lp_test*.c), $(wildcard src/gallium/drivers/llvmpipe/*.c))
GALLVMPIPE_SOURCES_CXX = 
GALLVMPIPE_INCLUDES = -Iinclude -Isrc -Isrc/gallium/include -Isrc/gallium/auxiliary -Isrc/gallium/winsys -Isrc/compiler/nir
GALLVMPIPE_OBJECTS_S =
GALLVMPIPE_OBJECTS_C = $(GALLVMPIPE_SOURCES_C:.c=.o) $(GALLVMPIPE_SOURCES_GEN_C:.c=.o)
GALLVMPIPE_OBJECTS_CXX = $(GALLVMPIPE_SOURCES_CXX:.cpp=.o) $(GALLVMPIPE_SOURCES_GEN_CXX:.cpp=.o)
GALLVMPIPE_LIBRARIES = 

#############################################
# Sources for gallium driver (softpipe) library
#############################################
GASOFTPIPE_SOURCES_GEN_H =
GASOFTPIPE_SOURCES_GEN_C =
GASOFTPIPE_SOURCES_GEN_S =
GASOFTPIPE_SOURCES_GEN_CXX = 
GASOFTPIPE_SOURCES_C = $(wildcard src/gallium/drivers/softpipe/*.c)
GASOFTPIPE_SOURCES_CXX = 
GASOFTPIPE_INCLUDES = -Iinclude -Isrc -Isrc/gallium/include -Isrc/gallium/auxiliary -Isrc/gallium/winsys -Isrc/compiler/nir
GASOFTPIPE_OBJECTS_S =
GASOFTPIPE_OBJECTS_C = $(GASOFTPIPE_SOURCES_C:.c=.o) $(GASOFTPIPE_SOURCES_GEN_C:.c=.o)
GASOFTPIPE_OBJECTS_CXX = $(GASOFTPIPE_SOURCES_CXX:.cpp=.o) $(GASOFTPIPE_SOURCES_GEN_CXX:.cpp=.o)
GASOFTPIPE_LIBRARIES = 

#############################################
# Sources for gallium driver (svga) library
#############################################
GASVGA_SOURCES_GEN_H =
GASVGA_SOURCES_GEN_C =
GASVGA_SOURCES_GEN_S =
GASVGA_SOURCES_GEN_CXX = 
GASVGA_SOURCES_C = $(wildcard src/gallium/drivers/svga/*.c)
GASVGA_SOURCES_CXX = 
GASVGA_INCLUDES = -DHAVE_STDINT_H -Iinclude -Isrc -Isrc/gallium/include -Isrc/gallium/auxiliary -Isrc/gallium/drivers/svga/include
GASVGA_OBJECTS_S =
GASVGA_OBJECTS_C = $(GASVGA_SOURCES_C:.c=.o) $(GASVGA_SOURCES_GEN_C:.c=.o)
GASVGA_OBJECTS_CXX = $(GASVGA_SOURCES_CXX:.cpp=.o) $(GASVGA_SOURCES_GEN_CXX:.cpp=.o)
GASVGA_LIBRARIES = 

#############################################
# Sources for gallium winsys (sw/null) library
#############################################
GAWINSYS_NULL_SOURCES_GEN_H =
GAWINSYS_NULL_SOURCES_GEN_C =
GAWINSYS_NULL_SOURCES_GEN_S =
GAWINSYS_NULL_SOURCES_GEN_CXX = 
GAWINSYS_NULL_SOURCES_C = src/gallium/winsys/sw/null/null_sw_winsys.c
GAWINSYS_NULL_SOURCES_CXX = 
GAWINSYS_NULL_INCLUDES = -Iinclude -Isrc -Isrc/gallium/include -Isrc/gallium/auxiliary -Isrc/gallium/winsys/sw/null/
GAWINSYS_NULL_OBJECTS_S =
GAWINSYS_NULL_OBJECTS_C = $(GAWINSYS_NULL_SOURCES_C:.c=.o) $(GAWINSYS_NULL_SOURCES_GEN_C:.c=.o)
GAWINSYS_NULL_OBJECTS_CXX = $(GAWINSYS_NULL_SOURCES_CXX:.cpp=.o) $(GAWINSYS_NULL_SOURCES_GEN_CXX:.cpp=.o)
GAWINSYS_NULL_LIBRARIES = 

#############################################
# Sources for gallium winsys (sw/wrapper) library
#############################################
GAWINSYS_WRAPPER_SOURCES_GEN_H =
GAWINSYS_WRAPPER_SOURCES_GEN_C =
GAWINSYS_WRAPPER_SOURCES_GEN_S =
GAWINSYS_WRAPPER_SOURCES_GEN_CXX = 
GAWINSYS_WRAPPER_SOURCES_C = src/gallium/winsys/sw/wrapper/wrapper_sw_winsys.c
GAWINSYS_WRAPPER_SOURCES_CXX = 
GAWINSYS_WRAPPER_INCLUDES = -Iinclude -Isrc -Isrc/gallium/include -Isrc/gallium/auxiliary -Isrc/gallium/winsys/sw/wrapper/
GAWINSYS_WRAPPER_OBJECTS_S =
GAWINSYS_WRAPPER_OBJECTS_C = $(GAWINSYS_WRAPPER_SOURCES_C:.c=.o) $(GAWINSYS_WRAPPER_SOURCES_GEN_C:.c=.o)
GAWINSYS_WRAPPER_OBJECTS_CXX = $(GAWINSYS_WRAPPER_SOURCES_CXX:.cpp=.o) $(GAWINSYS_WRAPPER_SOURCES_GEN_CXX:.cpp=.o)
GAWINSYS_WRAPPER_LIBRARIES = 

#############################################
# Sources for gallium target (graw-null) library
#############################################
GRAW_NULL_SOURCES_GEN_H =
GRAW_NULL_SOURCES_GEN_C =
GRAW_NULL_SOURCES_GEN_S =
GRAW_NULL_SOURCES_GEN_CXX = 
GRAW_NULL_SOURCES_C = $(wildcard src/gallium/targets/graw-null/*.c)
GRAW_NULL_SOURCES_CXX = src/gallium/targets/graw-null/main.cpp
GRAW_NULL_INCLUDES = -Iinclude -Isrc -Isrc/gallium/include -Isrc/gallium/auxiliary
GRAW_NULL_OBJECTS_S =
GRAW_NULL_OBJECTS_C = $(GRAW_NULL_SOURCES_C:.c=.o) $(GRAW_NULL_SOURCES_GEN_C:.c=.o)
GRAW_NULL_OBJECTS_CXX = $(GRAW_NULL_SOURCES_CXX:.cpp=.o) $(GRAW_NULL_SOURCES_GEN_CXX:.cpp=.o)
GRAW_NULL_LIBRARIES = $(MESA_BUILD_PATH)/util.lib $(MESA_BUILD_PATH)/gallium-aux.lib

#############################################
# Sources for gallium frontend (osmesa) library
#############################################
GAST_OSMESA_SOURCES_GEN_H =
GAST_OSMESA_SOURCES_GEN_C =
GAST_OSMESA_SOURCES_GEN_S =
GAST_OSMESA_SOURCES_GEN_CXX = 
GAST_OSMESA_SOURCES_C = src/gallium/frontends/osmesa/osmesa.c
GAST_OSMESA_SOURCES_CXX =
GAST_OSMESA_INCLUDES = -DBUILD_GL32 -Iinclude -Isrc -Isrc/mesa -Isrc/mapi -Isrc/gallium/include -Isrc/gallium/auxiliary
GAST_OSMESA_OBJECTS_S =
GAST_OSMESA_OBJECTS_C = $(GAST_OSMESA_SOURCES_C:.c=.o) $(GAST_OSMESA_SOURCES_GEN_C:.c=.o)
GAST_OSMESA_OBJECTS_CXX = $(GAST_OSMESA_SOURCES_CXX:.cpp=.o) $(GAST_OSMESA_SOURCES_GEN_CXX:.cpp=.o)
GAST_OSMESA_LIBRARIES =

#############################################
# Sources for gallium target (osmesa) library
# To use llvmpipe define GALLIUM_LLVMPIPE
# To use softpipe define GALLIUM_SOFTPIPE
#############################################
LLVM_LIBRARIES = $(wildcard $(VALI_DEPS_PATH)/lib/LLVM*)
GA_OSMESA_SOURCES_GEN_H =
GA_OSMESA_SOURCES_GEN_C =
GA_OSMESA_SOURCES_GEN_S =
GA_OSMESA_SOURCES_GEN_CXX = 
GA_OSMESA_SOURCES_C = src/gallium/targets/osmesa/target.c
GA_OSMESA_SOURCES_CXX = src/gallium/targets/osmesa/main.cpp
GA_OSMESA_INCLUDES = -DGALLIUM_LLVMPIPE -Iinclude -Isrc -Isrc/gallium/include -Isrc/gallium/auxiliary -Isrc/gallium/drivers -Isrc/gallium/winsys
GA_OSMESA_OBJECTS_S =
GA_OSMESA_OBJECTS_C = $(GA_OSMESA_SOURCES_C:.c=.o) $(GA_OSMESA_SOURCES_GEN_C:.c=.o)
GA_OSMESA_OBJECTS_CXX = $(GA_OSMESA_SOURCES_CXX:.cpp=.o) $(GA_OSMESA_SOURCES_GEN_CXX:.cpp=.o)
GA_OSMESA_LIBRARIES = $(LLVM_LIBRARIES) $(MESA_BUILD_PATH)/util.lib $(MESA_BUILD_PATH)/gallium-aux.lib \
					  $(MESA_BUILD_PATH)/gallium-st-osmesa.lib $(MESA_BUILD_PATH)/gallium-winsys-null.lib \
					  $(MESA_BUILD_PATH)/gallium-softpipe.lib $(MESA_BUILD_PATH)/glapi_lib.lib \
					  $(MESA_BUILD_PATH)/compiler.lib $(MESA_BUILD_PATH)/mesa.lib $(MESA_BUILD_PATH)/compiler-glsl.lib \
					  $(MESA_BUILD_PATH)/compiler-nir.lib $(MESA_BUILD_PATH)/compiler-spirv.lib $(MESA_BUILD_PATH)/gallium-llvmpipe.lib \
					  config/zlib/z.lib \
					  /def:src/gallium/targets/osmesa/osmesa.vali.def

.PHONY: all
all: $(MESA_BUILD_PATH) config/zlib/z.lib $(MESA_BUILD_PATH)/util.lib $(MESA_BUILD_PATH)/compiler.lib \
	 $(MESA_BUILD_PATH)/compiler-glsl.lib $(MESA_BUILD_PATH)/compiler-glsl.app \
	 $(MESA_BUILD_PATH)/glcpp.app $(MESA_BUILD_PATH)/compiler-nir.lib $(MESA_BUILD_PATH)/compiler-spirv.lib \
	 $(MESA_BUILD_PATH)/loader.lib $(MESA_BUILD_PATH)/glapi_lib.lib $(MESA_BUILD_PATH)/mesa.lib \
	 $(MESA_BUILD_PATH)/glapi.dll $(MESA_BUILD_PATH)/GLESv1.dll $(MESA_BUILD_PATH)/GLESv2.dll \
	 $(MESA_BUILD_PATH)/gallium-aux.lib $(MESA_BUILD_PATH)/gallium-pipe.lib \
	 $(MESA_BUILD_PATH)/gallium-llvmpipe.lib $(MESA_BUILD_PATH)/gallium-softpipe.lib \
	 $(MESA_BUILD_PATH)/gallium-svga.lib \
	 $(MESA_BUILD_PATH)/gallium-winsys-null.lib $(MESA_BUILD_PATH)/gallium-winsys-wrapper.lib \
	 $(MESA_BUILD_PATH)/gallium-graw-null.dll $(MESA_BUILD_PATH)/gallium-st-osmesa.lib \
	 $(MESA_BUILD_PATH)/gallium-osmesa.dll

# define the newline function for the foreach loops
define \n


endef

.PHONY: install
install: all
	@mkdir -p $(VALI_INSTALL_PREFIX)/bin
	@mkdir -p $(VALI_INSTALL_PREFIX)/include
	@mkdir -p $(VALI_INSTALL_PREFIX)/lib
	$(foreach app, $(INSTALL_APP), cp -f $(app) $(VALI_INSTALL_PREFIX)/bin/$(notdir $(app))${\n})
	$(foreach dll, $(INSTALL_DLL), cp -f $(dll) $(VALI_INSTALL_PREFIX)/bin/$(notdir $(dll))${\n})
	$(foreach map, $(INSTALL_MAP), cp -f $(map) $(VALI_INSTALL_PREFIX)/bin/$(notdir $(map))${\n})
	$(foreach lib, $(INSTALL_LIB), cp -f $(lib) $(VALI_INSTALL_PREFIX)/lib/$(notdir $(lib))${\n})
	@mkdir -p $(VALI_INSTALL_PREFIX)/include/GL
	cp -rf include/CL/ $(VALI_INSTALL_PREFIX)/include/
	cp -rf include/EGL/ $(VALI_INSTALL_PREFIX)/include/
	cp -rf include/GL/*.h $(VALI_INSTALL_PREFIX)/include/GL
	cp -rf include/GLES/ $(VALI_INSTALL_PREFIX)/include/
	cp -rf include/GLES2/ $(VALI_INSTALL_PREFIX)/include/
	cp -rf include/GLES3/ $(VALI_INSTALL_PREFIX)/include/
	cp -rf include/KHR/ $(VALI_INSTALL_PREFIX)/include/
	cp -rf include/vulkan/ $(VALI_INSTALL_PREFIX)/include/

$(MESA_BUILD_PATH):
	@mkdir -p $@

#############################################
# ZLib Library
#############################################
config/zlib/z.lib: $(ZLIB_OBJECTS_C)
	@printf "%b" "\033[0;36mCreating static library " $@ "\033[m\n"
	@$(LD) $(LDLIB) $(ZLIB_OBJECTS_C) /out:$@

$(ZLIB_OBJECTS_C): %.o : %.c
	@printf "%b" "\033[0;32mCompiling C source object " $< "\033[m\n"
	@$(CC) -c $(CFLAGS) $(ZLIB_INCLUDES) -o $@ $<

#############################################
# Utility Library
#############################################
$(MESA_BUILD_PATH)/util.lib: $(UTIL_SOURCES_GEN_H) $(UTIL_SOURCES_GEN_C) $(UTIL_SOURCES_GEN_CXX) $(UTIL_OBJECTS_C) $(UTIL_OBJECTS_CXX)
	@printf "%b" "\033[0;36mCreating static library " $@ "\033[m\n"
	@$(LD) $(LDLIB) $(UTIL_OBJECTS_C) $(UTIL_OBJECTS_CXX) $(UTIL_LIBRARIES) /out:$@

# python_cmd + ' $SCRIPT > $TARGET'
src/util/format/u_format_pack.h: src/util/format/u_format_table.py
	python3 $< src/util/format/u_format.csv --header > $@

# python_cmd + ' $SCRIPT > $TARGET'
src/util/format/u_format_table.c: src/util/format/u_format_table.py
	python3 $< src/util/format/u_format.csv > $@

# python_cmd + ' $SCRIPT > $TARGET'
src/util/format_srgb.c: src/util/format_srgb.py
	python3 $< > $@

$(UTIL_OBJECTS_C): %.o : %.c
	@printf "%b" "\033[0;32mCompiling C source object " $< "\033[m\n"
	@$(CC) -c $(CFLAGS) $(UTIL_INCLUDES) -o $@ $<

$(UTIL_OBJECTS_CXX): %.o : %.cpp
	@printf "%b" "\033[0;32mCompiling C++ source object " $< "\033[m\n"
	@$(CXX) -c $(CXXFLAGS) $(UTIL_INCLUDES) -o $@ $<

#############################################
# Compiler Library
#############################################
$(MESA_BUILD_PATH)/compiler.lib: $(COMPILER_SOURCES_GEN_H) $(COMPILER_GLSL_SOURCES_GEN_H) $(COMPILER_SOURCES_GEN_C) $(COMPILER_SOURCES_GEN_CXX) $(COMPILER_OBJECTS_C) $(COMPILER_OBJECTS_CXX)
	@printf "%b" "\033[0;36mCreating static library " $@ "\033[m\n"
	@$(LD) $(LDLIB) $(COMPILER_OBJECTS_C) $(COMPILER_OBJECTS_CXX) $(COMPILER_LIBRARIES) /out:$@

$(COMPILER_OBJECTS_C): %.o : %.c
	@printf "%b" "\033[0;32mCompiling C source object " $< "\033[m\n"
	@$(CC) -c $(CFLAGS) $(COMPILER_INCLUDES) -o $@ $<

$(COMPILER_OBJECTS_CXX): %.o : %.cpp
	@printf "%b" "\033[0;32mCompiling C++ source object " $< "\033[m\n"
	@$(CXX) -c $(CXXFLAGS) $(COMPILER_INCLUDES) -o $@ $<

#############################################
# GLSL-Compiler Library
#############################################
$(MESA_BUILD_PATH)/compiler-glsl.lib: $(COMPILER_NIR_SOURCES_GEN_H) $(COMPILER_GLSL_SOURCES_GEN_H) $(COMPILER_GLSL_SOURCES_GEN_C) $(COMPILER_GLSL_SOURCES_GEN_CXX) $(COMPILER_GLSL_OBJECTS_C) $(COMPILER_GLSL_OBJECTS_CXX)
	@printf "%b" "\033[0;36mCreating static library " $@ "\033[m\n"
	@$(LD) $(LDLIB) $(COMPILER_GLSL_OBJECTS_C) $(COMPILER_GLSL_OBJECTS_CXX) $(COMPILER_GLSL_LIBRARIES) /out:$@

src/compiler/glsl/glcpp/glcpp-lex.c: src/compiler/glsl/glcpp/glcpp-lex.l
	lex -o $@ $<
	
src/compiler/glsl/glcpp/glsl_lexer.cpp: src/compiler/glsl/glsl_lexer.ll
	lex -o $@ $<

src/compiler/glsl/glcpp/glcpp-parse.c: src/compiler/glsl/glcpp/glcpp-parse.y
	bison -o $@ -p glcpp_parser_ --defines=src/compiler/glsl/glcpp/glcpp-parse.h $<
	
src/compiler/glsl/glcpp/glsl_parser.cpp: src/compiler/glsl/glsl_parser.yy
	bison --defines=src/compiler/glsl/glcpp/glsl_parser.h -p _mesa_glsl_ -o $@ $<

src/compiler/glsl/extensions_table.c: src/mesa/main/extensions_table.c
	cp $< $@
src/compiler/glsl/symbol_table.c: src/mesa/program/symbol_table.c
	cp $< $@
src/compiler/glsl/dummy_errors.c: src/mesa/program/dummy_errors.c
	cp $< $@

# python_cmd + ' $SCRIPT enum > $TARGET'
src/compiler/glsl/ir_expression_operation.h: src/compiler/glsl/ir_expression_operation.py
	python3 $< enum > $@

# python_cmd + ' $SCRIPT constant > $TARGET'
src/compiler/glsl/ir_expression_operation_constant.h: src/compiler/glsl/ir_expression_operation.py
	python3 $< constant > $@

# python_cmd + ' $SCRIPT strings > $TARGET'
src/compiler/glsl/ir_expression_operation_strings.h: src/compiler/glsl/ir_expression_operation.py
	python3 $< strings > $@
	
src/compiler/glsl/float64_glsl.h: src/util/xxd.py src/compiler/glsl/float64.glsl
	python3 $^ $@ -n float64_source

$(COMPILER_GLSL_OBJECTS_C): %.o : %.c
	@printf "%b" "\033[0;32mCompiling C source object " $< "\033[m\n"
	@$(CC) -c $(CFLAGS) $(COMPILER_GLSL_INCLUDES) -o $@ $<

$(COMPILER_GLSL_OBJECTS_CXX): %.o : %.cpp
	@printf "%b" "\033[0;32mCompiling C++ source object " $< "\033[m\n"
	@$(CXX) -c $(CXXFLAGS) $(COMPILER_GLSL_INCLUDES) -o $@ $<

#############################################
# NIR-Compiler Library
#############################################
$(MESA_BUILD_PATH)/compiler-nir.lib: $(COMPILER_NIR_SOURCES_GEN_H) $(COMPILER_NIR_SOURCES_GEN_C) $(COMPILER_NIR_SOURCES_GEN_CXX) $(COMPILER_NIR_OBJECTS_C) $(COMPILER_NIR_OBJECTS_CXX)
	@printf "%b" "\033[0;36mCreating static library " $@ "\033[m\n"
	@$(LD) $(LDLIB) $(COMPILER_NIR_OBJECTS_C) $(COMPILER_NIR_OBJECTS_CXX) $(COMPILER_NIR_LIBRARIES) /out:$@

#python_cmd + ' $SCRIPT > $TARGET'
src/compiler/nir/nir_builder_opcodes.h: src/compiler/nir/nir_builder_opcodes_h.py
	python3 $< > $@

#python_cmd + ' $SCRIPT > $TARGET'
src/compiler/nir/nir_opcodes.h: src/compiler/nir/nir_opcodes_h.py 
	python3 $< > $@

#python_cmd + ' $SCRIPT > $TARGET'
src/compiler/nir/nir_intrinsics.h: src/compiler/nir/nir_intrinsics_h.py 
	python3 $< --outdir src/compiler/nir

#python_cmd + ' $SCRIPT > $TARGET'
src/compiler/nir/nir_intrinsics_indices.h: src/compiler/nir/nir_intrinsics_indices_h.py 
	python3 $< --outdir src/compiler/nir

#python_cmd + ' $SCRIPT > $TARGET'
src/compiler/nir/nir_constant_expressions.c: src/compiler/nir/nir_constant_expressions.py
	python3 $< > $@

#python_cmd + ' $SCRIPT > $TARGET'
src/compiler/nir/nir_opcodes.c: src/compiler/nir/nir_opcodes_c.py
	python3 $< > $@

#python_cmd + ' $SCRIPT > $TARGET'
src/compiler/nir/nir_intrinsics.c: src/compiler/nir/nir_intrinsics_c.py
	python3 $< --outdir src/compiler/nir

#python_cmd + ' $SCRIPT > $TARGET'
src/compiler/nir/nir_opt_algebraic.c: src/compiler/nir/nir_opt_algebraic.py
	python3 $< > $@

$(COMPILER_NIR_OBJECTS_C): %.o : %.c
	@printf "%b" "\033[0;32mCompiling C source object " $< "\033[m\n"
	@$(CC) -c $(CFLAGS) $(COMPILER_NIR_INCLUDES) -o $@ $<

$(COMPILER_NIR_OBJECTS_CXX): %.o : %.cpp
	@printf "%b" "\033[0;32mCompiling C++ source object " $< "\033[m\n"
	@$(CXX) -c $(CXXFLAGS) $(COMPILER_NIR_INCLUDES) -o $@ $<

#############################################
# SPIRV-Compiler Library
#############################################
$(MESA_BUILD_PATH)/compiler-spirv.lib: $(COMPILER_SPIRV_SOURCES_GEN_H) $(COMPILER_SPIRV_SOURCES_GEN_C) $(COMPILER_SPIRV_SOURCES_GEN_CXX) $(COMPILER_SPIRV_OBJECTS_C) $(COMPILER_SPIRV_OBJECTS_CXX)
	@printf "%b" "\033[0;36mCreating static library " $@ "\033[m\n"
	@$(LD) $(LDLIB) $(COMPILER_SPIRV_OBJECTS_C) $(COMPILER_SPIRV_OBJECTS_CXX) $(COMPILER_SPIRV_LIBRARIES) /out:$@

#python_cmd + ' $SCRIPT > $TARGET'
src/compiler/spirv/spirv_info.c: src/compiler/spirv/spirv_info_c.py
	python3 $< src/compiler/spirv/spirv.core.grammar.json $@

#python_cmd + ' $SCRIPT > $TARGET'
src/compiler/spirv/vtn_gather_types.c: src/compiler/spirv/vtn_gather_types_c.py
	python3 $< src/compiler/spirv/spirv.core.grammar.json $@

#python_cmd + ' $SCRIPT > $TARGET'
src/compiler/spirv/vtn_generator_ids.h: src/compiler/spirv/vtn_generator_ids_h.py
	python3 $< src/compiler/spirv/spir-v.xml $@

$(COMPILER_SPIRV_OBJECTS_C): %.o : %.c
	@printf "%b" "\033[0;32mCompiling C source object " $< "\033[m\n"
	@$(CC) -c $(CFLAGS) $(COMPILER_SPIRV_INCLUDES) -o $@ $<

$(COMPILER_SPIRV_OBJECTS_CXX): %.o : %.cpp
	@printf "%b" "\033[0;32mCompiling C++ source object " $< "\033[m\n"
	@$(CXX) -c $(CXXFLAGS) $(COMPILER_SPIRV_INCLUDES) -o $@ $<

#############################################
# Loader Library
#############################################
$(MESA_BUILD_PATH)/loader.lib: $(LOADER_SOURCES_GEN_H) $(LOADER_SOURCES_GEN_C) $(LOADER_SOURCES_GEN_CXX) $(LOADER_OBJECTS_C) $(LOADER_OBJECTS_CXX)
	@printf "%b" "\033[0;36mCreating static library " $@ "\033[m\n"
	@$(LD) $(LDLIB) $(LOADER_OBJECTS_C) $(LOADER_OBJECTS_CXX) $(LOADER_LIBRARIES) /out:$@

$(LOADER_OBJECTS_C): %.o : %.c
	@printf "%b" "\033[0;32mCompiling C source object " $< "\033[m\n"
	@$(CC) -c $(CFLAGS) $(LOADER_INCLUDES) -o $@ $<

$(LOADER_OBJECTS_CXX): %.o : %.cpp
	@printf "%b" "\033[0;32mCompiling C++ source object " $< "\033[m\n"
	@$(CXX) -c $(CXXFLAGS) $(LOADER_INCLUDES) -o $@ $<

#############################################
# MAPI Glapi Library
#############################################
$(MESA_BUILD_PATH)/glapi_lib.lib: $(MAPI_GLAPI_SOURCES_GEN_H) $(MAPI_GLAPI_SOURCES_GEN_S) $(MAPI_GLAPI_SOURCES_GEN_C) $(MAPI_GLAPI_SOURCES_GEN_CXX) $(MAPI_GLAPI_OBJECTS_S) $(MAPI_GLAPI_OBJECTS_C) $(MAPI_GLAPI_OBJECTS_CXX)
	@printf "%b" "\033[0;36mCreating static library " $@ "\033[m\n"
	@$(LD) $(LDLIB) $(MAPI_GLAPI_OBJECTS_S) $(MAPI_GLAPI_OBJECTS_C) $(MAPI_GLAPI_OBJECTS_CXX) $(MAPI_GLAPI_LIBRARIES) /out:$@

# Xml dependancies
MAPI_GEN_XML = src/mapi/glapi/gen/gl_and_es_API.xml
MAPI_GEN_XML_DEPENDS = $(filter-out src/mapi/glapi/gen/gl_and_es_API.xml, $(wildcard src/mapi/glapi/gen/*xml))

# python_cmd + ' $SCRIPT -m remap_table -f $SOURCE > $TARGET',
src/mesa/main/dispatch.h: src/mapi/glapi/gen/gl_table.py
	python3 $< -m remap_table -f src/mapi/glapi/gen/gl_and_es_API.xml > $@

# python_cmd + ' $SCRIPT -f $SOURCE > $TARGET'
src/mapi/glapi/glapitable.h: src/mapi/glapi/gen/gl_table.py
	python3 $< -m table -f src/mapi/glapi/gen/gl_and_es_API.xml > $@

# python_cmd + ' $SCRIPT -f $SOURCE > $TARGET'
src/mapi/glapi/glapitemp.h: src/mapi/glapi/gen/gl_apitemp.py
	python3 $< -f src/mapi/glapi/gen/gl_and_es_API.xml > $@

# python_cmd + ' $SCRIPT -c -f $SOURCE > $TARGET'
src/mapi/glapi/glprocs.h: src/mapi/glapi/gen/gl_procs.py
	python3 $< -c -f src/mapi/glapi/gen/gl_and_es_API.xml > $@

# python_cmd + ' $SCRIPT -f $SOURCE > $TARGET'
src/mesa/main/remap_helper.h: src/mapi/glapi/gen/remap_helper.py
	python3 $< -f src/mapi/glapi/gen/gl_and_es_API.xml > $@

# python_cmd + ' $SCRIPT -f $SOURCE > $TARGET'
src/mesa/main/enums.c: src/mapi/glapi/gen/gl_enums.py
	python3 $< -f src/mapi/glapi/gen/gl_and_es_API.xml > $@

# python_cmd + ' $SCRIPT -f $SOURCE > $TARGET'
src/mesa/main/api_exec.c: src/mapi/glapi/gen/gl_genexec.py
	python3 $< -f src/mapi/glapi/gen/gl_and_es_API.xml > $@

# python_cmd + ' $SCRIPT -f $SOURCE > $TARGET'
src/mapi/glapi/glapi_x86.S: src/mapi/glapi/gen/gl_x86_asm.py
	python3 $< -f src/mapi/glapi/gen/gl_and_es_API.xml > $@

# python_cmd + ' $SCRIPT -f $SOURCE > $TARGET'
src/mapi/glapi/glapi_x86-64.S: src/mapi/glapi/gen/gl_x86-64_asm.py
	python3 $< -f src/mapi/glapi/gen/gl_and_es_API.xml > $@

$(MAPI_GLAPI_OBJECTS_S): %.o : %.S
	@printf "%b" "\033[0;32mAssembling source object " $< "\033[m\n"
	@$(CC) -c $(CFLAGS) $(MAPI_GLAPI_INCLUDES) -o $@ $<

$(MAPI_GLAPI_OBJECTS_C): %.o : %.c
	@printf "%b" "\033[0;32mCompiling C source object " $< "\033[m\n"
	@$(CC) -c $(CFLAGS) $(MAPI_GLAPI_INCLUDES) -o $@ $<

$(MAPI_GLAPI_OBJECTS_CXX): %.o : %.cpp
	@printf "%b" "\033[0;32mCompiling C++ source object " $< "\033[m\n"
	@$(CXX) -c $(CXXFLAGS) $(MAPI_GLAPI_INCLUDES) -o $@ $<

#############################################
# Mesa Library
#############################################
$(MESA_BUILD_PATH)/mesa.lib: $(MESA_SOURCES_GEN_H) $(MESA_SOURCES_GEN_C) $(MESA_SOURCES_GEN_CXX) $(MESA_OBJECTS_S) $(MESA_OBJECTS_C) $(MESA_OBJECTS_CXX)
	@printf "%b" "\033[0;36mCreating static library " $@ "\033[m\n"
	@$(LD) $(LDLIB) $(MESA_OBJECTS_S) $(MESA_OBJECTS_C) $(MESA_OBJECTS_CXX) $(MESA_LIBRARIES) /out:$@

# python_cmd + ' $SCRIPT -f $SOURCE > $TARGET'
src/mesa/main/marshal_generated.h: src/mapi/glapi/gen/gl_marshal_h.py
	python3 $< -f src/mapi/glapi/gen/gl_and_es_API.xml > $@

# python_cmd + ' $SCRIPT ' + ' -f $SOURCE > $TARGET'
src/mesa/main/get_hash.h: src/mesa/main/get_hash_generator.py
	python3 $< -f src/mapi/glapi/gen/gl_and_es_API.xml > $@

# python_cmd + ' $SCRIPT ' + ' $SOURCE > $TARGET'
src/mesa/main/format_info.h: src/mesa/main/format_info.py src/mesa/main/formats.csv
	python3 $^ > $@

# python_cmd + ' $SCRIPT -f $SOURCE > $TARGET'
src/mesa/main/marshal_generated0.c: src/mapi/glapi/gen/gl_marshal.py
	python3 $< -f src/mapi/glapi/gen/gl_and_es_API.xml -i 0 -n 8 > $@
src/mesa/main/marshal_generated1.c: src/mapi/glapi/gen/gl_marshal.py
	python3 $< -f src/mapi/glapi/gen/gl_and_es_API.xml -i 1 -n 8 > $@
src/mesa/main/marshal_generated2.c: src/mapi/glapi/gen/gl_marshal.py
	python3 $< -f src/mapi/glapi/gen/gl_and_es_API.xml -i 2 -n 8 > $@
src/mesa/main/marshal_generated3.c: src/mapi/glapi/gen/gl_marshal.py
	python3 $< -f src/mapi/glapi/gen/gl_and_es_API.xml -i 3 -n 8 > $@
src/mesa/main/marshal_generated4.c: src/mapi/glapi/gen/gl_marshal.py
	python3 $< -f src/mapi/glapi/gen/gl_and_es_API.xml -i 4 -n 8 > $@
src/mesa/main/marshal_generated5.c: src/mapi/glapi/gen/gl_marshal.py
	python3 $< -f src/mapi/glapi/gen/gl_and_es_API.xml -i 5 -n 8 > $@
src/mesa/main/marshal_generated6.c: src/mapi/glapi/gen/gl_marshal.py
	python3 $< -f src/mapi/glapi/gen/gl_and_es_API.xml -i 6 -n 8 > $@
src/mesa/main/marshal_generated7.c: src/mapi/glapi/gen/gl_marshal.py
	python3 $< -f src/mapi/glapi/gen/gl_and_es_API.xml -i 7 -n 8 > $@

# python_cmd + ' $SCRIPT ' + ' $SOURCE > $TARGET'
src/mesa/main/format_fallback.c: src/mesa/main/format_fallback.py src/mesa/main/formats.csv
	python3 $^ $@

# python_cmd + ' $SCRIPT ' + ' $SOURCE > $TARGET'
src/mesa/main/format_pack.c: src/mesa/main/format_pack.py src/mesa/main/formats.csv
	python3 $^ > $@

src/mesa/program/lex.yy.c: src/mesa/program/program_lexer.l
	lex -o $@ $<

src/mesa/program/program_parse.tab.c: src/mesa/program/program_parse.y
	yacc -d -p _mesa_program_ -o $@ $<

$(MESA_OBJECTS_S): %.o : %.S
	@printf "%b" "\033[0;32mAssembling source object " $< "\033[m\n"
	@$(CC) -c $(CFLAGS) $(MESA_INCLUDES) -o $@ $<

$(MESA_OBJECTS_C): %.o : %.c
	@printf "%b" "\033[0;32mCompiling C source object " $< "\033[m\n"
	@$(CC) -c $(CFLAGS) $(MESA_INCLUDES) -o $@ $<

$(MESA_OBJECTS_CXX): %.o : %.cpp
	@printf "%b" "\033[0;32mCompiling C++ source object " $< "\033[m\n"
	@$(CXX) -c $(CXXFLAGS) $(MESA_INCLUDES) -o $@ $<


#############################################
# Gallium Auxiliary Library
#############################################
$(MESA_BUILD_PATH)/gallium-aux.lib: $(GAAUX_SOURCES_GEN_H) $(GAAUX_SOURCES_GEN_S) $(GAAUX_SOURCES_GEN_C) $(GAAUX_SOURCES_GEN_CXX) $(GAAUX_OBJECTS_S) $(GAAUX_OBJECTS_C) $(GAAUX_OBJECTS_CXX)
	@printf "%b" "\033[0;36mCreating static library " $@ "\033[m\n"
	@$(LD) $(LDLIB) $(GAAUX_OBJECTS_S) $(GAAUX_OBJECTS_C) $(GAAUX_OBJECTS_CXX) $(GAAUX_LIBRARIES) /out:$@

# python_cmd + ' $SCRIPT > $TARGET'
src/gallium/auxiliary/indices/u_indices_gen.c: src/gallium/auxiliary/indices/u_indices_gen.py
	python3 $< > $@

# python_cmd + ' $SCRIPT > $TARGET'
src/gallium/auxiliary/indices/u_unfilled_gen.c: src/gallium/auxiliary/indices/u_unfilled_gen.py
	python3 $< > $@

$(GAAUX_OBJECTS_S): %.o : %.S
	@printf "%b" "\033[0;32mAssembling source object " $< "\033[m\n"
	@$(CC) -c $(CFLAGS) $(GAAUX_INCLUDES) -o $@ $<

$(GAAUX_OBJECTS_C): %.o : %.c
	@printf "%b" "\033[0;32mCompiling C source object " $< "\033[m\n"
	@$(CC) -c $(CFLAGS) $(GAAUX_INCLUDES) -o $@ $<

$(GAAUX_OBJECTS_CXX): %.o : %.cpp
	@printf "%b" "\033[0;32mCompiling C++ source object " $< "\033[m\n"
	@$(CXX) -c $(CXXFLAGS) $(GAAUX_INCLUDES) -o $@ $<


#############################################
# Gallium Auxiliary Pipe Library
#############################################
$(MESA_BUILD_PATH)/gallium-pipe.lib: $(GAPIPE_SOURCES_GEN_H) $(GAPIPE_SOURCES_GEN_S) $(GAPIPE_SOURCES_GEN_C) $(GAPIPE_SOURCES_GEN_CXX) $(GAPIPE_OBJECTS_S) $(GAPIPE_OBJECTS_C) $(GAPIPE_OBJECTS_CXX)
	@printf "%b" "\033[0;36mCreating static library " $@ "\033[m\n"
	@$(LD) $(LDLIB) $(GAPIPE_OBJECTS_S) $(GAPIPE_OBJECTS_C) $(GAPIPE_OBJECTS_CXX) $(GAPIPE_LIBRARIES) /out:$@

$(GAPIPE_OBJECTS_S): %.o : %.S
	@printf "%b" "\033[0;32mAssembling source object " $< "\033[m\n"
	@$(CC) -c $(CFLAGS) $(GAPIPE_INCLUDES) -o $@ $<

$(GAPIPE_OBJECTS_C): %.o : %.c
	@printf "%b" "\033[0;32mCompiling C source object " $< "\033[m\n"
	@$(CC) -c $(CFLAGS) $(GAPIPE_INCLUDES) -o $@ $<

$(GAPIPE_OBJECTS_CXX): %.o : %.cpp
	@printf "%b" "\033[0;32mCompiling C++ source object " $< "\033[m\n"
	@$(CXX) -c $(CXXFLAGS) $(GAPIPE_INCLUDES) -o $@ $<

#############################################
# Gallium LLVM Pipe Library
#############################################
$(MESA_BUILD_PATH)/gallium-llvmpipe.lib: $(GALLVMPIPE_SOURCES_GEN_H) $(GALLVMPIPE_SOURCES_GEN_S) $(GALLVMPIPE_SOURCES_GEN_C) $(GALLVMPIPE_SOURCES_GEN_CXX) $(GALLVMPIPE_OBJECTS_S) $(GALLVMPIPE_OBJECTS_C) $(GALLVMPIPE_OBJECTS_CXX)
	@printf "%b" "\033[0;36mCreating static library " $@ "\033[m\n"
	@$(LD) $(LDLIB) $(GALLVMPIPE_OBJECTS_S) $(GALLVMPIPE_OBJECTS_C) $(GALLVMPIPE_OBJECTS_CXX) $(GALLVMPIPE_LIBRARIES) /out:$@

$(GALLVMPIPE_OBJECTS_S): %.o : %.S
	@printf "%b" "\033[0;32mAssembling source object " $< "\033[m\n"
	@$(CC) -c $(CFLAGS) $(GALLVMPIPE_INCLUDES) -o $@ $<

$(GALLVMPIPE_OBJECTS_C): %.o : %.c
	@printf "%b" "\033[0;32mCompiling C source object " $< "\033[m\n"
	@$(CC) -c $(CFLAGS) $(GALLVMPIPE_INCLUDES) -o $@ $<

$(GALLVMPIPE_OBJECTS_CXX): %.o : %.cpp
	@printf "%b" "\033[0;32mCompiling C++ source object " $< "\033[m\n"
	@$(CXX) -c $(CXXFLAGS) $(GALLVMPIPE_INCLUDES) -o $@ $<

#############################################
# Gallium Driver (softpipe) Library
#############################################
$(MESA_BUILD_PATH)/gallium-softpipe.lib: $(GASOFTPIPE_SOURCES_GEN_H) $(GASOFTPIPE_SOURCES_GEN_S) $(GASOFTPIPE_SOURCES_GEN_C) $(GASOFTPIPE_SOURCES_GEN_CXX) $(GASOFTPIPE_OBJECTS_S) $(GASOFTPIPE_OBJECTS_C) $(GASOFTPIPE_OBJECTS_CXX)
	@printf "%b" "\033[0;36mCreating static library " $@ "\033[m\n"
	@$(LD) $(LDLIB) $(GASOFTPIPE_OBJECTS_S) $(GASOFTPIPE_OBJECTS_C) $(GASOFTPIPE_OBJECTS_CXX) $(GASOFTPIPE_LIBRARIES) /out:$@

$(GASOFTPIPE_OBJECTS_S): %.o : %.S
	@printf "%b" "\033[0;32mAssembling source object " $< "\033[m\n"
	@$(CC) -c $(CFLAGS) $(GASOFTPIPE_INCLUDES) -o $@ $<

$(GASOFTPIPE_OBJECTS_C): %.o : %.c
	@printf "%b" "\033[0;32mCompiling C source object " $< "\033[m\n"
	@$(CC) -c $(CFLAGS) $(GASOFTPIPE_INCLUDES) -o $@ $<

$(GASOFTPIPE_OBJECTS_CXX): %.o : %.cpp
	@printf "%b" "\033[0;32mCompiling C++ source object " $< "\033[m\n"
	@$(CXX) -c $(CXXFLAGS) $(GASOFTPIPE_INCLUDES) -o $@ $<

#############################################
# Gallium Driver (svga) Library
#############################################
$(MESA_BUILD_PATH)/gallium-svga.lib: $(GASVGA_SOURCES_GEN_H) $(GASVGA_SOURCES_GEN_S) $(GASVGA_SOURCES_GEN_C) $(GASVGA_SOURCES_GEN_CXX) $(GASVGA_OBJECTS_S) $(GASVGA_OBJECTS_C) $(GASVGA_OBJECTS_CXX)
	@printf "%b" "\033[0;36mCreating static library " $@ "\033[m\n"
	@$(LD) $(LDLIB) $(GASVGA_OBJECTS_S) $(GASVGA_OBJECTS_C) $(GASVGA_OBJECTS_CXX) $(GASVGA_LIBRARIES) /out:$@

$(GASVGA_OBJECTS_S): %.o : %.S
	@printf "%b" "\033[0;32mAssembling source object " $< "\033[m\n"
	@$(CC) -c $(CFLAGS) $(GASVGA_INCLUDES) -o $@ $<

$(GASVGA_OBJECTS_C): %.o : %.c
	@printf "%b" "\033[0;32mCompiling C source object " $< "\033[m\n"
	@$(CC) -c $(CFLAGS) $(GASVGA_INCLUDES) -o $@ $<

$(GASVGA_OBJECTS_CXX): %.o : %.cpp
	@printf "%b" "\033[0;32mCompiling C++ source object " $< "\033[m\n"
	@$(CXX) -c $(CXXFLAGS) $(GASVGA_INCLUDES) -o $@ $<

#############################################
# Gallium Winsys (sw/null) Library
#############################################
$(MESA_BUILD_PATH)/gallium-winsys-null.lib: $(GAWINSYS_NULL_SOURCES_GEN_H) $(GAWINSYS_NULL_SOURCES_GEN_S) $(GAWINSYS_NULL_SOURCES_GEN_C) $(GAWINSYS_NULL_SOURCES_GEN_CXX) $(GAWINSYS_NULL_OBJECTS_S) $(GAWINSYS_NULL_OBJECTS_C) $(GAWINSYS_NULL_OBJECTS_CXX)
	@printf "%b" "\033[0;36mCreating static library " $@ "\033[m\n"
	@$(LD) $(LDLIB) $(GAWINSYS_NULL_OBJECTS_S) $(GAWINSYS_NULL_OBJECTS_C) $(GAWINSYS_NULL_OBJECTS_CXX) /out:$@

$(GAWINSYS_NULL_OBJECTS_S): %.o : %.S
	@printf "%b" "\033[0;32mAssembling source object " $< "\033[m\n"
	@$(CC) -c $(CFLAGS) $(GAWINSYS_NULL_INCLUDES) -o $@ $<

$(GAWINSYS_NULL_OBJECTS_C): %.o : %.c
	@printf "%b" "\033[0;32mCompiling C source object " $< "\033[m\n"
	@$(CC) -c $(CFLAGS) $(GAWINSYS_NULL_INCLUDES) -o $@ $<

$(GAWINSYS_NULL_OBJECTS_CXX): %.o : %.cpp
	@printf "%b" "\033[0;32mCompiling C++ source object " $< "\033[m\n"
	@$(CXX) -c $(CXXFLAGS) $(GAWINSYS_NULL_INCLUDES) -o $@ $<

#############################################
# Gallium Winsys (sw/wrapper) Library
#############################################
$(MESA_BUILD_PATH)/gallium-winsys-wrapper.lib: $(GAWINSYS_WRAPPER_SOURCES_GEN_H) $(GAWINSYS_WRAPPER_SOURCES_GEN_S) $(GAWINSYS_WRAPPER_SOURCES_GEN_C) $(GAWINSYS_WRAPPER_SOURCES_GEN_CXX) $(GAWINSYS_WRAPPER_OBJECTS_S) $(GAWINSYS_WRAPPER_OBJECTS_C) $(GAWINSYS_WRAPPER_OBJECTS_CXX)
	@printf "%b" "\033[0;36mCreating static library " $@ "\033[m\n"
	@$(LD) $(LDLIB) $(GAWINSYS_WRAPPER_OBJECTS_S) $(GAWINSYS_WRAPPER_OBJECTS_C) $(GAWINSYS_WRAPPER_OBJECTS_CXX) /out:$@

$(GAWINSYS_WRAPPER_OBJECTS_S): %.o : %.S
	@printf "%b" "\033[0;32mAssembling source object " $< "\033[m\n"
	@$(CC) -c $(CFLAGS) $(GAWINSYS_WRAPPER_INCLUDES) -o $@ $<

$(GAWINSYS_WRAPPER_OBJECTS_C): %.o : %.c
	@printf "%b" "\033[0;32mCompiling C source object " $< "\033[m\n"
	@$(CC) -c $(CFLAGS) $(GAWINSYS_WRAPPER_INCLUDES) -o $@ $<

$(GAWINSYS_WRAPPER_OBJECTS_CXX): %.o : %.cpp
	@printf "%b" "\033[0;32mCompiling C++ source object " $< "\033[m\n"
	@$(CXX) -c $(CXXFLAGS) $(GAWINSYS_WRAPPER_INCLUDES) -o $@ $<

#############################################
# Gallium state-tracker (osmesa) Library
#############################################
$(MESA_BUILD_PATH)/gallium-st-osmesa.lib: $(GAST_OSMESA_SOURCES_GEN_H) $(GAST_OSMESA_SOURCES_GEN_S) $(GAST_OSMESA_SOURCES_GEN_C) $(GAST_OSMESA_SOURCES_GEN_CXX) $(GAST_OSMESA_OBJECTS_S) $(GAST_OSMESA_OBJECTS_C) $(GAST_OSMESA_OBJECTS_CXX)
	@printf "%b" "\033[0;36mCreating static library " $@ "\033[m\n"
	@$(LD) $(LDLIB) $(GAST_OSMESA_OBJECTS_S) $(GAST_OSMESA_OBJECTS_C) $(GAST_OSMESA_OBJECTS_CXX) /out:$@

$(GAST_OSMESA_OBJECTS_S): %.o : %.S
	@printf "%b" "\033[0;32mAssembling source object " $< "\033[m\n"
	@$(CC) -c $(CFLAGS) $(GAST_OSMESA_INCLUDES) -o $@ $<

$(GAST_OSMESA_OBJECTS_C): %.o : %.c
	@printf "%b" "\033[0;32mCompiling C source object " $< "\033[m\n"
	@$(CC) -c $(CFLAGS) $(GAST_OSMESA_INCLUDES) -o $@ $<

$(GAST_OSMESA_OBJECTS_CXX): %.o : %.cpp
	@printf "%b" "\033[0;32mCompiling C++ source object " $< "\033[m\n"
	@$(CXX) -c $(CXXFLAGS) $(GAST_OSMESA_INCLUDES) -o $@ $<

#############################################
# Shared Libraries
#############################################
$(MESA_BUILD_PATH)/glapi.dll: $(GLAPI_DLL_SOURCES_GEN_H) $(GLAPI_DLL_SOURCES_GEN_C) $(GLAPI_DLL_SOURCES_GEN_CXX) $(GLAPI_DLL_OBJECTS_C) $(GLAPI_DLL_OBJECTS_CXX)
	@printf "%b" "\033[0;36mCreating shared library " $@ "\033[m\n"
	@$(LD) $(LDSO) $(GLAPI_DLL_LIBRARIES) $(GLAPI_DLL_OBJECTS_C) $(GLAPI_DLL_OBJECTS_CXX) /out:$@

# python_cmd + ' $SCRIPT ' + '--printer %s $SOURCE > $TARGET' % (printer),
src/mapi/shared-glapi-tmp.h: src/mapi/mapi_abi.py $(MAPI_GEN_XML_DEPENDS)
	@python3 $< --printer shared-glapi $(MAPI_GEN_XML) > $@

src/mapi/gl_entry.c: src/mapi/entry.c
	cp $< $@

src/mapi/gl_mapi_glapi.c: src/mapi/mapi_glapi.c
	cp $< $@

src/mapi/gl_stub.c: src/mapi/stub.c
	cp $< $@

src/mapi/gl_table.c: src/mapi/table.c
	cp $< $@

src/mapi/gl_u_current.c: src/mapi/u_current.c
	cp $< $@

src/mapi/gl_u_execmem.c: src/mapi/u_execmem.c
	cp $< $@

src/mapi/gl_main.cpp: src/mapi/main.cpp
	cp $< $@

$(GLAPI_DLL_OBJECTS_C): %.o : %.c
	@printf "%b" "\033[0;32mCompiling C source object " $< "\033[m\n"
	@$(CC) -c $(CFLAGS) $(GLAPI_DLL_INCLUDES) -o $@ $<

$(GLAPI_DLL_OBJECTS_CXX): %.o : %.cpp
	@printf "%b" "\033[0;32mCompiling C++ source object " $< "\033[m\n"
	@$(CXX) -c $(CXXFLAGS) $(GLAPI_DLL_INCLUDES) -o $@ $<



$(MESA_BUILD_PATH)/GLESv1.dll: $(GLESV1_DLL_SOURCES_GEN_H) $(GLESV1_DLL_SOURCES_GEN_C) $(GLESV1_DLL_SOURCES_GEN_CXX) $(GLESV1_DLL_OBJECTS_C) $(GLESV1_DLL_OBJECTS_CXX)
	@printf "%b" "\033[0;36mCreating shared library " $@ "\033[m\n"
	@$(LD) $(LDSO) $(GLESV1_DLL_LIBRARIES) $(GLESV1_DLL_OBJECTS_C) $(GLESV1_DLL_OBJECTS_CXX) /out:$@

# python_cmd + ' $SCRIPT ' + '--printer %s $SOURCE > $TARGET' % (printer),
src/mapi/es1api-tmp.h: src/mapi/new/gen_gldispatch_mapi.py
	@python3 $< glesv1 $(MAPI_GEN_XML) > $@

src/mapi/gl1_entry.c: src/mapi/entry.c
	cp $< $@

src/mapi/gl1_main.cpp: src/mapi/main.cpp
	cp $< $@

$(GLESV1_DLL_OBJECTS_C): %.o : %.c
	@printf "%b" "\033[0;32mCompiling C source object " $< "\033[m\n"
	@$(CC) -c $(CFLAGS) $(GLESV1_DLL_INCLUDES) -o $@ $<

$(GLESV1_DLL_OBJECTS_CXX): %.o : %.cpp
	@printf "%b" "\033[0;32mCompiling C++ source object " $< "\033[m\n"
	@$(CXX) -c $(CXXFLAGS) $(GLESV1_DLL_INCLUDES) -o $@ $<



$(MESA_BUILD_PATH)/GLESv2.dll: $(GLESV2_DLL_SOURCES_GEN_H) $(GLESV2_DLL_SOURCES_GEN_C) $(GLESV2_DLL_SOURCES_GEN_CXX) $(GLESV2_DLL_OBJECTS_C) $(GLESV2_DLL_OBJECTS_CXX)
	@printf "%b" "\033[0;36mCreating shared library " $@ "\033[m\n"
	@$(LD) $(LDSO) $(GLESV2_DLL_LIBRARIES) $(GLESV2_DLL_OBJECTS_C) $(GLESV2_DLL_OBJECTS_CXX) /out:$@

# python_cmd + ' $SCRIPT ' + '--printer %s $SOURCE > $TARGET' % (printer),
src/mapi/es2api-tmp.h: src/mapi/new/gen_gldispatch_mapi.py
	@python3 $< glesv2 $(MAPI_GEN_XML) > $@

src/mapi/gl2_entry.c: src/mapi/entry.c
	cp $< $@

src/mapi/gl2_main.cpp: src/mapi/main.cpp
	cp $< $@

$(GLESV2_DLL_OBJECTS_C): %.o : %.c
	@printf "%b" "\033[0;32mCompiling C source object " $< "\033[m\n"
	@$(CC) -c $(CFLAGS) $(GLESV2_DLL_INCLUDES) -o $@ $<

$(GLESV2_DLL_OBJECTS_CXX): %.o : %.cpp
	@printf "%b" "\033[0;32mCompiling C++ source object " $< "\033[m\n"
	@$(CXX) -c $(CXXFLAGS) $(GLESV2_DLL_INCLUDES) -o $@ $<


$(MESA_BUILD_PATH)/gallium-graw-null.dll: $(GRAW_NULL_SOURCES_GEN_H) $(GRAW_NULLSOURCES_GEN_C) $(GRAW_NULL_SOURCES_GEN_CXX) $(GRAW_NULL_OBJECTS_C) $(GRAW_NULL_OBJECTS_CXX)
	@printf "%b" "\033[0;36mCreating shared library " $@ "\033[m\n"
	@$(LD) $(LDSO) $(GRAW_NULL_LIBRARIES) $(GRAW_NULL_OBJECTS_C) $(GRAW_NULL_OBJECTS_CXX) /out:$@

$(GRAW_NULL_OBJECTS_C): %.o : %.c
	@printf "%b" "\033[0;32mCompiling C source object " $< "\033[m\n"
	@$(CC) -c $(CFLAGS) $(GRAW_NULL_INCLUDES) -o $@ $<

$(GRAW_NULL_OBJECTS_CXX): %.o : %.cpp
	@printf "%b" "\033[0;32mCompiling C++ source object " $< "\033[m\n"
	@$(CXX) -c $(CXXFLAGS) $(GRAW_NULL_INCLUDES) -o $@ $<

$(MESA_BUILD_PATH)/gallium-osmesa.dll: $(GA_OSMESA_SOURCES_GEN_H) $(GA_OSMESA_SOURCES_GEN_C) $(GA_OSMESA_SOURCES_GEN_CXX) $(GA_OSMESA_OBJECTS_C) $(GA_OSMESA_OBJECTS_CXX)
	@printf "%b" "\033[0;36mCreating shared library " $@ "\033[m\n"
	@$(LD) $(LDSO) $(GA_OSMESA_LIBRARIES) $(GA_OSMESA_OBJECTS_C) $(GA_OSMESA_OBJECTS_CXX) /out:$@

$(GA_OSMESA_OBJECTS_C): %.o : %.c
	@printf "%b" "\033[0;32mCompiling C source object " $< "\033[m\n"
	@$(CC) -c $(CFLAGS) $(GA_OSMESA_INCLUDES) -o $@ $<

$(GA_OSMESA_OBJECTS_CXX): %.o : %.cpp
	@printf "%b" "\033[0;32mCompiling C++ source object " $< "\033[m\n"
	@$(CXX) -c $(CXXFLAGS) $(GA_OSMESA_INCLUDES) -o $@ $<

#############################################
# Applications
#############################################
$(MESA_BUILD_PATH)/spirv2nir: src/compiler/spirv/spirv2nir.c
	@gcc -DHAVE_PTHREAD -DHAVE_TIMESPEC_GET -Isrc -Isrc/mesa -Iinclude -Isrc/mapi -Isrc/compiler/spirv -Isrc/compiler/nir -o $@ $<



$(MESA_BUILD_PATH)/compiler-glsl.app: $(COMPILER_GLSL_APP_SOURCES_GEN_H) $(COMPILER_GLSL_APP_SOURCES_GEN_C) $(COMPILER_GLSL_APP_SOURCES_GEN_CXX) $(COMPILER_GLSL_APP_OBJECTS_C) $(COMPILER_GLSL_APP_OBJECTS_CXX)
	@printf "%b" "\033[0;36mCreating application " $@ "\033[m\n"
	@$(LD) $(LDAPP) $(COMPILER_GLSL_APP_OBJECTS_C) $(COMPILER_GLSL_APP_OBJECTS_CXX) $(COMPILER_GLSL_APP_LIBRARIES) /out:$@

$(COMPILER_GLSL_APP_OBJECTS_C): %.o : %.c
	@printf "%b" "\033[0;32mCompiling C source object " $< "\033[m\n"
	@$(CC) -c $(CFLAGS) $(COMPILER_GLSL_APP_INCLUDES) -o $@ $<

$(COMPILER_GLSL_APP_OBJECTS_CXX): %.o : %.cpp
	@printf "%b" "\033[0;32mCompiling C++ source object " $< "\033[m\n"
	@$(CXX) -c $(CXXFLAGS) $(COMPILER_GLSL_APP_INCLUDES) -o $@ $<





$(MESA_BUILD_PATH)/glcpp.app: $(GLCPP_APP_SOURCES_GEN_H) $(GLCPP_APP_SOURCES_GEN_C) $(GLCPP_APP_SOURCES_GEN_CXX) $(GLCPP_APP_OBJECTS_C) $(GLCPP_APP_OBJECTS_CXX)
	@printf "%b" "\033[0;36mCreating application " $@ "\033[m\n"
	@$(LD) $(LDAPP) $(GLCPP_APP_OBJECTS_C) $(GLCPP_APP_OBJECTS_CXX) $(GLCPP_APP_LIBRARIES) /out:$@

$(GLCPP_APP_OBJECTS_C): %.o : %.c
	@printf "%b" "\033[0;32mCompiling C source object " $< "\033[m\n"
	@$(CC) -c $(CFLAGS) $(GLCPP_APP_INCLUDES) -o $@ $<

$(GLCPP_APP_OBJECTS_CXX): %.o : %.cpp
	@printf "%b" "\033[0;32mCompiling C++ source object " $< "\033[m\n"
	@$(CXX) -c $(CXXFLAGS) $(GLCPP_APP_INCLUDES) -o $@ $<

.PHONY: clean
clean:
	@rm -rf $(MESA_BUILD_PATH)
	@rm -f $(ZLIB_OBJECTS_C) config/zlib/z.lib
	@rm -f $(UTIL_SOURCES_GEN_H) $(UTIL_SOURCES_GEN_C) $(UTIL_SOURCES_GEN_CXX)
	@rm -f $(UTIL_OBJECTS_C) $(UTIL_OBJECTS_CXX)
	@rm -f $(COMPILER_SOURCES_GEN_H) $(COMPILER_SOURCES_GEN_C) $(COMPILER_SOURCES_GEN_CXX)
	@rm -f $(COMPILER_OBJECTS_C) $(COMPILER_OBJECTS_CXX)
	@rm -f $(COMPILER_GLSL_SOURCES_GEN_H) $(COMPILER_GLSL_SOURCES_GEN_C) $(COMPILER_GLSL_SOURCES_GEN_CXX)
	@rm -f $(COMPILER_GLSL_OBJECTS_C) $(COMPILER_GLSL_OBJECTS_CXX)
	@rm -f $(COMPILER_GLSL_APP_SOURCES_GEN_H) $(COMPILER_GLSL_APP_SOURCES_GEN_C) $(COMPILER_GLSL_APP_SOURCES_GEN_CXX)
	@rm -f $(COMPILER_GLSL_APP_OBJECTS_C) $(COMPILER_GLSL_APP_OBJECTS_CXX)
	@rm -f $(GLCPP_APP_SOURCES_GEN_H) $(GLCPP_APP_SOURCES_GEN_C) $(GLCPP_APP_SOURCES_GEN_CXX)
	@rm -f $(GLCPP_APP_OBJECTS_C) $(GLCPP_APP_OBJECTS_CXX)
	@rm -f $(COMPILER_NIR_SOURCES_GEN_H) $(COMPILER_NIR_SOURCES_GEN_C) $(COMPILER_NIR_SOURCES_GEN_CXX)
	@rm -f $(COMPILER_NIR_OBJECTS_C) $(COMPILER_NIR_OBJECTS_CXX)
	@rm -f $(COMPILER_SPIRV_SOURCES_GEN_H) $(COMPILER_SPIRV_SOURCES_GEN_C) $(COMPILER_SPIRV_SOURCES_GEN_CXX)
	@rm -f $(COMPILER_SPIRV_OBJECTS_C) $(COMPILER_SPIRV_OBJECTS_CXX)
	@rm -f $(LOADER_SOURCES_GEN_H) $(LOADER_SOURCES_GEN_C) $(LOADER_SOURCES_GEN_CXX)
	@rm -f $(LOADER_OBJECTS_C) $(LOADER_OBJECTS_CXX)
	@rm -f $(MAPI_GLAPI_SOURCES_GEN_H) $(MAPI_GLAPI_SOURCES_GEN_S) $(MAPI_GLAPI_SOURCES_GEN_C) $(MAPI_GLAPI_SOURCES_GEN_CXX)
	@rm -f $(MAPI_GLAPI_OBJECTS_S) $(MAPI_GLAPI_OBJECTS_C) $(MAPI_GLAPI_OBJECTS_CXX)
	@rm -f $(MESA_SOURCES_GEN_H) $(MESA_SOURCES_GEN_S) $(MESA_SOURCES_GEN_C) $(MESA_SOURCES_GEN_CXX)
	@rm -f $(MESA_OBJECTS_S) $(MESA_OBJECTS_C) $(MESA_OBJECTS_CXX)
	@rm -f $(OSMESA_DLL_SOURCES_GEN_H) $(OSMESA_DLL_SOURCES_GEN_C) $(OSMESA_DLL_SOURCES_GEN_CXX)
	@rm -f $(OSMESA_DLL_OBJECTS_C) $(OSMESA_DLL_OBJECTS_CXX)
	@rm -f $(GLAPI_DLL_SOURCES_GEN_H) $(GLAPI_DLL_SOURCES_GEN_C) $(GLAPI_DLL_SOURCES_GEN_CXX)
	@rm -f $(GLAPI_DLL_OBJECTS_C) $(GLAPI_DLL_OBJECTS_CXX)
	@rm -f $(GLESV1_DLL_SOURCES_GEN_H) $(GLESV1_DLL_SOURCES_GEN_C) $(GLESV1_DLL_SOURCES_GEN_CXX)
	@rm -f $(GLESV1_DLL_OBJECTS_C) $(GLESV1_DLL_OBJECTS_CXX)
	@rm -f $(GLESV2_DLL_SOURCES_GEN_H) $(GLESV2_DLL_SOURCES_GEN_C) $(GLESV2_DLL_SOURCES_GEN_CXX)
	@rm -f $(GLESV2_DLL_OBJECTS_C) $(GLESV2_DLL_OBJECTS_CXX)
	@rm -f $(GAAUX_SOURCES_GEN_H) $(GAAUX_SOURCES_GEN_S) $(GAAUX_SOURCES_GEN_C) $(GAAUX_SOURCES_GEN_CXX)
	@rm -f $(GAAUX_OBJECTS_S) $(GAAUX_OBJECTS_C) $(GAAUX_OBJECTS_CXX)
	@rm -f $(GAPIPE_SOURCES_GEN_H) $(GAPIPE_SOURCES_GEN_S) $(GAPIPE_SOURCES_GEN_C) $(GAPIPE_SOURCES_GEN_CXX)
	@rm -f $(GAPIPE_OBJECTS_S) $(GAPIPE_OBJECTS_C) $(GAPIPE_OBJECTS_CXX)
	@rm -f $(GALLVMPIPE_SOURCES_GEN_H) $(GALLVMPIPE_SOURCES_GEN_S) $(GALLVMPIPE_SOURCES_GEN_C) $(GALLVMPIPE_SOURCES_GEN_CXX)
	@rm -f $(GALLVMPIPE_OBJECTS_S) $(GALLVMPIPE_OBJECTS_C) $(GALLVMPIPE_OBJECTS_CXX)
	@rm -f $(GASOFTPIPE_SOURCES_GEN_H) $(GASOFTPIPE_SOURCES_GEN_S) $(GASOFTPIPE_SOURCES_GEN_C) $(GASOFTPIPE_SOURCES_GEN_CXX)
	@rm -f $(GASOFTPIPE_OBJECTS_S) $(GASOFTPIPE_OBJECTS_C) $(GASOFTPIPE_OBJECTS_CXX)
	@rm -f $(GASVGA_SOURCES_GEN_H) $(GASVGA_SOURCES_GEN_S) $(GASVGA_SOURCES_GEN_C) $(GASVGA_SOURCES_GEN_CXX)
	@rm -f $(GASVGA_OBJECTS_S) $(GASVGA_OBJECTS_C) $(GASVGA_OBJECTS_CXX)
	@rm -f $(GAWINSYS_NULL_SOURCES_GEN_H) $(GAWINSYS_NULL_SOURCES_GEN_S) $(GAWINSYS_NULL_SOURCES_GEN_C) $(GAWINSYS_NULL_SOURCES_GEN_CXX)
	@rm -f $(GAWINSYS_NULL_OBJECTS_S) $(GAWINSYS_NULL_OBJECTS_C) $(GAWINSYS_NULL_OBJECTS_CXX)
	@rm -f $(GAWINSYS_WRAPPER_SOURCES_GEN_H) $(GAWINSYS_WRAPPER_SOURCES_GEN_S) $(GAWINSYS_WRAPPER_SOURCES_GEN_C) $(GAWINSYS_WRAPPER_SOURCES_GEN_CXX)
	@rm -f $(GAWINSYS_WRAPPER_OBJECTS_S) $(GAWINSYS_WRAPPER_OBJECTS_C) $(GAWINSYS_WRAPPER_OBJECTS_CXX)
	@rm -f $(GRAW_NULL_SOURCES_GEN_H) $(GRAW_NULL_SOURCES_GEN_S) $(GRAW_NULL_SOURCES_GEN_C) $(GRAW_NULL_SOURCES_GEN_CXX)
	@rm -f $(GRAW_NULL_OBJECTS_S) $(GRAW_NULL_OBJECTS_C) $(GRAW_NULL_OBJECTS_CXX)
	@rm -f $(GAST_OSMESA_SOURCES_GEN_H) $(GAST_OSMESA_SOURCES_GEN_S) $(GAST_OSMESA_SOURCES_GEN_C) $(GAST_OSMESA_SOURCES_GEN_CXX)
	@rm -f $(GAST_OSMESA_OBJECTS_S) $(GAST_OSMESA_OBJECTS_C) $(GAST_OSMESA_OBJECTS_CXX)
	@rm -f $(GA_OSMESA_SOURCES_GEN_H) $(GA_OSMESA_SOURCES_GEN_S) $(GA_OSMESA_SOURCES_GEN_C) $(GA_OSMESA_SOURCES_GEN_CXX)
	@rm -f $(GA_OSMESA_OBJECTS_S) $(GA_OSMESA_OBJECTS_C) $(GA_OSMESA_OBJECTS_CXX)

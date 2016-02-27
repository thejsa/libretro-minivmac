TARGET_NAME := cap32

DEBUG   = 0
LOG_PERFORMANCE = 1
HAVE_COMPAT = 0

SOURCES_C   :=
SOURCES_CXX :=
LIBS    :=

ifneq ($(EMSCRIPTEN),)
	platform = emscripten
endif

ifeq ($(platform),)
	platform = unix
	ifeq ($(shell uname -a),)
		platform = win
	else ifneq ($(findstring MINGW,$(shell uname -a)),)
		platform = win
	else ifneq ($(findstring Darwin,$(shell uname -a)),)
		platform = osx
	else ifneq ($(findstring win,$(shell uname -a)),)
		platform = win
	endif
endif

# system platform
system_platform = unix
ifeq ($(shell uname -a),)
	EXE_EXT = .exe
	system_platform = win
else ifneq ($(findstring Darwin,$(shell uname -a)),)
	system_platform = osx
else ifneq ($(findstring MINGW,$(shell uname -a)),)
	system_platform = win
endif

CC_AS ?= $(CC)

# Unix
ifneq (,$(findstring unix,$(platform)))
	TARGET := $(TARGET_NAME)_libretro.so
	fpic := -fPIC
	SHARED := -shared -Wl,-version-script=link.T -Wl,-no-undefined

# Raspberry Pi
else ifneq (,$(findstring rpi,$(platform)))
	TARGET := $(TARGET_NAME)_libretro.so
	LDFLAGS += -shared -Wl,--version-script=libretro/link.T
	fpic = -fPIC
	SHARED := -shared -Wl,-version-script=link.T -Wl,-no-undefined

# OS X
else ifeq ($(platform), osx)
	TARGET := $(TARGET_NAME)_libretro.dylib
	fpic := -fPIC
	SHARED := -dynamiclib
	OSXVER = `sw_vers -productVersion | cut -d. -f 2`
	OSX_LT_MAVERICKS = `(( $(OSXVER) <= 9)) && echo "YES"`
	ifeq ($(OSX_LT_MAVERICKS),"YES")
		fpic += -mmacosx-version-min=10.5
	endif

# iOS
else ifneq (,$(findstring ios,$(platform)))
	TARGET := $(TARGET_NAME)_libretro_ios.dylib
	fpic := -fPIC
	SHARED := -dynamiclib

	ifeq ($(IOSSDK),)
		IOSSDK := $(shell xcrun -sdk iphoneos -show-sdk-path)
	endif

	CC = cc -arch armv7 -isysroot $(IOSSDK)
	CC_AS = perl ./tools/gas-preprocessor.pl $(CC)
	CXX = c++ -arch armv7 -isysroot $(IOSSDK)
ifeq ($(platform),ios9)
	CC += -miphoneos-version-min=8.0
	CXX += -miphoneos-version-min=8.0
	CC_AS += -miphoneos-version-min=8.0
	PLATFORM_DEFINES := -miphoneos-version-min=8.0
else
	CC += -miphoneos-version-min=5.0
	CXX += -miphoneos-version-min=5.0
	CC_AS += -miphoneos-version-min=5.0
	PLATFORM_DEFINES := -miphoneos-version-min=5.0
endif

# Theos
else ifeq ($(platform), theos_ios)
	DEPLOYMENT_IOSVERSION = 5.0
	TARGET = iphone:latest:$(DEPLOYMENT_IOSVERSION)
	ARCHS = armv7 armv7s
	TARGET_IPHONEOS_DEPLOYMENT_VERSION=$(DEPLOYMENT_IOSVERSION)
	THEOS_BUILD_DIR := objs
	include $(THEOS)/makefiles/common.mk

	LIBRARY_NAME = $(TARGET_NAME)_libretro_ios

# QNX
else ifeq ($(platform), qnx)
	TARGET := $(TARGET_NAME)_libretro_qnx.so
	fpic := -fPIC
	SHARED := -lcpp -lm -shared -Wl,-version-script=link.T
	CC = qcc -Vgcc_ntoarmv7le
	CC_AS = qcc -Vgcc_ntoarmv7le
	CXX = QCC -Vgcc_ntoarmv7le_cpp
	AR = QCC -Vgcc_ntoarmv7le
	PLATFORM_DEFINES := -D__BLACKBERRY_QNX__ -fexceptions -marm -mcpu=cortex-a9 -mfpu=neon -mfloat-abi=softfp

# PS3
else ifeq ($(platform), ps3)
	TARGET := $(TARGET_NAME)_libretro_ps3.a
	CC = $(CELL_SDK)/host-win32/ppu/bin/ppu-lv2-gcc.exe
	CC_AS = $(CELL_SDK)/host-win32/ppu/bin/ppu-lv2-gcc.exe
	CXX = $(CELL_SDK)/host-win32/ppu/bin/ppu-lv2-g++.exe
	AR = $(CELL_SDK)/host-win32/ppu/bin/ppu-lv2-ar.exe
	PLATFORM_DEFINES := -D__CELLOS_LV2__
	STATIC_LINKING = 1
	HAVE_COMPAT = 1

# sncps3
else ifeq ($(platform), sncps3)
	TARGET := $(TARGET_NAME)_libretro_ps3.a
	CC = $(CELL_SDK)/host-win32/sn/bin/ps3ppusnc.exe
	CC_AS = $(CELL_SDK)/host-win32/sn/bin/ps3ppusnc.exe
	CXX = $(CELL_SDK)/host-win32/sn/bin/ps3ppusnc.exe
	AR = $(CELL_SDK)/host-win32/sn/bin/ps3snarl.exe
	PLATFORM_DEFINES := -D__CELLOS_LV2__
	STATIC_LINKING = 1
	HAVE_COMPAT = 1

# Lightweight PS3 Homebrew SDK
else ifeq ($(platform), psl1ght)
	TARGET := $(TARGET_NAME)_libretro_psl1ght.a
	CC = $(PS3DEV)/ppu/bin/ppu-gcc$(EXE_EXT)
	CC_AS = $(PS3DEV)/ppu/bin/ppu-gcc$(EXE_EXT)
	CXX = $(PS3DEV)/ppu/bin/ppu-g++$(EXE_EXT)
	AR = $(PS3DEV)/ppu/bin/ppu-ar$(EXE_EXT)
	PLATFORM_DEFINES := -D__CELLOS_LV2__
	STATIC_LINKING = 1
	HAVE_COMPAT = 1

# PSP
else ifeq ($(platform), psp1)
	TARGET := $(TARGET_NAME)_libretro_psp1.a
	CC = psp-gcc$(EXE_EXT)
	CC_AS = psp-gcc$(EXE_EXT)
	CXX = psp-g++$(EXE_EXT)
	AR = psp-ar$(EXE_EXT)
	PLATFORM_DEFINES := -DPSP
	CFLAGS += -G0
	CXXFLAGS += -G0
	STATIC_LINKING = 1
	HAVE_COMPAT = 1
	EXTRA_INCLUDES := -I$(shell psp-config --pspsdk-path)/include

# CTR (3DS)
else ifeq ($(platform), ctr)
	TARGET := $(TARGET_NAME)_libretro_ctr.a
	CC = $(DEVKITARM)/bin/arm-none-eabi-gcc$(EXE_EXT)
	CXX = $(DEVKITARM)/bin/arm-none-eabi-g++$(EXE_EXT)
	AR = $(DEVKITARM)/bin/arm-none-eabi-ar$(EXE_EXT)
	PLATFORM_DEFINES := -DARM11 -D_3DS -DNO_UNALIGNED_ACCESS
	PLATFORM_DEFINES += -march=armv6k -mtune=mpcore -mfloat-abi=hard
	PLATFORM_DEFINES += -Wall -mword-relocations
	PLATFORM_DEFINES += -fomit-frame-pointer -ffast-math
	CFLAGS += -fno-rtti -fno-exceptions
	CXXFLAGS += -fno-rtti -fno-exceptions
	STATIC_LINKING = 1


# Xbox 360
else ifeq ($(platform), xenon)
	TARGET := $(TARGET_NAME)_libretro_xenon360.a
	CC = xenon-gcc$(EXE_EXT)
	CC_AS = xenon-gcc$(EXE_EXT)
	CXX = xenon-g++$(EXE_EXT)
	AR = xenon-ar$(EXE_EXT)
	PLATFORM_DEFINES := -D__LIBXENON__
	STATIC_LINKING = 1

# Nintendo Game Cube
else ifeq ($(platform), ngc)
	TARGET := $(TARGET_NAME)_libretro_ngc.a
	CC = $(DEVKITPPC)/bin/powerpc-eabi-gcc$(EXE_EXT)
	CC_AS = $(DEVKITPPC)/bin/powerpc-eabi-gcc$(EXE_EXT)
	CXX = $(DEVKITPPC)/bin/powerpc-eabi-g++$(EXE_EXT)
	AR = $(DEVKITPPC)/bin/powerpc-eabi-ar$(EXE_EXT)
	PLATFORM_DEFINES += -DGEKKO -DHW_DOL -mrvl -mcpu=750 -meabi -mhard-float
	STATIC_LINKING = 1
	HAVE_COMPAT = 1

# Nintendo Wii
else ifeq ($(platform), wii)
	TARGET := $(TARGET_NAME)_libretro_wii.a
	CC = $(DEVKITPPC)/bin/powerpc-eabi-gcc$(EXE_EXT)
	CC_AS = $(DEVKITPPC)/bin/powerpc-eabi-gcc$(EXE_EXT)
	CXX = $(DEVKITPPC)/bin/powerpc-eabi-g++$(EXE_EXT)
	AR = $(DEVKITPPC)/bin/powerpc-eabi-ar$(EXE_EXT)
	PLATFORM_DEFINES += -DGEKKO -DHW_RVL -mrvl -mcpu=750 -meabi -mhard-float
	STATIC_LINKING = 1
	HAVE_COMPAT = 1

# ARM
else ifneq (,$(findstring armv,$(platform)))
	TARGET := $(TARGET_NAME)_libretro.so
	fpic := -fPIC
	SHARED := -shared -Wl,-version-script=link.T
	CC = gcc
	CC_AS = gcc
	CXX = g++
	ifneq (,$(findstring cortexa8,$(platform)))
		PLATFORM_DEFINES += -marm -mcpu=cortex-a8
	else ifneq (,$(findstring cortexa9,$(platform)))
		PLATFORM_DEFINES += -marm -mcpu=cortex-a9
	endif
	PLATFORM_DEFINES += -marm
	ifneq (,$(findstring neon,$(platform)))
		PLATFORM_DEFINES += -mfpu=neon
		HAVE_NEON = 1
	endif
	ifneq (,$(findstring softfloat,$(platform)))
		PLATFORM_DEFINES += -mfloat-abi=softfp
	else ifneq (,$(findstring hardfloat,$(platform)))
		PLATFORM_DEFINES += -mfloat-abi=hard
	endif
	PLATFORM_DEFINES += -DARM

# emscripten
else ifeq ($(platform), emscripten)
	TARGET := $(TARGET_NAME)_libretro_emscripten.bc

# Windows
else
	TARGET := $(TARGET_NAME)_libretro.dll
	CC = gcc
	CC_AS = gcc
	CXX = g++
	SHARED := -shared -static-libgcc -static-libstdc++ -Wl,-no-undefined -Wl,-version-script=link.T
	LIBS += -lshlwapi
	HAVE_WIN32_MSX_MANAGER = 1

endif

CORE_DIR  := .
CAP32_DIR := $(CORE_DIR)/cap32

ifeq ($(HAVE_COMPAT), 1)
	PLATFORM_DEFINES += -DHAVE_COMPAT
endif

ifeq ($(DEBUG), 1)
	CFLAGS += -O0 -g
	CXXFLAGS += -O0 -g
else ifeq ($(platform), emscripten)
	CFLAGS += -O2
	CXXFLAGS += -O2 -fno-exceptions -fno-rtti -DHAVE_STDINT_H
else
	CFLAGS += -O3
	CXXFLAGS += -O3 -fno-exceptions -fno-rtti -DHAVE_STDINT_H
endif

ifeq ($(LOG_PERFORMANCE), 1)
	CFLAGS += -DLOG_PERFORMANCE
	CXXFLAGS += -DLOG_PERFORMANCE
endif


DEFINES := -D__LIBRETRO__ $(PLATFORM_DEFINES)
DEFINES += -DHAVE_CONFIG_H

CFLAGS   += $(fpic) $(DEFINES)
CFLAGS   += -Wall

CXXFLAGS += $(fpic) $(DEFINES)
CXXFLAGS += -Wall

LDFLAGS += -lm -lz

ROMS =
SNAPS =

include Makefile.common

HEADERS += $(ROMS:.rom=.h) $(SNAPS:.szx=.h)
OBJS += $(SOURCES_C:.c=.o) $(SOURCES_CXX:.cpp=.o)

INCDIRS := $(EXTRA_INCLUDES) $(INCFLAGS)

%.o: %.cpp
	$(CXX) -c -o $@ $< $(CXXFLAGS) $(INCDIRS)

%.o: %.c
	$(CC) -c -o $@ $< $(CFLAGS) $(INCDIRS)

%.o: %.S
	$(CC_AS) -c -o $@ $< $(CFLAGS) $(INCDIRS)

%.h: %.rom
	xxd -i $< | sed "s/unsigned/const unsigned/g" > $@

%.h: %.szx
	xxd -i $< | sed "s/unsigned/const unsigned/g" > $@

ifeq ($(platform), theos_ios)
COMMON_FLAGS := -DIOS $(COMMON_DEFINES) $(INCFLAGS) -I$(THEOS_INCLUDE_PATH) -Wno-error
$(LIBRARY_NAME)_CFLAGS += $(CFLAGS) $(COMMON_FLAGS)
$(LIBRARY_NAME)_CXXFLAGS += $(CXXFLAGS) $(COMMON_FLAGS)
${LIBRARY_NAME}_FILES = $(SOURCES_CXX) $(SOURCES_C)
${LIBRARY_NAME}_LIBRARIES = z
include $(THEOS_MAKE_PATH)/library.mk
else
all: $(TARGET)

$(TARGET): $(HEADERS) $(OBJS)
ifeq ($(STATIC_LINKING), 1)
	$(AR) rcs $@ $(OBJS)
else
	$(CXX) -o $@ $(SHARED) $(OBJS) $(LDFLAGS) $(LIBS)
endif

fuse/config.h:
	cp src/config_fuse.h fuse/config.h

libspectrum/config.h:
	cp src/config_libspectrum.h libspectrum/config.h

clean-objs:
	rm -f $(OBJS)

clean:
	rm -f $(OBJS)
	rm -f $(HEADERS)
	rm -f $(TARGET)

.PHONY: $(TARGET) clean clean-objs
endif

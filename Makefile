# BUILD SETTINGS ###################################
DEBUG := 0
# Valid values: UNIX, GP2X, GCW_ZERO
PLATFORM := GCW_ZERO

# If building for the GP2X
GP2X_CHAINPREFIX := /opt/open2x/gcc-4.1.1-glibc-2.3.6
GP2X_CHAIN := $(GP2X_CHAINPREFIX)/bin/arm-open2x-linux-

# If building for the GCW Zero
GCW_ZERO_CHAINPREFIX := /opt/gcw0-toolchain
GCW_ZERO_CHAIN := $(GCW_ZERO_CHAINPREFIX)/usr/bin/mipsel-linux-

# END SETTINGS #####################################

TARGET := o2xiv
OBJS := files.o font.o image.o input.o main.o menu.o prefs.o scale.o thread.o

ifeq ($(DEBUG), 1)
	DEBUG_FLAGS := -g3 -O0
else
	DEBUG_FLAGS := -O3 -DNDEBUG
endif

ifeq ($(PLATFORM), GP2X)
	SDL_CFLAGS := `$(GP2X_CHAINPREFIX)/bin/sdl-config --cflags` -I$(GP2X_CHAINPREFIX)/include
	SDL_LDFLAGS := `$(GP2X_CHAINPREFIX)/bin/sdl-config --libs` -L$(GP2X_CHAINPREFIX)/lib
	CC := $(GP2X_CHAIN)gcc
	STRIP := $(GP2X_CHAIN)strip
	TARGET := $(TARGET).gpu
	OPT_CFLAGS := -DTARGET_GP2X -mcpu=arm920t -mtune=arm920t -ffast-math
endif
ifeq ($(PLATFORM), GCW_ZERO)
	CC := $(GCW_ZERO_CHAIN)gcc
	SYSROOT := $(shell $(CC) --print-sysroot)
	SDL_CFLAGS := $(shell $(SYSROOT)/usr/bin/sdl-config --cflags)
	SDL_LDFLAGS := $(shell $(SYSROOT)/usr/bin/sdl-config --libs)
	STRIP := $(GCW_ZERO_CHAIN)strip
	OPT_CFLAGS := -DTARGET_GCW_ZERO
endif
ifeq ($(PLATFORM), UNIX)
	SDL_CFLAGS := $(shell sdl-config --cflags)
	SDL_LDFLAGS := $(shell sdl-config --libs)
	OPT_CFLAGS := -DTARGET_UNIX
endif

CFLAGS := --std=c99 -pedantic -Wall -Wextra -Werror -I$(CURDIR)/src/ $(DEBUG_FLAGS) $(SDL_CFLAGS) $(OPT_CFLAGS)
LDFLAGS := $(SDL_LDFLAGS) -lSDL_image -ljpeg

####################################################

all : $(TARGET)

OBJS := $(foreach obj, $(OBJS), obj/$(obj))

$(TARGET) : $(OBJS)
	$(CC) -o $@ $^ $(LDFLAGS)

ifneq ($(MAKECMDGOALS), clean)
-include $(OBJS:.o=.d)
endif

obj/%.d : obj/%.o
obj/%.o : src/%.c
	$(CC) -o $@ -MMD -c $(CFLAGS) $<

opk: $(TARGET)
	rm -rf .opk_data
	mkdir .opk_data
	cp o2xiv.png default.gcw0.desktop .opk_data
	cp $< .opk_data
	$(STRIP) .opk_data/$<
	mksquashfs .opk_data o2xiv.opk -all-root -noappend -no-exports -no-xattrs -no-progress >/dev/null

.PHONY : clean

clean :
	rm -f obj/*.o obj/*.d
	rm -f $(TARGET)

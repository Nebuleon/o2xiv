# BUILD SETTINGS ###################################

DEBUG ?= 0
# Valid values: UNIX, GP2X, GCW_ZERO
PLATFORM ?= GCW_ZERO
CROSS_COMPILE ?= mipsel-linux-

# END SETTINGS #####################################

TARGET := o2xiv
OBJS := files.o font.o image.o input.o main.o menu.o prefs.o scale.o thread.o


CC := $(CROSS_COMPILE)gcc
STRIP := $(CROSS_COMPILE)strip
SYSROOT := $(shell $(CC) --print-sysroot)

CFLAGS := $(shell $(SYSROOT)/usr/bin/sdl-config --cflags) \
	-DTARGET_$(PLATFORM) --std=c99 -pedantic -Wall -Wextra -Werror -Isrc/
LDFLAGS := $(shell $(SYSROOT)/usr/bin/sdl-config --libs) \
	-lSDL_image -ljpeg

ifeq ($(DEBUG), 1)
	CFLAGS += -g3 -O0
else
	CFLAGS += -O3 -DNDEBUG
endif

ifeq ($(PLATFORM), GP2X)
	CFLAGS += -mcpu=arm920t -mtune=arm920t -ffast-math
endif
ifeq ($(PLATFORM), UNIX)
	SDL_CFLAGS := $(shell sdl-config --cflags)
	SDL_LDFLAGS := $(shell sdl-config --libs)
	OPT_CFLAGS := -DTARGET_UNIX
endif

CFLAGS := --std=c99 -pedantic -Wall -Wextra -I$(CURDIR)/src/ $(DEBUG_FLAGS) $(SDL_CFLAGS) $(OPT_CFLAGS)
LDFLAGS := $(SDL_LDFLAGS) -lSDL_image -ljpeg

####################################################

all : $(TARGET)

OBJS := $(foreach obj, $(OBJS), obj/$(obj))

$(TARGET) : $(OBJS)
	$(CC) -o $@ $^ $(CFLAGS) $(LDFLAGS)

$(OBJS) : | obj

obj :
	mkdir obj

ifneq ($(MAKECMDGOALS), clean)
-include $(OBJS:.o=.d)
endif

obj/%.d : obj/%.o
obj/%.o : src/%.c
	$(CC) -o $@ -MMD -c $(CFLAGS) $<

opk: $(TARGET)
	rm -rf .opk_data
	mkdir .opk_data
	cp o2xiv.png default.gcw0.desktop manual-en.txt .opk_data
	cp $< .opk_data
	$(STRIP) .opk_data/$<
	mksquashfs .opk_data o2xiv.opk -all-root -noappend -no-exports -no-xattrs -no-progress >/dev/null

.PHONY : clean

clean :
	rm -rf obj
	rm -f $(TARGET)

.PHONY: all
.PHONY: clean

TARGET=keyboard
PRODUCT = $(TARGET).elf

###########################################################

ifeq (,$(CROSS_COMPILE))
$(error missing CROSS_COMPILE for this toolchain)
endif

###########################################################

ifeq ($(DEBUG), 1)
	CFLAGS = -ggdb3 -Og -DDEBUG
else
	CFLAGS = -Os -DNDEBUG
	ifneq ($(PROFILE), 1)
		CFLAGS += -fdata-sections -ffunction-sections -Wl,--gc-sections -s
	endif
endif

CC = $(CROSS_COMPILE)gcc
LIBS = -lSDL -lSDL_image -lSDL_ttf

CFLAGS += -Wall -marm -march=armv7ve+simd -mtune=cortex-a7 -mfpu=neon-vfpv4 -mfloat-abi=hard
CFLAGS += -flto -fipa-pta -fipa-ra -ftree-vectorize -ffast-math -funsafe-math-optimizations
CFLAGS += -fno-math-errno -fno-unwind-tables -fno-asynchronous-unwind-tables -std=gnu99
CFLAGS += $(LIBS)

all:
	$(CC) $(TARGET).c -o $(PRODUCT) $(CFLAGS)

clean:
	rm -f $(PRODUCT)

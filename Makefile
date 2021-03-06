.PHONY: all clean rom

.SUFFIXES:
.SUFFIXES: .asm .o .gbc .png .wav
.SECONDEXPANSION:

#These tell Make where our files are.
SRC_DIR := src
LIB_DIR := lib/system lib/lcd_control lib/text_services lib/cart/mbc5
BUILD_DIR := build
TOOLS_DIR := tools

BUILDROM := ${BUILD_DIR}/rom.gbc

#This configuration is suitable for a single version project.
OBJS_LIB := ${foreach dir,${LIB_DIR},$(patsubst %.asm,%.o,$(shell find ${dir} -type f -name "*.asm"))}
OBJS_SRC := ${foreach dir,${SRC_DIR},$(patsubst %.asm,%.o,$(shell find ${dir} -type f -name "*.asm"))}
OBJS := ${OBJS_LIB} ${OBJS_SRC}
OBJS_RGBASM := ${OBJS}

PYTHON3 := $(shell tools/interpreters/python3.sh)
PYTHON2 := $(shell tools/interpreters/python2.sh)
PYTHONANY := $(shell tools/interpreters/pythonany.sh)

# Link objects together to build a rom.
all: rom

rom: $(BUILDROM)

#Link and fix a ROM
$(BUILDROM): $(OBJS:%.o=${BUILD_DIR}/%.o)
	rgblink -n $(@:.gbc=.sym) -m $(@:.gbc=.map) -o $@ $^
	rgbfix -vc -m 27 -r 2 $@

# Remove files generated by the build process.
clean:
	rm -r build

#Assemble source files into objects.
#Use rgbasm -h to use halts without nops.
$(OBJS_RGBASM:%.o=${BUILD_DIR}/%.o): $(BUILD_DIR)/%.o : %.asm $$($$*_dep)
	@echo "Assembling" $<
	@mkdir -p $(dir $@)
	@rgbasm -h -o $@ $<

#This rule is needed if we want make to not die. It expects to see .inc files in
#the build directory now that we moved all resources there. We DO want to see
#.inc files as dependencies but I can't be arsed to fiddle with any more arcane
#makefile bullshit to get it to not prefix .inc files.
$(BUILD_DIR)/%.inc: %.inc
	@mkdir -p $(dir $@)
	@cp $< $@

#These rules cover resources. You may add more below, if you want.
#To include a resource, INCBIN it's build path (e.g. build/src/someimage.2bpp)
$(BUILD_DIR)/%.color.2bpp $(BUILD_DIR)/%.color.gbcpal: %.color.png
	@echo "Building" $<
	@rm -f $@
	@mkdir -p $(dir $(BUILD_DIR)/$*.color.2bpp)
	@mkdir -p $(dir $(BUILD_DIR)/$*.gbcpal)
	@rgbgfx -d 2 -p $(BUILD_DIR)/$*.color.gbcpal -o $(BUILD_DIR)/$*.color.2bpp $<

$(filter-out $(BUILD_DIR)/%.color.2bpp,$(BUILD_DIR)/%.2bpp): %.png
	@echo "Building" $<
	@$(TOOLS_DIR)/images/prohibit_indexed_png.sh $<
	@rm -f $@
	@mkdir -p $(dir $@)
	@rgbgfx -d 2 -o $@ $<

$(BUILD_DIR)/%.1bpp: %.png
	@echo "Building" $<
	@$(TOOLS_DIR)/images/prohibit_indexed_png.sh $<
	@rm -f $@
	@mkdir -p $(dir $@)
	@rgbgfx -d 1 -o $@ $<

#This final bit automatically scans for all includes and adds them as build
#dependencies to the objects.
DEPENDENCY_SCAN_EXIT_STATUS := $(shell $(PYTHONANY) $(TOOLS_DIR)/scan_rgbasm_includes.py $(OBJS_RGBASM:.o=.asm) > ${BUILD_DIR}/dependencies.d; echo $$?)
ifneq ($(DEPENDENCY_SCAN_EXIT_STATUS), 0)
$(error Dependency scan failed)
endif
include ${BUILD_DIR}/dependencies.d
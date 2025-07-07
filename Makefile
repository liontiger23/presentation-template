############################
# Usage
# make         # converts all src/*.md files to publish/*.pptx files using pandoc
# make clean   # cleans up publish/*.pptx artifacts
############################

all:

############################
# Common
############################

PANDOC = pandoc

PUBLISH_DIR = publish
SRC_DIR = src
IMAGES_DIR = images
TIKZ_DIR = tikz
DOT_DIR = dot
COMMON_DIR = common
BUILD_DIR = build

############################
# Targets
############################

SRC  = $(wildcard $(SRC_DIR)/*.md)
PPTX = $(SRC:.md=.pptx)

PPTX_PUBLISH = $(PPTX:$(SRC_DIR)/%=$(PUBLISH_DIR)/%)
PPTX_NAMES = $(PPTX:$(SRC_DIR)/%.pptx=%)

PNG_ROOT = $(wildcard $(IMAGES_DIR)/*.png)
PNG_TARGET = $(foreach NAME,$(PPTX_NAMES),$(wildcard $(IMAGES_DIR)/$(NAME)/*.png))
PNG = $(PNG_ROOT) $(PNG_TARGET)

SVG_ROOT = $(wildcard $(IMAGES_DIR)/*.svg)
SVG_TARGET = $(foreach NAME,$(PPTX_NAMES),$(wildcard $(IMAGES_DIR)/$(NAME)/*.svg))
SVG = $(SVG_ROOT) $(SVG_TARGET)

DOT_ROOT = $(wildcard $(DOT_DIR)/*.gv)
DOT_TARGET = $(foreach NAME,$(PPTX_NAMES),$(wildcard $(DOT_DIR)/$(NAME)/*.gv))
DOT_SVG_ROOT = $(DOT_ROOT:.gv=.svg)
DOT_SVG_TARGET = $(DOT_TARGET:.gv=.svg)
DOT_SVG = $(DOT_SVG_ROOT) $(DOT_SVG_TARGET)

TIKZ_ROOT = $(wildcard $(TIKZ_DIR)/*.tikz)
TIKZ_TARGET = $(foreach NAME,$(PPTX_NAMES),$(wildcard $(TIKZ_DIR)/$(NAME)/*.tikz))
TIKZ_SVG_ROOT = $(TIKZ_ROOT:.tikz=.svg)
TIKZ_SVG_TARGET = $(TIKZ_TARGET:.tikz=.svg)
TIKZ_SVG = $(TIKZ_SVG_ROOT) $(TIKZ_SVG_TARGET)

############################
# Goals
############################

.PHONY: all clean pptx
.DEFAULT_GOAL := all

all: pptx

publish: $(PPTX_PUBLISH)
pptx:  $(PPTX)

clean: 
	@echo "Cleaning up..."
	rm -rvf $(DOT_SVG) $(PPTX) $(TIKZ_SVG) $(BUILD_DIR)

############################
# Publish patterns
############################

$(PPTX_PUBLISH): $(PUBLISH_DIR)/%.pptx: $(SRC_DIR)/%.pptx
	@mkdir -p $(@D)
	cp $< $@

############################
# Pandoc patterns
############################

PANDOC_ARGS :=

$(PPTX): %.pptx: %.md
	python3 $(COMMON_DIR)/check-pptx.py $(COMMON_DIR)/pres-template.pptx
	$(PANDOC) $(PANDOC_ARGS) --reference-doc $(COMMON_DIR)/pres-template.pptx $< -o $@
	python3 $(COMMON_DIR)/postprocess-pptx.py $@ $@
	
############################
# Image patterns
############################

$(DOT_SVG): %.svg: %.gv
	dot -Tsvg $< -o $@


$(TIKZ_SVG): %.svg: %.tikz
	@mkdir -p $(dir $(BUILD_DIR)/$<)
	@cp $< $(BUILD_DIR)/$<
	cd $(dir $(BUILD_DIR)/$<); \
		pdflatex $(notdir $<) >/dev/null
	@# SELF_CALL is workaround for running inkscape in parallel
	@# See https://gitlab.com/inkscape/inkscape/-/issues/4716
	SELF_CALL=no inkscape $(BUILD_DIR)/$*.pdf --pages=1 --export-plain-svg=$@

############################
# Custom patterns
############################

$(COMMON_DIR)/pres-template.pptx: $(COMMON_DIR)/pres-template-pptx
	cd $(COMMON_DIR)/pres-template-pptx; \
		zip -r ../pres-template.pptx . >/dev/null

TARGET_IMAGE_DEPS = $(filter $(IMAGES_DIR)/$*/%,$(SVG_TARGET) $(PNG_TARGET))
ROOT_IMAGE_DEPS = $(filter $(IMAGES_DIR)/%,$(SVG_ROOT) $(PNG_ROOT))

TARGET_DOT_DEPS = $(filter $(TIKZ_DIR)/$*/%,$(DOT_SVG_TARGET))
ROOT_DOT_DEPS = $(filter $(TIKZ_DIR)/%,$(DOT_SVG_ROOT))

TARGET_TIKZ_DEPS = $(filter $(TIKZ_DIR)/$*/%,$(TIKZ_SVG_TARGET))
ROOT_TIKZ_DEPS = $(filter $(TIKZ_DIR)/%,$(TIKZ_SVG_ROOT))

.SECONDEXPANSION:
$(PPTX): $(SRC_DIR)/%.pptx: $(ROOT_TIKZ_DEPS) $$(TARGET_TIKZ_DEPS) $(ROOT_IMAGE_DEPS) $$(TARGET_IMAGE_DEPS) $(ROOT_DOT_DEPS) $$(TARGET_DOT_DEPS)

$(PPTX): $(COMMON_DIR)/check-pptx.py $(COMMON_DIR)/pres-template.pptx

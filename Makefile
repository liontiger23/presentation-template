############################
# Usage
# make         # converts all src/*.md files to publish/*.pdf files using pandoc
# make clean   # cleans up publish/*.pdf artifacts
############################

all:

############################
# Common
############################

PANDOC = pandoc

PUBLISH_DIR = publish
SRC_DIR = src
IMAGES_DIR = images
COMMON_DIR = common
BUILD_DIR = build

############################
# Targets
############################

SRC  = $(wildcard $(SRC_DIR)/*.md)
PDF  = $(SRC:.md=.pdf)
PDF_DARK = $(PDF:.pdf=-dark.pdf)
PPTX = $(SRC:.md=.pptx)

PDF_PUBLISH = $(PDF:$(SRC_DIR)/%=$(PUBLISH_DIR)/%) $(PDF_DARK:$(SRC_DIR)/%=$(PUBLISH_DIR)/%)
PDF_NAMES = $(PDF:$(SRC_DIR)/%.pdf=%)

PPTX_PUBLISH = $(PPTX:$(SRC_DIR)/%=$(PUBLISH_DIR)/%)
PPTX_NAMES = $(PPTX:$(SRC_DIR)/%.pptx=%)

PNG_ROOT = $(wildcard $(IMAGES_DIR)/*.png)
PNG_TARGET = $(foreach NAME,$(PDF_NAMES),$(wildcard $(IMAGES_DIR)/$(NAME)/*.png))
PNG = $(PNG_ROOT) $(PNG_TARGET)

SVG_ROOT = $(wildcard $(IMAGES_DIR)/*.svg)
SVG_TARGET = $(foreach NAME,$(PDF_NAMES),$(wildcard $(IMAGES_DIR)/$(NAME)/*.svg))
SVG_PDF_ROOT = $(SVG_ROOT:.svg=.pdf)
SVG_PDF_TARGET = $(SVG_TARGET:.svg=.pdf)
SVG_PDF = $(SVG_PDF_ROOT) $(SVG_PDF_TARGET)

DOT_ROOT = $(wildcard $(IMAGES_DIR)/*.gv)
DOT_TARGET = $(foreach NAME,$(PDF_NAMES),$(wildcard $(IMAGES_DIR)/$(NAME)/*.gv))
DOT_PDF_ROOT = $(DOT_ROOT:.gv=.pdf)
DOT_PDF_TARGET = $(DOT_TARGET:.gv=.pdf)
DOT_PDF = $(DOT_PDF_ROOT) $(DOT_PDF_TARGET)

TIKZ_ROOT = $(wildcard $(IMAGES_DIR)/*.tikz)
TIKZ_TARGET = $(foreach NAME,$(PDF_NAMES),$(wildcard $(IMAGES_DIR)/$(NAME)/*.tikz))
TIKZ_SVG_ROOT = $(TIKZ_ROOT:.tikz=.svg)
TIKZ_SVG_TARGET = $(TIKZ_TARGET:.tikz=.svg)
TIKZ_SVG = $(TIKZ_SVG_ROOT) $(TIKZ_SVG_TARGET)

############################
# Goals
############################

.PHONY: all clean pdf pptx
.DEFAULT_GOAL := all

all: pdf

publish: $(PDF_PUBLISH) $(PPTX_PUBLISH)
pdf:  $(PDF) $(PDF_DARK)
pptx:  $(PPTX)

clean: 
	@echo "Cleaning up..."
	rm -rvf $(PDF) $(PDF_DARK) $(SVG_PDF) $(DOT_PDF) $(PPTX) $(TIKZ_SVG) $(BUILD_DIR)

############################
# Publish patterns
############################

$(PDF_PUBLISH): $(PUBLISH_DIR)/%.pdf: $(SRC_DIR)/%.pdf
	@mkdir -p $(@D)
	cp $< $@

$(PPTX_PUBLISH): $(PUBLISH_DIR)/%.pptx: $(SRC_DIR)/%.pptx
	@mkdir -p $(@D)
	cp $< $@

############################
# Pandoc patterns
############################

PANDOC_ARGS :=

$(PDF): %.pdf: %.md
	$(PANDOC) $(PANDOC_ARGS) -t beamer --pdf-engine lualatex $< -o $@

$(PDF_DARK): %-dark.pdf: %.md
	$(PANDOC) $(PANDOC_ARGS) -t beamer --pdf-engine lualatex --variable darkmode=true $< -o $@

$(PPTX): %.pptx: %.md
	python3 $(COMMON_DIR)/check-pptx.py $(COMMON_DIR)/pres-template.pptx
	$(PANDOC) $(PANDOC_ARGS) --reference-doc $(COMMON_DIR)/pres-template.pptx $< -o $@
	python3 $(COMMON_DIR)/postprocess-pptx.py $@ $@
	
############################
# Image patterns
############################

$(SVG_PDF): %.pdf: %.svg
	@# SELF_CALL is workaround for running inkscape in parallel
	@# See https://gitlab.com/inkscape/inkscape/-/issues/4716
	SELF_CALL=no inkscape -D $< -o $@


$(DOT_PDF): %.pdf: %.gv
	dot -Tpdf $< -o $@


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

TARGET_IMAGE_DEPS = $(filter $(IMAGES_DIR)/$*/%,$(DOT_PDF_TARGET) $(SVG_PDF_TARGET) $(PNG_TARGET))
ROOT_IMAGE_DEPS = $(filter $(IMAGES_DIR)/%,$(DOT_PDF_ROOT) $(SVG_PDF_ROOT) $(PNG_ROOT))

.SECONDEXPANSION:
$(PDF): $(SRC_DIR)/%.pdf: $(ROOT_IMAGE_DEPS) $(COMMON_PNG_IMAGE_DEPS) $$(TARGET_IMAGE_DEPS)
$(PDF_DARK): $(SRC_DIR)/%-dark.pdf: $(ROOT_IMAGE_DEPS) $(COMMON_PNG_IMAGE_DEPS) $$(TARGET_IMAGE_DEPS)

$(PDF) $(PDF_DARK): $(COMMON_DIR)/pres.yaml $(COMMON_DIR)/pres-preamble.tex $(COMMON_DIR)/pres-template.tex
$(PDF) $(PDF_DARK): PANDOC_ARGS = $(COMMON_DIR)/pres.yaml -H $(COMMON_DIR)/pres-preamble.tex --listings --template $(COMMON_DIR)/pres-template.tex --slide-level=1

TARGET_TIKZ_DEPS = $(filter $(IMAGES_DIR)/$*/%,$(TIKZ_SVG_TARGET) $(SVG_TARGET) $(PNG_TARGET))
ROOT_TIKZ_DEPS = $(filter $(IMAGES_DIR)/%,$(TIKZ_SVG_ROOT) $(SVG_ROOT) $(PNG_ROOT))

.SECONDEXPANSION:
$(PPTX): $(SRC_DIR)/%.pptx: $(ROOT_TIKZ_DEPS) $(COMMON_PNG_IMAGE_DEPS) $$(TARGET_TIKZ_DEPS)

$(PPTX): $(COMMON_DIR)/check-pptx.py $(COMMON_DIR)/pres-template.pptx

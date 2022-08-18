# Zeno Build & Orchestration Makefile
HAXE = haxe
BIN_DIR = bin

export HAXE_STD_PATH ?= /opt/homebrew/lib/haxe/std
export PATH := /opt/homebrew/bin:$(PATH)

.PHONY: all test bench clean js neko python run

all: test

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

test:
	$(HAXE) test.hxml

bench:
	$(HAXE) bench.hxml

run:
	$(HAXE) build.hxml

js: $(BIN_DIR)
	$(HAXE) -cp src -main zeno.cli.CLI -dce full -D analyzer-optimize -js $(BIN_DIR)/zeno.js

neko: $(BIN_DIR)
	$(HAXE) -cp src -main zeno.cli.CLI -dce full -D analyzer-optimize -neko $(BIN_DIR)/zeno.n

python: $(BIN_DIR)
	$(HAXE) -cp src -main zeno.cli.CLI -dce full -D analyzer-optimize -python $(BIN_DIR)/zeno.py

verify:
	@bash scripts/verify_all.sh

clean:
	rm -rf $(BIN_DIR) export

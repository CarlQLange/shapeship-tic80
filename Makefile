# Generic TIC-80 Development Makefile
# Auto-detects .lua files and derives project name

# Auto-detect the main .lua file (first one found)
LUA_FILE := $(shell ls *.lua 2>/dev/null | head -n1)
PROJECT_NAME := $(basename $(LUA_FILE))

# TIC-80 commands
TIC80 := tic80
TIC80_FLAGS := --fs .

# File watching command (prefer fswatch on macOS, fallback to entr)
WATCHER := $(shell which fswatch 2>/dev/null || which entr 2>/dev/null)

.PHONY: dev run build web clean help

# Default target
help:
	@echo "TIC-80 Development Commands:"
	@echo "  make dev   - Watch $(LUA_FILE) and auto-reload on changes"
	@echo "  make run   - Run $(LUA_FILE) once"
	@echo "  make build - Build $(PROJECT_NAME).tic"
	@echo "  make web   - Export $(PROJECT_NAME) for web"
	@echo "  make clean - Clean generated files"
	@echo ""
	@echo "Detected: $(LUA_FILE) -> $(PROJECT_NAME)"

# Development with file watching
dev:
	@if [ -z "$(LUA_FILE)" ]; then \
		echo "Error: No .lua file found in current directory"; \
		exit 1; \
	fi
	@if [ -z "$(WATCHER)" ]; then \
		echo "Error: Neither fswatch nor entr found. Please install one:"; \
		echo "  brew install fswatch"; \
		echo "  brew install entr"; \
		exit 1; \
	fi
	@echo "Watching $(LUA_FILE) for changes. Press Ctrl+C to stop."
	@if command -v fswatch >/dev/null 2>&1; then \
		fswatch -o $(LUA_FILE) | while read; do \
			echo "File changed, reloading..."; \
			$(TIC80) $(TIC80_FLAGS) --cmd "new lua & import code $(LUA_FILE) & run"; \
		done; \
	else \
		echo $(LUA_FILE) | entr -r $(TIC80) $(TIC80_FLAGS) --cmd "new lua & import code $(LUA_FILE) & run"; \
	fi

# Single run
run:
	@if [ -z "$(LUA_FILE)" ]; then \
		echo "Error: No .lua file found in current directory"; \
		exit 1; \
	fi
	$(TIC80) $(TIC80_FLAGS) --cmd "new lua & import code $(LUA_FILE) & run"

# Build .tic file
build:
	@if [ -z "$(LUA_FILE)" ]; then \
		echo "Error: No .lua file found in current directory"; \
		exit 1; \
	fi
	$(TIC80) $(TIC80_FLAGS) --cmd "new lua & import code $(LUA_FILE) & save $(PROJECT_NAME).tic"
	@echo "Built $(PROJECT_NAME).tic"

# Export for web
web: build
	$(TIC80) $(TIC80_FLAGS) --cmd "load $(PROJECT_NAME).tic & export html $(PROJECT_NAME)"
	@echo "Exported $(PROJECT_NAME) for web"

# Clean generated files
clean:
	@echo "Cleaning generated files..."
	@rm -f *.tic
	@rm -f *.html
	@rm -f *.js
	@rm -f *.wasm
	@rm -f *.zip
	@rm -f cart.tic
	@echo "Clean complete"

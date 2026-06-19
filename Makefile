APP_NAME := NotchCloset
APP_BUNDLE := $(APP_NAME).app
APP_EXEC := $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)

# Detect the exact executable path for pkill
APP_EXEC_PATH := $(shell pwd)/$(APP_EXEC)

.PHONY: run build kill clean

# ── Default: build + run ──────────────────────────────────────────
run: kill build open

# ── Kill running instance ─────────────────────────────────────────
kill:
	@pkill -f '$(APP_EXEC_PATH)' 2>/dev/null || true
	@echo "[ok] Killed $(APP_NAME)"

# ── Build .app bundle ─────────────────────────────────────────────
build:
	@./build-app.sh

# ── Launch (non-blocking) ─────────────────────────────────────────
open:
	@open $(APP_BUNDLE)
	@echo "[ok] Launched $(APP_BUNDLE)"

# ── Full rebuild + run ────────────────────────────────────────────
rebuild: clean run

# ── Clean build artifacts ─────────────────────────────────────────
clean:
	@swift package clean
	@rm -rf $(APP_BUNDLE)
	@echo "[ok] Cleaned"

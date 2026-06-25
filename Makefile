APP_NAME := NotchCloset
APP_BUNDLE := $(APP_NAME).app
APP_EXEC := $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)

# Detect the exact executable path for pkill
APP_EXEC_PATH := $(shell pwd)/$(APP_EXEC)
BUILD_DIR := .build/debug

.PHONY: run build kill open clean rebuild

# ── Default: build + run ──────────────────────────────────────────
run: kill build open

# ── Kill running instance ─────────────────────────────────────────
kill:
	@pkill -f '$(APP_EXEC_PATH)' 2>/dev/null || true
	@echo "[ok] Killed $(APP_NAME)"

# ── Build .app bundle ─────────────────────────────────────────────
build:
	@echo "==> Building..."
	@swift build
	@echo "==> Creating .app bundle..."
	@rm -rf "$(APP_BUNDLE)"
	@mkdir -p "$(APP_BUNDLE)/Contents/MacOS" "$(APP_BUNDLE)/Contents/Resources"
	@cp "$(BUILD_DIR)/$(APP_NAME)" "$(APP_BUNDLE)/Contents/MacOS/"
	@BUNDLE="$(BUILD_DIR)/$(APP_NAME)_$(APP_NAME).bundle"; \
	if [ -d "$$BUNDLE" ]; then \
		find "$$BUNDLE" -name '*.lproj' -type d | while read lproj; do \
			cp -R "$$lproj" "$(APP_BUNDLE)/Contents/Resources/"; \
		done; \
	fi
	@printf '<?xml version="1.0" encoding="UTF-8"?>\n<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n<plist version="1.0"><dict>\n<key>CFBundleExecutable</key><string>$(APP_NAME)</string>\n<key>CFBundleIdentifier</key><string>com.kanade2511.$(APP_NAME)</string>\n<key>CFBundleName</key><string>$(APP_NAME)</string>\n<key>CFBundleDisplayName</key><string>$(APP_NAME)</string>\n<key>CFBundleVersion</key><string>1</string>\n<key>CFBundleShortVersionString</key><string>0.1.0</string>\n<key>CFBundlePackageType</key><string>APPL</string>\n<key>LSMinimumSystemVersion</key><string>14.0</string>\n<key>NSHighResolutionCapable</key><true/>\n<key>LSUIElement</key><true/>\n</dict></plist>\n' > "$(APP_BUNDLE)/Contents/Info.plist"
	@echo "==> Done: open $(APP_BUNDLE)"

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

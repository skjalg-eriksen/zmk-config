VENV ?= $(CURDIR)/.venv
WEST ?= $(if $(wildcard $(VENV)/bin/west),$(VENV)/bin/west,west)
WEST_TOPDIR ?= $(shell $(WEST) topdir 2>/dev/null)
WORKSPACE_DIR ?= $(or $(WEST_TOPDIR),$(CURDIR))
ZMK_APP ?= $(if $(WEST_TOPDIR),$(WEST_TOPDIR)/zmk/app,$(CURDIR)/zmk/app)
ZEPHYR_DIR ?= $(WORKSPACE_DIR)/zephyr
ZMK_CONFIG ?= $(CURDIR)/config
BUILD_DIR ?= $(CURDIR)/build
PYTHON ?= python3
SDK_VERSION ?= 0.16.9
SDK_HOST ?= linux-x86_64
SDK_INSTALL_DIR ?= $(HOME)/.local/opt
SDK_DIR ?= $(SDK_INSTALL_DIR)/zephyr-sdk-$(SDK_VERSION)
SDK_ARCHIVE ?= zephyr-sdk-$(SDK_VERSION)_$(SDK_HOST).tar.xz
SDK_URL ?= https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v$(SDK_VERSION)/$(SDK_ARCHIVE)
BUILD_ENV = ZEPHYR_SDK_INSTALL_DIR="$(SDK_DIR)" PATH="$(VENV)/bin:$(PATH)"

.PHONY: help all clean \
	venv deps sdk doctor \
	corne_min_left_with_studio \
	corne_min_left_with_studio_and_peripheral_battery_reporting \
	corne_min_right \
	prospector_for_corne_min \
	prospector_settings_reset \
	corne_min_left_for_prospector \
	corne_min_right_for_prospector \
	corne_min_settings_reset

help:
	@printf '%s\n' 'Local ZMK build targets:'
	@printf '  %-58s %s\n' 'make prospector_for_corne_min' 'Prospector dongle with ZMK Studio'
	@printf '  %-58s %s\n' 'make corne_min_left_for_prospector' 'Left half for Prospector dongle'
	@printf '  %-58s %s\n' 'make corne_min_right_for_prospector' 'Right half for Prospector dongle'
	@printf '  %-58s %s\n' 'make corne_min_left_with_studio' 'Standard split left half with ZMK Studio'
	@printf '  %-58s %s\n' 'make corne_min_right' 'Standard split right half'
	@printf '  %-58s %s\n' 'make deps' 'Create .venv and install local build dependencies'
	@printf '  %-58s %s\n' 'make sdk' 'Install Zephyr SDK compiler toolchain'
	@printf '  %-58s %s\n' 'make doctor' 'Print local toolchain diagnostics'
	@printf '  %-58s %s\n' 'make clean' 'Remove all build directories'
	@printf '  %-58s %s\n' 'make all' 'Build every firmware target from build.yaml'
	@printf '\n%s\n' 'Outputs are written to build/<target>/zephyr/zmk.uf2.'
	@printf '%s\n' 'Override ZMK_APP=/path/to/zmk/app if west cannot find it automatically.'

venv:
	$(PYTHON) -m venv "$(VENV)"
	"$(VENV)/bin/python" -m pip install -U pip wheel "setuptools<81" west "cmake<4" ninja

deps: venv
	"$(VENV)/bin/python" -m pip install -r "$(ZEPHYR_DIR)/scripts/requirements.txt" -r "$(ZMK_APP)/scripts/requirements.txt"
	"$(VENV)/bin/python" -m pip install "setuptools<81"

sdk:
	mkdir -p "$(SDK_INSTALL_DIR)"
	test -d "$(SDK_DIR)" || curl -L "$(SDK_URL)" -o "$(SDK_INSTALL_DIR)/$(SDK_ARCHIVE)"
	test -d "$(SDK_DIR)" || tar -C "$(SDK_INSTALL_DIR)" -xf "$(SDK_INSTALL_DIR)/$(SDK_ARCHIVE)"
	cd "$(SDK_DIR)" && ./setup.sh -t arm-zephyr-eabi

doctor:
	@$(BUILD_ENV) sh -c 'printf "west: "; west --version; printf "cmake: "; cmake --version | sed -n "1p"; printf "ninja: "; ninja --version'
	$(BUILD_ENV) cmake -P "$(ZEPHYR_DIR)/cmake/verify-toolchain.cmake"

all: corne_min_left_with_studio \
	corne_min_left_with_studio_and_peripheral_battery_reporting \
	corne_min_right \
	prospector_for_corne_min \
	prospector_settings_reset \
	corne_min_left_for_prospector \
	corne_min_right_for_prospector \
	corne_min_settings_reset

corne_min_left_with_studio:
	$(BUILD_ENV) $(WEST) build -d "$(BUILD_DIR)/$@" -s "$(ZMK_APP)" -b corne_min_left -S studio-rpc-usb-uart -- -DSHIELD=rgbled_adapter -DZMK_CONFIG="$(ZMK_CONFIG)" -DCONFIG_ZMK_STUDIO=y -DCONFIG_ZMK_STUDIO_LOCKING=n -DCONFIG_ZMK_BLE_EXPERIMENTAL_CONN=y

corne_min_left_with_studio_and_peripheral_battery_reporting:
	$(BUILD_ENV) $(WEST) build -d "$(BUILD_DIR)/$@" -s "$(ZMK_APP)" -b corne_min_left -S studio-rpc-usb-uart -- -DSHIELD=rgbled_adapter -DZMK_CONFIG="$(ZMK_CONFIG)" -DCONFIG_ZMK_STUDIO=y -DCONFIG_ZMK_STUDIO_LOCKING=n -DCONFIG_ZMK_BLE_EXPERIMENTAL_CONN=y -DCONFIG_ZMK_SPLIT_BLE_CENTRAL_BATTERY_LEVEL_FETCHING=y -DCONFIG_ZMK_SPLIT_BLE_CENTRAL_BATTERY_LEVEL_PROXY=y

corne_min_right:
	$(BUILD_ENV) $(WEST) build -d "$(BUILD_DIR)/$@" -s "$(ZMK_APP)" -b corne_min_right -- -DSHIELD=rgbled_adapter -DZMK_CONFIG="$(ZMK_CONFIG)" -DCONFIG_ZMK_BLE_EXPERIMENTAL_CONN=y

prospector_for_corne_min:
	$(BUILD_ENV) $(WEST) build -d "$(BUILD_DIR)/$@" -s "$(ZMK_APP)" -b seeeduino_xiao_ble -S studio-rpc-usb-uart -- -DSHIELD="corne_min_dongle prospector_adapter" -DSHIELD_ROOT="$(CURDIR)" -DZMK_CONFIG="$(ZMK_CONFIG)" -DCONFIG_ZMK_STUDIO=y -DCONFIG_ZMK_STUDIO_LOCKING=n

prospector_settings_reset:
	$(BUILD_ENV) $(WEST) build -d "$(BUILD_DIR)/$@" -s "$(ZMK_APP)" -b seeeduino_xiao_ble -- -DSHIELD=settings_reset -DZMK_CONFIG="$(ZMK_CONFIG)"

corne_min_left_for_prospector:
	$(BUILD_ENV) $(WEST) build -d "$(BUILD_DIR)/$@" -s "$(ZMK_APP)" -b corne_min_left -- -DSHIELD=rgbled_adapter -DZMK_CONFIG="$(ZMK_CONFIG)" -DCONFIG_ZMK_SPLIT=y -DCONFIG_ZMK_SPLIT_ROLE_CENTRAL=n

corne_min_right_for_prospector:
	$(BUILD_ENV) $(WEST) build -d "$(BUILD_DIR)/$@" -s "$(ZMK_APP)" -b corne_min_right -- -DSHIELD=rgbled_adapter -DZMK_CONFIG="$(ZMK_CONFIG)" -DCONFIG_ZMK_SPLIT=y -DCONFIG_ZMK_SPLIT_ROLE_CENTRAL=n

corne_min_settings_reset:
	$(BUILD_ENV) $(WEST) build -d "$(BUILD_DIR)/$@" -s "$(ZMK_APP)" -b corne_min_left -- -DSHIELD=settings_reset -DZMK_CONFIG="$(ZMK_CONFIG)"

clean:
	rm -rf "$(BUILD_DIR)"

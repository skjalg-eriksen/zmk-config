# Corne Min ZMK Firmware Builds
.
This repository produces firmware for two different Corne Min configurations:

* **Standard Split** — The left half acts as the central device and communicates directly with your computer over USB or Bluetooth.
* **Prospector Dongle** — A Prospector USB dongle acts as the central device, while both keyboard halves operate as BLE peripherals.

<br>


---

<details open>
<summary><strong>Standard Firmware</strong></summary>


### `corne_min_left_with_studio.uf2`

Firmware for the **left (central)** half of the Corne Min.

**Features**

* [ZMK Studio support](https://zmk.studio/)
* Experimental BLE connection

Use this build if you want to configure your keyboard with ZMK Studio.

---

### `corne_min_left_with_studio_and_peripheral_battery_reporting.uf2`

Firmware for the **left (central)** half with battery reporting from the peripheral half.

**Features**

* [ZMK Studio support](https://zmk.studio/)
* Experimental BLE connection
* Peripheral battery level reporting

---

### `corne_min_right.uf2`

Firmware for the **right (peripheral)** half.

**Features**

* Experimental BLE connection

Flash this alongside one of the left-half firmware variants above.

</details>

---

<details>
<summary><strong>Prospector Dongle Firmware</strong></summary>


### `prospector_for_corne_min.uf2`

Firmware for the Prospector USB dongle.

**Features**

* [ZMK Studio support](https://zmk.studio/)

---

### `corne_min_left_for_prospector.uf2`

Firmware for the **left** keyboard half.

---

### `corne_min_right_for_prospector.uf2`

Firmware for the **right** keyboard half.

</details>

---

<details>
<summary><strong>Settings Reset Firmware</strong></summary>


### `prospector_settings_reset.uf2`

Clears all stored settings and Bluetooth bonds on the Prospector dongle.

---

### `corne_min_settings_reset.uf2`

Clears all stored settings and Bluetooth bonds on a Corne Min half.

After flashing a reset image, flash the desired firmware again before using the device.

</details>

---

## Local Builds

Install the ZMK local toolchain first:

```sh
west init -l config
west update
west zephyr-export
make deps
make sdk
make doctor
```

On Arch Linux, `make deps` installs Python packages into a local `.venv` so the system-managed Python environment is left alone. It also installs a compatible CMake version into the venv because Zephyr 3.5 does not configure cleanly with CMake 4.x, and pins `setuptools` for the older nanopb generator used by this Zephyr tree. `make sdk` downloads Zephyr SDK 0.16.9 to `~/.local/opt` and runs its setup for the ARM compiler toolchain used to build keyboard firmware.

Build the Prospector dongle firmware with ZMK Studio:

```sh
make prospector_for_corne_min
```

The UF2 will be written to:

```text
build/prospector_for_corne_min/zephyr/zmk.uf2
```

Other useful targets:

```sh
make corne_min_left_for_prospector
make corne_min_right_for_prospector
make corne_min_left_with_studio
make corne_min_right
make all
```

Clean local build output:

```sh
make clean
```

After the first build, rerunning the same `make` target reuses its build directory and is much faster. If your ZMK checkout is not in the west workspace that contains this repo, pass the app path explicitly:

```sh
make prospector_for_corne_min ZMK_APP=/path/to/zmk/app
```

If your Zephyr SDK is installed somewhere else, pass that path explicitly:

```sh
make prospector_for_corne_min SDK_DIR=/path/to/zephyr-sdk-0.16.9
```

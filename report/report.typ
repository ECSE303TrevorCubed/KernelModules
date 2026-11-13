#show link: set text(fill: blue)
#show title: set text(size: 17pt)
#show title: set align(center)

#title[
  ECSE303 Lab Assignment K \
  Kernel Modules
]
#align(center)[Trevor Swan, Justin Fossum, Trevor Nichols]

#set heading(numbering: "1.")

= Assignment Statement and Objective
The objective of this assignment is to design and build microsecond-response drivers as Raspberry Pi Linux Kernel Modules. The compiled kernel modules implement the behavior from Lab 1 (Blink) and Lab 2 (Temperature) to eliminate user-space scheduling latencies and other overheads.

== Summary of Contents
- *Part 1 - Blinking LED:* An implementation of an autonomous kernel module driver (`blink_km.ko`) that periodically turns an LED on and off at a set interval of 500 ms. This is accomplished using the kernel's GPIO API (```c #include <linux/gpio.h>```) and asynchronous kernel timers (```c #include <linux/timer.h>```), achieving feature parity with lab 1's user-space blink implementation.
- *Part 2 - Temperature and Humidity Sensor:* Configuration of the Raspberry Pi using device tree overlays (`dht11.dts`) and kernel module (`dht11.ko`). The sensor exposes temperature and humidity readings via sysfs (`/sys/bus/iio/devices/iio:deviceX/`), implemented with a shell script.
- *Analysis:* Comparison of the kernel module method against the user-space method taken in previous labs in terms of response time, results, and accuracy.

= Methodology and Steps

== Hardware Configuration
- *Blinking LED Setup*
  - An LED with its anode connected through a 220 $Omega$ current-limiting resistor to GPIO pin 25 (configurable at module insertion via the `led_pin` parameter)
  - The LED's cathode is connected directly to the Pi's ground pin
- *DHT11 Sensor Setup*
  - Data Pin: Connected to GPIO 25 (`#define DHT11_PIN 25`, physical pin 37) with a 10 kOhm pull-up resistor to the 3.3V power rail.
  - Power and Ground: Connected to 3.3V (physical pin 1) and Ground (physical pin 39).

== LED - Kernel Module Compilation & Upload
1. Compile the kernel module with ```bash make modules```
2. Load the kernel module using `insmod`: ```bash sudo insmod blink_km.ko```
  - Note that you can specify different led pin or blink period in the `insmod` command: ```bash sudo insmod blink_km.ko led_pin=25 blink_period_ms=500```
3. View the kernel logs with ```bash dmesg | tail -n 15```
4. Confirm the module is loaded with ```bash lsmod | grep blink_km```
5. Verify the GPIO export with ```bash ls -l /sys/class/gpio/gpio25```
6. The kernel module can then be removed with ```bash sudo rmmod blink_km```, deallocated all resources after turning off the LED

== DHT11 - Device Tree Overlay Deployment
1. Compile the device tree overlay source file `dht11.dts` into a binary using `make dtb`, which makes the call:
  ```bash
  dtc -I dts -O dtb -o dht11-overlay.dtb -b 0 -@ dht11.dts
  ```
2. Copy the resulting binary into the overlays boot subdirectory:
  ```bash
  sudo cp dht11-overlay.dtb /boot/firmware/overlays/
  ```
3. Enable the overlay in `/boot/firmware/config.txt`:
  ```ini
  dtoverlay=dht11,gpiopin=25
  ```
4. Reboot the Raspberry Pi with `sudo reboot`
5. Unload the module with ```bash sudo rmmod dht11``` if it was loaded automatically (check with ```bash lsmod | grep dht11```)
6. Insert the compiled module with ```bash sudo insmod dht11.ko```
7. Verify execution through kernel logs ```bash dmesg | tail -n 20```
8. Observe the sensor readings using IIO (or use the `read.sh` shell script)
  ```bash
  # Temperature (e.g. 21000 = 21.000 °C)
  cat /sys/bus/iio/devices/iio:device3/in_temp_input

  # Humidity (e.g. 45000 = 45.000 % RH)
  cat /sys/bus/iio/devices/iio:device3/in_humidityrelative_input
  ```
  - Note that your Pi's iio device may be different. Check its mapping with ```bash ls -l ls -l /sys/bus/iio/devices/```
9. Unload the module with ```bash sudo rmmod dht11``` to release allocated resources

= Results and Observations

= Conclusions

== Techniques learned
- Learned how to interface with the Pi's GPIO interface without relying on application-space libraries like `wiringPi`
- Learned about the C macros that embed kernel module metadata and support loading the module with different parameters
- Learned how to use the device tree overlays to manage kernel modules
- Gained experience with the command line workflow required to compile a device tree overlay and use it to load an associated kernel module

== Assignment Feedback
- The two PDFs posted made navigating assignment instructions confusing. Having the part 2 instructions in the same document as the part 1 document would be helpful
- The deadline for this lab was communicated 2 days in advance. Giving more advance notice with lab deadlines either on Canvas or via email would be helpful
- The content of the lab was very feasible to complete and digest given the sample code
  - The LED code was nice because it didn't exactly give the implementation needed for parity with Lab 1, requiring some modifications
  - The DHT11 code was also nice as that implementation was considerably more complex, so having the sample code to use for our driver, with some modifications to be made, made the process smooth

= Notes
- GPIO pin layout:
```txt
+-----+-----+---------+------+---+---Pi 3B--+---+------+---------+-----+-----+
| BCM | wPi |   Name  | Mode | V | Physical | V | Mode | Name    | wPi | BCM |
+-----+-----+---------+------+---+----++----+---+------+---------+-----+-----+
|     |     |    3.3v |      |   |  1 || 2  |   |      | 5v      |     |     |
|   2 |   8 |   SDA.1 | ALT0 | 1 |  3 || 4  |   |      | 5v      |     |     |
|   3 |   9 |   SCL.1 | ALT0 | 1 |  5 || 6  |   |      | 0v      |     |     |
|   4 |   7 | GPIO. 7 |   IN | 0 |  7 || 8  | 1 | ALT5 | TxD     | 15  | 14  |
|     |     |      0v |      |   |  9 || 10 | 1 | ALT5 | RxD     | 16  | 15  |
|  17 |   0 | GPIO. 0 |   IN | 0 | 11 || 12 | 0 | IN   | GPIO. 1 | 1   | 18  |
|  27 |   2 | GPIO. 2 |   IN | 0 | 13 || 14 |   |      | 0v      |     |     |
|  22 |   3 | GPIO. 3 |   IN | 0 | 15 || 16 | 0 | IN   | GPIO. 4 | 4   | 23  |
|     |     |    3.3v |      |   | 17 || 18 | 0 | IN   | GPIO. 5 | 5   | 24  |
|  10 |  12 |    MOSI | ALT0 | 0 | 19 || 20 |   |      | 0v      |     |     |
|   9 |  13 |    MISO | ALT0 | 0 | 21 || 22 | 0 | IN   | GPIO. 6 | 6   | 25  |
|  11 |  14 |    SCLK | ALT0 | 0 | 23 || 24 | 1 | OUT  | CE0     | 10  | 8   |
|     |     |      0v |      |   | 25 || 26 | 1 | OUT  | CE1     | 11  | 7   |
|   0 |  30 |   SDA.0 |   IN | 1 | 27 || 28 | 1 | IN   | SCL.0   | 31  | 1   |
|   5 |  21 | GPIO.21 |   IN | 1 | 29 || 30 |   |      | 0v      |     |     |
|   6 |  22 | GPIO.22 |   IN | 1 | 31 || 32 | 0 | IN   | GPIO.26 | 26  | 12  |
|  13 |  23 | GPIO.23 |   IN | 0 | 33 || 34 |   |      | 0v      |     |     |
|  19 |  24 | GPIO.24 |   IN | 0 | 35 || 36 | 0 | IN   | GPIO.27 | 27  | 16  |
|  26 |  25 | GPIO.25 |   IN | 1 | 37 || 38 | 0 | IN   | GPIO.28 | 28  | 20  |
|     |     |      0v |      |   | 39 || 40 | 0 | IN   | GPIO.29 | 29  | 21  |
+-----+-----+---------+------+---+----++----+---+------+---------+-----+-----+
| BCM | wPi |   Name  | Mode | V | Physical | V | Mode | Name    | wPi | BCM |
+-----+-----+---------+------+---+---Pi 3B--+---+------+---------+-----+-----+
```
- On the Raspberry Pi OS version we are using, the boot partition is mounted at `/boot/firmware/` rather than `/boot` as the lab instructions suggest
  - Similarly, overlays must be placed in `/boot/firmware/overlays/` rather than in `/boot/overlays/`
  - The boot configuration is also at `/boot/firmware/config.txt`
- The boot partition is formatted as FAT32 which cannot support the file permissions that `cp -p` tries to set (as suggested by the instructions)
  - The error message we got here was `cp: failed to preserve ownership ... Operation not permitted`, but the copy of the file contents succeeded, which was all that was needed
  - The command ```bash sudo cp dht11-overlay.dtb /boot/firmware/overlays/``` could be used to do this without error
- `dht11.dts` provides an `__overrides__` table that allows us to change the used gpio pin directly in `config.txt`
  - Instead of using a text editor to change this value directly, we used the command ```bash echo "dtoverlay=dht11,gpiopin=25" | sudo tee -a /boot/firmware/config.txt```
- We changed the provided blink sample code to not use the button-driven interrupts as we wanted to match the behavior in Lab 1 as requested by the lab instructions
- We could set the LED module's parameters via ```bash sudo insmod blink_km.ko led_pin=25 blink_period_ms=500```
  - The `MODULE_PARM_DESC` C macro was used to declare these parameters
  - The parameters are `led_pin` (default 25) and `blink_period_ms` (default 500)
- Querying `in_temp_input` or `in_humidityrelative_input` without a physical sensor attached returns: `cat: ...: Connection timed out`
- The commands provided that detail using `iio:device0` to read the sensor output were general, and we had to change the device number following inspection of `/sys/bus/iio/devices/`
  - When inspecting `/sys/bus/iio/devices/` we saw multiple overlay instances:
    - `dht11@4` was assigned to `iio:device3`
    - `dht11@19` was assigned to `iio:device2`
- Reading the sensor output (```bash cat /sys/bus/iio/devices/iio:deviceX/in_temp_input```) does not require `sudo`

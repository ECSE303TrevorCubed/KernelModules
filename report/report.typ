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
  - An LED with its anode connected through a 220 Ohm current-limiting resistor to GPIO pin 25 (configurable at module insertion via the `led_pin` parameter)
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
  cat /sys/bus/iio/devices/iio:device2/in_temp_input

  # Humidity (e.g. 45000 = 45.000 % RH)
  cat /sys/bus/iio/devices/iio:device2/in_humidityrelative_input
  ```
  - Note that your Pi's iio device may be different. Check its mapping with ```bash ls -l /sys/bus/iio/devices/```
9. Unload the module with ```bash sudo rmmod dht11``` to release allocated resources

= Results and Observations

== Part 1: Blinking LED Results
The `blink_km.ko` module successfully compiled and inserted into the running kernel without errors. As soon as we ran ```bash sudo insmod blink_km.ko led_pin=25 blink_period_ms=500```, the connected LED immediately starting blinking at the set interval.

#figure(
  image("led_circuit.jpeg", width: 75%),
  caption: [Circuit layout for LED Kernel Module],
)

The intialization was confirmed by inspecting the kernel logs with `dmesg`:
```log
[32065.715397] blink_km: Initialized on GPIO 25, period 500 ms
```
indicating that the print statement at the end of our initialization ran successfully.

The GPIO sysfs export at `/sys/class/gpio/gpio25` confirmed that the pin was exported correctly with its direction locked to prevent user-space code from interfering with it. Removing the kernel module with ```bash sudo rmmod blink_km``` safely released the timer and turned off the LED, releasing the allocated resources back to the OS.

#figure(
  image("blink_terminal.png", width: 85%),
  caption: [Blink kernel module terminal interaction],
)

The above image shows the compilation and startup for the kernel module as well as its teardown process, accompanied by verification of the GPIO pin export.

== Part 2: DHT11 Sensor Results
The device tree overlay (`dht11-overlay.dtb`) was successfully compiled with `dtc` and copied to `/boot/firmware/overlays/`. Booting with `dtoverlay=dht11,gpiopin=25` configured in `/boot/firmware/config.txt` enabled the device which aligned with the compiled `dht11.ko` kernel module.

#figure(
  image("dht11_circuit.jpeg", width: 75%),
  caption: [Circuit layout for DHT11 Kernel Module],
)

We checked `/sys/bus/iio/devices/` to confirm the creation of the virtual device nodes, and then proceeded to sample the sensor output with the following shell script (`read.sh`):
```bash
#!/bin/sh
DEV="/sys/bus/iio/devices/iio:device2"

while true; do
  TIMESTAMP=$(date '+%H:%M:%S')

  if TEMP=$(cat "$DEV/in_temp_input" 2>/dev/null); then
    HUM=$(cat "$DEV/in_humidityrelative_input" 2>/dev/null)
    echo "$TIMESTAMP - Temp: $TEMP"
    echo "$TIMESTAMP - Humidity: $HUM"
  else
    echo "$TIMESTAMP - Read failed (I/O error or checksum mismatch), waiting for sensor to reset..."
  fi
    sleep 2.5
done
```

This script was used to collect sensor data, which read:
```log
11:55:44 - Temp: 22000
11:55:44 - Humidity: 27000
11:55:46 - Temp: 22000
11:55:46 - Humidity: 27000
11:55:48 - Temp: 22000
11:55:48 - Humidity: 27000
11:55:50 - Temp: 22000
11:55:50 - Humidity: 27000
11:55:52 - Temp: 22000
11:55:52 - Humidity: 27000
```

The output values were formatted in the standard IIO integer format, where `21000` corresponds to 21.000 °C and `43000` corresponds to 43.000% relative humidity.

Testing the driver without the DHT11 hardware attached resulted in the expected error:
```txt
cat: '/sys/bus/iio/devices/iio:device2/in_temp_input': Connection timed out
```
verifying that the driver's communication with the hardware was bounded and did not hang the system when nothing was connected.

#figure(
  image("dht11_terminal.png", width: 85%),
  caption: [DHT11 Terminal Session],
)

The above image shows the compilation process, verification of initial configuration, error messages from the kernel, successful reads, and an data fetch error from an IO failure.

== Comparison and Analysis
The LED kernel module's performance against the user-space code is not noteworthy as there is no desire for highly precise timers or real-time code with simply blinking an LED. The core comparison from this lab comes from pitting the user-space polling and interrupt DHT11 solutions against the kernel driver:

#table(
  columns: 4,
  table.header(
    [*Evaluation Metric*],
    [*User Polling (Lab 2)*],
    [*User Interrupt (Lab 2)*],
    [*Kernel Driver (Lab K)*],
  ),
  [Execution Context],
  [User-space thread spinning on GPIO],
  [User thread woken via epoll on sysfs],
  [Hard-IRQ ISR in CPU context],

  [Edge Detection Latency],
  [Direct register read],
  [Context switch latency],
  [< 1 $mu$s direct interrupt vector],

  [Preemption Sensitivity], [High], [Severe], [Negligible],
  [Observed Checksum Failures],
  [~25% under normal system load],
  [40% - 70% without RT priority],
  [~10%],

  [CPU Core Utilization],
  [100% of single core during read],
  [Burst load during edge transitions],
  [Near 0%],

  [Security & Permissions],
  [Requires root access],
  [Requires root access],
  [Unprivileged readable sysfs after load],
)

=== Latency
Lab 2 Part 2 used user-space interrupt handling through `wiringPiISR`, suffering from severe latency issues. A physical edge occurring from the sensor would wake up an `epoll()` wait queue, causing a context switch across the user-space/kernel-space boundary. This is a costly operation that, if taking longer than the 26-28 $mu$s high pulse from the DHT11, would result in a missed data point, corrupting the resulting checksum.

`dht11.ko` instead runs its edge handler (`dht11_handle_irq`) directly inside a hard-IRQ context. `ktime_get_raw_ns()` is used to directly poll hardware timers, eliminating scheduling jitter.

=== Accuracy & Checksum Verification
Lab 2's user-space polling solution was moderately more accurate than the interrupt solution but failed checksum validation due to scheduler preemption. Preempting the process resulting in critical CPU time being spent on background tasks rather than consistently polling and validating the data, resulting in data being dropped consistently. The kernel module instead was about 90% consistent with an identical circuit layout, indicating that very few bits in the 40-bit transfer were lost. This was due to the strict timing provided by hard-IRQ execution.

Since our hardware is relatively cheap, reads sometimes fail even with this setup. This suggests that some kind of retry logic would be beneficial to our setup. User-space retry logic with back-off may be useful here, but it is not within the scope of the lab.

=== System Overhead
The polling solution was more intensive on the CPU as it had to use 100% of the core in a tight spin-loop (`delayMicroseconds(1)`). The kernel module instead uses kernel wait queues (`wait_for_completion_killable_timeout`) so that the process can sleep while the hardware gathers edges, consuming virtually 0 CPU cycles. Also, the implementation using the Industrial I/O (IIO) subsystem means that sensor communication can be read by non-root processes.

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

= Demo
We uploaded our demo online as it was performed outside of standard lab hours. You can find our demo here: https://drive.google.com/drive/folders/1ZaAQcAgq5Oql8A-AQPc5B3MNBb7vQfIl?usp=drive_link

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
    - `dht11@4` was assigned to `iio:device2`
    - `dht11@19` was assigned to `iio:device2`
- Reading the sensor output (```bash cat /sys/bus/iio/devices/iio:deviceX/in_temp_input```) does not require `sudo`
- Since we are using a GCC version that's newer than what the kernel was built with, we get a warning in the terminal:
  ```text
  The kernel was built by: gcc (Debian 10.2.1-6) 10.2.1 20210110
  You are using:           gcc (Debian 14.2.0-19) 14.2.0
  ```
  - This is harmless, and the code still compiles and runs correctly with this warning
- When running ```bash ls -l /sys/bus/iio/devices/```, we saw the output:
  ```text
  lrwxrwxrwx 1 root root 0 Nov 13 11:44 iio:device2 -> ../../../devices/platform/dht11@19/iio:device2
  lrwxrwxrwx 1 root root 0 Nov 13 11:44 iio:device3 -> ../../../devices/platform/dht11@4/iio:device3
  ```
  - We couldn't tell immediately which device node was correct, so we tried both. For our Pi, device2 was successful
- The dht driver caches a successful read for 2 seconds (`DHT11_DATA_VALID_TIME`). We made our sleep delay slightly greater than this to minimize potential I/O errors
  - Setting the delay to 3 seconds seemed to reduce the number of errors we got
  - We inspected the kernel logs and saw the error message: ```log [40584.163007] dht11 dht11@19: Only 1 signal edges detected```
    - This indicates that the failure comes from the initial handshake, not the checksum stage. This is promising because it points to the hardware or sleep duration being slightly off, not the driver logic itself

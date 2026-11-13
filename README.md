# Lab K: Kernel Modules
Authors: Trevor Swan, Justin Fossum, Trevor Nichols

## Part 1: Blink
The following sequence of commands is used to compile and load the blink kernel module:
```bash
cd /path/to/KernelModules/c
make modules
sudo insmod blink_km.ko
```

This uses the default GPIO 25 and 500 ms period, but you can specify your own with:
```bash
sudo insmod blink_km.ko led_pin=25 blink_period_ms=500
```

Once running, the LED should start blinking immediately, but you can run the following to check execution is proceeding as expected:
```bash
# View kernel logs
dmesg | tail -n 15

# Confirm module is actively loaded
lsmod | grep blink_km

# Verify GPIO sysfs export
ls -l /sys/class/gpio/gpio25
```

The kernel module can then be removed with:
```bash
sudo rmmod blink_km
```
which will safely turn off the LED and deallocate all resources.

## Part 2: DHT11 Sensor
The following commands are used to compile the device tree source into a binary:
```bash
cd /path/to/KernelModules/c
make dtb
```

Next, copy the compiled overlay into the system overlays folder
```bash
sudo cp -p dht11-overlay.dtb /boot/firmware/overlays/
```
Note that this folder may be `/boot/overlays` in older versions. You can check the existence of either with `ls /boot/overlays` (if 'No such file or directory' is seen, use the other path!)

Then, tell the bootloader to load the overlay on boot:
```bash
echo "dtoverlay=dht11,gpiopin=25" | sudo tee -a /boot/firmware/config.txt
```
Similarly, older system versions may have the config file at `/boot/config.txt` (check this with the same `ls` command). Note that you can set the gpiopin above to the BCM pin that you desire to use for the lab.

Next, you should reboot the Pi with `sudo reboot`.

Once rebooted, run the following commands to build the kernel module itself:
```bash
cd /path/to/KernelModules/c
make dht11
```

Now the module can be tested:
```bash
# Check if the kernel auto-loaded the stock dht11 driver
lsmod | grep dht11

# Remove the stock driver if the above command returned a process
sudo rmmod dht11

# Insert the compiled module
sudo insmod dht11.ko

# Verify execution through the kernel logs
dmesg | tail -n 20
```

With the module running, you should be able to observe the device with:
```bash
ls -l /sys/bus/iio/devices/
# You should see iio:device0
```

and you can read individual values with:
```bash
# Temperature (e.g. 21000 = 21.000 °C)
cat /sys/bus/iio/devices/iio:device0/in_temp_input

# Humidity (e.g. 45000 = 45.000 % RH)
cat /sys/bus/iio/devices/iio:device0/in_humidityrelative_input
```

The `read.sh` shell script can be used to automate the process, polling every 2 seconds and printing the data retrieved:
```bash
cd /path/to/KernelModules
chmod +x read.sh
./read.sh
```

Once done, unload the module with:
```bash
sudo rmmod dht11
```

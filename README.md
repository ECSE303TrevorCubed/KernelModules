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

# Part 2: DHT11 Sensor

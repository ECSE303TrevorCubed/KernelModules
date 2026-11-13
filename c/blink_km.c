#include <linux/gpio.h>
#include <linux/init.h>
#include <linux/jiffies.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/timer.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Trevor Swan, Justin Fossum, Trevor Nichols");
MODULE_DESCRIPTION("Autonomous periodic LED blinker kernel module");
MODULE_VERSION("1.0");

static int led_pin = 25;
module_param(led_pin, int, 0644);
MODULE_PARM_DESC(led_pin,
                 "BCM GPIO pin connected to the LED anode (default: 25)");

static int blink_period_ms = 500;
module_param(blink_period_ms, int, 0644);
MODULE_PARM_DESC(blink_period_ms,
                 "Blink period in milliseconds (default: 500)");

static struct timer_list blink_timer;
static int led_state = 0;

static void blink_timer_callback(struct timer_list *t) {
  led_state = !led_state;
  gpio_set_value(led_pin, led_state);
  mod_timer(&blink_timer, jiffies + msecs_to_jiffies(blink_period_ms));
}

static int __init blink_km_init(void) {
  int result = 0;

  // Validate pin number
  if (!gpio_is_valid(led_pin)) {
    printk(KERN_INFO "blink_km: Initialization failed. Invalid LED GPIO.\n");
    return -ENODEV;
  }

  // Request GPIO pin
  result = gpio_request(led_pin, "blink_km_led");
  if (result) {
    printk(KERN_ERR "blink_km: Failed to request GPIO pin %d (err: %d)\n",
           led_pin, result);
    return result;
  }

  // Initialize pin as output with initial low
  result = gpio_direction_output(led_pin, 0);
  if (result) {
    printk(KERN_ERR
           "blink_km: Failed to configure GPIO %d as output (err: %d)\n",
           led_pin, result);
    gpio_free(led_pin);
    return result;
  }

  // Make LED GPIO visible in /sys/class/gpio with direction fixed
  gpio_export(led_pin, 0);

  // Configure the timer
  timer_setup(&blink_timer, blink_timer_callback, 0);
  result = mod_timer(&blink_timer, jiffies + msecs_to_jiffies(blink_period_ms));
  if (result) {
    printk(KERN_ERR "blink_km: Failed to arm kernel timer (err: %d)\n", result);
    gpio_set_value(led_pin, 0);
    gpio_unexport(led_pin);
    gpio_free(led_pin);
    return result;
  }

  printk(KERN_INFO "blink_km: Initialized on GPIO %d, period %d ms\n", LED_PIN,
         blink_period_ms);
  return result;
}

static void __exit blink_km_exit(void) {
  // Release timer and block until in flight cb completes
  del_timer_sync(&blink_timer);

  // Turn off LED and release resources
  gpio_set_value(led_pin, 0);
  gpio_unexport(led_pin);
  gpio_free(led_pin);

  printk(KERN_INFO "blink_km: Module unloaded and GPIO %d released\n", led_pin);
}

module_init(blink_km_init);
module_exit(blink_km_exit);

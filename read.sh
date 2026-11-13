#!/bin/sh
while true; do 
  echo -n "$(date '+%H:%M:%S') - Temp: "
  cat /sys/bus/iio/devices/iio:device2/in_temp_input
  echo -n "$(date '+%H:%M:%S') - Humidity: "
  cat /sys/bus/iio/devices/iio:device2/in_humidityrelative_input
  sleep 2
done
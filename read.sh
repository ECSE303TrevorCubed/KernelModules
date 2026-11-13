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

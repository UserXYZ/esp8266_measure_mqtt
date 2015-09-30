# [esp8266_measure_mqtt](https://github.com/UserXYZ/esp8266_measure_mqtt)

Very simple measuring and reporting station based witten in Lua for the ESP8266 running the NodeMCU firmware.
Based on [nodemcu-httpserver](https://github.com/marcoskirsch/nodemcu-httpserver) from Marcos Kirsch 

## Features

* Measuring temperature with DS18B20, using reworked out module
* Measuring temperature and humidity with DHT22 using in-built library/API
* Measuring temperature, pressure and altitude using BMP180, using lua module for BMP085 from nodemcu-firmware
* Sending data in JSON format to MQTT server
* Using pieces of code from nodemcu-httpserver for some of the current and mostly future functionality

After data is processed, it is sent to a MQTT server in JSON format, where it is parsed and presented as web page with gauges, dials etc
to a local web browser through Javascript Paho MQTT library.

Freeboard and ThingStudio are used for generating dashboards an presenting them in the browser.

## Future upgrades

Would use some parts of nodemcu-httpserver code to make my own http server with basic authentication for configuring the whole thing,
adding knobs for turning specific measurings on or off etc.
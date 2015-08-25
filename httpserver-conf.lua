-- httpserver-conf.lua
-- Part of nodemcu-httpserver, contains static configuration for httpserver.
-- Author: Sam Dieck
local conf = {}

-- Basic Authentication Conf
local auth = {}
auth.enabled = true
-- auth.enabled = false
auth.realm = "NodeMCU http server"
-- displayed in the login dialog users get
auth.user = "admin"
auth.password = "admin"
conf.auth = auth

local wlan = {}
-- wifi config etc
wlan.ssid="Mali_Zeka"
wlan.pwd="StaTeBriga123!?"
conf.wlan = wlan

local misc = {}
-- debugging
misc.debug = false
-- measuring rate in seconds, decimal value allowed
misc.wait = 5
-- pin on which the sensors are connected
misc.pin = 4
conf.misc = misc

local mqtt = {}
mqtt.clientid = "esp8266_home"
mqtt.secure = false
mqtt.user = ""
mqtt.password = ""
mqtt.broker = "10.20.30.10"
mqtt.port = 9001
mqtt.topic = esp8266
conf.mqtt = mqtt

return conf

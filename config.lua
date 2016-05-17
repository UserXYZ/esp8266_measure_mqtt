local conf = {}
-- Basic Authentication Conf
local auth = {}
auth.enabled = true
auth.realm = "NodeMCU http server"
-- displayed in the login dialog users get
auth.user = "admin"
auth.password = "admin"
conf.auth = auth
-- wifi config etc
local wlan = {}
wlan.ssid="Mali_Zeka"
wlan.pwd="StaTeBriga123!?"
conf.wlan = wlan
-- debugging and miscellaneous, sensors pins also
local misc = {}
misc.debug = false
misc.delay = 60 -- data sending period
misc.ntpsleep = 600 -- ntp sync period
misc.zone = "Europe/Belgrade" -- time zonename
misc.timezonedb_key = "0ZDSLL4QJS5I" -- timezonedb.com API key
misc.status = false
misc.sw_pin = 1 -- pin for the switch
misc.use_display = false -- use display or not
-- display is defined and configured in the appropriate module file
conf.misc = misc
-- sensors
local sens = {}
-- DS18B20 temperature measurement sensor
sens.ds_enable = false
sens.ds_pin = 4 -- pin on which the sensors are connected
sens.ds_wait = 60 -- measuring rate in seconds
-- DHT22 temperature and humidity sensor
sens.dht_enable = true
sens.dht_pin = 4 -- pin on which the sensor is connected
sens.dht_wait = 60 -- measuring rate in seconds
-- BMP180 temperature and pressure sensor
sens.bmp_enable = true
sens.bmp_sda = 5 -- I2C sda pin
sens.bmp_scl = 6 -- I2C scl pin
sens.bmp_wait = 60 -- measuring rate in seconds
conf.sens = sens
-- mqtt settings
local mqtt = {}
mqtt.use = true -- use mqtt or other method
mqtt.clientid = "NOC"
mqtt.secure = false
mqtt.user = "guest"
mqtt.password = "guest"
--mqtt.broker = "mqtt.thingstud.io"
mqtt.broker = "ubudev.yu.net"
mqtt.port = 1883
mqtt.topic = "/Confuzed/esp8266/work" -- post topic
mqtt.rtopic = "/Confuzed/esp8266/work/todo" -- receive topic
conf.mqtt = mqtt
-- emoncms settings
local emon = {}
emon.use = false -- use emoncms or other method
emon.node = 1 -- node id
emon.server = "www.confuzed.in.rs"
emon.path = "/emoncms9/input/post.json"
emon.apikey = "81ec4aa2e02963e5c1c770ca1c204b83"
conf.emon = emon
-- end
return conf

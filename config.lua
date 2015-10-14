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
conf.misc = misc
-- sensors
local sens = {}
-- DS18B20 temperature measurement sensor
sens.ds_enable = false
sens.ds_pin = 4 -- pin on which the sensors are connected
sens.ds_wait = 5 -- measuring rate in seconds, decimal value allowed
-- DHT22 temperature and humidity sensor
sens.dht_enable = true
sens.dht_pin = 4 -- pin on which the sensor is connected
sens.dht_wait = 5 -- measuring rate in seconds, decimal value allowed
-- BMP180 temperature and pressure sensor
sens.bpm_enable = true
sens.bmp_sda = 5 -- I2C sda pin
sens.bmp_scl = 6 -- I2C scl pin
sens.dht_wait = 5 -- measuring rate in seconds, decimal value allowed
conf.sens = sens
-- mqtt settings
local mqtt = {}
mqtt.clientid = "NOC"
mqtt.secure = true
mqtt.user = "guest"
mqtt.password = "guest"
--mqtt.broker = "broker.mqttdashboard.com"
mqtt.broker = "mqtt.thingstud.io"
mqtt.port = 9001
mqtt.topic = "/Confuzed/work" -- post topic
mqtt.rtopic = "/Confuzed/work/todo" -- receive topic
mqtt.delay = 60
conf.mqtt = mqtt
-- end
return conf

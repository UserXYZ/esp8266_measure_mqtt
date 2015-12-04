local conf = require("config")

local function debounce()
	tmr.alarm(0, 50, 0, function()
		if gpio.read(conf.misc.sw_pin) == 0 then
			print("button pressed")
			if conf.mqtt.use then -- send to mqtt broker
				mq.msgSend(client, conf.mqtt.topic, cjson.encode("led_on"))
			end
		end
    end)
end

gpio.mode(conf.misc.sw_pin, gpio.INT, gpio.PULLUP)
tmr.wdclr()
gpio.trig(conf.misc.sw_pin, "both", debounce)

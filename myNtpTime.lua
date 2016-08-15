local M = {}

local conf = require("config")
if conf.display.use then
    display = require("display")
end

local function getTime(tz)
    local t, h, m, s
    t = rtctime.get()
    if t ~= 0 then
        t = t + tz*3600
        h = t % 86400 / 3600
        m = t % 3600 / 60
        s = t % 60
        return string.format("%02d:%02d:%02d", h, m, s)
    else
        return nil
    end
end

local function sync(ntpsrv,tz,cb)
    sntp.sync(ntpsrv,
    function()
        if tz then
            cb(getTime(tz))
        end
    end,
    function()
	local msg="NTP sync failed!"
        print(msg)
        if conf.disp.use then
		    display.disp_stat(msg)
	    end
        cb(nil)
    end)
end
-- export functions
M = { getTime = getTime, sync = sync }
return M

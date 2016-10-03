local M = {}

local conf = require("config")

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
        printout("NTP sync failed!", 2)
        cb(nil)
    end)
end
-- export functions
M = { getTime = getTime, sync = sync }
return M

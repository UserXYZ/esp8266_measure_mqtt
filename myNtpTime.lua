local M
 
local function resolveIP(host,cb)
    local conn=net.createConnection(net.TCP, 0)
    conn:dns(tostring(host),function(conn,ip)
        if ip then
            cb(ip)
        else
            print("DNS query failed for "..host)
            cb(nil)
        end
    end)
    conn = nil
    collectgarbage("collect")
end

local function getTime(tz)
    local t, h, m, s
    t = rtctime.get() + tz*3600
    h = t % 86400 / 3600
    m = t % 3600 / 60
    s = t % 60
    return string.format("%02d:%02d:%02d", h, m, s)
end

local function sync(ntpsrv)
    sntp.sync(ntpsrv,
    function() end,
    function()
        print('NTP sync failed!')
    end
)
end

-- export functions
M = { resolveIP = resolveIP, getTime = getTime, sync = sync }
return M

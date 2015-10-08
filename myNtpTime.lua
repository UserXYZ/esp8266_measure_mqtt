local M

local function resolveIP(fqdn)
    local ipaddr
    sk=net.createConnection(net.TCP, 0)
    sk:dns(tostring(fqdn),function(conn,ip) ipaddr=tostring(ip) end)
    sk = nil
    return ipaddr
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
    sntp.sync(resolveIP(ntpsrv),
    function() end,
    function()
        print('NTP sync failed!')
    end
)
end

-- export functions
M = { resolveIP = resolveIP, getTime = getTime, sync = sync }
return M
local M = {}

local conf = require("config")

local function resolveIP(host,cb)
    local conn=net.createConnection(net.TCP, 0)
    conn:dns(tostring(host),function(conn,ip)
        if ip then
            cb(ip)
        else
            printout("DNS query failed for "..host, 2)
            cb(nil)
        end
        conn:close()
        conn = nil
        collectgarbage()
    end)
end
-- export functions
M = { resolveIP = resolveIP }
return M

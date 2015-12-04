local M = {}

local function resolveIP(host,cb)
    local conn=net.createConnection(net.TCP, 0)
    conn:dns(tostring(host),function(conn,ip)
        if ip then
            cb(ip)
        else
            print("DNS query failed for "..host)
            cb(nil)
        end
        conn = nil
        collectgarbage("collect")
    end)
end
-- export functions
M = { resolveIP = resolveIP }
return M

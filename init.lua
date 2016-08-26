function abortInit()
    -- initailize abort boolean flag
    abort = false
    print("Press ENTER within 5s to abort startup")
    -- if <CR> is pressed, call abortTest
    uart.on("data", "\r", abortTest, 0)
    -- start timer to execute startup function in 5 seconds
    tmr.alarm(2, 5000, tmr.ALARM_SINGLE, startup)
    end
    
function abortTest(data)
    -- user requested abort
    abort = true
    -- turns off uart scanning
    uart.on("data")
end

function startup()
    uart.on("data") -- if user requested abort, exit
    if abort == true then
        print("Startup aborted")
        return
    end
    -- otherwise, start up
    tmr.unregister(2)
    print("Starting main program")
    dofile("startup.lc")
end

tmr.alarm(2, 1000, tmr.ALARM_SINGLE, abortInit) -- call abortInit after 1s

-- prepare files
local compileAndRemoveIfNeeded = function(f)
    if file.open(f) then
	    file.close()
	    print('Compiling:', f)
	    node.compile(f)
	    file.remove(f)
	    collectgarbage()
    end
end
-- main()
local serverFiles = {'dns.lua', 'telnet.lua', 'main3.lua', 'message3.lua', 'myds3.lua', 'myNtpTime.lua', 'getDST.lua', 'myemoncms.lua', 'button.lua', 'ds1307.lua', 'startup.lua', 'display2.lua', 'display_drv.lua'}

function abortTest(data)
    -- user requested abort
    abort = true
    -- turns off uart scanning
    uart.on("data")
end

function abortInit()
    -- initailize abort boolean flag
    abort = false
    print("Press 'q' within 5s to abort startup")
    -- if <CR> is pressed, call abortTest
    uart.on("data", "q", abortTest, 0)
    -- start timer to execute startup function in 5 seconds
    tmr.alarm(2, 5000, tmr.ALARM_SINGLE, startup)
end

function startup()
    uart.on("data") -- if user requested abort, exit
    if abort == true then
        print("Startup aborted")
        return
    end
    -- otherwise, start up
    tmr.unregister(2)
    -- compile files
    for i, f in ipairs(serverFiles) do
	    compileAndRemoveIfNeeded(f)
    end

    compileAndRemoveIfNeeded = nil
    serverFiles = nil
    collectgarbage()
    -- start now
    if file.exists("config.lua") then
	    print("Starting main program")
	    dofile("startup.lc")
    else
	    print("No config file, aborting!")
	    return
    end
end

tmr.alarm(2, 1000, tmr.ALARM_SINGLE, abortInit) -- call abortInit after 1s

local M = {}
local d = nil
local conf = require("config")

local function setup()
    if string.lower(conf.display.conn) == "i2c" then
        if i2c.setup(0, conf.display.i2c_sda, conf.display.i2c_scl, i2c.SLOW) ~= 0 then
            if conf.display.type == "sh1106" then
                d = u8g.sh1106_128x64_i2c(conf.display.i2c_addr)
            elseif conf.display.type == "ssd1306" then
                d = u8g.ssd1306_128x64_i2c(conf.display.i2c_addr)
            else -- display type not known
                return nil
            end
            return d
        else -- i2c setup failed
            return nil
        end
    --elseif string.lower(conf.display.conn) ~= "spi" then
    --    spi.setup(1, spi.MASTER, spi.CPOL_LOW, spi.CPHA_LOW, 8, 8)
    --    disp = u8g.pcd8544_84x48_hw_spi(conf.display.spi_cs, dc, res)
    --    display.setup(conf.display.spi_miso, conf.display.spi_mosi, conf.display.spi_cs, conf.display.spi_clk)
    else -- not i2c nor spi display connection
        print("Wrong type of display selected")
        return nil
    end
end

-- Return module table
M = {
    setup = setup,
}
return M

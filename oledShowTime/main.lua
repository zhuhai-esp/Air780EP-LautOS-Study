-- ============================================================
-- 模块功能：基于I2C直接驱动SSD1306显示实时时钟
-- 屏幕分辨率：128x64，I2C地址：0x3C
-- 显示布局：第1行显示时间HH:MM:SS，第2行显示日期YYYY-MM-DD
-- ============================================================

PROJECT = "lbsLoc2demo"
VERSION = "1.0.0"

log.info("main", PROJECT, VERSION)

sys = require("sys")
local lbsLoc2 = require("lbsLoc2")
local unpack = table.unpack or unpack

-- ============================================================
-- 1. 硬件配置
-- ============================================================
local SCL_PIN = 30
local SDA_PIN = 29
local I2C_ADDR = 0x3C

-- ============================================================
-- 2. 创建软件I2C对象
-- ============================================================
local soft_i2c = i2c.createSoft(SCL_PIN, SDA_PIN, 5)
if not soft_i2c then
    log.error("SSD1306", "软件I2C创建失败")
    return
end

-- ============================================================
-- 3. SSD1306底层通信
-- 关键修复：控制字节0x00后只能跟一个命令，必须逐条发送
-- ============================================================

-- 发送单条命令
local function send_cmd(cmd)
    -- 0x00 = Co=0, D/C#=0，表示后续字节为命令
    i2c.send(soft_i2c, I2C_ADDR, string.char(0x00, cmd))
end

-- 发送数据流（显示数据）
-- 0x40 = Co=0, D/C#=1，表示后续字节全部为显示数据
local function send_data(data_bytes)
    i2c.send(soft_i2c, I2C_ADDR, string.char(0x40) .. data_bytes)
end

-- ============================================================
-- 4. SSD1306初始化
-- ============================================================
local function init_ssd1306()
    local cmds = {
        0xAE,       -- 关闭显示
        0xD5, 0x80, -- 设置时钟分频
        0xA8, 0x3F, -- 多路复用率 64
        0xD3, 0x00, -- 显示偏移 0
        0x40,       -- 起始行 0
        0x8D, 0x14, -- 开启电荷泵
        0x20, 0x00, -- 水平寻址模式（关键！）
        0xA1,       -- 列映射翻转
        0xC8,       -- 行扫描方向
        0xDA, 0x12, -- COM引脚配置
        0x81, 0x7F, -- 对比度
        0xD9, 0xF1, -- 预充电周期
        0xDB, 0x40, -- VCOMH电压
        0xA4,       -- 跟随RAM内容
        0xA6,       -- 正常显示（非反色）
        0x2E,       -- 关闭滚动
        0xAF,       -- 开启显示
    }
    for _, v in ipairs(cmds) do
        send_cmd(v)
    end
    log.info("SSD1306", "初始化完成")
end

-- ============================================================
-- 5. 设置显示区域（水平寻址模式下）
-- ============================================================
local function set_window(col_start, col_end, page_start, page_end)
    send_cmd(0x21)          -- 设置列地址
    send_cmd(col_start)
    send_cmd(col_end)
    send_cmd(0x22)          -- 设置页地址
    send_cmd(page_start)
    send_cmd(page_end)
end

-- 清屏（全黑）
local function clear_screen()
    set_window(0, 127, 0, 7)
    local empty = string.rep(string.char(0x00), 1024)
    send_data(empty)
end

-- ============================================================
-- 6. 8×16 数字字模（0-9 和 '-' 和 ':'）
-- 格式：每个字符 8列，数据按页优先排列
--   data[1..8]  = 第0页（上8行）各列字节
--   data[9..16] = 第1页（下8行）各列字节
-- 合计每字符 16 字节
-- ============================================================
-- 使用标准8×16点阵，数码管风格，清晰易读

local font8x16 = {
    -- 字符 '0'
    [0] = {
        0x00,0xE0,0x10,0x08,0x08,0x10,0xE0,0x00,  -- 上半部分
        0x00,0x0F,0x10,0x20,0x20,0x10,0x0F,0x00,  -- 下半部分
    },
    -- 字符 '1'
    [1] = {
        0x00,0x10,0x10,0xF8,0x00,0x00,0x00,0x00,
        0x00,0x20,0x20,0x3F,0x20,0x20,0x00,0x00,
    },
    -- 字符 '2'
    [2] = {
        0x00,0x70,0x08,0x08,0x08,0x88,0x70,0x00,
        0x00,0x30,0x28,0x24,0x22,0x21,0x30,0x00,
    },
    -- 字符 '3'
    [3] = {
        0x00,0x30,0x08,0x88,0x88,0x48,0x30,0x00,
        0x00,0x18,0x20,0x20,0x20,0x11,0x0E,0x00,
    },
    -- 字符 '4'
    [4] = {
        0x00,0x00,0xC0,0x20,0x10,0xF8,0x00,0x00,
        0x00,0x07,0x04,0x24,0x24,0x3F,0x24,0x00,
    },
    -- 字符 '5'
    [5] = {
        0x00,0xF8,0x88,0x88,0x88,0x08,0x08,0x00,
        0x00,0x19,0x21,0x20,0x20,0x11,0x0E,0x00,
    },
    -- 字符 '6'
    [6] = {
        0x00,0xE0,0x10,0x88,0x88,0x18,0x00,0x00,
        0x00,0x0F,0x11,0x20,0x20,0x11,0x0E,0x00,
    },
    -- 字符 '7'
    [7] = {
        0x00,0x38,0x08,0x08,0xC8,0x38,0x08,0x00,
        0x00,0x00,0x00,0x3F,0x00,0x00,0x00,0x00,
    },
    -- 字符 '8'
    [8] = {
        0x00,0x70,0x88,0x08,0x08,0x88,0x70,0x00,
        0x00,0x1C,0x22,0x21,0x21,0x22,0x1C,0x00,
    },
    -- 字符 '9'
    [9] = {
        0x00,0x70,0x88,0x08,0x08,0x88,0x70,0x00,
        0x00,0x00,0x31,0x22,0x22,0x11,0x0F,0x00,
    },
    -- 字符 '-' (index=10)
    [10] = {
        0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
    },
    -- 字符 ':' (index=11)
    [11] = {
        0x00,0x00,0x00,0x60,0x60,0x00,0x00,0x00,
        0x00,0x00,0x00,0x06,0x06,0x00,0x00,0x00,
    },
    -- 字符 '.' (index=12)
    [12] = {
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,0x06,0x06,0x00,0x00,
    },
}

-- ============================================================
-- 7. 绘图函数
-- ============================================================

-- 在指定位置绘制单个8×16字符
-- page: 起始页(0-6)，col: 起始列(0-127)，ch_idx: 字符索引
local function draw_char(page, col, ch_idx)
    local data = font8x16[ch_idx]
    if not data then return end

    -- 写上半部分（第page页）
    set_window(col, col + 7, page, page)
    local top = {}
    for i = 1, 8 do top[i] = data[i] end
    send_data(string.char(unpack(top)))

    -- 写下半部分（第page+1页）
    set_window(col, col + 7, page + 1, page + 1)
    local bot = {}
    for i = 9, 16 do bot[i - 8] = data[i] end
    send_data(string.char(unpack(bot)))
end

local function draw_text(page, col, text)
    for i = 1, #text do
        local ch = text:sub(i, i)
        local idx
        if ch == "-" then
            idx = 10
        elseif ch == ":" then
            idx = 11
        elseif ch == "." then
            idx = 12
        else
            idx = tonumber(ch)
        end
        if idx then
            draw_char(page, col + (i - 1) * 8, idx)
        else
            set_window(col + (i - 1) * 8, col + (i - 1) * 8 + 7, page, page + 1)
            send_data(string.rep(string.char(0x00), 16))
        end
    end
end

-- 缩放字体缓存，用于将8×16字体放大为16×32
local scaled_font_cache = {}

local function make_char_16x32(ch_idx)
    if scaled_font_cache[ch_idx] then
        return scaled_font_cache[ch_idx]
    end
    local src = font8x16[ch_idx]
    if not src then
        return nil
    end

    local page_data = {{}, {}, {}, {}}
    for col = 0, 15 do
        local src_col = math.floor(col / 2)
        local top_byte = src[src_col + 1]
        local bot_byte = src[src_col + 9]
        for row = 0, 31 do
            local src_row = math.floor(row / 2)
            local src_byte = src_row < 8 and top_byte or bot_byte
            local bit = math.floor(src_byte / (2 ^ (src_row % 8))) % 2
            if bit ~= 0 then
                local page = math.floor(row / 8)
                local bit_mask = 2 ^ (row % 8)
                page_data[page + 1][col + 1] = (page_data[page + 1][col + 1] or 0) + bit_mask
            end
        end
    end

    local bytes = {}
    for page = 1, 4 do
        for col = 1, 16 do
            bytes[#bytes + 1] = string.char(page_data[page][col] or 0)
        end
    end
    local result = table.concat(bytes)
    scaled_font_cache[ch_idx] = result
    return result
end

local function make_blank_16x32()
    return string.rep(string.char(0x00), 16 * 4)
end

local function draw_char_16x32(page, col, ch_idx, visible)
    local data
    if visible then
        data = make_char_16x32(ch_idx)
    else
        data = make_blank_16x32()
    end
    if not data then
        return
    end
    set_window(col, col + 15, page, page + 3)
    send_data(data)
end

-- 绘制时间行：22:45:55
-- 使用16×32放大字体，整个宽度为128列，水平居中
local function draw_time_row(hour, minute, second)
    local page = 2  -- 显示在第2~5页（屏幕中间偏下区域）
    local col = 0   -- 放大字体宽度正好占满128列
    local colon_visible = (second % 2) == 0
    local COLON = 11

    local chars = {
        math.floor(hour / 10),   -- H十位
        hour % 10,               -- H个位
        COLON,                   -- :
        math.floor(minute / 10), -- M十位
        minute % 10,             -- M个位
        COLON,                   -- :
        math.floor(second / 10), -- S十位
        second % 10,             -- S个位
    }

    for i, ch in ipairs(chars) do
        local visible = true
        if ch == COLON then
            visible = colon_visible
        end
        draw_char_16x32(page, col + (i - 1) * 16, ch, visible)
    end
end

-- 绘制日期行：YYYY-MM-DD
-- 12字符×8列 = 96列，居中起始列=16
local function draw_date_row(year, month, day)
    local page = 0  -- 显示在第0~1页（屏幕顶部区域）
    local col = 16
    local DASH = 10

    local y1 = math.floor(year / 1000)
    local y2 = math.floor(year / 100) % 10
    local y3 = math.floor(year / 10) % 10
    local y4 = year % 10

    local chars = {
        y1, y2, y3, y4,              -- YYYY
        DASH,                         -- -
        math.floor(month / 10),       -- M十位
        month % 10,                   -- M个位
        DASH,                         -- -
        math.floor(day / 10),         -- D十位
        day % 10,                     -- D个位
    }

    for i, ch in ipairs(chars) do
        draw_char(page, col + (i - 1) * 8, ch)
    end
end

-- ============================================================
-- 8. 主任务
-- ============================================================
sys.taskInit(function()
    log.info("Main", "启动SSD1306实时时钟 v2.0")

    -- 初始化屏幕
    init_ssd1306()
    sys.wait(100)
    clear_screen()
    sys.wait(50)

    -- 备用时间（系统时间无效时使用）
    local fb_year, fb_month, fb_day = 2026, 7, 8
    local fb_hour, fb_min, fb_sec   = 0, 0, 0

    local last_sec = -1
    local location_text = "00.0000-000.0000"

    local function format_location(lat, lng)
        lat = tonumber(lat)
        lng = tonumber(lng)
        if not lat or not lng then
            return location_text
        end
        local lat_sign = ""
        if lat < 0 then
            lat_sign = "-"
            lat = -lat
        end
        local lng_sign = ""
        if lng < 0 then
            lng_sign = "-"
            lng = -lng
        end
        local lat_deg = math.floor(lat)
        local lat_frac = math.floor((lat - lat_deg) * 10000 + 0.5)
        local lng_deg = math.floor(lng)
        local lng_frac = math.floor((lng - lng_deg) * 10000 + 0.5)
        return string.format("%s%02d.%04d-%s%03d.%04d", lat_sign, lat_deg, lat_frac, lng_sign, lng_deg, lng_frac)
    end

    local function draw_location_row(text)
        text = text or location_text
        if #text > 16 then
            text = text:sub(1, 16)
        elseif #text < 16 then
            text = text .. string.rep(" ", 16 - #text)
        end
        draw_text(6, 0, text)
    end

    draw_location_row(location_text)

    if rtos and rtos.bsp and rtos.bsp() == "EC618" and pm and pm.PWK_MODE then
        pm.power(pm.PWK_MODE, false)
    end

    sys.taskInit(function()
        sys.waitUntil("IP_READY", 30000)
        while mobile do -- 没有mobile库就没有基站定位
            mobile.reqCellInfo(15)
            sys.waitUntil("CELL_INFO_UPDATE", 3000)
            local lat, lng, t = lbsLoc2.request(5000)
            if lat and lng then
                location_text = format_location(lat, lng)
                draw_location_row(location_text)
            end
            log.info("lbsLoc2", lat, lng, (json.encode(t or {})))
            sys.wait(10000)
        end
    end)

    while true do
        local year, month, day, hour, minute, second

        local t = os.date("*t")
        if t and t.year and t.year > 2000 then
            year, month, day = t.year, t.month, t.day
            hour, minute, second = t.hour, t.min, t.sec
        else
            -- 系统时间无效：手动递增备用时间
            fb_sec = fb_sec + 1
            if fb_sec >= 60 then fb_sec = 0; fb_min = fb_min + 1 end
            if fb_min >= 60 then fb_min = 0; fb_hour = fb_hour + 1 end
            if fb_hour >= 24 then fb_hour = 0 end
            year, month, day = fb_year, fb_month, fb_day
            hour, minute, second = fb_hour, fb_min, fb_sec
        end

        -- 每秒刷新一次
        if second ~= last_sec then
            draw_time_row(hour, minute, second)
            draw_date_row(year, month, day)
            last_sec = second
            log.info("Clock",
                string.format("%04d-%02d-%02d %02d:%02d:%02d",
                    year, month, day, hour, minute, second))
        end

        sys.wait(100)
    end
end)

-- ============================================================
-- 9. 系统启动
-- ============================================================
sys.run()
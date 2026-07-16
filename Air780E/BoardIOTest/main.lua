-- ============================================================
-- 模块功能：GPIO 测试示例
-- 控制 Air780E 开发板上的 LED 灯和充电控制引脚循环闪烁
-- 用于验证硬件 IO 功能是否正常工作
-- ============================================================

-- LuaTools 需要 PROJECT 和 VERSION 这两个信息
PROJECT = "gpiodemo"
VERSION = "1.0.1"

log.info("main", PROJECT, VERSION)

-- sys 库是 LuatOS 标配，提供任务管理、定时器等核心功能
_G.sys = require("sys")

-- 看门狗配置（防止程序卡死）
-- 在支持看门狗功能的设备上启用此功能
if wdt then
    wdt.init(9000)                    -- 初始化看门狗，超时时间 9 秒
    sys.timerLoopStart(wdt.feed, 3000) -- 每 3 秒喂一次狗，防止超时复位
end

-- 定义 GPIO 引脚映射
-- P1-P4 分别对应：绿色 LED、红色 LED、CCP1、CCP2
local P1, P2, P3, P4 = 27, 26, 25, 29

-- 初始化 GPIO 为输出模式，并配置上拉电阻
-- 参数说明：引脚号, 初始电平(0=低), 模式(GPIO.PULLUP=上拉)
-- 返回值：可调用函数，用于设置引脚电平
local LEDA = gpio.setup(P1, 0, gpio.PULLUP)  -- 绿色 LED
local LEDB = gpio.setup(P2, 0, gpio.PULLUP)  -- 红色 LED
local LEDC = gpio.setup(P3, 0, gpio.PULLUP)  -- CCP1 充电控制引脚
local LEDD = gpio.setup(P4, 0, gpio.PULLUP)  -- CCP2 充电控制引脚

-- 主任务：LED 和 CCP 引脚循环测试
sys.taskInit(function()
    while true do
        -- 第一阶段：红灯亮，绿灯灭（约 4 秒）
        LEDA(0)  -- 绿色 LED 灭（低电平）
        LEDB(1)  -- 红色 LED 亮（高电平）
        LEDC(0)  -- CCP1L = LOW
        LEDD(1)  -- CCP2H = HIGH
        log.info("LuatOS:", "红灯亮，绿灯灭，高电平点亮")
        log.info("LuatOS:", "CCP1L:HIGH,CCP1H:LOW,CCP2L:LOW,CCP2H:HIGH")
        sys.wait(4000)

        -- 第二阶段：红灯灭，绿灯亮（约 2 秒）
        LEDA(1)  -- 绿色 LED 亮（高电平）
        LEDB(0)  -- 红色 LED 灭（低电平）
        LEDC(1)  -- CCP1H = HIGH
        LEDD(0)  -- CCP2L = LOW
        log.info("LuatOS:", "红灯灭，绿灯亮")
        log.info("LuatOS:", "CCP1L:LOW,CCP1H:HIGH,CCP2L:HIGH,CCP2H:LOW")
        sys.wait(2000)
    end
end)

-- 启动系统任务调度器
sys.run()
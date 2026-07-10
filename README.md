# Air780EP-LuatOS-Study

这个仓库用于记录和整理基于 Air780EP / Air780E 4G 模组的 LuatOS 实用程序工程。

项目目标不是只做单个 demo，而是持续沉淀一些可以直接刷入设备运行的小工具、小功能和硬件扩展示例，例如基站定位、OLED 时间显示、联网信息展示等。后续可以按功能逐步增加更多独立工程。

![Air780EP LuatOS 设备](images/Air780EP_LuatOS_2410.jpg)

## 设备说明

- 主要测试设备：电商平台常见的低成本 Air780EP 开发板。
- Air780E 与 Air780EP 的脚本程序大体通用，但需要刷入对应型号的 LuatOS 固件。
- 示例默认使用 LuatOS 脚本开发方式，不使用 AT 指令固件运行 Lua 脚本。

## 当前示例

| 目录 | 功能 | 说明 |
| --- | --- | --- |
| `lbsLoc2/` | 基站定位 | 通过 `mobile` 获取小区信息，并使用 `lbsLoc2` 请求经纬度。 |
| `I2cShowTime/` | OLED 时钟显示 | 使用软件 I2C 直接驱动 SSD1306 OLED，内置简单数字字模，同时显示时间、日期和定位信息。 |
| `U8g2ShowTime/` | OLED 时钟显示 | 使用 LuatOS 内置 `u8g2` 模块驱动 SSD1306，代码更简洁，但要求固件包含 `u8g2` 库。 |

## 快速开始

1. 准备 Air780EP / Air780E 设备、USB 数据线和可用 SIM 卡。
2. 使用 Luatools 给设备刷入对应型号的 LuatOS 固件。
3. 在 Luatools 中选择需要运行的示例目录，例如 `lbsLoc2/main.lua`。
4. 下载脚本到设备并查看串口日志。
5. 如果运行 OLED 示例，先按下方接线连接 SSD1306 OLED 屏幕。

## 烧录和固件

- Luatools 下载和使用说明：https://docs.openluat.com/common/Luatools/
- Air780EP LuatOS 固件：https://docs.openluat.com/air780ep/luatos/firmware/
- 注意：如果要运行 `U8g2ShowTime`，请确认固件包含 `u8g2` 模块。很多精简固件为了减小体积不会内置该模块。
- 示例固件 [LuatOS-SoC_V2026_Air780EP](https://cdn6.vue2.cn/Luat_tool_src/v2tools/LuatOS_Air780EP/LuatOS-SoC_V2026_Air780EP_1.zip) 不带 `u8g2`，可优先使用 `I2cShowTime` 示例。

## OLED 扩展

示例使用 128x64 分辨率、I2C 地址为 `0x3C` 的 SSD1306 OLED 屏幕。

### 接线

| OLED | Air780EP |
| --- | --- |
| VCC | 3.3V |
| GND | GND |
| SCL | GPIO 30 |
| SDA | GPIO 29 |

### 驱动方式

- 直接 I2C 驱动：对应 `I2cShowTime`，不依赖 `u8g2` 固件模块，兼容性更好；缺点是需要自己处理初始化命令、显存数据和字模。
- U8g2 驱动：对应 `U8g2ShowTime`，绘图 API 更好用，适合继续扩展复杂 UI；缺点是必须使用带 `u8g2` 模块的固件。

## 官方资料

1. Air780EP 说明：https://docs.openluat.com/air780ep/
2. AT 固件说明：https://docs.openluat.com/air780ep/at/app/at_command/
3. LuatOS 脚本开发：https://docs.openluat.com/air780ep/luatos/app/
4. LuatOS 官方教程：https://docs.openluat.com/luatos_lesson/

## 参考视频

- https://www.bilibili.com/video/BV161ML6KE46/
- https://www.bilibili.com/video/BV1g4nTz6EAM/

## 后续计划

- 增加更多可直接使用的小程序示例。
- 整理常用外设接线和驱动说明。
- 补充常见问题，例如刷机、联网、定位失败、固件模块缺失等。

#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

echo "开始注入 CLX S20M 设备适配代码..."

# 1. 自动生成 mt7986a-clx-s20m.dts 文件
cat << 'EOF' > target/linux/mediatek/dts/mt7986a-clx-s20m.dts
// SPDX-License-Identifier: GPL-2.0-or-later OR MIT

/dts-v1/;
#include <dt-bindings/gpio/gpio.h>
#include <dt-bindings/input/input.h>
#include <dt-bindings/leds/common.h>

#include "mt7986a.dtsi"

/ {
	model = "CLX S20M";
	compatible = "clx,s20m", "mediatek,mt7986a";

	aliases {
		serial0 = &uart0;
		led-boot = &sys_led;
		led-failsafe = &sys_led;
		led-running = &sys_led;
		led-upgrade = &sys_led;
	};

	chosen {
		stdout-path = "serial0:115200n8";
		bootargs-append = " root=PARTLABEL=rootfs rootwait";
	};

	memory {
		reg = <0 0x40000000 0 0x80000000>;
	};

	gpio-keys {
		compatible = "gpio-keys";

		reset {
			label = "reset";
			linux,code = <KEY_RESTART>;
			gpios = <&pio 16 GPIO_ACTIVE_LOW>;
		};
	};

	gpio-leds {
		compatible = "gpio-leds";

		sys_led: system {
			function = LED_FUNCTION_STATUS;
			color = <LED_COLOR_ID_BLUE>;
			gpios = <&pio 22 GPIO_ACTIVE_LOW>;
			default-state = "on";
		};
	};

	reg_1p8v: regulator-1p8v {
		compatible = "regulator-fixed";
		regulator-name = "fixed-1.8V";
		regulator-min-microvolt = <1800000>;
		regulator-max-microvolt = <1800000>;
		regulator-boot-on;
		regulator-always-on;
	};

	reg_3p3v: regulator-3p3v {
		compatible = "regulator-fixed";
		regulator-name = "fixed-3.3V";
		regulator-min-microvolt = <3300000>;
		regulator-max-microvolt = <3300000>;
		regulator-boot-on;
		regulator-always-on;
	};

	usb_vbus: regulator-usb-vbus {
		compatible = "regulator-fixed";
		regulator-name = "usb_vbus";
		regulator-min-microvolt = <5000000>;
		regulator-max-microvolt = <5000000>;
		gpios = <&pio 24 GPIO_ACTIVE_HIGH>;
		enable-active-high;
		regulator-boot-on;
	};
};

&uart0 {
	status = "okay";
};

&watchdog {
	status = "okay";
};

&eth {
	status = "okay";

	gmac0: mac@0 {
		compatible = "mediatek,eth-mac";
		reg = <0>;
		phy-mode = "2500base-x";

		fixed-link {
			speed = <2500>;
			full-duplex;
			pause;
		};
	};

	mdio: mdio-bus {
		#address-cells = <1>;
		#size-cells = <0>;

		switch@31 {
			compatible = "mediatek,mt7531";
			reg = <31>;
			reset-gpios = <&pio 5 GPIO_ACTIVE_HIGH>;
			interrupt-controller;
			#interrupt-cells = <1>;
			interrupt-parent = <&pio>;
			interrupts = <66 IRQ_TYPE_LEVEL_HIGH>;

			ports {
				#address-cells = <1>;
				#size-cells = <0>;

				port@0 {
					reg = <0>;
					label = "wan";
				};

				port@1 {
					reg = <1>;
					label = "lan4";
				};

				port@2 {
					reg = <2>;
					label = "lan3";
				};

				port@3 {
					reg = <3>;
					label = "lan2";
				};

				port@4 {
					reg = <4>;
					label = "lan1";
				};

				port@6 {
					reg = <6>;
					label = "cpu";
					ethernet = <&gmac0>;
					phy-mode = "2500base-x";

					fixed-link {
						speed = <2500>;
						full-duplex;
						pause;
					};
				};
			};
		};
	};
};

&mmc0 {
	pinctrl-names = "default", "state_uhs";
	pinctrl-0 = <&mmc0_pins_default>;
	pinctrl-1 = <&mmc0_pins_uhs>;
	bus-width = <8>;
	max-frequency = <200000000>;
	cap-mmc-highspeed;
	mmc-hs200-1_8v;
	mmc-hs400-1_8v;
	hs400-ds-delay = <0x14014>;
	vmmc-supply = <&reg_3p3v>;
	vqmmc-supply = <&reg_1p8v>;
	non-removable;
	no-sd;
	no-sdio;
	status = "okay";
};

&pio {
	mmc0_pins_default: mmc0-pins {
		mux {
			function = "emmc";
			groups = "emmc_51";
		};
		conf-cmd-dat {
			pins = "EMMC_DATA_0", "EMMC_DATA_1", "EMMC_DATA_2",
			       "EMMC_DATA_3", "EMMC_DATA_4", "EMMC_DATA_5",
			       "EMMC_DATA_6", "EMMC_DATA_7", "EMMC_CMD";
			input-enable;
			drive-strength = <4>;
			mediatek,pull-up-adv = <1>;
		};
		conf-clk {
			pins = "EMMC_CK";
			drive-strength = <6>;
			mediatek,pull-down-adv = <2>;
		};
		conf-ds {
			pins = "EMMC_DSL";
			mediatek,pull-down-adv = <2>;
		};
		conf-rst {
			pins = "EMMC_RSTB";
			drive-strength = <4>;
			mediatek,pull-up-adv = <1>;
		};
	};

	mmc0_pins_uhs: mmc0-uhs-pins {
		mux {
			function = "emmc";
			groups = "emmc_51";
		};
		conf-cmd-dat {
			pins = "EMMC_DATA_0", "EMMC_DATA_1", "EMMC_DATA_2",
			       "EMMC_DATA_3", "EMMC_DATA_4", "EMMC_DATA_5",
			       "EMMC_DATA_6", "EMMC_DATA_7", "EMMC_CMD";
			input-enable;
			drive-strength = <4>;
			mediatek,pull-up-adv = <1>;
		};
		conf-clk {
			pins = "EMMC_CK";
			drive-strength = <6>;
			mediatek,pull-down-adv = <2>;
		};
		conf-ds {
			pins = "EMMC_DSL";
			mediatek,pull-down-adv = <2>;
		};
		conf-rst {
			pins = "EMMC_RSTB";
			drive-strength = <4>;
			mediatek,pull-up-adv = <1>;
		};
	};

	/* [新增] PCIe 的引脚定义 */
	pcie_pins: pcie-pins {
		mux {
			function = "pcie";
			groups = "pcie_clk", "pcie_wake", "pcie_pereset";
		};
	};
};

/* [新增] 激活 PCIe MAC 接口 */
&pcie {
	pinctrl-names = "default";
	pinctrl-0 = <&pcie_pins>;
	status = "okay";
};

/* [新增] 激活 PCIe PHY 物理层 */
&pcie_phy {
	status = "okay";
};

/* [确认] 彻底禁用 WiFi */
&wifi {
	status = "disabled";
};

&usb_phy {
	status = "okay";
};

&ssusb {
	vusb33-supply = <&reg_3p3v>;
	vbus-supply = <&usb_vbus>;
	status = "okay";
};

&crypto {
	status = "okay";
};

&trng {
	status = "okay";
};
EOF

# 2. 将设备配置追加到 filogic.mk
cat << 'EOF' >> target/linux/mediatek/image/filogic.mk

define Device/clx_s20m
  DEVICE_VENDOR := CLX
  DEVICE_MODEL := S20M
  DEVICE_DTS := mt7986a-clx-s20m
  DEVICE_PACKAGES := kmod-usb3 kmod-usb-xhci-mtk
endef
TARGET_DEVICES += clx_s20m
EOF

echo "CLX S20M 适配代码注入完成！"

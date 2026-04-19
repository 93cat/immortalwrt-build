#!/bin/bash
#
# OpenWrt DIY script part 2 (After Update feeds)
#

echo "开始执行自定义脚本 (清理旧包 & 注入新包)..."

# 0. 修复 ImmortalWrt 24.10 上游昨天的 Typo Bug
# =========================================================
sed -i 's/mt7981b.dtsi/mt7981.dtsi/g' target/linux/mediatek/dts/mt7981b-zbtlink*.dtsi 2>/dev/null || true

# =========================================================
# 1. 升级 Golang 到 1.25.x (适配最新 Sing-box)
# =========================================================
echo "正在抹除旧版 Golang 并注入 Go 1.25.x 环境..."
rm -rf feeds/packages/lang/golang
git clone https://github.com/kenzok8/golang -b 1.25 feeds/packages/lang/golang

# =========================================================
# 2. 暴力清理旧版 Passwall 及其核心依赖，彻底杜绝冲突！
# =========================================================
echo "正在清理官方 feeds 中的旧版 Passwall 依赖..."
rm -rf feeds/luci/applications/luci-app-passwall
rm -rf feeds/packages/net/passwall
rm -rf feeds/packages/net/haproxy
rm -rf feeds/packages/net/xray-core
rm -rf feeds/packages/net/xray-plugin
rm -rf feeds/packages/net/sing-box

# =========================================================
# 3. 从官方最新仓库拉取代码到最高优先级的 package/ 目录
# =========================================================
echo "正在拉取最新版 Passwall 源码..."
git clone --depth=1 https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git package/openwrt-passwall-packages
git clone --depth=1 https://github.com/Openwrt-Passwall/openwrt-passwall.git package/openwrt-passwall

# =========================================================
# 4. 生成基于 6.6 内核规范的 mt7986a-clx-s20m.dts 文件
#    (采用最严谨的 files-6.6 版本专属目录注入 + 传统目录双备份机制)
# =========================================================
echo "正在注入 S20M 设备树文件 (files-6.6 机制)..."

mkdir -p target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek/
mkdir -p target/linux/mediatek/dts/

cat << 'EOF' > target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek/mt7986a-clx-s20m.dts
/dts-v1/;
#include "mt7986a.dtsi"
#include <dt-bindings/gpio/gpio.h>
#include <dt-bindings/input/input.h>
#include <dt-bindings/leds/common.h>

/ {
	model = "CLX S20M";
	compatible = "clx,s20m", "mediatek,mt7986a";

	aliases {
		serial0 = &uart0;
		led-boot = &led_system;
		led-failsafe = &led_system;
		led-running = &led_system;
		led-upgrade = &led_system;
	};

	chosen {
		stdout-path = "serial0:115200n8";
		bootargs = "console=ttyS0,115200n1 loglevel=8 earlycon=uart8250,mmio32,0x11002000 root=PARTLABEL=rootfs rootwait";
	};

	keys {
		compatible = "gpio-keys";
		button-reset {
			label = "reset";
			linux,code = <KEY_RESTART>;
			gpios = <&pio 16 GPIO_ACTIVE_LOW>;
		};
	};

	leds {
		compatible = "gpio-leds";
		led_system: system {
			label = "blue:system";
			color = <LED_COLOR_ID_BLUE>;
			function = LED_FUNCTION_STATUS;
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

&crypto { status = "okay"; };

&pio {
	pcie_pins: pcie-pins {
		mux { function = "pcie"; groups = "pcie_pereset"; };
	};
};

&pcie {
	pinctrl-names = "default";
	pinctrl-0 = <&pcie_pins>;
	status = "okay";
};

&pcie_phy { status = "okay"; };
&uart0 { status = "okay"; };
&usb_phy { status = "okay"; };

&ssusb {
	vusb33-supply = <&reg_3p3v>;
	vbus-supply = <&usb_vbus>;
	status = "okay";
};

&wifi { status = "disabled"; };

&eth {
	status = "okay";
	gmac0: mac@0 {
		compatible = "mediatek,eth-mac";
		reg = <0>;
		phy-mode = "2500base-x";
		fixed-link { speed = <2500>; full-duplex; pause; };
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
				port@0 { reg = <0>; label = "wan"; };
				port@1 { reg = <1>; label = "lan4"; };
				port@2 { reg = <2>; label = "lan3"; };
				port@3 { reg = <3>; label = "lan2"; };
				port@4 { reg = <4>; label = "lan1"; };
				port@6 {
					reg = <6>; label = "cpu"; ethernet = <&gmac0>;
					phy-mode = "2500base-x";
					fixed-link { speed = <2500>; full-duplex; pause; };
				};
			};
		};
	};
};
EOF

# 同步复制一份到传统目录，防止 Makefile 降级寻找
cp target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek/mt7986a-clx-s20m.dts target/linux/mediatek/dts/mt7986a-clx-s20m.dts

# 2. 将设备配置追加到对应的 mk 文件 (带防重复检查)
if ! grep -q "define Device/clx_s20m" target/linux/mediatek/image/filogic.mk; then
cat << 'EOF' >> target/linux/mediatek/image/filogic.mk

define Device/clx_s20m
  DEVICE_VENDOR := CLX
  DEVICE_MODEL := S20M
  DEVICE_DTS := mt7986a-clx-s20m
  DEVICE_PACKAGES := kmod-usb3 kmod-usb-xhci-mtk kmod-nvme
  IMAGES := sysupgrade.itb
endef
TARGET_DEVICES += clx_s20m
EOF
  echo "CLX S20M 适配代码追加成功！"
else
  echo "警告：检测到 filogic.mk 中已存在 CLX S20M 配置，跳过追加以防止重复。"
fi

echo "diy-part2.sh 执行完毕！祝编译顺利！"

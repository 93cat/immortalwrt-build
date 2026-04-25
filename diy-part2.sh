#!/bin/bash
#
# OpenWrt DIY script part 2 (After Update feeds)
#

echo "开始执行自定义脚本 (清理旧包 & 注入新包)..."

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
#    (采用最严谨的 files-6.6 机制，包含全套硬件加速节点)
# =========================================================
echo "正在注入 S20M 设备树文件 (files-6.6 机制)..."

mkdir -p target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek/
mkdir -p target/linux/mediatek/dts/

cat << 'EOF' > target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek/mt7986a-clx-s20m.dts
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
		bootargs-append = " root=PARTLABEL=rootfs rootwait rootfstype=squashfs,f2fs";
	};

	memory {
		reg = <0 0x40000000 0 0x80000000>;
	};

	gpio-keys {
		compatible = "gpio-keys";

		button-reset {
			label = "reset";
			linux,code = <KEY_RESTART>;
			gpios = <&pio 16 GPIO_ACTIVE_LOW>;
		};
	};

	gpio-leds {
		compatible = "gpio-leds";

		sys_led: sys-led {
			color = <LED_COLOR_ID_BLUE>;
			function = LED_FUNCTION_STATUS;
			gpios = <&pio 22 GPIO_ACTIVE_LOW>;
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
		gpios = <&pio 17 GPIO_ACTIVE_HIGH>;
		enable-active-high;
		regulator-boot-on;
	};
};

&eth {
	status = "okay";

	gmac0: mac@0 {
		compatible = "mediatek,eth-mac";
		reg = <0>;
		phy-mode = "2500base-x";
		nvmem-cells = <&macaddr_factory_2a 0>;
		nvmem-cell-names = "mac-address";

		fixed-link {
			speed = <2500>;
			full-duplex;
			pause;
		};
	};

	mdio: mdio-bus {
		#address-cells = <1>;
		#size-cells = <0>;

		switch: switch@1f {
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

					nvmem-cells = <&macaddr_factory_24 0>;
					nvmem-cell-names = "mac-address";
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

	card@0 {
		compatible = "mmc-card";
		reg = <0>;

		block {
			compatible = "block-device";

			partitions {
				block-partition-factory {
					partname = "factory";

					nvmem-layout {
						compatible = "fixed-layout";
						#address-cells = <1>;
						#size-cells = <1>;

						eeprom_factory_0: eeprom@0 {
							reg = <0x0 0x1000>;
						};

						macaddr_factory_4: macaddr@4 {
							compatible = "mac-base";
							reg = <0x4 0x6>;
							#nvmem-cell-cells = <1>;
						};

						macaddr_factory_24: macaddr@24 {
							compatible = "mac-base";
							reg = <0x24 0x6>;
							#nvmem-cell-cells = <1>;
						};

						macaddr_factory_2a: macaddr@2a {
							compatible = "mac-base";
							reg = <0x2a 0x6>;
							#nvmem-cell-cells = <1>;
						};

						macaddr_factory_30: macaddr@30 {
							compatible = "mac-base";
							reg = <0x30 0x6>;
							#nvmem-cell-cells = <1>;
						};
					};
				};
			};
		};
	};
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
			mediatek,pull-up-adv = <1>;	/* pull-up 10K */
		};

		conf-clk {
			pins = "EMMC_CK";
			drive-strength = <6>;
			mediatek,pull-down-adv = <2>;	/* pull-down 50K */
		};

		conf-ds {
			pins = "EMMC_DSL";
			mediatek,pull-down-adv = <2>;	/* pull-down 50K */
		};

		conf-rst {
			pins = "EMMC_RSTB";
			drive-strength = <4>;
			mediatek,pull-up-adv = <1>;	/* pull-up 10K */
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
			mediatek,pull-up-adv = <1>;	/* pull-up 10K */
		};

		conf-clk {
			pins = "EMMC_CK";
			drive-strength = <6>;
			mediatek,pull-down-adv = <2>;	/* pull-down 50K */
		};

		conf-ds {
			pins = "EMMC_DSL";
			mediatek,pull-down-adv = <2>;	/* pull-down 50K */
		};

		conf-rst {
			pins = "EMMC_RSTB";
			drive-strength = <4>;
			mediatek,pull-up-adv = <1>;	/* pull-up 10K */
		};
	};

	pcie_pins: pcie-pins {
		mux {
			function = "pcie";
			groups = "pcie_pereset";
		};
	};
};

&ssusb {
	vusb33-supply = <&reg_3p3v>;
	vbus-supply = <&usb_vbus>;
	status = "okay";
};

&pcie {
	pinctrl-names = "default";
	pinctrl-0 = <&pcie_pins>;
	status = "okay";
};

&usb_phy {
	status = "okay";
};

&pcie_phy {
	status = "okay";
};

&crypto {
	status = "okay";
};

&trng {
	status = "okay";
};

&uart0 {
	status = "okay";
};

&watchdog {
	status = "okay";
};

&wifi {
	status = "disabled";
};
EOF

# 同步复制一份到传统目录，防止 Makefile 降级寻找
cp target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek/mt7986a-clx-s20m.dts target/linux/mediatek/dts/mt7986a-clx-s20m.dts

# =========================================================
# 5. 将设备配置追加到对应的 mk 文件 (带防重复检查)
# =========================================================
if ! grep -q "define Device/clx_s20m" target/linux/mediatek/image/filogic.mk; then
cat << 'EOF' >> target/linux/mediatek/image/filogic.mk

define Device/clx_s20m
  DEVICE_VENDOR := CLX
  DEVICE_MODEL := S20M
  DEVICE_DTS := mt7986a-clx-s20m
  DEVICE_DTS_DIR := ../dts
  DEVICE_PACKAGES := \
    kmod-usb3 kmod-usb-xhci-mtk \
    kmod-nvme \
    kmod-crypto-mtk \
    block-mount automount \
    kmod-fs-ext4 kmod-fs-exfat kmod-fs-ntfs3 kmod-fs-f2fs f2fs-tools
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += clx_s20m
EOF
  echo "CLX S20M 适配代码追加成功！"
else
  echo "警告：检测到 filogic.mk 中已存在 CLX S20M 配置，跳过追加以防止重复。"
fi

# =========================================================
# 6. 在 .config 中显式移除 WiFi 驱动及无线工具（确保纯有线网关无残留）
# =========================================================
echo "正在配置 .config，移除 WiFi 相关包..."

# 确保 .config 文件存在（通常已经由 cp 命令生成）
if [ -f .config ]; then
    # 要移除的包列表（开源 WiFi 驱动 + 无线工具）
    REMOVE_PKGS="-kmod-mt76 -kmod-mt76-connac -kmod-mt76-core -kmod-mt7915e -kmod-mt7915-firmware -kmod-mt7916-firmware -kmod-mt7986-firmware -mt7986-wo-firmware -wpad-openssl -wireless-tools -wifi-scripts -iwinfo -zram-swap"

    # 删除可能存在的旧行
    sed -i '/CONFIG_TARGET_DEVICE_PACKAGES_mediatek_filogic_DEVICE_clx_s20m=/d' .config

    # 追加新的移除行
    echo "CONFIG_TARGET_DEVICE_PACKAGES_mediatek_filogic_DEVICE_clx_s20m=\"$REMOVE_PKGS\"" >> .config

    echo "已成功移除 WiFi 包配置行，后续 make defconfig 会自动生效。"
else
    echo "警告：.config 文件不存在，跳过 WiFi 包移除配置。"
fi

# =========================================================
# 1. 彻底移除 WiFi 相关源码及配置（适用于纯有线网关）
# =========================================================
echo "正在移除 WiFi 相关源码和配置..."

# 删除 WiFi 驱动源码（内核模块）
rm -rf package/kernel/mt76
#rm -rf package/kernel/mt_wifi
# 不要删除以下用户态工具的源码，仅通过 .config 排除打包
# rm -rf package/network/services/hostapd
# rm -rf package/network/utils/iw
# rm -rf package/network/utils/wireless-tools
# rm -rf package/network/config/wifi-scripts
# rm -rf package/network/utils/iwinfo

# 清理 .config 中所有 WiFi 相关配置项（包括依赖）
sed -i '/CONFIG_PACKAGE_kmod-mt76/d' .config
sed -i '/CONFIG_PACKAGE_kmod-mt7915/d' .config
sed -i '/CONFIG_PACKAGE_kmod-mt7986/d' .config
sed -i '/CONFIG_PACKAGE_mt76/d' .config
sed -i '/CONFIG_PACKAGE_mt_wifi/d' .config
sed -i '/CONFIG_PACKAGE_wpad/d' .config
sed -i '/CONFIG_PACKAGE_hostapd/d' .config
sed -i '/CONFIG_PACKAGE_iw/d' .config
sed -i '/CONFIG_PACKAGE_wireless-tools/d' .config
sed -i '/CONFIG_PACKAGE_wifi-scripts/d' .config
sed -i '/CONFIG_PACKAGE_iwinfo/d' .config
sed -i '/CONFIG_MTK_MT_WIFI/d' .config
sed -i '/CONFIG_MTK_WARP/d' .config

# =========================================================
# 2. 关闭内核调试选项（减小体积，提升性能）
# =========================================================
echo "正在关闭内核调试选项..."
sed -i 's/^CONFIG_KERNEL_DEBUG_KERNEL=y/# CONFIG_KERNEL_DEBUG_KERNEL is not set/' .config
sed -i 's/^CONFIG_KERNEL_DEBUG_INFO=y/# CONFIG_KERNEL_DEBUG_INFO is not set/' .config
sed -i 's/^CONFIG_KERNEL_DEBUG_INFO_REDUCED=y/# CONFIG_KERNEL_DEBUG_INFO_REDUCED is not set/' .config
sed -i 's/^CONFIG_KERNEL_DEBUG_FS=y/# CONFIG_KERNEL_DEBUG_FS is not set/' .config
sed -i 's/^CONFIG_KERNEL_MAGIC_SYSRQ=y/# CONFIG_KERNEL_MAGIC_SYSRQ is not set/' .config
#添加mmc-utils
sed -i '/CONFIG_PACKAGE_mmc-utils/d' .config
echo "CONFIG_PACKAGE_mmc-utils=y" >> .config

# =========================================================
# 3. 重新生成完整配置（重要！）
# =========================================================
echo "正在重新生成配置（make defconfig）..."
make defconfig

echo "所有自定义配置已完成，WiFi 已移除，内核调试已关闭。"

echo "diy-part2.sh 执行完毕！祝编译顺利！"

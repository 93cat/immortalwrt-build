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

echo "开始注入 CLX S20M 设备适配代码 (全量直写版)..."

# 1. 自动生成 mt7986a-clx-s20m.dts 文件
cat << 'EOF' > target/linux/mediatek/dts/mt7986a-clx-s20m.dts
/dts-v1/;

/ {
	#address-cells = <0x02>;
	mediatek,env-size = "0x80000";
	model = "CLX S20M";
	#size-cells = <0x02>;
	interrupt-parent = <0x01>;
	mediatek,env-offset = "0x0";
	compatible = "clx,s20m\0mediatek,mt7986a";
	mediatek,env-part = "PARTUUID=19a4763a-6b19-4a4b-a0c4-8cc34f4c2ab9";

	regulator-3p3v {
		regulator-max-microvolt = <0x325aa0>;
		regulator-boot-on;
		regulator-always-on;
		regulator-min-microvolt = <0x325aa0>;
		regulator-name = "fixed-3.3V";
		compatible = "regulator-fixed";
		phandle = <0x09>;
	};

	oscillator-40m {
		clock-output-names = "clkxtal";
		#clock-cells = <0x00>;
		clock-frequency = <0x2625a00>;
		compatible = "fixed-clock";
		phandle = <0x12>;
	};

	thermal-zones {

		cpu-thermal {
			polling-delay = <0x3e8>;
			polling-delay-passive = <0x3e8>;
			thermal-sensors = <0x27 0x00>;
			phandle = <0x41>;

			trips {

				active-med {
					temperature = <0x14c08>;
					hysteresis = <0x7d0>;
					type = "active";
					phandle = <0x45>;
				};

				active-low {
					temperature = <0xea60>;
					hysteresis = <0x7d0>;
					type = "active";
					phandle = <0x46>;
				};

				active-high {
					temperature = <0x1c138>;
					hysteresis = <0x7d0>;
					type = "active";
					phandle = <0x44>;
				};

				crit {
					temperature = <0x1e848>;
					hysteresis = <0x7d0>;
					type = "critical";
					phandle = <0x42>;
				};

				hot {
					temperature = <0x1d4c0>;
					hysteresis = <0x7d0>;
					type = "hot";
					phandle = <0x43>;
				};
			};
		};
	};

	soc {
		#address-cells = <0x02>;
		#size-cells = <0x02>;
		compatible = "simple-bus";
		ranges;

		syscon@10060000 {
			#clock-cells = <0x01>;
			compatible = "mediatek,mt7986-sgmiisys_0\0syscon";
			reg = <0x00 0x10060000 0x00 0x1000>;
			phandle = <0x1e>;
		};

		infracfg@10001000 {
			#reset-cells = <0x01>;
			#clock-cells = <0x01>;
			compatible = "mediatek,mt7986-infracfg\0syscon";
			reg = <0x00 0x10001000 0x00 0x1000>;
			phandle = <0x03>;
		};

		thermal@1100c800 {
			nvmem-cells = <0x0f>;
			clock-names = "therm\0auxadc\0adc_32k";
			interrupts = <0x00 0x8a 0x04>;
			clocks = <0x03 0x1b 0x03 0x2c 0x03 0x2d>;
			mediatek,apmixedsys = <0x05>;
			#thermal-sensor-cells = <0x01>;
			compatible = "mediatek,mt7986-thermal";
			nvmem-cell-names = "calibration-data";
			reg = <0x00 0x1100c800 0x00 0x800>;
			phandle = <0x27>;
			mediatek,auxadc = <0x0e>;
		};

		audio-controller@11210000 {
			clock-names = "aud_bus_ck\0aud_26m_ck\0aud_l_ck\0aud_aud_ck\0aud_eg2_ck";
			assigned-clocks = <0x04 0x31 0x04 0x37 0x04 0x38>;
			assigned-clock-parents = <0x04 0x0f 0x05 0x07 0x04 0x0f>;
			interrupts = <0x00 0x6a 0x04>;
			clocks = <0x03 0x11 0x03 0x12 0x03 0x13 0x03 0x14 0x03 0x15>;
			compatible = "mediatek,mt7986-afe";
			reg = <0x00 0x11210000 0x00 0x9000>;
			phandle = <0x2f>;
		};

		usb@11200000 {
			clock-names = "sys_ck\0ref_ck\0mcu_ck\0dma_ck\0xhci_ck";
			reg-names = "mac\0ippc";
			vusb33-supply = <0x09>;
			interrupts = <0x00 0xad 0x04>;
			clocks = <0x03 0x31 0x03 0x32 0x03 0x2f 0x03 0x30 0x04 0x3b>;
			vbus-supply = <0x0a>;
			compatible = "mediatek,mt7986-xhci\0mediatek,mtk-xhci";
			status = "okay";
			phys = <0x06 0x03 0x07 0x04 0x08 0x03>;
			reg = <0x00 0x11200000 0x00 0x2e00 0x00 0x11203e00 0x00 0x100>;
			phandle = <0x37>;
		};

		spi@1100b000 {
			#address-cells = <0x01>;
			clock-names = "parent-clk\0sel-clk\0spi-clk\0hclk";
			interrupts = <0x00 0x8d 0x04>;
			clocks = <0x04 0x04 0x04 0x1d 0x03 0x24 0x03 0x26>;
			#size-cells = <0x00>;
			compatible = "mediatek,mt7986-spi-ipm\0mediatek,spi-ipm";
			status = "disabled";
			reg = <0x00 0x1100b000 0x00 0x100>;
			phandle = <0x36>;
		};

		mmc@11230000 {
			pinctrl-names = "default\0state_uhs";
			pinctrl-0 = <0x0b>;
			clock-names = "source\0hclk\0source_cg\0bus_clk\0sys_cg";
			vqmmc-supply = <0x0d>;
			mmc-hs200-1_8v;
			bus-width = <0x08>;
			non-removable;
			no-sdio;
			mmc-hs400-1_8v;
			interrupts = <0x00 0x8f 0x04>;
			clocks = <0x04 0x23 0x03 0x29 0x03 0x28 0x03 0x2a 0x03 0x2b>;
			hs400-ds-delay = <0x14014>;
			vmmc-supply = <0x09>;
			no-sd;
			compatible = "mediatek,mt7986-mmc";
			pinctrl-1 = <0x0c>;
			status = "okay";
			reg = <0x00 0x11230000 0x00 0x1000 0x00 0x11c20000 0x00 0x1000>;
			phandle = <0x38>;
			max-frequency = <0xbebc200>;
			cap-mmc-highspeed;
		};

		serial@11002000 {
			clock-names = "baud\0bus";
			assigned-clocks = <0x04 0x1e 0x03 0x01>;
			assigned-clock-parents = <0x04 0x00 0x04 0x1e>;
			interrupts = <0x00 0x7b 0x04>;
			clocks = <0x03 0x01 0x03 0x1d>;
			compatible = "mediatek,mt7986-uart\0mediatek,mt6577-uart";
			status = "okay";
			reg = <0x00 0x11002000 0x00 0x400>;
			phandle = <0x31>;
		};

		apmixedsys@1001e000 {
			#clock-cells = <0x01>;
			compatible = "mediatek,mt7986-apmixedsys";
			reg = <0x00 0x1001e000 0x00 0x1000>;
			phandle = <0x05>;
		};

		t-phy@11e10000 {
			#address-cells = <0x01>;
			#size-cells = <0x01>;
			compatible = "mediatek,mt7986-tphy\0mediatek,generic-tphy-v2";
			ranges = <0x00 0x00 0x11e10000 0x1700>;
			status = "okay";
			phandle = <0x3c>;

			usb-phy@1000 {
				clock-names = "ref\0da_ref";
				clocks = <0x04 0x3c 0x04 0x3d>;
				#phy-cells = <0x01>;
				reg = <0x1000 0x700>;
				phandle = <0x08>;
			};

			usb-phy@700 {
				clock-names = "ref";
				clocks = <0x04 0x35>;
				#phy-cells = <0x01>;
				reg = <0x700 0x900>;
				phandle = <0x07>;
			};

			usb-phy@0 {
				clock-names = "ref\0da_ref";
				clocks = <0x04 0x3c 0x04 0x3d>;
				#phy-cells = <0x01>;
				reg = <0x00 0x700>;
				phandle = <0x06>;
			};
		};

		t-phy@11c00000 {
			#address-cells = <0x02>;
			#size-cells = <0x02>;
			compatible = "mediatek,mt7986-tphy\0mediatek,generic-tphy-v2";
			ranges;
			status = "okay";
			phandle = <0x3a>;

			pcie-phy@11c00000 {
				clock-names = "ref";
				clocks = <0x12>;
				#phy-cells = <0x01>;
				reg = <0x00 0x11c00000 0x00 0x20000>;
				phandle = <0x10>;
			};
		};

		syscon@10070000 {
			#clock-cells = <0x01>;
			compatible = "mediatek,mt7986-sgmiisys_1\0syscon";
			reg = <0x00 0x10070000 0x00 0x1000>;
			phandle = <0x1f>;
		};

		wed-pcie@10003000 {
			compatible = "mediatek,mt7986-wed-pcie\0syscon";
			reg = <0x00 0x10003000 0x00 0x10>;
			phandle = <0x20>;
		};

		wed@15011000 {
			memory-region-names = "wo-emi\0wo-data";
			mediatek,wo-dlm = <0x1c>;
			memory-region = <0x19 0x14>;
			interrupts = <0x00 0xce 0x04>;
			interrupt-parent = <0x01>;
			compatible = "mediatek,mt7986-wed\0syscon";
			mediatek,wo-ccif = <0x1a>;
			reg = <0x00 0x15011000 0x00 0x1000>;
			mediatek,wo-ilm = <0x1b>;
			phandle = <0x22>;
			mediatek,wo-cpuboot = <0x18>;
		};

		i2c@11008000 {
			clock-div = <0x05>;
			#address-cells = <0x01>;
			clock-names = "main\0dma";
			interrupts = <0x00 0x88 0x04>;
			clocks = <0x03 0x1c 0x03 0x18>;
			#size-cells = <0x00>;
			compatible = "mediatek,mt7986-i2c";
			status = "disabled";
			reg = <0x00 0x11008000 0x00 0x90 0x00 0x10217080 0x00 0x80>;
			phandle = <0x34>;
		};

		watchdog@1001c000 {
			#reset-cells = <0x01>;
			interrupts = <0x00 0x6e 0x04>;
			compatible = "mediatek,mt7986-wdt";
			status = "okay";
			reg = <0x00 0x1001c000 0x00 0x1000>;
			phandle = <0x24>;
		};

		pwm@10048000 {
			clock-names = "top\0main\0pwm1\0pwm2";
			interrupts = <0x00 0x89 0x04>;
			clocks = <0x04 0x1f 0x03 0x0c 0x03 0x0d 0x03 0x0e>;
			#clock-cells = <0x01>;
			#pwm-cells = <0x02>;
			compatible = "mediatek,mt7986-pwm";
			status = "disabled";
			reg = <0x00 0x10048000 0x00 0x1000>;
			phandle = <0x30>;
		};

		wifi@18000000 {
			pinctrl-names = "default";
			pinctrl-0 = <0x26>;
			clock-names = "mcu\0ap2conn";
			resets = <0x24 0x17>;
			memory-region = <0x25>;
			interrupts = <0x00 0xd5 0x04 0x00 0xd6 0x04 0x00 0xd7 0x04 0x00 0xd8 0x04>;
			clocks = <0x04 0x32 0x04 0x3e>;
			compatible = "mediatek,mt7986-wmac";
			status = "disabled";
			reg = <0x00 0x18000000 0x00 0x1000000 0x00 0x10003000 0x00 0x1000 0x00 0x11d10000 0x00 0x1000>;
			phandle = <0x40>;
			reset-names = "consys";
		};

		syscon@151e0000 {
			compatible = "mediatek,mt7986-wo-ilm\0syscon";
			reg = <0x00 0x151e0000 0x00 0x8000>;
			phandle = <0x16>;
		};

		pinctrl@1001f000 {
			reg-names = "gpio\0iocfg_rt\0iocfg_rb\0iocfg_lt\0iocfg_lb\0iocfg_tr\0iocfg_tl\0eint";
			gpio-controller;
			interrupts = <0x00 0xe1 0x04>;
			interrupt-parent = <0x01>;
			compatible = "mediatek,mt7986a-pinctrl";
			#interrupt-cells = <0x02>;
			reg = <0x00 0x1001f000 0x00 0x1000 0x00 0x11c30000 0x00 0x1000 0x00 0x11c40000 0x00 0x1000 0x00 0x11e20000 0x00 0x1000 0x00 0x11e30000 0x00 0x1000 0x00 0x11f00000 0x00 0x1000 0x00 0x11f10000 0x00 0x1000 0x00 0x1000b000 0x00 0x1000>;
			phandle = <0x02>;
			#gpio-cells = <0x02>;
			gpio-ranges = <0x02 0x00 0x00 0x64>;
			interrupt-controller;

			mmc0-uhs-pins {
				phandle = <0x0c>;

				conf-cmd-dat {
					pins = "EMMC_DATA_0\0EMMC_DATA_1\0EMMC_DATA_2\0EMMC_DATA_3\0EMMC_DATA_4\0EMMC_DATA_5\0EMMC_DATA_6\0EMMC_DATA_7\0EMMC_CMD";
					drive-strength = <0x04>;
					input-enable;
					mediatek,pull-up-adv = <0x01>;
				};

				conf-rst {
					pins = "EMMC_RSTB";
					drive-strength = <0x04>;
					mediatek,pull-up-adv = <0x01>;
				};

				conf-clk {
					pins = "EMMC_CK";
					drive-strength = <0x06>;
					mediatek,pull-down-adv = <0x02>;
				};

				mux {
					function = "emmc";
					groups = "emmc_51";
				};

				conf-ds {
					pins = "EMMC_DSL";
					mediatek,pull-down-adv = <0x02>;
				};
			};

			wf_2g_5g-pins {
				phandle = <0x26>;

				mux {
					function = "wifi";
					groups = "wf_2g\0wf_5g";
				};

				conf {
					pins = "WF0_HB1\0WF0_HB2\0WF0_HB3\0WF0_HB4\0WF0_HB0\0WF0_HB0_B\0WF0_HB5\0WF0_HB6\0WF0_HB7\0WF0_HB8\0WF0_HB9\0WF0_HB10\0WF0_TOP_CLK\0WF0_TOP_DATA\0WF1_HB1\0WF1_HB2\0WF1_HB3\0WF1_HB4\0WF1_HB0\0WF1_HB5\0WF1_HB6\0WF1_HB7\0WF1_HB8\0WF1_TOP_CLK\0WF1_TOP_DATA";
					drive-strength = <0x04>;
				};
			};

			mmc0-pins {
				phandle = <0x0b>;

				conf-cmd-dat {
					pins = "EMMC_DATA_0\0EMMC_DATA_1\0EMMC_DATA_2\0EMMC_DATA_3\0EMMC_DATA_4\0EMMC_DATA_5\0EMMC_DATA_6\0EMMC_DATA_7\0EMMC_CMD";
					drive-strength = <0x04>;
					input-enable;
					mediatek,pull-up-adv = <0x01>;
				};

				conf-rst {
					pins = "EMMC_RSTB";
					drive-strength = <0x04>;
					mediatek,pull-up-adv = <0x01>;
				};

				conf-clk {
					pins = "EMMC_CK";
					drive-strength = <0x06>;
					mediatek,pull-down-adv = <0x02>;
				};

				mux {
					function = "emmc";
					groups = "emmc_51";
				};

				conf-ds {
					pins = "EMMC_DSL";
					mediatek,pull-down-adv = <0x02>;
				};
			};
		};

		ethernet@15100000 {
			#reset-cells = <0x01>;
			#address-cells = <0x01>;
			clock-names = "fe\0gp2\0gp1\0wocpu1\0wocpu0\0sgmii_tx250m\0sgmii_rx250m\0sgmii_cdr_ref\0sgmii_cdr_fb\0sgmii2_tx250m\0sgmii2_rx250m\0sgmii2_cdr_ref\0sgmii2_cdr_fb\0netsys0\0netsys1";
			assigned-clocks = <0x04 0x2e 0x04 0x2f>;
			assigned-clock-parents = <0x05 0x01 0x05 0x03>;
			interrupts = <0x00 0xc4 0x04 0x00 0xc5 0x04 0x00 0xc6 0x04 0x00 0xc7 0x04>;
			clocks = <0x1d 0x00 0x1d 0x01 0x1d 0x02 0x1d 0x03 0x1d 0x04 0x1e 0x00 0x1e 0x01 0x1e 0x02 0x1e 0x03 0x1f 0x00 0x1f 0x01 0x1f 0x02 0x1f 0x03 0x04 0x2b 0x04 0x2c>;
			mediatek,sgmiisys = <0x1e 0x1f>;
			#size-cells = <0x00>;
			mediatek,ethsys = <0x1d>;
			mediatek,wed-pcie = <0x20>;
			compatible = "mediatek,mt7986-eth";
			mediatek,wed = <0x21 0x22>;
			status = "okay";
			reg = <0x00 0x15100000 0x00 0x80000>;
			phandle = <0x3d>;

			mac@0 {
				phy-mode = "2500base-x";
				compatible = "mediatek,eth-mac";
				reg = <0x00>;
				phandle = <0x23>;

				fixed-link {
					full-duplex;
					speed = <0x9c4>;
					pause;
				};
			};

			mdio-bus {
				#address-cells = <0x01>;
				#size-cells = <0x00>;
				phandle = <0x3e>;

				switch@31 {
					interrupts = <0x42 0x04>;
					interrupt-parent = <0x02>;
					reset-gpios = <0x02 0x12 0x00>;
					compatible = "mediatek,mt7531";
					#interrupt-cells = <0x01>;
					reg = <0x1f>;
					phandle = <0x3f>;
					interrupt-controller;

					ports {
						#address-cells = <0x01>;
						#size-cells = <0x00>;

						port@0 {
							label = "wan";
							reg = <0x00>;
						};

						port@3 {
							label = "lan2";
							reg = <0x03>;
						};

						port@1 {
							label = "lan4";
							reg = <0x01>;
						};

						port@6 {
							phy-mode = "2500base-x";
							reg = <0x06>;
							ethernet = <0x23>;

							fixed-link {
								full-duplex;
								speed = <0x9c4>;
								pause;
							};
						};

						port@4 {
							label = "lan1";
							reg = <0x04>;
						};

						port@2 {
							label = "lan3";
							reg = <0x02>;
						};
					};
				};
			};
		};

		spi@1100a000 {
			#address-cells = <0x01>;
			clock-names = "parent-clk\0sel-clk\0spi-clk\0hclk";
			interrupts = <0x00 0x8c 0x04>;
			clocks = <0x04 0x04 0x04 0x1c 0x03 0x23 0x03 0x25>;
			#size-cells = <0x00>;
			compatible = "mediatek,mt7986-spi-ipm\0mediatek,spi-ipm";
			status = "disabled";
			reg = <0x00 0x1100a000 0x00 0x100>;
			phandle = <0x35>;
		};

		efuse@11d00000 {
			#address-cells = <0x01>;
			#size-cells = <0x01>;
			compatible = "mediatek,mt7986-efuse\0mediatek,efuse";
			reg = <0x00 0x11d00000 0x00 0x1000>;
			phandle = <0x3b>;

			calib@274 {
				reg = <0x274 0x0c>;
				phandle = <0x0f>;
			};
		};

		serial@11004000 {
			clock-names = "baud\0bus";
			assigned-clocks = <0x03 0x03>;
			assigned-clock-parents = <0x04 0x36>;
			interrupts = <0x00 0x7d 0x04>;
			clocks = <0x03 0x03 0x03 0x1f>;
			compatible = "mediatek,mt7986-uart\0mediatek,mt6577-uart";
			status = "disabled";
			reg = <0x00 0x11004000 0x00 0x400>;
			phandle = <0x33>;
		};

		interrupt-controller@c000000 {
			interrupts = <0x01 0x09 0x04>;
			interrupt-parent = <0x01>;
			compatible = "arm,gic-v3";
			#interrupt-cells = <0x03>;
			reg = <0x00 0xc000000 0x00 0x10000 0x00 0xc080000 0x00 0x80000 0x00 0xc400000 0x00 0x2000 0x00 0xc410000 0x00 0x1000 0x00 0xc420000 0x00 0x2000>;
			phandle = <0x01>;
			interrupt-controller;
		};

		crypto@10320000 {
			clock-names = "infra_eip97_ck";
			assigned-clocks = <0x04 0x33>;
			assigned-clock-parents = <0x05 0x01>;
			interrupts = <0x00 0x74 0x04 0x00 0x75 0x04 0x00 0x76 0x04 0x00 0x77 0x04>;
			clocks = <0x03 0x10>;
			compatible = "inside-secure,safexcel-eip97";
			status = "okay";
			interrupt-names = "ring0\0ring1\0ring2\0ring3";
			reg = <0x00 0x10320000 0x00 0x40000>;
			phandle = <0x2e>;
		};

		wed@15010000 {
			memory-region-names = "wo-emi\0wo-data";
			mediatek,wo-dlm = <0x17>;
			memory-region = <0x13 0x14>;
			interrupts = <0x00 0xcd 0x04>;
			interrupt-parent = <0x01>;
			compatible = "mediatek,mt7986-wed\0syscon";
			mediatek,wo-ccif = <0x15>;
			reg = <0x00 0x15010000 0x00 0x1000>;
			mediatek,wo-ilm = <0x16>;
			phandle = <0x21>;
			mediatek,wo-cpuboot = <0x18>;
		};

		syscon@15194000 {
			compatible = "mediatek,mt7986-wo-cpuboot\0syscon";
			reg = <0x00 0x15194000 0x00 0x1000>;
			phandle = <0x18>;
		};

		adc@1100d000 {
			clock-names = "main";
			clocks = <0x03 0x2c>;
			#io-channel-cells = <0x01>;
			compatible = "mediatek,mt7986-auxadc";
			status = "disabled";
			reg = <0x00 0x1100d000 0x00 0x1000>;
			phandle = <0x0e>;
		};

		syscon@151f0000 {
			compatible = "mediatek,mt7986-wo-ilm\0syscon";
			reg = <0x00 0x151f0000 0x00 0x8000>;
			phandle = <0x1b>;
		};

		syscon@151a5000 {
			interrupts = <0x00 0xd3 0x04>;
			interrupt-parent = <0x01>;
			compatible = "mediatek,mt7986-wo-ccif\0syscon";
			reg = <0x00 0x151a5000 0x00 0x1000>;
			phandle = <0x15>;
		};

		syscon@151e8000 {
			compatible = "mediatek,mt7986-wo-dlm\0syscon";
			reg = <0x00 0x151e8000 0x00 0x2000>;
			phandle = <0x17>;
		};

		pcie@11280000 {
			#address-cells = <0x03>;
			phy-names = "pcie-phy";
			bus-range = <0x00 0xff>;
			clock-names = "pl_250m\0tl_26m\0peri_26m\0top_133m";
			reg-names = "pcie-mac";
			interrupts = <0x00 0xa8 0x04>;
			clocks = <0x03 0x34 0x03 0x33 0x03 0x35 0x03 0x36>;
			interrupt-map = <0x00 0x00 0x00 0x01 0x11 0x00 0x00 0x00 0x00 0x02 0x11 0x01 0x00 0x00 0x00 0x03 0x11 0x02 0x00 0x00 0x00 0x04 0x11 0x03>;
			#size-cells = <0x02>;
			device_type = "pci";
			interrupt-map-mask = <0x00 0x00 0x00 0x07>;
			compatible = "mediatek,mt7986-pcie\0mediatek,mt8192-pcie";
			ranges = <0x82000000 0x00 0x20000000 0x00 0x20000000 0x00 0x10000000>;
			#interrupt-cells = <0x01>;
			status = "okay";
			phys = <0x10 0x02>;
			reg = <0x00 0x11280000 0x00 0x4000>;
			phandle = <0x39>;

			interrupt-controller {
				#address-cells = <0x00>;
				#interrupt-cells = <0x01>;
				phandle = <0x11>;
				interrupt-controller;
			};
		};

		rng@1020f000 {
			clock-names = "rng";
			clocks = <0x03 0x37>;
			compatible = "mediatek,mt7986-rng\0mediatek,mt7623-rng";
			status = "okay";
			reg = <0x00 0x1020f000 0x00 0x100>;
			phandle = <0x2d>;
		};

		serial@11003000 {
			clock-names = "baud\0bus";
			assigned-clocks = <0x03 0x02>;
			assigned-clock-parents = <0x04 0x36>;
			interrupts = <0x00 0x7c 0x04>;
			clocks = <0x03 0x02 0x03 0x1e>;
			compatible = "mediatek,mt7986-uart\0mediatek,mt6577-uart";
			status = "disabled";
			reg = <0x00 0x11003000 0x00 0x400>;
			phandle = <0x32>;
		};

		syscon@15000000 {
			#reset-cells = <0x01>;
			#address-cells = <0x01>;
			#size-cells = <0x01>;
			#clock-cells = <0x01>;
			compatible = "mediatek,mt7986-ethsys\0syscon";
			reg = <0x00 0x15000000 0x00 0x1000>;
			phandle = <0x1d>;
		};

		topckgen@1001b000 {
			#clock-cells = <0x01>;
			compatible = "mediatek,mt7986-topckgen\0syscon";
			reg = <0x00 0x1001b000 0x00 0x1000>;
			phandle = <0x04>;
		};

		syscon@151ad000 {
			interrupts = <0x00 0xd4 0x04>;
			interrupt-parent = <0x01>;
			compatible = "mediatek,mt7986-wo-ccif\0syscon";
			reg = <0x00 0x151ad000 0x00 0x1000>;
			phandle = <0x1a>;
		};

		syscon@151f8000 {
			compatible = "mediatek,mt7986-wo-dlm\0syscon";
			reg = <0x00 0x151f8000 0x00 0x2000>;
			phandle = <0x1c>;
		};
	};

	leds {
		compatible = "gpio-leds";

		system {
			label = "blue:system";
			default-state = "on";
			phandle = <0x47>;
			gpios = <0x02 0x16 0x01>;
		};
	};

	psci {
		method = "smc";
		compatible = "arm,psci-0.2";
	};

	regulator-1p8v {
		regulator-max-microvolt = <0x1b7740>;
		regulator-boot-on;
		regulator-always-on;
		regulator-min-microvolt = <0x1b7740>;
		regulator-name = "1.8vd";
		compatible = "regulator-fixed";
		phandle = <0x0d>;
	};

	keys {
		compatible = "gpio-keys";

		reset {
			label = "reset";
			linux,code = <0x198>;
			gpios = <0x02 0x10 0x01>;
		};
	};

	timer {
		interrupts = <0x01 0x0d 0x08 0x01 0x0e 0x08 0x01 0x0b 0x08 0x01 0x0a 0x08>;
		interrupt-parent = <0x01>;
		compatible = "arm,armv8-timer";
	};

	aliases {
		led-boot = "/leds/system";
		led-upgrade = "/leds/system";
		led-running = "/leds/system";
		led-failsafe = "/leds/system";
		serial0 = "/soc/serial@11002000";
	};

	chosen {
		u-boot,version = "2025.07";
		u-boot,bootconf = "config-1";
		bootargs-append = " root=PARTLABEL=rootfs rootwait";
		stdout-path = "serial0:115200n8";
	};

	regulator-usb-vbus {
		regulator-max-microvolt = <0x4c4b40>;
		regulator-boot-on;
		enable-active-high;
		regulator-min-microvolt = <0x4c4b40>;
		regulator-name = "usb_vbus";
		compatible = "regulator-fixed";
		phandle = <0x0a>;
		gpios = <0x02 0x18 0x00>;
	};

	cpus {
		#address-cells = <0x01>;
		#size-cells = <0x00>;

		cpu@1 {
			device_type = "cpu";
			compatible = "arm,cortex-a53";
			reg = <0x01>;
			enable-method = "psci";
			phandle = <0x29>;
			#cooling-cells = <0x02>;
		};

		cpu@2 {
			device_type = "cpu";
			compatible = "arm,cortex-a53";
			reg = <0x02>;
			enable-method = "psci";
			phandle = <0x2a>;
			#cooling-cells = <0x02>;
		};

		cpu@0 {
			device_type = "cpu";
			compatible = "arm,cortex-a53";
			reg = <0x00>;
			enable-method = "psci";
			phandle = <0x28>;
			#cooling-cells = <0x02>;
		};

		cpu@3 {
			device_type = "cpu";
			compatible = "arm,cortex-a53";
			reg = <0x03>;
			enable-method = "psci";
			phandle = <0x2b>;
			#cooling-cells = <0x02>;
		};
	};

	__symbols__ {
		pwm = "/soc/pwm@10048000";
		mdio = "/soc/ethernet@15100000/mdio-bus";
		thermal = "/soc/thermal@1100c800";
		u3port0 = "/soc/t-phy@11e10000/usb-phy@700";
		usb_vbus = "/regulator-usb-vbus";
		crypto = "/soc/crypto@10320000";
		secmon_reserved = "/reserved-memory/secmon@43000000";
		gmac0 = "/soc/ethernet@15100000/mac@0";
		pcie_port = "/soc/t-phy@11c00000/pcie-phy@11c00000";
		wo_ccif0 = "/soc/syscon@151a5000";
		trng = "/soc/rng@1020f000";
		reg_3p3v = "/regulator-3p3v";
		wo_ilm0 = "/soc/syscon@151e0000";
		spi0 = "/soc/spi@1100a000";
		afe = "/soc/audio-controller@11210000";
		wifi = "/soc/wifi@18000000";
		infracfg = "/soc/infracfg@10001000";
		cpu_trip_active_med = "/thermal-zones/cpu-thermal/trips/active-med";
		apmixedsys = "/soc/apmixedsys@1001e000";
		cpu_trip_active_low = "/thermal-zones/cpu-thermal/trips/active-low";
		u2port0 = "/soc/t-phy@11e10000/usb-phy@0";
		cpu_thermal = "/thermal-zones/cpu-thermal";
		wo_dlm1 = "/soc/syscon@151f8000";
		wo_emi0 = "/reserved-memory/wo-emi@4fd00000";
		cpu3 = "/cpus/cpu@3";
		uart2 = "/soc/serial@11004000";
		eth = "/soc/ethernet@15100000";
		gic = "/soc/interrupt-controller@c000000";
		switch = "/soc/ethernet@15100000/mdio-bus/switch@31";
		wf_2g_5g_pins = "/soc/pinctrl@1001f000/wf_2g_5g-pins";
		cpu1 = "/cpus/cpu@1";
		uart0 = "/soc/serial@11002000";
		pcie_phy = "/soc/t-phy@11c00000";
		ssusb = "/soc/usb@11200000";
		thermal_calibration = "/soc/efuse@11d00000/calib@274";
		mmc0_pins_uhs = "/soc/pinctrl@1001f000/mmc0-uhs-pins";
		sgmiisys0 = "/soc/syscon@10060000";
		wed0 = "/soc/wed@15010000";
		pcie = "/soc/pcie@11280000";
		ethsys = "/soc/syscon@15000000";
		wo_ccif1 = "/soc/syscon@151ad000";
		wo_ilm1 = "/soc/syscon@151f0000";
		spi1 = "/soc/spi@1100b000";
		i2c0 = "/soc/i2c@11008000";
		mmc0_pins_default = "/soc/pinctrl@1001f000/mmc0-pins";
		u2port1 = "/soc/t-phy@11e10000/usb-phy@1000";
		reg_1p8v = "/regulator-1p8v";
		wo_cpuboot = "/soc/syscon@15194000";
		cpu_trip_hot = "/thermal-zones/cpu-thermal/trips/hot";
		mmc0 = "/soc/mmc@11230000";
		wo_emi1 = "/reserved-memory/wo-emi@4fd40000";
		wo_data = "/reserved-memory/wo-data@4fd80000";
		wmcpu_emi = "/reserved-memory/wmcpu-reserved@4fc00000";
		cpu_trip_crit = "/thermal-zones/cpu-thermal/trips/crit";
		clk40m = "/oscillator-40m";
		topckgen = "/soc/topckgen@1001b000";
		auxadc = "/soc/adc@1100d000";
		wo_dlm0 = "/soc/syscon@151e8000";
		pio = "/soc/pinctrl@1001f000";
		efuse = "/soc/efuse@11d00000";
		cpu2 = "/cpus/cpu@2";
		uart1 = "/soc/serial@11003000";
		wed_pcie = "/soc/wed-pcie@10003000";
		sgmiisys1 = "/soc/syscon@10070000";
		wed1 = "/soc/wed@15011000";
		usb_phy = "/soc/t-phy@11e10000";
		pcie_intc = "/soc/pcie@11280000/interrupt-controller";
		led_system = "/leds/system";
		watchdog = "/soc/watchdog@1001c000";
		cpu0 = "/cpus/cpu@0";
		cpu_trip_active_high = "/thermal-zones/cpu-thermal/trips/active-high";
	};

	reserved-memory {
		#address-cells = <0x02>;
		#size-cells = <0x02>;
		ranges;

		wo-data@4fd80000 {
			reg = <0x00 0x4fd80000 0x00 0x240000>;
			phandle = <0x14>;
			no-map;
		};

		wo-emi@4fd00000 {
			reg = <0x00 0x4fd00000 0x00 0x40000>;
			phandle = <0x13>;
			no-map;
		};

		wo-emi@4fd40000 {
			reg = <0x00 0x4fd40000 0x00 0x40000>;
			phandle = <0x19>;
			no-map;
		};

		secmon@43000000 {
			reg = <0x00 0x43000000 0x00 0x30000>;
			phandle = <0x2c>;
			no-map;
		};

		ramoops@42ff0000 {
			record-size = <0x1000>;
			compatible = "ramoops";
			reg = <0x00 0x42ff0000 0x00 0x10000>;
		};

		wmcpu-reserved@4fc00000 {
			reg = <0x00 0x4fc00000 0x00 0x100000>;
			phandle = <0x25>;
			no-map;
		};
	};

	memory {
		device_type = "memory";
		reg = <0x00 0x40000000 0x00 0x80000000>;
	};
};
EOF

# 2. 将设备配置追加到 filogic.mk
cat << 'EOF' >> target/linux/mediatek/image/filogic.mk

define Device/clx_s20m
  DEVICE_VENDOR := CLX
  DEVICE_MODEL := S20M
  DEVICE_DTS := mt7986a-clx-s20m
  DEVICE_PACKAGES := kmod-usb3 kmod-usb-xhci-mtk kmod-nvme
endef
TARGET_DEVICES += clx_s20m
EOF

echo "CLX S20M 适配代码注入完成！"

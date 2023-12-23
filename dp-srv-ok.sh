#!/bin/bash

# =================================================
#	Description: drawpile-server-onekey
#	Version: 1.0.0
#	Author: RHWong
# =================================================

author="RHWong"
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Warrning="${Red_font_prefix}[警告]${Font_color_suffix}"
Tip="${Green_font_prefix}[提示]${Font_color_suffix}"

basepath=$(cd `dirname $0`; pwd)
project_path=$basepath/dpserver
project_name=dpserver
main_file=set-webadmin-password.sh
$basepath
$project_path
$ret_code
    # 检测本机内核发行版
    check_sys(){
        if [[ -f /etc/redhat-release ]]; then
            release="Centos"
        elif cat /etc/issue | grep -q -E -i "Debian"; then
            release="Debian"
        elif cat /etc/issue | grep -q -E -i "Ubuntu"; then
            release="Ubuntu"
        elif cat /etc/issue | grep -q -E -i "Centos|red hat|redhat"; then
            release="Centos"
        elif cat /proc/version | grep -q -E -i "Debian"; then
            release="Debian"
        elif cat /proc/version | grep -q -E -i "Ubuntu"; then
            release="Ubuntu"
        elif cat /proc/version | grep -q -E -i "Centos|red hat|redhat"; then
            release="Centos"
        # 如果是termux
        elif [ -f /data/data/com.termux/files/usr/bin/bash ]; then
            release="Termux"
        # 如果是未知系统版本则输出unknown
        else
            release="unknown"
        fi
        bit=`uname -m`
    }
    anti_bit(){
        if [[ ${bit} == "x86_64" ]]; then
            print_release_bit
        else
            echo -e "${Warrning} ${project_name}官方未发布${Red_font_prefix}[${bit}]${Font_color_suffix}服务端!"
            echo -e "${Warrning} 请您更换x86_64后重新尝试。"
				sleep 3
                exit 1
        fi

    }
    # 打印release和bit
        # 如果是Centos则返回警告
    print_release_bit(){
            echo -e "${Info} 当前系统为 ${Green_font_prefix}[${release}]${Font_color_suffix} ${Green_font_prefix}[${bit}]${Font_color_suffix}"
    }

    # 安装项目
    install_project()
    {
        # 判断项目目录下主要程序是否存在  
    if [ ! -f "${project_path}/${main_file}" ]; then
        echo -e "${Info} ${project_name}主文件不存在，开始安装..."
        sleep 1
            echo -e "${Info} 网络连接异常，开始使用镜像下载${project_name}..."
            git clone https://mirror.ghproxy.com/https://github.com/drawpile/dpserver.git
        echo -e "${Tip} ${project_name}下载完成！"
        sleep 1
    else
        echo -e "${Info} ${project_name}文件已存在，无需安装！"
        sleep 1
    fi
    }
	
	update_webadmin()
    {
	cd "${project_path}"
	# Get latest webadmin source code
	if [[ ! -d "${project_path}/dpwebadmin" ]]
	then
		git clone https://mirror.ghproxy.com/https://github.com/drawpile/dpwebadmin.git
		cd "${project_path}/dpwebadmin"
	else
		cd "${project_path}/dpwebadmin"
		git pull
	fi
	# Local server specific configuration
	cat > .env.local <<END
REACT_APP_APIROOT=/admin/api
REACT_APP_BASENAME=/admin
PUBLIC_URL=/admin
END
	# Build
	rm -rf build
	docker run --rm -ti \
		--mount type=bind,source="$(pwd)",target=/app \
		-w=/app \
		-u=$UID \
		-e 'NODE_OPTIONS=--openssl-legacy-provider' \
		node:lts-alpine \
		/bin/sh -c "npm install --no-progress && npm run build"

	# Replace existing webadmin deployment (if any) with the fresh build
	cd ../public_html
	rm -rf admin
	mv ../dpwebadmin/build admin
	}
	
   # 设置管理员密码
	set_webadmin_password()
	{
	PW_FILE=${project_path}/nginx-config/htpasswd	
        if [[ ${release} == "Centos" ]]; then
            yum -y install httpd
        elif [[ ${release} == "Ubuntu" ]]; then
            apt install -y apache2-utils
        elif [[ ${release} == "Debian" ]]; then
            apt install -y apache2-utils
        elif [[ ${release} == "unknown" ]]; then
            echo -e "${Warrning} 未知系统版本，若无法继续运行请自行安装apache2-utils或httpd以激活htpasswd"
            sleep 3
        fi	
	echo -e "请输入 Drawpile 服务端要设置的密码[password]"
	read -erp "(默认: dpasswd):" password_dp
	[[ -z "$password_dp" ]] && password_dp="dpasswd"
	echo && echo "	================================================"
	echo -e "	密码[password]: ${Red_background_prefix} ${password_dp} ${Font_color_suffix}"
	echo "	================================================" && echo
	touch $PW_FILE
	htpasswd -b $PW_FILE admin ${password_dp}
	}
	
	set_server_host() {
		echo -e "请输入 Drawpile 服务端中网站要设置的 域名[domain]
		例如输入: drawpile.cn ，如果要使用本机IP，请留空直接回车"
		read -erp "(默认: 本机IP):" server_s
		[[ -z "$server_s" ]] && server_s=""
	cat > .env <<END
DOMAIN=$server_s
USE_CERTBOT=no
EMAIL=10000@qq.com
DISCORD_WEBHOOK=
END
	}	


    # 本地安装  
    install_local(){
        check_sys
        anti_bit
        install_project
        chmod -R 766 ${project_path}
        cd ${project_path}
		set_webadmin_password
		update_webadmin
        set_server_host
        echo -e "${Tip} ${project_name}安装完成！"
        sleep 1
        # 打印安装位置
        echo -e "${Tip} ${project_name}安装位置：${project_path}"
        sleep 3
        echo -e "${Tip} 开始尝试运行，如有问题请提交issue"
        sleep 1
        cd ${project_path} && docker-compose up -d
    }

    # 修改密码
    change_password(){
        check_sys
        anti_bit
        cd ${project_path}
		set_webadmin_password
        echo -e "${Tip} ${project_name}修改完成！"
        sleep 1
        echo -e "${Tip} 开始尝试更新docker，如有问题请提交issue"
        sleep 1
        cd ${project_path} && docker-compose up -d
    }


    # 启动项目
    dp_srv_start(){
        echo -e "${Info} 你要做什么？"
        echo -e "1. 安装dp_srv"
        echo -e "2. 修改管理员密码"
        read -p "请输入数字:" num
        case "$num" in
            1)
            install_local
            ;;
            2)
            change_password
            ;;
            *)
            echo -e "${Error} 请输入正确的数字"
            exit 1
            ;;
        esac
    }
dp_srv_start
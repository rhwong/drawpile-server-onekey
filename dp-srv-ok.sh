#!/bin/bash

# =================================================
#	Description: drawpile-server-onekey
#	Version: 1.0.0
#	Author: RHWong
# =================================================

author="RHWong"
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[��Ϣ]${Font_color_suffix}"
Error="${Red_font_prefix}[����]${Font_color_suffix}"
Warrning="${Red_font_prefix}[����]${Font_color_suffix}"
Tip="${Green_font_prefix}[��ʾ]${Font_color_suffix}"

basepath=$(cd `dirname $0`; pwd)
project_path=$basepath/dpserver
project_name=dpserver
main_file=set-webadmin-password.sh
$basepath
$project_path
$ret_code
    # ��Ȿ���ں˷��а�
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
        # �����termux
        elif [ -f /data/data/com.termux/files/usr/bin/bash ]; then
            release="Termux"
        # �����δ֪ϵͳ�汾�����unknown
        else
            release="unknown"
        fi
        bit=`uname -m`
    }
    anti_bit(){
        if [[ ${bit} == "x86_64" ]]; then
            print_release_bit
        else
            echo -e "${Warrning} ${project_name}�ٷ�δ����${Red_font_prefix}[${bit}]${Font_color_suffix}�����!"
            echo -e "${Warrning} ��������x86_64�����³��ԡ�"
				sleep 3
                exit 1
        fi

    }
    # ��ӡrelease��bit
        # �����Centos�򷵻ؾ���
    print_release_bit(){
            echo -e "${Info} ��ǰϵͳΪ ${Green_font_prefix}[${release}]${Font_color_suffix} ${Green_font_prefix}[${bit}]${Font_color_suffix}"
    }

    # ��װ��Ŀ
    install_project()
    {
        # �ж���ĿĿ¼����Ҫ�����Ƿ����  
    if [ ! -f "${project_path}/${main_file}" ]; then
        echo -e "${Info} ${project_name}���ļ������ڣ���ʼ��װ..."
        sleep 1
            echo -e "${Info} ���������쳣����ʼʹ�þ�������${project_name}..."
            git clone https://mirror.ghproxy.com/https://github.com/drawpile/dpserver.git
        echo -e "${Tip} ${project_name}������ɣ�"
        sleep 1
    else
        echo -e "${Info} ${project_name}�ļ��Ѵ��ڣ����谲װ��"
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
	
   # ���ù���Ա����
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
            echo -e "${Warrning} δ֪ϵͳ�汾�����޷��������������а�װapache2-utils��httpd�Լ���htpasswd"
            sleep 3
        fi	
	echo -e "������ Drawpile �����Ҫ���õ�����[password]"
	read -erp "(Ĭ��: dpasswd):" password_dp
	[[ -z "$password_dp" ]] && password_dp="dpasswd"
	echo && echo "	================================================"
	echo -e "	����[password]: ${Red_background_prefix} ${password_dp} ${Font_color_suffix}"
	echo "	================================================" && echo
	touch $PW_FILE
	htpasswd -b $PW_FILE admin ${password_dp}
	}
	
	set_server_host() {
		echo -e "������ Drawpile ���������վҪ���õ� ����[domain]
		��������: drawpile.cn �����Ҫʹ�ñ���IP��������ֱ�ӻس�"
		read -erp "(Ĭ��: ����IP):" server_s
		[[ -z "$server_s" ]] && server_s=""
	cat > .env <<END
DOMAIN=$server_s
USE_CERTBOT=no
EMAIL=10000@qq.com
DISCORD_WEBHOOK=
END
	}	


    # ���ذ�װ  
    install_local(){
        check_sys
        anti_bit
        install_project
        chmod -R 766 ${project_path}
        cd ${project_path}
		set_webadmin_password
		update_webadmin
        set_server_host
        echo -e "${Tip} ${project_name}��װ��ɣ�"
        sleep 1
        # ��ӡ��װλ��
        echo -e "${Tip} ${project_name}��װλ�ã�${project_path}"
        sleep 3
        echo -e "${Tip} ��ʼ�������У������������ύissue"
        sleep 1
        cd ${project_path} && docker-compose up -d
    }

    # �޸�����
    change_password(){
        check_sys
        anti_bit
        cd ${project_path}
		set_webadmin_password
        echo -e "${Tip} ${project_name}�޸���ɣ�"
        sleep 1
        echo -e "${Tip} ��ʼ���Ը���docker�������������ύissue"
        sleep 1
        cd ${project_path} && docker-compose up -d
    }


    # ������Ŀ
    dp_srv_start(){
        echo -e "${Info} ��Ҫ��ʲô��"
        echo -e "1. ��װdp_srv"
        echo -e "2. �޸Ĺ���Ա����"
        read -p "����������:" num
        case "$num" in
            1)
            install_local
            ;;
            2)
            change_password
            ;;
            *)
            echo -e "${Error} ��������ȷ������"
            exit 1
            ;;
        esac
    }
dp_srv_start
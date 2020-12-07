#! /bin/bash
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"

function check_sys()
{
    if [[ -f /etc/redhat-release ]]; then
        release="centos"
    elif cat /etc/issue | grep -q -E -i "debian"; then
        release="debian"
    elif cat /etc/issue | grep -q -E -i "ubuntu"; then
        release="ubuntu"
    elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
        release="centos"
    elif cat /proc/version | grep -q -E -i "debian"; then
        release="debian"
    elif cat /proc/version | grep -q -E -i "ubuntu"; then
        release="ubuntu"
    elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
        release="centos"
    fi
    bit=$(uname -m)
        if test "$bit" != "x86_64"; then
           echo "请输入你的芯片架构，/386/armv5/armv6/armv7/armv8"
           read bit
        else bit="amd64"
    fi
}
function Installation_dependency(){
    if [[ ${release} == "centos" ]]; then
        yum update
        yum install -y wget
        yum -y install lsof
        yum -y install curl
    else
        apt-get update
        apt-get install -y wget
        apt-get install -y lsof
        apt-get -y install curl
    fi
    if ! type docker >/dev/null 2>&1; then
    curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
    systemctl start docker
    fi
}
function check_root()
{
    [[ $EUID != 0 ]] && echo -e "${Error} 当前非ROOT账号(或没有ROOT权限)，无法继续操作，请更换ROOT账号或使用 ${Green_background_prefix}sudo su${Font_color_suffix} 命令获取临时ROOT权限（执行后可能会提示输入当前账号的密码）。" && exit 1
}

function install(){
	num=1
    check_sys
    Installation_dependency
    rm -rf /etc/xdzz
    wget -P /etc/xdzz https://sh.xdmb.xyz/xiandan/xd.mv.db
    wget -P /etc/xdzz https://sh.xdmb.xyz/xiandan/xd.trace.db
    read_port
}
function update(){
    if [[ ! -n $port ]];then
	portinfo=`docker port xiandan`
	if [[ ! -n "$portinfo" ]];then
	 read_port
	else
	port=${portinfo#*:}
	fi
    fi
    version=`docker -v`
    if ! type docker >/dev/null 2>&1; then
        wget -qO- https://get.docker.com/ | sh
        systemctl start docker
    fi
    docker rm -f xiandan
    docker pull docker.xdmb.xyz/xiandan/release:latest
    docker run --restart=always --name=xiandan -v /etc/xdzz:/xiandan -d -p ${port}:8080 docker.xdmb.xyz/xiandan/release:latest
    ip=`curl -4 ip.sb`
    echo -e "${Green_font_prefix}闲蛋面板已安装成功！请等待1-2分钟后访问面板入口。${Font_color_suffix}"
    echo -e "${Green_font_prefix}访问入口为 $ip:${port} ${Font_color_suffix}"
}
function uninstall(){
    rm -rf /etc/xdzz
    docker rm -f xiandan
    echo -e "${Green_font_prefix}闲蛋已成功卸载${Font_color_suffix}"
}
function start(){
	portinfo=`docker ps -a |grep xiandan`
	if [[ ! -n "$portinfo" ]];then
		echo -e "${Green_font_prefix}面板未安装,请安装面板！${Font_color_suffix}"
	else
		docker start xiandan
		echo -e "${Green_font_prefix}已启动${Font_color_suffix}"
	fi
}
function stop()
{
	portinfo=`docker ps -a |grep xiandan`
	if [[ ! -n "$portinfo" ]];then
		echo -e "${Green_font_prefix}面板未安装,请安装面板！${Font_color_suffix}"
	else
		docker stop xiandan
		echo -e "${Green_font_prefix}已停止${Font_color_suffix}"
	fi
}
function restart(){
	portinfo=`docker ps -a |grep xiandan`
	if [[ ! -n "$portinfo" ]];then
		echo -e "${Green_font_prefix}面板未安装,请安装面板！${Font_color_suffix}"
	else
		docker restart xiandan
		echo -e "${Green_font_prefix}已重启${Font_color_suffix}"
	fi
}
function restore(){
    rm -rf /etc/xdzz
	wget -P /etc/xdzz https://sh.xdmb.xyz/xiandan/xd.mv.db
    wget -P /etc/xdzz https://sh.xdmb.xyz/xiandan/xd.trace.db
    restart
}
function read_port(){
	echo -e "请输入面板映射端口（面板访问端口）"
	echo "-----------------------------------"
	read -p "请输入(1-65535, 默认：80): " port
	if [[ ! -n $port ]];then
		port=80
	fi
	if [ "$port" -gt 0 ] 2>/dev/null;then
		if [[ $port -lt 0 || $port -gt 65535 ]];then
		 echo -e "端口号不正确"
		 read_port
		fi
		isUsed=`lsof -i:${port}`
		if [ -n "$isUsed" ];then
		 echo -e "端口被占用"
		 read_port
		fi
		update
	else
 		read_port
	fi
}

function auto() {
    check_root
    echo && echo -e "${Green_font_prefix}       闲蛋面板 一键脚本
   ${Green_font_prefix} ----------- Noob_Cfy -----------
   ${Green_font_prefix}1. 安装 闲蛋面板
   ${Green_font_prefix}2. 更新 闲蛋面板
   ${Green_font_prefix}3. 卸载 闲蛋面板
  ————————————
   ${Green_font_prefix}4. 启动 闲蛋面板
   ${Green_font_prefix}5. 停止 闲蛋面板
   ${Green_font_prefix}6. 重启 闲蛋面板
  ————————————
   ${Green_font_prefix}7. 数据库还原
   ${Green_font_prefix}8. 退出脚本
  ———————————— ${Font_color_suffix}" && echo
  read -e -p " 请输入数字 [1-8]:" num
  case "$num" in
      1)
          install
          ;;
      2)
          update
          ;;
      3)
          uninstall
          ;;
      4)
          start
          ;;
      5)
          stop
          ;;
      6)
          restart
          ;;
      7)
          restore
          ;;
	8)
		exit 0
		;;
      *)
    	echo "请输入正确数字 [1-8]"
    	;;
  esac
}

if [ $# -gt 0 ] ; then
  if [ $1 == "install" ]; then
    install
  elif [ $1 == "start" ]; then
    start
  elif [ $1 == "stop" ]; then
    stop
  elif [ $1 == "update" ]; then
    update
  elif [ $1 == "uninstall" ]; then
    uninstall
  fi
else
    auto;
fi
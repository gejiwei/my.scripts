#!/bin/bash
#suto install zabbix_agentd
#author :gjw
echo"安装aliyun源及epel源"
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
yum makecache


echo "清除/卸载原有zabbix残留文件"
rpm -e `rpm -qa|grep zabbix` --nodeps
rm -fr `find / -name "zabbix"`
rm -fr `find / -name "zabbix.*"`
rm -fr `find / -name "zabbix_*"`
rm -fr `find / -name "*.zabbix"`

echo  "现在，开始自动安装zabbix-agentd，先下载依赖包，请稍等"
yum install net-snmp-devel libxml2-devel libcurl-devel  -y

echo "创建zabbix用户与组"
useradd  -s /sbin/nologin -M zabbix

echo "正在安装zabbix，请稍等！"
mkdir -p /server/tools
tar -zxf zabbix-3.0.12.tar.gz -C /server/tools
cd /server/tools/zabbix-3.0.12
./configure --prefix=/usr/local/zabbix --enable-agent
make && make install


echo"配置zabbix_agentd"
ret=$?      
if [ $? -eq 0 ] 
  then      
      cp -rp /usr/local/zabbix/etc/zabbix_agentd.conf /usr/local/zabbix/etc/zabbix_agentd.conf.bak
cat >/usr/local/zabbix/etc/zabbix_agentd.conf<<<"
EnableRemoteCommands=1
EnableRemoteCommands=1
LogRemoteCommands=1
ListenPort=10050
ListenIP=0.0.0.0
StartAgents=10
Timeout=30
AllowRoot=1
LogFile=/tmp/zabbix_agentd.log
Server=127.0.0.1
ServerActive=127.0.0.1
Hostname=Zabbix server
Include=/usr/local/zabbix/etc/zabbix_agentd.conf.d/
UnsafeUserParameters=1
"
      mkdir -p /usr/local/zabbix/etc/zabbix_agentd.conf.d/
      read  -p "please input zabbix_serverip:"  zabbix_serverip
      sed -i 's/Server=127.0.0.1/Server='$zabbix_serverip'/' /usr/local/zabbix/etc/zabbix_agentd.conf
      sed -i 's/ServerActive=127.0.0.1/ServerActive='$zabbix_serverip'/' /usr/local/zabbix/etc/zabbix_agentd.conf
      echo "zabbix install success."
        
else
      echo "install failed,please check"
fi  
/usr/local/zabbix/sbin/zabbix_agentd
if [ $? -eq 0 ] 
  then
      echo "set zabbix_agentd start with system"
      echo "/usr/local/zabbix/sbin/zabbix_agentd start" >> /etc/rc.d/rc.local
else
      echo "start error,please check"
fi

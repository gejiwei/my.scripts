#!/bin/bash
# 判断mysql是否安装

COUNT=`netstat -lntup|grep 3306|wc -l`
WHERE=`whereis mysql|awk -F ":" '{print $2}'|wc -c`

function_zabbix () {
    #11.安装zabbix
    echo "开始下载安装zabbix-server"
    rpm -i http://repo.zabbix.com/zabbix/3.2/rhel/7/x86_64/zabbix-release-3.2-1.el7.noarch.rpm
    
    yum install -y zabbix-server-mysql zabbix-web-mysql zabbix-agent 
    ln -s /application/mysql-5.6.40/lib/libmysqlclient.so.18 /usr/lib64/
    
    #12.配置zabbix数据库，导入数据
    echo "配置zabbix数据库"
    mysql -uroot -p$input -e"
    create database zabbix character set utf8 collate utf8_bin;
    grant all privileges on zabbix.* to zabbix@localhost identified by 'zabbix';
    quit"
    
    
    zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix -pzabbix zabbix
    
    echo "DBPassword=zabbix" >>/etc/zabbix/zabbix_server.conf
    
    sed -i 's#       \# php_value date.timezone Europe/Riga#       php_value date.timezone Asia/Shanghai#g' /etc/httpd/conf.d/zabbix.conf
    grep Shanghai /etc/httpd/conf.d/zabbix.conf
    
    systemctl restart zabbix-server zabbix-agent httpd
    systemctl enable zabbix-server zabbix-agent httpd 
}

function_rm () {
    # 重装使用此参数，先清空残留文件
    echo "清除/卸载原有zabbix及mysql残留文件"
    pkill mysql
    pkill zabbix
    pkill httpd
    
    rpm -e `rpm -qa|grep zabbix` --nodeps
    rm -fr `find / -name "zabbix"`
    rm -fr `find / -name "zabbix.*"`
    rm -fr `find / -name "zabbix_*"`
    rm -fr `find / -name "*zabbix*"`
    rm -fr `find / -name "zabbix-*"`
    
    rpm -e `rpm -qa|grep mysql` --nodeps
    rm -fr `find / -name "mysql"`
    rm -fr `find / -name "mysql.*"`
    rm -fr `find / -name "mysql_*"`
    rm -fr `find / -name "*mysql*"|grep -v mysql-5.6.40-*`
    rm -fr `find / -name "mysql-*"|grep -v mysql-5.6.40-*`
}


function_automatic () {
    echo "开始自动化安装mysql"
    #1.添加一个mysql虚拟用户
    useradd -s /sbin/nologin -M mysql
    
    #2.解压
    tar xf mysql-5.6.40-linux-glibc2.12-x86_64.tar.gz 
    
    
    #3.移动到/application/mysq-5.6.40 目录
    [ ! -d /application ] && mkdir /application
    mv mysql-5.6.40-linux-glibc2.12-x86_64  /application/mysql-5.6.40
    ln -s /application/mysql-5.6.40 /application/mysql
    
    #5.data目录mysql 
    chown -R  mysql.mysql  /application/mysql/data/
    
    #6.初始化MySQL 
    /application/mysql/scripts/mysql_install_db  --user=mysql --basedir=/application/mysql  --datadir=/application/mysql/data
    
    #7.准备配置文件 
    cd /application/mysql
    cp support-files/my-default.cnf  /etc/my.cnf
    
    sed -i.bak 's#/usr/local/#/application/#g' /application/mysql/support-files/mysql.server /application/mysql/bin/mysqld_safe
    
    cp /application/mysql/support-files/mysql.server  /etc/init.d/mysqld
    chmod +x /etc/init.d/mysqld
    
    #8.启动MySQL 
    /etc/init.d/mysqld start
    
    #9.设置mysql密码
    /application/mysql/bin/mysqladmin -u root password 'waming@2030'
    
    #10.PATH路径
    echo 'export PATH=/application/mysql/bin:$PATH' >>/etc/profile
    source /etc/profile
    which mysql 
    
    #11.安装zabbix
    echo "开始下载安装zabbix-server"
    rpm -i http://repo.zabbix.com/zabbix/3.2/rhel/7/x86_64/zabbix-release-3.2-1.el7.noarch.rpm
    
    yum install -y zabbix-server-mysql zabbix-web-mysql zabbix-agent 
    ln -s /application/mysql-5.6.40/lib/libmysqlclient.so.18 /usr/lib64/
    
    #12.配置zabbix数据库，导入数据
    echo "配置zabbix数据库"
    mysql -uroot -pwaming@2030 -e"
    create database zabbix character set utf8 collate utf8_bin;
    grant all privileges on zabbix.* to zabbix@localhost identified by 'zabbix';
    quit"
    
    
    zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix -pzabbix zabbix
    
    echo "DBPassword=zabbix" >>/etc/zabbix/zabbix_server.conf
    
    sed -i 's#       \# php_value date.timezone Europe/Riga#       php_value date.timezone Asia/Shanghai#g' /etc/httpd/conf.d/zabbix.conf
    grep Shanghai /etc/httpd/conf.d/zabbix.conf
    
    systemctl restart zabbix-server zabbix-agent httpd
    systemctl enable zabbix-server zabbix-agent httpd 
}

if [ $WHERE -gt 1 ];then
    echo -e "\e[1;42m mysql已安装. \e[0m"
    if [ $COUNT -ne 1 ];then
        echo -e "\e[1;41m mysql未启动. \e[0m"
        echo -e "\e[1;31m 是否继续使用你的MySQL？y/n. \e[0m"
        read n
        case "$n" in
            y)
            echo -e "\e[1;31m 继续使用请先启动你的MySQL \e[0m"
            ;;
            n)
            function_rm
            function_automatic        
            ;;
            *)
            echo "Usage:$0 {yes|no}"
    		;;
        esac
    else
        echo -e "\e[1;42m mysql已启动. \e[0m"
        echo "请输入你的MySQL数据库密码：" 
        \read input
        function_zabbix
    fi

else
    echo -e "\e[1;41m mysql未安装. \e[0m"
    function_automatic
fi

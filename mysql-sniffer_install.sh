wget https://codeload.github.com/Qihoo360/mysql-sniffer/zip/master -O /usr/local/src/mysql-sniffer.zip
yum -y install gcc glib2-devel libpcap-devel libnet-devel cmake gcc-c++ unzip
yum erase libpcap
yum -y install http://rpmfind.net/linux/fedora/linux/releases/27/Everything/x86_64/os/Packages/l/libpcap-1.8.1-6.fc27.x86_64.rpm
unzip /usr/local/src/mysql-sniffer.zip -d /usr/local/src/
mkdir /usr/local/mysql-sniffer
cd /usr/local/mysql-sniffer
cmake ../src/mysql-sniffer-master/
make
echo "PATH=$PATH:/usr/local/mysql-sniffer/bin/" >> /etc/profile
source /etc/profile

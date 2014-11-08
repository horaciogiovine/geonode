#!/bin/sh

##############
############## IMPORTANT STEPS FOR RUNNING VAGRANT ON WINDOWS 7
############## Start up virtualbox in admin mode by right clicking on virtualbox and clicking "run as administrator" and then open up cygwin terminal as an administrator as well. Both programs must be run as admin for symlinking to work correctly on windows 7.
##############

SITE_DIR="/var/www/html" # The path to the web application on the server (default: /var/www/html)
SITE_PUB_DIR="/var/www/html/geonode.local/public" # The path to the application public web folder.
VAGRANT_DATA_DIR="/vagrant/vagrant"
DB_NAME="geoname" #name of mysql DB.

# Install Applications
yum install -y git
yum install -y vim
yum install -y unzip.x86_64
yum install -y screen
yum -y groupinstall "Development Tools"
yum install -y gcc gcc-c++ autoconf automake make


# Install node
cd /usr/src
wget http://nodejs.org/dist/v0.10.33/node-v0.10.33.tar.gz
tar zxf node-v0.10.33.tar.gz
cd node-v0.10.33
./configure
make
make install
export PATH=$PATH:/usr/local/bin
npm install -g express express-generator


# Comment these lines if starting a new project.
cd /vagrant/node
npm install

# run this to build the seqeulize structure if not yet built (models/config/migrations)
# node_modules/.bin/sequelize init

# Uncomment the following lines if starting a new project. 
# New skeleton express app will be created in /node/geonode to be copied to the /vagrant/node dir.
# Make sure to comment the lines above.
#mkdir -p /node
#cd /node
#express geonode
#cd /node/geonode
#npm install

# Forward port 80 requests to Node's default port 3000
#iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j REDIRECT --to-port 3000
iptables -t nat -I PREROUTING -p tcp --dport 80 -j REDIRECT --to-ports 3000
#iptables -t nat -I OUTPUT -p tcp -d 127.0.0.1 --dport 80 -j REDIRECT --to-ports 3000

# MySql / MariaDB
yum install -y mysql mysql-server
service mysqld start
chkconfig mysqld on
mysqladmin -u root password root # set mysql root password to root

#echo "Symlinking site ..."
#rm -rf /var/www/html #delete html folder so the symlink will recreate it correctly (folder recreated as link).
#ln -s /vagrant $SITE_DIR


# Download geonames data and import into mysql
cd /vagrant/geoname-import/
#sh geonames_importer.sh -a download-data
sh geonames_importer.sh -a create-db -u root -p root
#sh geonames_importer.sh -a import-dumps -u root -p root
mysql -u root -proot --local-infile=1 geoname < geonames_import_example_data.sql

# Restart services
service mysqld restart

# Disabling the development firewall
systemctl stop firewalld.service

echo "Server provisioning complete!"
echo "Start node server by going to /vagrant/node and running 'npm start'"
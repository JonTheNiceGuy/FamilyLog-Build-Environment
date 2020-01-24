#! /bin/bash
echo "fs.inotify.max_user_watches=524288" >> /etc/sysctl.conf
sysctl -p

# Configure MariaDB
export MYSQL_ROOT_PASSWORD=password
debconf-set-selections <<< "mysql-server mysql-server/root_password password $MYSQL_ROOT_PASSWORD"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD"
apt-get update && apt install -y php php-cli php-curl php-gd php-readline php-bcmath php-imagick libapache2-mod-php php-mysql mariadb-server git-core bindfs composer
rm -Rf /var/www/html

echo "CREATE DATABASE mydb; CREATE USER laravel@localhost IDENTIFIED BY 'password'; GRANT ALL ON mydb.* TO laravel@localhost;" | mysql -u root --password "$MYSQL_ROOT_PASSWORD"

# Get PHP Version
PHP_VERSION=$(dpkg -l | grep " php[0-9].[0-9] " | cut -f 3 -d\ | cut -f 3 -dp)

# Install composer and Laravel dependencies
apt install -y "php${PHP_VERSION}-zip" "php${PHP_VERSION}-mbstring"  "php${PHP_VERSION}-xml"

# Configure PHP logging
sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/$PHP_VERSION/apache2/php.ini
sed -i "s/display_errors = .*/display_errors = On/" /etc/php/$PHP_VERSION/apache2/php.ini
sed -i "s/disable_functions = .*/disable_functions = /" /etc/php/$PHP_VERSION/cli/php.ini

# Reconfigure Apache2
a2enmod rewrite
systemctl restart apache2

# Configure mount of /var/www from /vagrant
echo "/vagrant/var/www  /var/www   fuse.bindfs _netdev,force-user=www-data,force-group=www-data,perms=0644:a+D 0 0" >> /etc/fstab
mount -a

# Allow Shell as www-data
chsh -s /bin/bash www-data

# Install package dependencies
cd /var/www/html ; sudo -u www-data composer install

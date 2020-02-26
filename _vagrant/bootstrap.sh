#!/usr/bin/env bash

# Use single quotes instead of double quotes to make it work with special-character passwords
PASSWORD='12345678'
PROJECTFOLDER='myproject'

yum update
yum install -y httpd
yum -y install mysql-server mysql
mysqladmin -uroot password $PASSWORD
chkconfig --levels 235 mysqld on
service mysqld restart
yum install -y php-mysql

# Create project folder, written in 3 single mkdir-statements to make sure this runs everywhere without problems
mkdir "/var/www"
mkdir "/var/www/html"
mkdir "/var/www/html/${PROJECTFOLDER}"

# setup hosts file
VHOST=$(cat <<EOF
<VirtualHost *:80>
	serverName: localhost
    DocumentRoot "/var/www/html/${PROJECTFOLDER}/public"
    <Directory "/var/www/html/${PROJECTFOLDER}/public">
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF
)
echo "${VHOST}" > /etc/apache2/sites-available/000-default.conf

# enable mod_rewrite
a2enmod rewrite

# restart apache
service httpd restart
# remove default apache index.html
rm -rf "/var/www/html/index.html"
cp -R * "/var/www/html/${PROJECTFOLDER}/"

# run SQL statements from MINI folder
mysql -h "localhost" -u "root" "-p${PASSWORD}" < "/var/www/html/${PROJECTFOLDER}/_install/01-create-database.sql"
mysql -h "localhost" -u "root" "-p${PASSWORD}" < "/var/www/html/${PROJECTFOLDER}/_install/02-create-table-song.sql"
mysql -h "localhost" -u "root" "-p${PASSWORD}" < "/var/www/html/${PROJECTFOLDER}/_install/03-insert-demo-data-into-table-song.sql"

# put the password into the application's config. This is quite hardcore, but why not :)
sed -i "s/your_password/${PASSWORD}/" "/var/www/html/${PROJECTFOLDER}/application/config/config.php"

# final feedback
echo "Voila!"

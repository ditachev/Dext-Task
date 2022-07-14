#! /bin/bash
db_name='${db_name}'
db_username='${db_username}'
db_password='${db_password}'
db_rds_endpoint='${db_rds_endpoint}'
site_url='${site_url}'

yum install -y httpd mysql
amazon-linux-extras enable php7.4
yum install -y php php-{pear,cgi,common,curl,mbstring,gd,mysqlnd,gettext,bcmath,json,xml,fpm,intl,zip,imap,devel}

systemctl restart php-fpm.service

usermod -a -G apache ec2-user
chown -R ec2-user:apache /var/www
find /var/www -type d -exec chmod 2775 {} \;
find /var/www -type f -exec chmod 0664 {} \;

cd /var/www/html

wget http://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
rm -f latest.tar.gz

systemctl start httpd
systemctl enable httpd

curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp
wp core download --path=/var/www/html --allow-root

wp config create --dbname=$db_name --dbuser=$db_username --dbpass=$db_password --dbhost=$db_rds_endpoint --path=/var/www/html --allow-root

chown -R ec2-user:apache /var/www/html
chmod -R 774 /var/www/html

# sed -i '/<Directory "\/var\/www\/html">/,/<\/Directory>/ s/AllowOverride None/AllowOverride all/' /etc/httpd/conf/httpd.conf

systemctl restart httpd

wp core install --url=$site_url --title="Linux Namespaces" --admin_name=$db_username --admin_password=$db_password --admin_email=admin@admin.com --allow-root

systemctl restart httpd

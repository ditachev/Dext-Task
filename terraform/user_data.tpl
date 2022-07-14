#! /bin/bash
yum install -y httpd mysql
amazon-linux-extras enable php7.4
yum install -y php-cli php-pdo php-fpm php-json php-mysqlnd

cd /var/www/html
wget http://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
rm latest.tar.gz

systemctl start httpd
systemctl enable httpd

curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp
wp core download --path=/var/www/html --allow-root

wp config create --dbname=$db_name --dbuser=$db_username --dbpass=$db_password --dbhost=$db_rds_endpoint --path=/var/www/html --allow-root

systemctl enable httpd.service
systemctl restart httpd.service

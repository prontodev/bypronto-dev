# Init script for WordPress trunk site

# Install required packages
apt-get -y install curl libcurl3 libcurl3-dev php5-curl

# Install HHVM
sudo apt-get -y install libgmp-dev libmemcached-dev

wget -O - http://dl.hhvm.com/conf/hhvm.gpg.key | sudo apt-key add -
echo deb http://dl.hhvm.com/ubuntu trusty main | sudo tee /etc/apt/sources.list.d/hhvm.list
sudo apt-get update
sudo apt-get -y install hhvm

echo "Commencing Bypronto Setup"

# Make a database, if we don't already have one
echo "Creating Bypronto database (if it's not already there)"
mysql -u root --password=root -e "CREATE DATABASE IF NOT EXISTS bypronto"
mysql -u root --password=root -e "GRANT ALL PRIVILEGES ON bypronto.* TO wp@localhost IDENTIFIED BY 'wp';"

# Make a database, if we don't already have one
echo "Creating Bypronto database for test (if it's not already there)"
mysql -u root --password=root -e "CREATE DATABASE IF NOT EXISTS bypronto_test"
mysql -u root --password=root -e "GRANT ALL PRIVILEGES ON bypronto_test.* TO wp@localhost IDENTIFIED BY 'wp';"

cp /srv/www/wp-tests-config.php /srv/www/wordpress-develop/
cp /srv/www/bootstrap.php /srv/www/wordpress-develop/tests/phpunit/includes/
mv /srv/www/bypronto /srv/www/wordpress-develop/

# Generate the wp-config file
wp core config --dbname="bypronto" --dbuser=root --dbpass=root --dbhost="localhost" --allow-root --path=/srv/www/wordpress-develop/bypronto/ --extra-php <<PHP
\$memcached_servers = array( 'default' => array( '127.0.0.1:11211' ) );
define( 'WP_DEBUG', true );
define( 'WP_DEBUG_LOG', true );
define( 'SAVEQUERIES', true );
define( 'DEVBAR_NOTIFY', true );
PHP

# Install multisite
wp core multisite-install --url=local.bypronto.dev --subdomains --title="Phoenix Test" --admin_user=admin --admin_password=password --admin_email=admin@pronto.com --allow-root --path=/srv/www/wordpress-develop/bypronto/
wp theme activate phoenix-child --allow-root --path=/srv/www/wordpress-develop/bypronto/

# Install plugins
wp plugin install debug-bar --activate --allow-root --path=/srv/www/wordpress-develop/bypronto/
wp plugin install log-deprecated-notices --activate --allow-root --path=/srv/www/wordpress-develop/bypronto/

# Enable Object Cache on Bypronto.
echo "Enable Object Cache on Bypronto"
ln -s /srv/www/wordpress-develop/bypronto/conf/object-cache.php /srv/www/wordpress-develop/bypronto/wp-content/

# Install WP Mock
echo "Install WP Mock on Bypronto"
composer require --dev 10up/wp_mock:dev-master
mv composer.json /srv/www/wordpress-develop/bypronto/
mv composer.lock /srv/www/wordpress-develop/bypronto/
mv vendor /srv/www/wordpress-develop/bypronto/

## The Vagrant site setup script will restart Nginx for us

## Let the user know the good news
echo "Bypronto site is now installed!";

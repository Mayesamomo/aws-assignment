procedimento para instalar agente no linux

#!/bin/bash-x
#REGION=$(curl 169.254.169.244/latast/meta-data/placement/avaibility-zone/
sudo yum update -y
sudo amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
sudo yum install -y httpd
sudo systemctl start httpd
sudo systemctl enable httpd
sudo groupadd www
sudo usermod -a -G www ec2-user

#exit and log back in and verify www group exists with the groups command by typing "groups"
#Change the group ownership of the /var/www directory and its contents to the www group.
sudo chgrp -R www /var/www

#Change the directory permissions of /var/www and its subdirectories to add group write permissions and set the group ID on subdirectories created in the future.

#sudo su as a root user
sudo su 
chmod 2775 /var/www
find /var/www -type d -exec sudo chmod 2775 {} +

#change the permissions for files in the /var/www directory and its subdirectories to add group write permissions.

find /var/www -type f -exec sudo chmod 0664 {} +

# change the directory to /var/www and create a new subdirectory named inc.

cd /var/www
mkdir inc
cd inc
#Create a new file in the inc directory named dbinfo.inc, and then edit the file and enter database set-up config .
nano dbinfo.inc
#Install Node
#nvm install node

#install git
sudo yum install git

#install Nginx server for Node
#sudo amazon-linux-extras install nginx1.12

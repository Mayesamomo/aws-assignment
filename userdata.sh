procedimento para instalar agente no linux

#!/bin/bash-x
#REGION=$(curl 169.254.169.244/latast/meta-data/placement/avaibility-zone/
sudo yum update -y
sudo amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
sudo yum install -y httpd
sudo systemctl start httpd
sudo systemctl enable httpd
#sudo yum install wget

#Install Node
#nvm install node

#install git
sudo yum install git

#install Nginx server for Node
#sudo amazon-linux-extras install nginx1.12

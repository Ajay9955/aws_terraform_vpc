#!/bin/bash

sudo apt update
sudo apt install -y apache2

cat<<EOF > /var/www/html/index.html
<h1>HI, I am krishna </h1>

EOF

sudo systemctl start apache2
sudo systemctl enable apache2
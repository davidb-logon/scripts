
#!/usr/bin/bash 

echo "Run the buildcs.sh script"
exit

yum install -y epel-release
yum install -y java-1.11.0-openjdk-devel maven python-setuptools python-pip genisoimage git 

# If installing on a mac, use homebrew to install jdk 11 like so:
#: brew install java11
#: sudo ln -sfn /usr/local/opt/openjdk@11/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-11.jdk
#: echo 'export PATH="/usr/local/opt/openjdk@11/bin:$PATH"' >> /Users/dbarta/.bash_profile
#: echo 'export CPPFLAGS="-I/usr/local/opt/openjdk@11/include"' >> /Users/dbarta/.bash_profile

# To install Maven 3.6.3 (make sure this is the one)
# download it from https://archive.apache.org/dist/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz
# unzip and move the directory to /Library, and then add the following to .bash_profile:
#: export MAVEN_HOME=/Library/apache-maven-3.6.3
#: export PATH=$MAVEN_HOME/bin:$PATH  
#: to install mysql on mac:
#: brew install mysql
#: brew services start mysql



# To install mysql community server 8.0 on centOS 9 (as part of building the dev env for cloudstack)

wget https://repo.mysql.com//mysql80-community-release-el9-1.noarch.rpm
sudo dnf install mysql-community-server 
sudo yum install pip

# to find the root password for the database
sudo grep 'A temporary password is generated' /var/log/mysqld.log | tail -1 

#temp password: ez#H>=hO/3Zh
#
# new password for root: Wave-123
sudo mysql_secure_installation 
# Enter password for user root: [Enter temporary password]
# New password: [Enter a new password]
# Re-enter new password: [Re-enter new password]
# Change the password for root ? ((Press y|Y for Yes, any other key for No) : n
# Remove anonymous users? (Press y|Y for Yes, any other key for No) : y
# Disallow root login remotely? (Press y|Y for Yes, any other key for No) : y
# Remove test database and access to it? (Press y|Y for Yes, any other key for No) : y
# Reload privilege tables now? (Press y|Y for Yes, any other key for No) : y

mvn -Pdeveloper,systemvm clean install -DskipTests

# 
# copy utils/conf/db.properties yo db.properties.override
cp utils/conf/db.properties utils/conf/db.properties.override 

# Chane root password in utils/conf/db.properties.override, I changed to "Wave-123"
# Remove the password validation plugin to allow the "cloud" password:
mysql -uroot -pWave-123
UNINSTALL COMPONENT 'file://component_validate_password';

# Deploy the database
mvn -P developer -pl developer -Ddeploydb

# Run the CS management server
mvn -pl :cloud-client-ui jetty:run

# Build the Web UI:
# Make sure you remove nodejs and npm before running the following
# on CentOS do:
cd ui
curl -sL https://rpm.nodesource.com/setup_14.x | sudo bash -
    sudo yum install nodejs
# on Mac os x do:
#: brew install node@14
#: Add to .bash_profile:
#: export PATH="/usr/local/opt/node@14/bin:$PATH"

# copy the correct package-lock.json to ui
#: run npm install
#: run npm run serve
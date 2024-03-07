#!/bin/bash
# This script prepares the cloudstack build and development environment on Mac OS (Intel) and CentOS 9.
# It assumes a system with no previously installed java, maven, python, node, npm, git and mysql. 
# If your system has any of these installed, please uninstall them prior to running this script.

# The script:
#    1. Installs the required versions of these tools. If these versions are not adhered to exactly,
#       the build will likely fail.
#    2. Clones the https://github.com/avri-log-on/cloudstack.git repo
#    3. Checks out the "3-simulator-enhancements" branch
#    4. Builds CS management server 
#    5. Deploys the CS mysql database
#    6. Builds the CS web app
#    7. Starts the CS management server
#    8. Tells the user how to start the CS UI.

# Function to get the OS name
get_os_name() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "mac"
    elif [[ -e /etc/os-release ]]; then
        source /etc/os-release
        echo "$ID"
    elif [[ -e /etc/redhat-release ]]; then
        echo "redhat"
    elif [[ -e /etc/debian_version ]]; then
        echo "debian"
    else
        echo "unknown"
    fi
}

prepare_cs_build_env_for_mac() {
    cd /tmp

    # Install Java 11
    brew install java11
    sudo ln -sfn /usr/local/opt/openjdk@11/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-11.jdk
    echo 'export PATH="/usr/local/opt/openjdk@11/bin:$PATH"' >> /Users/dbarta/.bash_profile
    echo 'export CPPFLAGS="-I/usr/local/opt/openjdk@11/include"' >> /Users/dbarta/.bash_profile

    # Install Maven 3.6.3
    curl https://archive.apache.org/dist/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz -o mvn363.gz
    cd /Library
    sudo tar -xvf /tmp/mvn363.gz
    echo 'export MAVEN_HOME="/Library/apache-maven-3.6.3"' >> /Users/dbarta/.bash_profile
    echo 'export PATH="$MAVEN_HOME/bin:$PATH"'  >> /Users/dbarta/.bash_profile

    # Install node 14 and npm
    brew install node@14
    echo 'export PATH="/usr/local/opt/node@14/bin:$PATH"' >> /Users/dbarta/.bash_profile

    # Install mysql
    brew install mysql
    brew services start mysql

    source ~/.bash_profile
}

prepare_cs_build_env_for_centos() {
    # Install java 11, maven, git, python
    sudo yum install -y epel-release
    sudo yum install -y java-1.11.0-openjdk-devel maven python-setuptools python-pip pip genisoimage git 

    # Install node 14 and npm
    curl -sL https://rpm.nodesource.com/setup_14.x | sudo bash -
    sudo yum install nodejs
    
    # Install mysql
    wget https://repo.mysql.com//mysql80-community-release-el9-1.noarch.rpm
    sudo dnf install mysql-community-server 
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
}

# Get the OS name
os_name=$(get_os_name)

# Run different commands based on the OS
case "$os_name" in
    "mac")
        echo "Preparing cloudStack dev. environment for Mac"
        prepare_cs_build_env_for_mac
        ;;
    "centos" | "redhat")
        echo "Preparing cloudStack dev. environment for Centos9"
        prepare_cs_build_env_for_centos
        ;;
    "debian" | "ubuntu")
        echo "Build for debian or ubuntu will be done in the future. Sorry."
        exit 1
        ;;
    *)
        echo "Unsupported OS: $os_name"
        exit 1
        ;;
esac

cd ~/wave/git
git clone https://github.com/avri-log-on/cloudstack.git
cd cloudstack
git checkout -b 3-simulator-enhancements origin/3-simulator-enhancements

mvn -Pdeveloper,systemvm clean install -DskipTests

mvn -P developer -pl developer -Ddeploydb

cp -f build-helper/package-lock.json.keep  ui/package-lock.json
cd ui
npm install
cd ..

mvn -pl :cloud-client-ui jetty:run

echo "To run the ui, open another terminal, cd to cloudstack/ui, and run: npm run serve"
echo "Then open a browser to http://localhost:5050"


install_groovy() {
    GROOVY_VERSION="4.0.9"
    GROOVY_URL="https://groovy.jfrog.io/artifactory/dist-release-local/groovy-zips/apache-groovy-binary-${GROOVY_VERSION}.zip"
    INSTALL_DIR="/opt/groovy"

    # Create the installation directory if it doesn't exist
    sudo mkdir -p $INSTALL_DIR

    # Download the Groovy binary
    wget $GROOVY_URL -O /tmp/groovy.zip

    # Extract the downloaded ZIP file
    sudo unzip /tmp/groovy.zip -d $INSTALL_DIR

    # Set up environment variables
    echo "export GROOVY_HOME=${INSTALL_DIR}/groovy-${GROOVY_VERSION}" | sudo tee -a /etc/profile.d/groovy.sh
    echo "export PATH=\$PATH:\$GROOVY_HOME/bin" | sudo tee -a /etc/profile.d/groovy.sh

    # Apply environment variables to the current session
    source /etc/profile.d/groovy.sh

    # Verify the installation
    groovy --version
}

# Run the function
install_groovy

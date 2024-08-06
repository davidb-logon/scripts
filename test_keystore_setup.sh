
rm -f /etc/cloudstack/agent/cloud.jks
rm -f /etc/cloudstack/agent/cloud.csr

sudo keystore_setup_1   /etc/cloudstack/agent/agent.properties \
                        /etc/cloudstack/agent/cloud.jks \
                        e3va7zkS7QnUacBV \
                        365 \
                        /etc/cloudstack/agent/cloud.csr


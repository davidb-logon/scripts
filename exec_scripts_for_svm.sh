

# /home/sefi/scripts/apt_upgrade.sh  2>&1 | tee exec.log
# # /home/sefi/scripts/configure_grub.sh 2>&1 | tee exec.log
# /home/sefi/scripts/configure_locale.sh 2>&1 | tee exec.log
# /home/sefi/scripts/configure_networking.sh 2>&1 | tee exec.log
# /home/sefi/scripts/configure_acpid.sh 2>&1 | tee exec.log
# /home/sefi/scripts/install_systemvm_packages.sh 2>&1 | tee exec.log
# exit
/home/sefi/scripts/configure_conntrack.sh 2>&1 | tee exec.log
/home/sefi/scripts/authorized_keys.sh 2>&1 | tee exec.log
/home/sefi/scripts/configure_persistent_config.sh 2>&1 | tee exec.log
/home/sefi/scripts/configure_login.sh 2>&1 | tee exec.log
/home/sefi/cloud_scripts_shar_archive.sh 2>&1 | tee exec.log
/home/sefi/scripts/configure_systemvm_services.sh 2>&1 | tee exec.log
/home/sefi/scripts/cleanup.sh 2>&1 | tee exec.log
/home/sefi/scripts/finalize.sh 2>&1 | tee exec.log
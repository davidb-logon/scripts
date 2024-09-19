for fldr in cloudstack scripts libvirt-java; do
cd /data/$fldr
pwd
sudo git fetch
sudo git pull
git status
done
# cd /data/scripts
# pwd
# sudo git fetch
# sudo git pull
# git status
# cd /data/libvirt-java
# pwd
# sudo git fetch
# sudo git pull
# git status

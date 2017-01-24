## cluster setup using three nodes. 
## References
## https://redis.io/topics/cluster-tutorial
## https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-redis-on-ubuntu-16-04

# csshx to all three instances
# csshx 10.199.244.8 10.199.253.75 10.199.248.105

# 01. From my laptop, put the new id_rsa files onto the new nodes
#_________________________________________________________________________________________________________
# This is not using cluster ssh
clear
ZRSAZ='/Users/ubathsu/.ssh/id_rsa_nibiru_v2'
ZTARGETFILEZ='/home/ubuntu/.ssh/'
ZSOURCEFILEZ='/Users/ubathsu/.ssh/ppepaf/id_rsa*'

ZBOXZ='ubuntu@10.199.244.8'
ZZZT='scp -i '$ZRSAZ' '$ZSOURCEFILEZ' '$ZBOXZ':'$ZTARGETFILEZ
$ZZZT
#pause
ZBOXZ='ubuntu@10.199.253.75'
ZZZT='scp -i '$ZRSAZ' '$ZSOURCEFILEZ' '$ZBOXZ':'$ZTARGETFILEZ
$ZZZT
#pause
ZBOXZ='ubuntu@10.199.248.105'
ZZZT='scp -i '$ZRSAZ' '$ZSOURCEFILEZ' '$ZBOXZ':'$ZTARGETFILEZ
$ZZZT

#Using cluster ssh
sudo -i
clear
ls -lha /home/ubuntu/.ssh/
#on all nodes, change the owner of these files to root
chown root:root /home/ubuntu/.ssh/id_rsa*
#on all nodes, move these files to /root/.ssh
clear
mv /home/ubuntu/.ssh/id_rsa* /root/.ssh/
ls -lha /root/.ssh/
#Run this on all nodes
clear
chmod 600 /root/.ssh/id_rsa*
cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
#Find out which nodes do not have /root/.ssh/config with StrictHostKeyChecking off
clear
cat /root/.ssh/config
#Run this on the nodes that need it
echo "
host *
user root
StrictHostKeyChecking no
  " >> /root/.ssh/config

# 02. Update Ubuntu and Install build essential
#_________________________________________________________________________________________________________
apt-get update
clear
apt-get install build-essential tcl 

# 03. Download Redis
#_________________________________________________________________________________________________________

# make the directory
clear
mkdir cluster-test && cd cluster-test
# download the latest stable version of the Redis
curl -O http://download.redis.io/redis-stable.tar.gz
# Unpack the tar
tar xzvf redis-stable.tar.gz
# Move into the Redis source directory that was just extracted.
cd redis-stable

## 04. Build and Install Redis
#_________________________________________________________________________________________________________

# compile Redis binaries.
make 
# run the test suite to make sure everything was built correctly.
make test
#result 
#\o/ All tests passed without errors!

# Install the binaries to the system.
clear
make install

## 05. Update the cluster configuration.
#_________________________________________________________________________________________________________
# create configuration directory.
mkdir /etc/redis
# copy the sample config file. 
cp redis.conf /etc/redis
# open the file. 
vi /etc/redis/redis.conf
# modify the followings in each node. 

# On all nodes.
cluster-enabled yes
cluster-config-file nodes-6379.conf
cluster-node-timeout 5000 ## miliseconds

# On node 1
bind 10.199.244.8

# On node 2
bind 10.199.253.75

# On node 3
bind 10.199.248.105

## 06. Start Redis on all nodes.
#_________________________________________________________________________________________________________
vi /etc/systemd/system/redis.service
vi /lib/systemd/system/redis.service

## 07. Create the user group and directories.
#_________________________________________________________________________________________________________
adduser --system --group --no-create-home redis
mkdir /var/lib/redis
chown redis:redis /var/lib/redis
ls -lha /var/lib/redis
chmod 770 /var/lib/redis

## 08. Start Redis on all nodes.
#_________________________________________________________________________________________________________
#clear
#src/redis-server ./redis.conf

# no such commands found as below. 
systemctl start redis
systemctl status redis

## 09. Create the cluster.
#_________________________________________________________________________________________________________
#The redis-trib utility is in the src directory of the Redis source code distribution. 
#You need to install redis gem to be able to run redis-trib
gem install redis
clear
apt-get update
src/redis-trib.rb create 10.199.244.8:6379 10.199.253.75:6379 10.199.248.105:6379 

## 10. Test.
#_________________________________________________________________________________________________________




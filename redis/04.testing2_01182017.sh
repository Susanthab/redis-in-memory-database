
# Redis 
# This video gives you a quick start guide to install and configure Redis so that you can poke around it and play with its features. 

# Before you install Redis, you need to download its binaries and compile it. 

# Before we start, you need to have empty instances spin-up somewhere. In this video I'm already spun-up 3 empty instances in
# AWS. After end of this video, you will get 3 nodes , all are masters Redis cluster. 

# I'm going to ssh to all 3 nodes at once so that its easy to do the configuration'
# I'm using cluster ssh tool to connect to all 3 nodes. 
# connecting to all the nodes. 
csshx 10.199.248.37 10.199.253.244 10.199.244.244 

## -------------------------------------------------------------------------------------------------------------------
## Installing Redis
## -------------------------------------------------------------------------------------------------------------------

# download redis binaries. 
mkdir cluster-test && cd cluster-test
wget http://download.redis.io/redis-stable.tar.gz
tar -xvzf redis-stable.tar.gz
cd cluster-test/

sudo -i
# @ /home/ubuntu/cluster-test/redis-stable
# Install build-essential and redis dependencies
apt-get install -y make gcc build-essential 
apt-get update
apt-get install make
apt-get install gcc
cd deps
make hiredis jemalloc linenoise lua
cd ..

clear
make MALLOC=libc

clear
apt-get install -y tk8.5 tcl8.5
# At this point you can try if your build works correctly by typing make test, but this is an optional step.
make test

# After the compilation the src directory inside the Redis distribution is populated with the different executables that are 
# part of Redis:
#   * redis-server is the Redis Server itself.
#   * redis-sentinel is the Redis Sentinel executable (monitoring and failover).
#   * redis-cli is the command line interface utility to talk with Redis.
#   * redis-benchmark is used to check Redis performances.
#   * redis-check-aof and redis-check-dump are useful in the rare event of corrupted data files.

# It is a good idea to copy both the Redis server and the command line interface in proper places, either manually using the 
# following commands:
#   sudo cp src/redis-server /usr/local/bin/
#   sudo cp src/redis-cli /usr/local/bin/

make install

## We assume you already copied redis-server and redis-cli executables under /usr/local/bin.

# copy redis-server to /usr/local/bin/
# Exec location: /home/ubuntu/cluster-test/redis-stable
cp src/redis-server /usr/local/bin
cp src/redis-cli /usr/local/bin

## -------------------------------------------------------------------------------------------------------------------
## making it a proper configuration.
## -------------------------------------------------------------------------------------------------------------------

# Create a directory where to store your Redis config files and your data:
mkdir /etc/redis
mkdir /var/redis
#Create a directory inside /var/redis that will work as data and working directory for this Redis instance:
mkdir /var/redis/6379

#port
# Every Redis Cluster node requires two TCP connections open. The normal Redis TCP port used to serve clients, 
# for example 6379, plus the port obtained by adding 10000 to the data port, so 16379 in the example.
# This second high port is used for the Cluster bus, that is a node-to-node communication channel using a binary protocol. 
# The Cluster bus is used by nodes for failure detection, configuration update, failover authorization and so forth.

# Copy the init script that you'll find in the Redis distribution under the utils directory into /etc/init.d.
cp utils/redis_init_script /etc/init.d/redis.server 
ls -alh /etc/init.d/redis.server

# Edit the init script.
# Make sure to modify REDISPORT accordingly to the port you are using. 
sudo vi /etc/init.d/redis.server 

# Copy the template configuration file. 
# Note, that file name should be "6379.conf" because this is the file name used in utils/redis_init_script dir. 
cp redis.conf /etc/redis/6379.conf

# Edit the configuration file, making sure to perform the following changes:
vi /etc/redis/6379.conf

    # on all nodes
    cluster-enabled yes
    cluster-config-file nodes-6379.conf
    cluster-node-timeout 5000
    daemonize yes

    # Set daemonize to yes (by default it is set to no).
    # Set the pidfile to /var/run/redis_6379.pid (modify the port if needed).
    # Change the port accordingly. In our example it is not needed as the default port is already 6379.
    # Set your preferred loglevel.
    # Set the logfile to /var/log/redis_6379.log
    # Set the dir to /var/redis/6379 (very important step!)

    # node 1 
    bind 10.199.248.37

    # node 2 
    bind 10.199.253.244

    # node 3
    bind 10.199.244.244

# Finally add the new Redis init script to all the default runlevels using the following command:
update-rc.d redis.server defaults

# You are done! Now you can try running your instance with:
# service redis.server stop
service redis.server start
# or /etc/init.d/redis.server start

# check redis is started.. 
ps -ef|grep "redis"

## checking logfile. 
tail -200f /var/log/redis_6379.log

#### ==========================================

## on seperate tab in all 3 nodes
## install Reby and redis gem
## Eexc location: /home/ubuntu/cluster-test/redis-stable
\curl -L https://get.rvm.io | bash -s stable

source ~/.rvm/scripts/rvm
# or source /usr/local/rvm/scripts/rvm

clear
rvm requirements
rvm install ruby
# You need to install redis gem to be able to run redis-trib, redis cluster command line utility. 
gem install redis

## create the cluster by combining all 3 nodes. 
## redis-trib is, redis cluster command line utility.
## To create your cluster simply type:
src/redis-trib.rb create 10.199.248.37:6379 10.199.253.244:6379 10.199.244.244:6379
  
## test the cluster
## on node 2
src/redis-cli -h 10.199.240.231 cluster nodes

## ----------
## benchmarks
## ----------

wget https://github.com/antirez/redis-rb-cluster/archive/master.zip
sudo apt-get install unzip
unzip master.zip
cd redis-rb-cluster-master
clear
ruby example.rb 10.199.240.231 6379

## --------------------------
## connecting to redis shell. 
## --------------------------
src/redis-cli -h 10.199.253.150 

src/redis-cli -h 10.199.244.183 

src/redis-cli -h 10.199.240.231 

# Some commands. 
src/redis-cli cluster nodes
cluster slots
cluster info
info

## Needs to test. 
## ------------------------------
## Adding a new node as a replica
## ------------------------------

# Two ways. 
# 1. without specifiying which master you need have the slave. 
./redis-trib.rb add-node --slave 127.0.0.1:7006 127.0.0.1:7000
# 2. with specifiying which master you need have the slave. 
./redis-trib.rb add-node --slave --master-id 3c3a0c74aae0b56170ccb03a76b60cfe7dc1912e 127.0.0.1:7006 127.0.0.1:7000

# check the log
tail -200f /var/log/redis_6379.log


## ---------
# References
## ---------
https://redis.io/topics/quickstart
https://www.youtube.com/watch?v=s4YpCA2Y_-Q
https://redis.io/topics/cluster-tutorial
https://redis.io/topics/rediscli
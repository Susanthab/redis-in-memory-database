

csshx 10.199.240.231 10.199.253.150 10.199.244.183 

mkdir build && cd build
wget http://download.redis.io/releases/redis-3.0.0.tar.gz
tar -xvzf redis-3.0.0.tar.gz
cd redis-3.0.0/

sudo apt-get install -y make gcc build-essential 
sudo apt-get update
sudo apt-get install make
sudo apt-get install gcc
cd deps
make hiredis jemalloc linenoise lua
cd ..

clear
make MALLOC=libc

clear
sudo apt-get install -y tk8.5 tcl8.5
make test

## update the configuration of cluster
clear
sudo vi redis.conf

## On all nodes
cluster-enabled yes
cluster-config-file nodes-6379.conf
cluster-node-timeout 5000

## node 1
bind 10.199.240.231

## node 2
bind 10.199.253.150

## node 3
bind 10.199.244.183

## start redis on all 3 nodes
src/redis-server ./redis.conf

## on seperate tab in all 3 nodes
## install Reby and redis gem
cd build/redis-3.0.0/
\curl -L https://get.rvm.io | bash -s stable


source ~/.rvm/scripts/rvm
source /usr/local/rvm/scripts/rvm

clear
rvm requirements
rvm install ruby
# You need to install redis gem to be able to run redis-trib, redis cluster command line utility. 
gem install redis

## create the cluster by combining all 3 nodes. 
## redis-trib is, redis cluster command line utility.
## To create your cluster simply type:
src/redis-trib.rb create 10.199.240.231:6379 10.199.253.150:6379 10.199.244.183:6379

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
client list


## Needs to test. 
## ------------------------------
## Adding a new node as a replica
## ------------------------------

# Two ways. 
# 1. without specifiying which master you need have the slave. 
./redis-trib.rb add-node --slave 127.0.0.1:7006 127.0.0.1:7000
# 2. with specifiying which master you need have the slave. 
./redis-trib.rb add-node --slave --master-id 3c3a0c74aae0b56170ccb03a76b60cfe7dc1912e 127.0.0.1:7006 127.0.0.1:7000

## ---------------------------------
## making it a proper configuration.
## ---------------------------------
## We assume you already copied redis-server and redis-cli executables under /usr/local/bin.

# copy redis-server to /usr/local/bin/
cd build/redis-3.0.0
sudo cp src/redis-server /usr/local/bin
sudo cp /home/ubuntu/build/redis-3.0.0/src/redis-cli /usr/local/bin

# Create a directory where to store your Redis config files and your data:
sudo mkdir /etc/redis
sudo mkdir /var/redis

# Copy the init script that you'll find in the Redis distribution under the utils directory into /etc/init.d.
cd build/redis-3.0.0
sudo cp utils/redis_init_script /etc/init.d/redis.server 
ls -alh /etc/init.d/redis.server

# Edit the init script.
# Make sure to modify REDISPORT accordingly to the port you are using. 
sudo vi /etc/init.d/redis.server 

# Copy the template configuration file. 
# Note, that file name should be "6379.conf" because this is the file name used in utils/redis_init_script dir. 
sudo cp redis.conf /etc/redis/6379.conf

#Create a directory inside /var/redis that will work as data and working directory for this Redis instance:
sudo mkdir /var/redis/6379

# Edit the configuration file, making sure to perform the following changes:
sudo vi /etc/redis/redis.conf
    # Set daemonize to yes (by default it is set to no).
    # Set the pidfile to /var/run/redis_6379.pid (modify the port if needed).
    # Change the port accordingly. In our example it is not needed as the default port is already 6379.
    # Set your preferred loglevel.
    # Set the logfile to /var/log/redis_6379.log
    # Set the dir to /var/redis/6379 (very important step!)

# Finally add the new Redis init script to all the default runlevels using the following command:
sudo update-rc.d redis.server defaults

# You are done! Now you can try running your instance with:
sudo service redis.server start
sudo /etc/init.d/redis.server start

## ---------
# References
## ---------
https://redis.io/topics/quickstart
https://www.youtube.com/watch?v=s4YpCA2Y_-Q
https://redis.io/topics/cluster-tutorial

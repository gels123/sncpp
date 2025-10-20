apt-get update
apt-get install -y curl make gcc build-essential
cd /compile/framework && make clean && make linux

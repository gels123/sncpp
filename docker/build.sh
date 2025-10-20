#!/usr/bin/env bash
set -x
set -e
set -o pipefail

image_name=snpp

#创建编译脚本
compile_file=compile.sh
echo "创建编译脚本: $compile_file"
rm -f $compile_file
cat >$compile_file <<EOL
apt-get update
apt-get install -y curl make gcc build-essential
cd /compile/framework && make clean && make linux
EOL
chmod a+x $compile_file

#启动编译容器并编译工程
echo "启动编译容器并编译工程"
if docker ps -a --format "table {{.Names}}" | grep -q "debain_compile"; then
    docker rm -f debain_compile
fi
docker run --name debain_compile -itd -v $(pwd)/..:/compile debian:12
docker cp $compile_file debain_compile:/compile/$compile_file
docker exec -it debain_compile sh /compile/$compile_file
rm -f $compile_file

#创建镜像
echo "创建镜像: $image_name"
docker rmi $image_name 2>/dev/null && echo "删除snpp镜像成功" || echo "snpp镜像不存在"
docker images -f "dangling=true" -q | xargs -r docker rmi -f
cd .. && docker build -f ./docker/Dockerfile -t $image_name .

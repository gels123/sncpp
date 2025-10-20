# Skynet Docker Image

## Usage

### Build your snpp image with build.sh使用docker/build.sh构建snpp镜像
```console
$ 更新framework/skynet
$ docker pull debian:12
$ cd docker
$ chmod o+x build.sh
$ ./build.sh
```

### Run directly
```console
#测试能否启动成功：docker run -itd .:/apps/snpp debian:12
$ docker run -it --name snpp-gameserver -v ./app-gameserver:/apps/snpp/app snpp
#framework目录若无修改可不映射
$ docker run -it --name snpp-gameserver -v ./app-gameserver:/apps/snpp/app -v ./framework:/apps/snpp/framework -v ./logs/gameserver:/apps/snpp/app/logs snpp
$ docker-compose -f ./docker/docker-compose.yml up
```

## How Build
1. compile project with debian:12 image
2. create image from debian:12

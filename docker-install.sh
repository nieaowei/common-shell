#!/bin/bash
res=""
echo "The script is running."
echo "The docker installer is running."
if res=`docker --version | grep "Docker"`
then
	echo "The Docker is installed."
	echo "Your Docker vesion is $res"
elif	curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
then
	echo "The Docker install is sucessed."
else
	echo "The Docker install is faild."
	exit 1
fi

if mkdir /etc/docker | grep "exist"
then 
	echo "The dir is existed."
fi

if sudo echo "{     
  "registry-mirrors": ["https://9cpn8tt6.mirror.aliyuncs.com"]
}" >> /etc/docker/daemon.json
then
	echo "The config is moved."
else
	echo "The config is not moved."
	exit 3
fi

if systemctl status docker | grep "running"
then
	echo "The Docker is running."
elif systemctl start docker
then
	echo "The Docker is started."
else
	echo "The Docker start is faild."
	exit 2
fi

if systemctl enable docker
then
	echo "The Docker autonal starting is set."
else
	echo "The Docker autonal start seting is faild."
fi

#!/bin/bash
portStart=7000
number=3
requirepass=1234
masterauth=1234
net="redis-bridge"
ipStart="172.19.0"

params(){

	echo "请输入起始端口号:(默认7000)"
	read portStart
	if [ ! -n "$portStart" ]
	then
		portStart=7000
	fi;
	echo "请输入节点数量:(默认3)"
	read number
	if [ ! -n "$number" ]
        then
                number=3
    fi;
    
   
	echo "请输入网桥名称:(默认redis-bridge)"
	read net
	if [ ! -n "$net" ]
        then
                net="redis-bridge"
    fi;

 	op=1
    
    echo "1. 创建集群"
    echo "2. 关闭集群"
    read -p "请输入:" op
    if [ $op -eq 2 ]
    then
        total=`expr ${portStart} + ${number} \* 2 - 1`
        for i in `seq ${portStart} ${total}`;
        do
            docker stop redis-${i} && docker rm redis-${i}
        done
		docker network rm ${net}
        echo "The all node has closed."
        exit 0
    fi
    
    
	echo "请输入授权密码:(默认1234)"
	read requirepass
	if [ ! -n "$requirepass" ]
        then
                requirepass=1234
        fi;
	echo "请输入主节点授权密码:(默认1234)"
	read masterauth
	if [ ! -n "$masterauth" ]
        then
                masterauth=1234
        fi;

	echo "请输入网段起始:(默认172.19.0.0/16)"
	read ipStart
	if [ ! -n "$ipStart" ]
        then
                ipStart="172.19.0.0/16"
        fi;
	if docker network create --driver bridge --subnet=${ipStart} ${net}
	then
		ipStart=${ipStart%.*/*}
	else
		exit 1
	fi
	echo "PortStart:${portStart},Number:${number}"
	echo "Network:${net}"
	echo "IpStart:${ipStart}"
	echo "Total: `expr ${portStart} + ${number} \* 2 - 1`"
}

genTemplate(){
	echo 'port ${PORT}
	protected-mode no
	bind 0.0.0.0
	requirepass ${requirepass}
	masterauth ${masterauth}
	cluster-enabled yes
	cluster-config-file nodes.conf
	cluster-node-timeout 5000
	cluster-announce-ip ${ipStart}.${TEMP}
	cluster-announce-port ${PORT}
	cluster-announce-bus-port 1${PORT}
	appendonly yes' > ./template.tmpl
}
allNode=""

genConfig(){
	total=`expr ${portStart} + ${number} \* 2 - 1`
	for port in `seq ${portStart}  ${total}`; do 
	base=portStart
	ip=$[port-base+2]
	mkdir -p ./${port}/conf
	PORT=${port} TEMP=${ip} ipStart=${ipStart} requirepass=${requirepass} masterauth=${masterauth} envsubst < ./template.tmpl > ./${port}/conf/redis.conf
	mkdir -p ./${port}/data;
	echo "${ipStart}.${ip}:${port}"
	allNode=${allNode}"${ipStart}.${ip}:${port} "
	done
}

startNode(){
	total=`expr ${portStart} + ${number} \* 2 - 1`
	for port in `seq ${portStart}  ${total}`; do 
		base=portStart
		myips=$[port-base+2]
		docker run -d -it -p ${port}:${port} -p 1${port}:1${port} \
		--privileged=true -v $(pwd)/${port}/conf/redis.conf:/usr/local/etc/redis/redis.conf \
		--privileged=true -v $(pwd)/${port}/data:/data \
		--restart always --name redis-${port} --net ${net} --ip ${ipStart}.${myips} \
		--sysctl net.core.somaxconn=1024 redis redis-server /usr/local/etc/redis/redis.conf; \
	done
}

createCluster(){
	echo "$allNode"
	if docker exec -it redis-${portStart} redis-cli --cluster create ${allNode}--cluster-replicas 1 -a ${requirepass}
	then
		exit 0
	else
		total=`expr ${portStart} + ${number} \* 2 - 1`
        for i in `seq ${portStart} ${total}`;
        do
            docker stop redis-${i} && docker rm redis-${i}
        done
		docker network rm ${net}
        echo "The all node has closed."
        exit 0
	fi
}

params
genTemplate
genConfig
startNode
createCluster


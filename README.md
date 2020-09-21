# common-shell

安装Docker: 
  
  `curl https://raw.githubusercontent.com/nieaowei/common-shell/master/docker-install.sh|bash`

Docker-Redis集群:

    先拉取redis镜像:
  
    `docker pull redis`
   
    再执行:
  
    `sh -c "$(curl -fsSL https://raw.githubusercontent.com/nieaowei/common-shell/master/redis-clu.sh)"`

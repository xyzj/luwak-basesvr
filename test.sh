#!/bin/bash
REDISIMAGE=redis:alpine
BASEDIR=$(dirname $(readlink -f "$0"))
aa=$(docker images | grep redis | grep alpine | wc -l)

echo "---$(docker images | grep redis | grep alpine | wc -l)==="
echo "$(docker inspect -f {{.RepoTags}} $REDISIMAGE)"

echo $#
if [ $# = 0 ]; then
    echo "not found"
else
    echo "found"
fi
echo $($BASEDIR/base64 "a2RFnbj3a0kumRg7N1Kumz")

# funETCD(){
#     echo "start etcd"
# }
# for arg in $*; do
#     case $arg in
#     "etcd") echo funEtcd ;;
#     "nginx") echo "funNginx()" ;;
#     "redis") echo "funRedis()" ;;
#     "mariadb") echo "funMariadb()" ;;
#     "rabbitmq") echo "funRabbitmq()" ;;
#     *) echo "unknow $arg" ;;
#     esac
# done

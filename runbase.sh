#!/bin/bash
# Written by: X.Minamoto

# set variable
# BASEDIR=/home/luwak-install
BASEDIR=$(dirname $(readlink -f "$0"))
echo "--------------------------------------------------"
echo "Run in BASEDIR: $BASEDIR"
echo "--------------------------------------------------"

REDISNAME=luwak-redis
REDISIMAGE=redis:alpine

RMQNAME=luwak-rabbitmq
RMQIMAGE=rabbitmq:management-alpine

MDBNAME=luwak-mariadb
MDBIMAGE=mariadb:10.6.4

ETCDNAME=luwak-etcd
ETCDIMAGE=xyzj/etcd:latest

NGINXNAME=luwak-nginx
NGINXIMAGE=nginx:alpine

echo "start sslrenew ..."
start-stop-daemon --start --background -d $BASEDIR -m -p $BASEDIR/sslrenew.pid --exec $BASEDIR/sslrenew
echo ""

sleep 1

# download images
if [ $(docker inspect -f {{.RepoTags}} $REDISIMAGE | grep $REDISIMAGE | wc -l) = "0" ]; then
	echo ">>> download $REDISIMAGE ..."
	docker pull $REDISIMAGE
	echo ""
fi
if [ $(docker inspect -f {{.RepoTags}} $RMQIMAGE | grep $RMQIMAGE | wc -l) = "0" ]; then
	echo ">>> download $RMQIMAGE ..."
	docker pull $RMQIMAGE
	echo ""
fi
if [ $(docker inspect -f {{.RepoTags}} $MDBIMAGE | grep $MDBIMAGE | wc -l) = "0" ]; then
	echo ">>> download $MDBIMAGE ..."
	docker pull $MDBIMAGE
	echo ""
fi
if [ $(docker inspect -f {{.RepoTags}} $ETCDIMAGE | grep $ETCDIMAGE | wc -l) = "0" ]; then
	echo ">>> download $ETCDIMAGE ..."
	docker pull $ETCDIMAGE
	echo ""
fi

funRedis() {
	echo ">>> start redis ..."
	echo "try to delete stopped container: $(docker rm $REDISNAME)"
	docker run -d --restart=unless-stopped --name=$REDISNAME \
		-p6379:6379 \
		$REDISIMAGE \
		--requirepass $(echo "YXJiYWxlc3QK"|base64 -d) \
		--appendfsync no \
		--appendonly no \
		--save ""
	echo ""
}

funRabbitmq() {
	echo ">>> start rabbitmq ..."
	echo "try to delete stopped container: $(docker rm $RMQNAME)"
	docker run -d --restart=unless-stopped --name=$RMQNAME \
		-eRABBITMQ_DEFAULT_USER=$(echo "YXJ4Nwo="|base64 -d) \
		-eRABBITMQ_DEFAULT_PASS=$(echo "YXJiYWxlc3QK"|base64 -d)  \
		-p5671-5672:5671-5672 \
		-p15672:15672 \
		-v$BASEDIR/rabbitmq.config:/etc/rabbitmq/rabbitmq.config \
		-v$BASEDIR/ca:/opt/ca \
		$RMQIMAGE
	echo ""
}

funMariadb() {
	echo ">>> start mariadb ..."
	echo "try to delete stopped container: $(docker rm $MDBNAME)"
	chown -R 999:999 $BASEDIR/dockerDB
	docker run -d --restart=unless-stopped --name=$MDBNAME \
		-eMARIADB_ROOT_PASSWORD="$(echo "bHAxMjM0eHkK"|base64 -d)" \
		-p3306:3306 \
		-v$BASEDIR/myserver.cnf:/etc/mysql/mariadb.conf.d/90-server.cnf \
		-v$BASEDIR/dockerDB:/var/lib/mysql \
		-v$BASEDIR/ca:/opt/ca \
		$MDBIMAGE
	# sleep 1
	# docker exec $MDBNAME chown mysql:mysql /var/lib/mysql -R
	echo ""
}

funEtcd() {
	echo ">>> start etcd ..."
	echo "try to delete stopped container: $(docker rm $ETCDNAME)"
	docker run -d --restart=unless-stopped --name $ETCDNAME \
		-p2378-2379:2378-2379 \
		-v$BASEDIR/ca:/opt/ca \
		$ETCDIMAGE
	echo ""
}

funNginx() {
	echo ">>> start nginx ..."
	echo "try to delete stopped container: $(docker rm $NGINXNAME)"
	docker run -d --restart=unless-stopped --name $NGINXNAME \
		-p2095:80 \
		-p2096:443 \
		-v$BASEDIR/ca:/opt/ca \
		-v$BASEDIR/html:/usr/share/nginx/html \
		-v$BASEDIR/nginx-default:/etc/nginx/sites-enabled/default \
		$NGINXIMAGE
	echo ""
}

echo $*
if [ $# = 0 ]; then
	funEtcd
	funNginx
	funRedis
	funMariadb
	funRabbitmq
else
	for arg in $*; do
		case $arg in
		"etcd") funEtcd ;;
		"nginx") funNginx ;;
		"redis") funRedis ;;
		"mariadb") funMariadb ;;
		"rabbitmq") funRabbitmq ;;
		*) echo "unknow $arg" ;;
		esac
	done
fi

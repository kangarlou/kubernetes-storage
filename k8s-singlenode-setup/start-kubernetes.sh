#############################################
# Ardalan Kangarlou
# 
# Mounting /dev for iSCSI setup
# Setting iSCSI service inside Kubelet
#############################################
export K8S_VERSION=$(curl -sS https://storage.googleapis.com/kubernetes-release/release/stable.txt)
docker run \
    --volume=/:/rootfs:ro \
    --volume=/sys:/sys:ro \
    --volume=/var/lib/docker/:/var/lib/docker:rw \
    --volume=/var/lib/kubelet/:/var/lib/kubelet:rw \
    --volume=/var/run:/var/run:rw \
	--volume=/dev:/dev:rw \
    --net=host \
    --pid=host \
    --privileged=true \
    --name=kubelet \
    -d \
  	gcr.io/google_containers/hyperkube-amd64:${K8S_VERSION} \
		/hyperkube kubelet \
			--containerized \
			--hostname-override="127.0.0.1" \
			--address="0.0.0.0" \
			--api-servers=http://localhost:8080 \
			--config=/etc/kubernetes/manifests \
			--allow-privileged=true --v=2

wget http://storage.googleapis.com/kubernetes-release/release/${K8S_VERSION}/bin/linux/amd64/kubectl
chmod 755 kubectl
PATH=$PATH:`pwd`

# Setting up iSCSI service in the kubelet container
KUBELET=`docker ps --format '{{.ID}} {{.Names}}' | grep kubelet | awk '{print $1}'`
sudo service open-iscsi stop
sudo modprobe iscsi_tcp
docker exec $KUBELET apt-get update
docker exec $KUBELET apt-get install -y \
	open-iscsi \
	lsscsi \
	sg3-utils \
	scsitools \
	kmod \
	ca-certificates
docker exec $KUBELET rm /run/sendsigs.omit.d/iscsid.pid
docker exec $KUBELET sh -c 'echo "InitiatorName=iqn.1993-08.org.debian:01:cca3f14e35" > /etc/iscsi/initiatorname.iscsi'
docker exec $KUBELET service open-iscsi start 

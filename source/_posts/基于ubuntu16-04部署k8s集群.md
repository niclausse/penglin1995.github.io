---
title: 基于ubuntu16.04部署k8s集群<br/>
date: 2019-03-21 14:31:29<br/>
tags: kubernetes<br/>
categories: Linux

---

## 环境信息
### 1 版本信息
<table border="1" width="80%" align="center"><tr><td>名称</td><td>版本</td></tr><tr><th>Docker</th><th>18.06-ce</th></tr><tr><th>Kubernetes</th><th>v1.13.4</th></tr><tr><th>操作系统</th><th>ubuntu16.04</th></tr></table>

### 2 机器信息
<table border="1" width="80%" align="center"><tr><td>IP</td><td>作用</td><td>组件</td></tr><tr><th>192.168.56.20</th><th>master</th><th></th></tr><tr><th>192.168.56.21</th><th>node</th><th></th></tr><tr><th>192.168.56.22</th><th>node</th><th></th></tr></table>

## 部署步骤
### 1 系统配置修改
#### （1）禁用swap
临时禁用：

```sh
swapoff -a
```

永久禁用：                  
将`/etc/fstab`文件中包含swap的行注释掉。

#### （2）关闭防火墙
```sh
ufw disable
ufw status
```

#### （3）禁用Selinux
```sh
apt install selinux-utils
setenforce 0
```

#### （4）主机名及IP映射
在`/etc/hosts`文件中添加：

```sh
192.168.56.20 k8s-master
192.168.56.21 k8s-node1
192.168.56.22 k8s-node2
```
<b>以上操作在三台机器上分别操作。</b>

### 2 安装docker
* 在master节点和node节点分别进行如下操作：

```sh
# Step1：安装一些必要的系统工具
apt-get update
apt-get -y install apt-transport-https ca-certificates curl software-properties-common

# Step2：安装GPG证书
curl -fsSL http://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -

# Step3：写入软件源信息
add-apt-repository "deb [arch=amd64] http://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"
apt-get update

# Step4：查找docker-ce的版本
apt-cache madison docker-ce

# Step5：安装指定版本的docker-ce
apt-get install -y docker-ce=[VERSION]

# Step6：查看docker版本，检查安装
docker version

# Step7：启动docker service
systemctl enable docker
systemctl start docker 
systemctl status docker
```

* 使用阿里云加速器
由于网络原因，从docker hub上拉取镜像的时候会很慢，修改文件`/etc/docker/daemon.json`：

```json
{
    "registry-mirrors": ["https://alzgoonw.mirror.aliyuncs.com"],
    "live-restore": true
}
```

* 重启docker服务

```sh
systemctl daemon-reload
systemctl restart docker
```

### 3 安装kubelet，kubeadm，kubectl
在master节点和node节点分别执行如下操作：

* 添加密钥

```sh
curl -O https://packages.cloud.google.com/apt/doc/apt-key.gpg
apt-key add apt-key.gpg
```

* 添加kubernetes软件源

```sh
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://mirrors.ustc.edu.cn/kubernetes/apt kubernetes-xenial main
EOF
```

* 安装

```sh
apt-get update && apt-get install -y kubelet kubeadm kubectl
systemctl enable kubelet

# 查看版本
kubeadm --version
```

### 4 拉取k8s镜像
由于k8s.gcr.io被墙，可通过阿里云镜像拉取，再重新tag。

```sh
# 查看所需的镜像
kubeadm config images list

# 拉取
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-controller-manager:v1.13.4
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-scheduler:v1.13.4
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-proxy:v1.13.4
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.1
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/etcd:3.2.24
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/coredns:1.2.6
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-apiserver:v1.13.4

# 将这些镜像重新tag
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/kube-controller-manager:v1.13.4 k8s.gcr.io/kube-controller-manager:v1.13.4
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/kube-scheduler:v1.13.4 k8s.gcr.io/kube-scheduler:v1.13.4
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/kube-proxy:v1.13.4 k8s.gcr.io/kube-proxy:v1.13.4
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.1 k8s.gcr.io/pause:3.1
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/etcd:3.2.24 k8s.gcr.io/etcd:3.2.24
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/coredns:1.2.6 k8s.gcr.io/coredns:1.2.6
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/kube-apiserver:v1.13.4 k8s.gcr.io/kube-apiserver:v1.13.4

```

### 5 初始化k8s集群
```sh
kubeadm init --kubernetes-version=v1.13.4 --pod-network-cidr=10.244.0.0/16 --service-cidr=10.96.0.0/12 --apiserver-advertise-address=192.168.56.20 --token-ttl=0 --ignore-preflight-errors=Swap

```

结果如下：

```sh
Your Kubernetes master has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

You can now join any number of machines by running the following on each node
as root:

  kubeadm join 192.168.56.20:6443 --token h7u22o.nk23ias5f1ft8hj9 --discovery-token-ca-cert-hash sha256:9f93785608c9a9de3e5d74e9ed30b8302691abfee7efd946a8c1b80d8582fe92
```

* 在master中查看节点信息：

```sh
kubectl get node

NAME         STATUS   ROLES    AGE   VERSION
k8s-master   NotReady    master   31h   v1.13.4
```

* master节点此时处于NotReady状态，因为没有部署网络，以下为集群部署flannel网络：

```sh
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

再次查看节点信息，发现状态变为Ready。

* 查看kube-system名称空间上运行的pods，若不指定名称空间，会指向默认名称空间defaults

```sh
kubectl get pods -n kube-system
```



### 6 node节点加入集群

```sh
kubeadm join 192.168.56.20:6443 --token h7u22o.nk23ias5f1ft8hj9 --discovery-token-ca-cert-hash sha256:9f93785608c9a9de3e5d74e9ed30b8302691abfee7efd946a8c1b80d8582fe92
```

### 7 在master节点上查看集群信息

```sh
kubectl get nodes
kubectl get pods -n kube-system
```

至此，k8s集群搭建完毕。
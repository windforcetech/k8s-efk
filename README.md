# k8s-efk
K8S ElasticSearch Fluent Kibana集群

---
## 1. 介绍
参考kubernetes官方配置进行集群部署https://github.com/kubernetes/kubernetes/tree/master/cluster/addons/fluentd-elasticsearch

同时，对官方配置参数进行优化

----

## 批量删除pod
`kubectl -n kube-system  get pods | grep Evicted |awk '{print$1}'|xargs kubectl -n kube-system delete`

`kubectl get pods --all-namespaces| grep mysql |awk '{cmd="kubectl delete pod "$2" -n "$1;system(cmd)}'`

volume支持两种方式，一种是直接挂载，一种是通过PVC挂载

### 一、直接挂载
1. 目前仅支持EmptyDir,NFS,Glusterfs,HostPath四种存储类型，后续将增加其他类型；
2. 如何使用，通过以下可以，例如申请type为1的nfs存储，可以直接挂载

`"volumeReqs":[
      	{
      		"type":1,
      		"name":"nfs-fast",
      		"args":{
      			"path":"/nfs",
      			"server":"172.16.18.146"
      		}
      	}]`
		
### 二、通过PVC来挂载，可以实现动态管理
1. 直接挂载的方式无法动态创建PV，一个POD只能挂载一个path挂载点，每次都需要手动创建nfs的PV
2. 使用PVC来挂载，虽然也需要每次创建PV和PVC（一个PV只能和一个PVC绑定，
但多个POD可以共用一个PVC），但通过PVC的StorageClass可以使用实现动态创建PV，POD不用关心磁盘
配合从哪来，直接用就可以，详见https://www.cnblogs.com/DaweiJ/articles/8618317.html。
3. 用法，API请求，注意volumesReq是和containters参数并列的，不在里面，type也必须去掉

`"volumeReqs":[
  	{
  		"name":"nfs-pvc",
  		"persistentVolumeClaim":{
          			"claimName": "test-claim"
        		}
  	}
  ]`
  
4. 注意，一个pvc只能同时被一个POD使用，如果多个PVC，需要先建立一个PVC池，Client端维护
这个PVC的Pooling，创建POD的时候，分配没有使用的PVC的name给POD，POD删除后会回收PVC，
不会删除nfs上的数据。
5. 删除POD不会释放PVC，需要手动删除，调用/api/v1/namespaces/monitoring/persistentvolumeclaims/{pvcname}
的DELETE方法。
6. PVC删除后PV也会自动删除，如果PVC采用claimPolicy=DELETE策略，nfs上的存储也不会真的删除，
会改为目录改为archieved-开头的名字，还是要求nfs服务器上执行手动删除，可以写一个定时任务，定时删除
archieved开头的文件目录。
7. 动态PV创建，PVC会自动在nfs的根目录下面创建namespace-pvcname的文件目录，看不到别人的文件，
实现权限隔离，但是nfs对配额不会限制，每个用户都可以使用/nfs这个挂载卷的最大配额，
一种解决是改造nfs实现二级目录的配额管理，另一种是通过应用手动实现逻辑配额管理。
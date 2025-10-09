### Задание 1 

**Что нужно сделать**

Создать Deployment приложения, состоящего из двух контейнеров и обменивающихся данными.

1. Создать Deployment приложения, состоящего из контейнеров busybox и multitool.
2. Сделать так, чтобы busybox писал каждые пять секунд в некий файл в общей директории.
3. Обеспечить возможность чтения файла контейнером multitool.


**Ответ**

### Создаем манифест для деплоя приложения, в нем 2 контейнера, writer и reader

1) writer записывает время в конец файла log.txt не перезаписывая.
2) reader прочитывает файл в реальном времени, показывая новые строки по мере их появления.

##### containers-data-exchange.yaml

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: data-exchange
spec:
  replicas: 1
  selector:
    matchLabels:
      app: data-exchange-app
  template:
    metadata:
      labels:
        app: data-exchange-app
    spec:
      containers:
      - name: writer
        image: busybox
        command: ["/bin/sh", "-c"] 
        args: ["while true; do echo $(date) >> /shared/data/log.txt; sleep 5; done"]
        volumeMounts:
        - name: shared-data
          mountPath: /shared/data
      - name: reader
        image: wbitt/network-multitool
        command: ["/bin/sh", "-c"]
        args: ["tail -f /shared/data/log.txt"]
        volumeMounts:
        - name: shared-data
          mountPath: /shared/data
      volumes:
      - name: shared-data
        emptyDir: {}
```

##### Описание пода с контейнерами (kubectl describe pods data-exchange)

```
/home/kusk111serj/k8s_homeworks/homework_5/src# kubectl describe pods data-exchange
Name:             data-exchange-6659d456b-k8xd7
Namespace:        default
Priority:         0
Service Account:  default
Node:             ubuntulearn/10.129.0.26
Start Time:       Thu, 09 Oct 2025 04:24:35 +0000
Labels:           app=data-exchange-app
                  pod-template-hash=6659d456b
Annotations:      cni.projectcalico.org/containerID: c918945eb047b159052093dd07e3b722117e9fb8cf27e17f543c0fd390eeb262
                  cni.projectcalico.org/podIP: 10.1.66.138/32
                  cni.projectcalico.org/podIPs: 10.1.66.138/32
Status:           Running
IP:               10.1.66.138
IPs:
  IP:           10.1.66.138
Controlled By:  ReplicaSet/data-exchange-6659d456b
Containers:
  writer:
    Container ID:  containerd://7d709bfded1457a0bd5e2155ee6023629e1eb486ade2d1e47dd11d264639a111
    Image:         busybox
    Image ID:      docker.io/library/busybox@sha256:d82f458899c9696cb26a7c02d5568f81c8c8223f8661bb2a7988b269c8b9051e
    Port:          <none>
    Host Port:     <none>
    Command:
      /bin/sh
      -c
    Args:
      while true; do echo $(date) >> /shared/data/log.txt; sleep 5; done
    State:          Running
      Started:      Thu, 09 Oct 2025 04:24:43 +0000
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /shared/data from shared-data (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-fgdv8 (ro)
  reader:
    Container ID:  containerd://c5e0245dae66752d88ef0695ce2706fda3f81e11bd0a65ef7ca2b67488e5c0f6
    Image:         wbitt/network-multitool
    Image ID:      docker.io/wbitt/network-multitool@sha256:d1137e87af76ee15cd0b3d4c7e2fcd111ffbd510ccd0af076fc98dddfc50a735
    Port:          <none>
    Host Port:     <none>
    Command:
      /bin/sh
      -c
    Args:
      tail -f /shared/data/log.txt
    State:          Running
      Started:      Thu, 09 Oct 2025 04:24:48 +0000
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /shared/data from shared-data (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-fgdv8 (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       True 
  ContainersReady             True 
  PodScheduled                True 
Volumes:
  shared-data:
    Type:       EmptyDir (a temporary directory that shares a pod's lifetime)
    Medium:     
    SizeLimit:  <unset>
  kube-api-access-fgdv8:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:                      <none>

```

##### Вывод команды чтения файла (tail -f <имя общего файла>)

<img width="884" height="309" alt="task_1" src="https://github.com/user-attachments/assets/d176029f-a51a-4e01-b265-a8f91baef378" />



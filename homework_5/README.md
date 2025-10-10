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

## Задание 2. PV, PVC
### Задача
Создать Deployment приложения, использующего локальный PV, созданный вручную.

### Шаги выполнения
1. Создать Deployment приложения, состоящего из контейнеров busybox и multitool, использующего созданный ранее PVC
2. Создать PV и PVC для подключения папки на локальной ноде, которая будет использована в поде.
3. Продемонстрировать, что контейнер multitool может читать данные из файла в смонтированной директории, в который busybox записывает данные каждые 5 секунд. 
4. Удалить Deployment и PVC. Продемонстрировать, что после этого произошло с PV. Пояснить, почему. (Используйте команду `kubectl describe pv`).
5. Продемонстрировать, что файл сохранился на локальном диске ноды. Удалить PV.  Продемонстрировать, что произошло с файлом после удаления PV. Пояснить, почему.


**Ответ**


### Создаем манифест для деплоя приложения, в нем 2 контейнера, writer и reader, также как в первой задаче writer будет записывать время, но теперь будет использоваться локальный PV и все будет писаться в ранее созданную директорию.

1) writer записывает время в конец файла log.txt не перезаписывая.
2) reader прочитывает файл в реальном времени, показывая новые строки по мере их появления.
3) создаем директорию для локального PV: mkdir -p /mnt/local-data


### pv-pvc.yaml

```
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-pv
spec:
  capacity:
    storage: 1Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  hostPath:
    path: /mnt/local-data
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
spec:
  volumeName: local-pv
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: data-exchange-pvc
spec:
  replicas: 1
  selector:
    matchLabels:
      app: data-exchange
  template:
    metadata:
      labels:
        app: data-exchange
    spec:
      containers:
      - name: writer
        image: busybox
        command: ["/bin/sh", "-c", "while true; do echo 'Data from busybox at '$(date) >> /shared/data.txt; sleep 5; done"]
        volumeMounts:
        - name: shared-volume
          mountPath: /shared
      - name: reader
        image: wbitt/network-multitool
        command: ["/bin/sh", "-c", "tail -f /shared/data.txt"]
        volumeMounts:
        - name: shared-volume
          mountPath: /shared
      volumes:
      - name: shared-volume
        persistentVolumeClaim:
          claimName: data-pvc
```

#### Примемяем манифест и проверяем что все создалось корректно:

<img width="1098" height="264" alt="task_2 1" src="https://github.com/user-attachments/assets/9770a41a-2b63-426c-a6d5-01b86e5be3a4" />

          
#### Проверяем, что контейнер multitool может читать данные из примонтированной директории:

```
root@ubuntulearn:/home/kusk111serj/k8s_homeworks/homework_5/src# kubectl logs data-exchange-pvc-68cddd98f6-gkq8k -c reader
Data from busybox at Thu Oct 9 09:00:20 UTC 2025
Data from busybox at Thu Oct 9 09:00:25 UTC 2025
Data from busybox at Thu Oct 9 09:00:30 UTC 2025
Data from busybox at Thu Oct 9 09:00:35 UTC 2025
Data from busybox at Thu Oct 9 09:00:40 UTC 2025
Data from busybox at Thu Oct 9 09:00:45 UTC 2025
Data from busybox at Thu Oct 9 09:00:50 UTC 2025
Data from busybox at Thu Oct 9 09:00:55 UTC 2025
Data from busybox at Thu Oct 9 09:01:00 UTC 2025
Data from busybox at Thu Oct 9 09:01:05 UTC 2025
Data from busybox at Thu Oct 9 09:01:10 UTC 2025
Data from busybox at Thu Oct 9 09:01:15 UTC 2025
Data from busybox at Thu Oct 9 09:01:20 UTC 2025
Data from busybox at Thu Oct 9 09:01:25 UTC 2025
Data from busybox at Thu Oct 9 09:01:30 UTC 2025
Data from busybox at Thu Oct 9 09:01:35 UTC 2025
Data from busybox at Thu Oct 9 09:01:40 UTC 2025
Data from busybox at Thu Oct 9 09:01:45 UTC 2025
```

Примонтированый файл:

```
root@ubuntulearn:/home/kusk111serj/k8s_homeworks/homework_5/src# tail -f /mnt/local-data/data.txt
Data from busybox at Thu Oct 9 09:03:45 UTC 2025
Data from busybox at Thu Oct 9 09:03:50 UTC 2025
Data from busybox at Thu Oct 9 09:03:55 UTC 2025
Data from busybox at Thu Oct 9 09:04:00 UTC 2025
Data from busybox at Thu Oct 9 09:04:05 UTC 2025
Data from busybox at Thu Oct 9 09:04:10 UTC 2025
Data from busybox at Thu Oct 9 09:04:15 UTC 2025
Data from busybox at Thu Oct 9 09:04:20 UTC 2025
Data from busybox at Thu Oct 9 09:04:25 UTC 2025
Data from busybox at Thu Oct 9 09:04:30 UTC 2025
Data from busybox at Thu Oct 9 09:04:35 UTC 2025
```

 
#### Удаляем  Deployment и PVC и сразу даем 2 команды, kubectl get pvс и kubectl describe pv local-pv

<img width="1004" height="442" alt="task_2 6" src="https://github.com/user-attachments/assets/de718b49-4eac-41fb-9d5b-174ff285502e" />

PV переходит в статус Released, но не удаляется автоматически, потому что persistentVolumeReclaimPolicy: Retain значит, что данные необходимо сохранять даже после освобождения pvc. PV ожидает ручной очистки или повтороного использования.


#### Демонстрируем что файл сохранлися на локальной ноде:

```
root@ubuntulearn:/home/kusk111serj/k8s_homeworks/homework_5/src# ls -la /mnt/local-data/
total 36
drwxrwxrwx 2 root root  4096 Oct  9 08:03 .
drwxr-xr-x 3 root root  4096 Oct  9 08:02 ..
-rw-r--r-- 1 root root 23282 Oct  9 09:05 data.txt
root@ubuntulearn:/home/kusk111serj/k8s_homeworks/homework_5/src# cat /mnt/local-data/data.txt
Data from busybox at Thu Oct 9 09:03:45 UTC 2025
Data from busybox at Thu Oct 9 09:03:50 UTC 2025
Data from busybox at Thu Oct 9 09:03:55 UTC 2025
Data from busybox at Thu Oct 9 09:04:00 UTC 2025
Data from busybox at Thu Oct 9 09:04:05 UTC 2025
Data from busybox at Thu Oct 9 09:04:10 UTC 2025
Data from busybox at Thu Oct 9 09:04:15 UTC 2025
Data from busybox at Thu Oct 9 09:04:20 UTC 2025
Data from busybox at Thu Oct 9 09:04:25 UTC 2025

```

#### Удаляем PV, смотрим что файл никуда не делся:

<img width="616" height="141" alt="task_2 5" src="https://github.com/user-attachments/assets/d5829262-636d-4d27-b1c8-e4b943dc3462" />

PV с persistentVolumeReclaimPolicy: Retain, это значит, что при удалении PV данные не удаляются автоматически. Удаление PV в k8s не затрагивает физические файлы на диске. 

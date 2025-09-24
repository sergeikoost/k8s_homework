### Задание 1. Создать Pod с именем hello-world

1. Создать манифест (yaml-конфигурацию) Pod.
2. Использовать image - gcr.io/kubernetes-e2e-test-images/echoserver:2.2.
3. Подключиться локально к Pod с помощью `kubectl port-forward` и вывести значение (curl или в браузере).

**Ответ.**


#### Файл pod.yaml

```
---
apiVersion: v1
kind: Pod
metadata:
  name: echoserver
  namespace: default
  labels:
    app: echoserver
    comment: task1.1
spec:
  containers:
  - name: echoserver
    image: gcr.io/kubernetes-e2e-test-images/echoserver:2.2
    resources:
      requests:
        memory: "100Mi"
        cpu: "100m"
      limits:
        memory: "200Mi"
        cpu: "500m"
    ports:
    - name: http
      containerPort: 8080
    - name: https
      containerPort: 8443
...
```

Pod создался корректно:
```
root@ubuntulearn:/home/kusk111serj/k8s_homeworks/homework_2/src#  kubectl get pods -A
NAMESPACE     NAME                                         READY   STATUS    RESTARTS      AGE
default       echoserver                                   1/1     Running   0             97s
```


#### Проверяем - kubectl port-forward --address=0.0.0.0 pods/echoserver 8080 8443

<img width="1172" height="542" alt="hm2 1" src="https://github.com/user-attachments/assets/797b1261-23b8-498c-85ec-ea93f6dcc12e" />


### Задание 2. Создать Service и подключить его к Pod

1. Создать Pod с именем netology-web.
2. Использовать image — gcr.io/kubernetes-e2e-test-images/echoserver:2.2.
3. Создать Service с именем netology-svc и подключить к netology-web.
4. Подключиться локально к Service с помощью `kubectl port-forward` и вывести значение (curl или в браузере).

**Ответ.**

#### Конфигурация для Pod с именем netology-web, podtask2.yaml

```
---
apiVersion: v1
kind: Pod
metadata:
  name: netology-web
  labels:
    app: netology-web
    comment: task2.1
  namespace: default
spec:
  containers:
  - name: netology-web
    image: gcr.io/kubernetes-e2e-test-images/echoserver:2.2
    resources:
      requests:
        memory: "100Mi"
        cpu: "100m"
      limits:
        memory: "200Mi"
        cpu: "500m"
    ports:
    - name: http
      containerPort: 8080
    - name: https
      containerPort: 8443
...
```
#### Конфигурация service.yaml

```
---
apiVersion: v1
kind: Service
metadata:
  name: netology-svc
spec:
  selector:
    app: netology-web
  type: ClusterIP
  ports:
  - name: http
    port: 8080
    targetPort: 8080
  - name: https
    port: 8443
    targetPort: 8443
...
```
#### Запускаем 

```
root@ubuntulearn:/home/kusk111serj/k8s_homeworks/homework_2/src# kubectl get svc --show-labels 
NAME           TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE     LABELS
kubernetes     ClusterIP   10.152.183.1     <none>        443/TCP             43h     component=apiserver,provider=kubernetes
netology-svc   ClusterIP   10.152.183.123   <none>        8080/TCP,8443/TCP   2m55s   <none>
root@ubuntulearn:/home/kusk111serj/k8s_homeworks/homework_2/src# kubectl get pods  --show-labels 
NAME           READY   STATUS    RESTARTS   AGE     LABELS
echoserver     1/1     Running   0          30m     app=echoserver,comment=task1.1
netology-web   1/1     Running   0          3m21s   app=netology-web,comment=task2.1
```

#### Проверяем

```
kubectl port-forward --address=0.0.0.0 service/netology-svc 8080:8080 8443:8443
```

<img width="1108" height="509" alt="hm2 2" src="https://github.com/user-attachments/assets/2a224fec-e882-42bf-9094-ec95935d899a" />

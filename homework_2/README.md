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

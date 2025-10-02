### Задание 1. Создать Deployment и обеспечить доступ к контейнерам приложения по разным портам из другого Pod внутри кластера

1. Создать Deployment приложения, состоящего из двух контейнеров (nginx и multitool), с количеством реплик 3 шт.
2. Создать Service, который обеспечит доступ внутри кластера до контейнеров приложения из п.1 по порту 9001 — nginx 80, по 9002 — multitool 8080.
3. Создать отдельный Pod с приложением multitool и убедиться с помощью `curl`, что из пода есть доступ до приложения из п.1 по разным портам в разные контейнеры.
4. Продемонстрировать доступ с помощью `curl` по доменному имени сервиса.
5. Предоставить манифесты Deployment и Service в решении, а также скриншоты или вывод команды п.4.

**Ответ**

#### Для выполнения задания создаем 3 файла.

1) deploy_1.yaml

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-multitool-deployment
  namespace: task1
  labels:
    app: nginx-multitool
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx-multitool
  template:
    metadata:
      labels:
        app: nginx-multitool
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
      - name: multitool
        image: praqma/network-multitool:alpine-extra
        env:
        - name: HTTP_PORT
          value: "8080"
        ports:
        - containerPort: 8080
```

2) service.yaml

```
apiVersion: v1
kind: Service
metadata:
  name: clusterip-service
  namespace: task1
spec:
  selector:
    app: nginx-multitool
  type: ClusterIP
  ports:
  - name: nginx
    port: 9001
    targetPort: 80
  - name: multitool
    port: 9002
    targetPort: 8080
```
3) nodeport-service.yaml

```
apiVersion: v1
kind: Service
metadata:
  name: nodeport-service
  namespace: task1
spec:
  selector:
    app: nginx-multitool
  type: NodePort
  ports:
  - name: nginx
    port: 80
    targetPort: 80
    nodePort: 30080
  ```  

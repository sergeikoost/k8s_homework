### Задание 1. Создать Deployment и обеспечить доступ к контейнерам приложения по разным портам из другого Pod внутри кластера

1. Создать Deployment приложения, состоящего из двух контейнеров (nginx и multitool), с количеством реплик 3 шт.
2. Создать Service, который обеспечит доступ внутри кластера до контейнеров приложения из п.1 по порту 9001 — nginx 80, по 9002 — multitool 8080.
3. Создать отдельный Pod с приложением multitool и убедиться с помощью `curl`, что из пода есть доступ до приложения из п.1 по разным портам в разные контейнеры.
4. Продемонстрировать доступ с помощью `curl` по доменному имени сервиса.
5. Предоставить манифесты Deployment и Service в решении, а также скриншоты или вывод команды п.4.

**Ответ**

#### Для выполнения задания создаем 2 файла.

1) deploy_1.yaml

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deploy
  labels:
    task: one
    tier: homework
  annotations:
    container1: nginx
    container2: multitool  
  namespace: task1
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
          resources:
            limits:
              memory: "64Mi"
              cpu: "200m"
            requests:
              memory: "32Mi"
              cpu: "100m"
          ports:
            - containerPort: 80
          livenessProbe:
            tcpSocket:
              port: 80
            initialDelaySeconds: 30
            periodSeconds: 20
          readinessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 30
            periodSeconds: 20
        - name: multitool
          image: praqma/network-multitool:alpine-extra
          resources:
            limits:
              memory: "64Mi"
              cpu: "200m"
            requests:
              memory: "32Mi"
              cpu: "100m"
          env:
            - name: HTTP_PORT
              value: "8080"
            - name: HTTPS_PORT
              value: "1443"
          ports:
            - name: http
              containerPort: 8080
              protocol: TCP
            - name: https
              containerPort: 1443
              protocol: TCP
          livenessProbe:
            tcpSocket:
              port: 8080
            initialDelaySeconds: 10
          readinessProbe:
            httpGet:
              path: /
              port: 8080
            initialDelaySeconds: 15
```

2) service.yaml

```
---
apiVersion: v1
kind: Service
metadata:
  name: service
  namespace: homework4
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
...
```


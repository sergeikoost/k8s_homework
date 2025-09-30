### Задание 1. Создать Deployment и обеспечить доступ к репликам приложения из другого Pod

1. Создать Deployment приложения, состоящего из двух контейнеров — nginx и multitool. Решить возникшую ошибку.
2. После запуска увеличить количество реплик работающего приложения до 2.
3. Продемонстрировать количество подов до и после масштабирования.
4. Создать Service, который обеспечит доступ до реплик приложений из п.1.
5. Создать отдельный Pod с приложением multitool и убедиться с помощью curl, что из пода есть доступ до приложений из п.1.

**Ответ**

#### Создаем 3 файла для выполнения всех задач:

1. deployment_task1.yaml

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deploy
  labels:
    task: one
    tier: homework
  namespace: task1
spec:
  replicas: 2
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
              value: "1181"
            - name: HTTPS_PORT
              value: "1443"
          ports:
            - name: http
              containerPort: 1181
              protocol: TCP
            - name: https
              containerPort: 2443
              protocol: TCP
          livenessProbe:
            tcpSocket:
              port: 1181
            initialDelaySeconds: 10
          readinessProbe:
            httpGet:
              path: /
              port: 1181
            initialDelaySeconds: 15
```

2. pod.yaml

```
apiVersion: v1
kind: Service
metadata:
  name: nginx-multitool-service
  namespace: task1
spec:
  selector:
    app: nginx-multitool
  ports:
    - name: nginx
      port: 8081
      targetPort: 8081
    - name: multitool
      port: 8080     
      targetPort: 8080 
  type: ClusterIP
```

3. services.yaml

```
apiVersion: v1
kind: Service
metadata:
  name: nginx-multitool-service
  namespace: task1
spec:
  selector:
    app: nginx-multitool
  ports:
    - name: nginx
      port: 8080
      targetPort: 80
    - name: multitool-http
      port: 9080
      targetPort: 1181
    - name: multitool-https
      port: 9443
      targetPort: 2443
  type: ClusterIP
```

#### Запускаем и увеличиваем количество реплик работающего приложения до 2

```
root@ubuntulearn:/home/kusk111serj/k8s_homeworks/homework_3/src# kubectl apply -f service.yaml -n task1
service/nginx-multitool-service configured

root@ubuntulearn:/home/kusk111serj/k8s_homeworks/homework_3/src# kubectl apply -f deployment_task1.yaml -n task1
deployment.apps/deploy created

root@ubuntulearn:/home/kusk111serj/k8s_homeworks/homework_3/src# kubectl scale deployment deploy --replicas=2 -n task1
deployment.apps/deploy scaled

```
#### Проверяем pod-ы
<img width="1238" height="88" alt="1 1" src="https://github.com/user-attachments/assets/7d2a0b2f-7c83-4969-8144-2253e06b37ef" />


#### Создаем отдельный под для проверок

```
root@ubuntulearn:/home/kusk111serj/k8s_homeworks/homework_3/src# kubectl apply -f pod.yaml -n task1
```

#### Делаем curl

```
root@ubuntulearn:/home/kusk111serj/k8s_homeworks/homework_3/src# kubectl get svc -n task1
NAME                      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
nginx-multitool-service   ClusterIP   10.152.183.166   <none>        8080/TCP,9080/TCP,9443/TCP   7s



root@ubuntulearn:/home/kusk111serj/k8s_homeworks/homework_3/src# kubectl exec -it test-multitool -n task1 -- curl nginx-multitool-service:9080
Praqma Network MultiTool (with NGINX) - deploy-74d84d7d44-2bt97 - 10.1.66.169
root@ubuntulearn:/home/kusk111serj/k8s_homeworks/homework_3/src# kubectl exec -it test-multitool -n task1 -- curl nginx-multitool-service:9443
<html>
<head><title>400 The plain HTTP request was sent to HTTPS port</title></head>
<body>
<center><h1>400 Bad Request</h1></center>
<center>The plain HTTP request was sent to HTTPS port</center>
<hr><center>nginx/1.18.0</center>
</body>
</html>
```

### Задание 2. Создать Deployment и обеспечить старт основного контейнера при выполнении условий

1. Создать Deployment приложения nginx и обеспечить старт контейнера только после того, как будет запущен сервис этого приложения.
2. Убедиться, что nginx не стартует. В качестве Init-контейнера взять busybox.
3. Создать и запустить Service. Убедиться, что Init запустился.
4. Продемонстрировать состояние пода до и после запуска сервиса.

#### Для выполнения 2 задачи создаем 2 файла.

1. deployment_task1.yaml

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deploy2
  namespace: task2
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx-init
  template:
    metadata:
      labels:
        app: nginx-init
    spec:
      initContainers:
      - name: wait-for-service
        image: busybox:1.36
        command: 
          - 'sh'
          - '-c'
          - |
            until nslookup svc2.task2.svc.cluster.local; do 
              echo "Waiting for service svc2..."; 
              sleep 3; 
            done
            echo "Service servicetask2 is available!"
      containers:
      - name: nginx
        image: nginx:1.24.0
        resources:
          limits:
            memory: "64Mi"
            cpu: "250m"
          requests:
            memory: "32Mi"
            cpu: "100m"
        ports:
        - containerPort: 80
```

2. servicetask2.yaml

```
apiVersion: v1
kind: Service
metadata:
  name: servicetask2
  namespace: task2
spec:
  selector:
    app: nginx-init
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
  ```

#### После создания необходимо создать новый namespace, чтобы изолировать окружение 2-ух разных задач и чтобы было проще управлять подами.

```
root@ubuntulearn:/home/kusk111serj/k8s_homeworks/homework_3/src# kubectl create namespace task2
namespace/task2 created
```

#### Создаем deployment без servicetask2.yaml и наблюдаем что под находится в состоянии init

```
root@ubuntulearn:/home/kusk111serj/k8s_homeworks/homework_3/src# kubectl apply -f deployment_task2.yaml -n task2
deployment.apps/deploy2 created

```

<img width="927" height="126" alt="1 2" src="https://github.com/user-attachments/assets/a6140895-0bcc-46e8-ad19-2fa01d44cb1f" />

<img width="495" height="219" alt="1 3" src="https://github.com/user-attachments/assets/665dfe3e-0fe4-4ad2-a5d3-0a5fa8e9545d" />

#### Создаем service, наблюдаем что под запустился

<img width="1244" height="135" alt="1 4" src="https://github.com/user-attachments/assets/d447828c-43e2-49fa-9b21-f68aa42e3971" />

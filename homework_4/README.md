# Задание 1: Настройка Service (ClusterIP и NodePort)

## Задача

Развернуть приложение из двух контейнеров (`nginx` и `multitool`) и обеспечить доступ к ним:

- **Внутри кластера** — через `ClusterIP`.
- **Снаружи кластера** — через `NodePort`.

## Шаги выполнения

#### № 1. Создать Deployment с двумя контейнерами:
- `nginx` на порту `80`.
- `multitool` на порту `8080`.
- Количество реплик: **3**.

#### 2. Создать Service типа `ClusterIP`
Должен предоставлять доступ:
- К `nginx` на порту **9001**.
- К `multitool` на порту **9002**.

#### 3. Проверить доступность изнутри кластера

Запустите временный под для тестирования:
```
bash
kubectl run test-pod --image=wbitt/network-multitool --rm -it -- sh
```
#### 4. Создать Service типа NodePort для доступа к nginx снаружи.
#### 5. Проверить доступ с локального компьютера или через браузер.




## **Ответ**


### Для выполнения задания создаем 3 файла.

1) deployment-multi-container.yaml

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

2) service-clusterip.yaml

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

#### Применяем эти манифесты и проверяем что ресурсы создались

```
kubectl apply -f deployment-multi-container.yaml
kubectl apply -f service-clusterip.yaml
kubectl apply -f nodeport-service.yaml
```

<img width="924" height="434" alt="1 1" src="https://github.com/user-attachments/assets/095d19e4-2f49-4e9a-9a47-f0835fdc0369" />

#### Тестируем Cluser-ip изнутри кластера, для этого запускаем тестовый под и с него делаем curl на порты 9001 и 9002 

```
kubectl run test-pod --image=wbitt/network-multitool --rm -it --restart=Never -- sh


curl clusterip-service.task1.svc.cluster.local:9001 
curl clusterip-service.task1.svc.cluster.local:9002  
```
<img width="1116" height="496" alt="1 2" src="https://github.com/user-attachments/assets/11bb2d3c-2e56-4ea0-b887-660b895226e7" />

#### Тестируем NodePort снаружи, для этого я перешел с веб-браузера на внешний ip адрес своей vm по порту 30080

<img width="1837" height="413" alt="1 3" src="https://github.com/user-attachments/assets/161c374e-0824-43bf-81e1-5cf00a934c34" />



## **Задание 2: Настройка Ingress**
### **Задача**
Развернуть два приложения (`frontend` и `backend`) и обеспечить доступ к ним через **Ingress** по разным путям.

### **Шаги выполнения**
1. **Развернуть два Deployment**:
   - `frontend` (образ `nginx`).
   - `backend` (образ `wbitt/network-multitool`).
2. **Создать Service** для каждого приложения.
3. **Включить Ingress-контроллер**:
```bash
 microk8s enable ingress
   ```
4. **Создать Ingress**, который:
   - Открывает `frontend` по пути `/`.
   - Открывает `backend` по пути `/api`.
5. **Проверить доступность**:
```bash
 curl <host>/
 curl <host>/api
   ```
 или через браузер.

### **Что сдать на проверку**
- Манифесты:
  - `deployment-frontend.yaml`
  - `deployment-backend.yaml`
  - `service-frontend.yaml`
  - `service-backend.yaml`
  - `ingress.yaml`
- Скриншоты проверки доступа (`curl` или браузер).


   
   ## **Ответ**

1) deployment-frontend.yaml

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-deployment
  namespace: task2
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: nginx:alpine
        ports:
        - containerPort: 80
```
2) deployment-backend.yaml

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-deployment
  namespace: task2
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: wbitt/network-multitool
        env:
        - name: HTTP_PORT
          value: "8080"
        ports:
        - containerPort: 8080
```

3) service-frontend.yaml

```
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: task2
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
```
4) service-backend.yaml

```
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: task2
spec:
  selector:
    app: backend
  ports:
  - port: 8080
    targetPort: 8080
 ```   
5) ingress.yaml

```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: task2-ingress
  namespace: task2
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: backend-service
            port:
              number: 8080
```                            

#### Применяем эти манифесты и проверяем что ресурсы создались

<img width="967" height="751" alt="2 1" src="https://github.com/user-attachments/assets/dac399fd-b88b-4380-b641-4ded5047da7d" />

#### С удаленного хоста делаем curl 

 1) curl <host>/

 <img width="1895" height="571" alt="2 2" src="https://github.com/user-attachments/assets/73378786-4a15-40e7-b3dd-e9492cac7cb2" />

 2) curl <host>/api

<img width="1428" height="414" alt="2 3" src="https://github.com/user-attachments/assets/06d28868-eeaf-4bbf-a119-64fae3ecaf7c" />


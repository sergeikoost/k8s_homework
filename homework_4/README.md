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



# Задание 2: Настройка Ingress

## Задача

Развернуть два приложения (`frontend` и `backend`) и обеспечить доступ к ним через Ingress по разным путям:
- `frontend` — по пути `/`
- `backend` — по пути `/api`

#### Шаги выполнения

1. **Создать два Deployment:**
   - `frontend` на основе образа `nginx`
   - `backend` на основе образа `wbitt/network-multitool`
   - Количество реплик: не менее 1 для каждого

2. **Создать Service для каждого приложения:**
   - `frontend-svc` — для сервиса `frontend`
   - `backend-svc` — для сервиса `backend`
   - Тип сервиса: `ClusterIP` (по умолчанию)

3. **Включить Ingress-контроллер:**
   Выполните команду в зависимости от вашей среды:
   ```bash
   microk8s enable ingress
   ```

   
   ## **Ответ**

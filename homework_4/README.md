# Задание 1: Настройка Service (ClusterIP и NodePort)

## Задача

Развернуть приложение из двух контейнеров (`nginx` и `multitool`) и обеспечить доступ к ним:

- **Внутри кластера** — через `ClusterIP`.
- **Снаружи кластера** — через `NodePort`.

## Шаги выполнения

###№ 1. Создать Deployment с двумя контейнерами:
- `nginx` на порту `80`.
- `multitool` на порту `8080`.
- Количество реплик: **3**.

###№ 2. Создать Service типа `ClusterIP`
Должен предоставлять доступ:
- К `nginx` на порту **9001**.
- К `multitool` на порту **9002**.

###№ 3. Проверить доступность изнутри кластера

Запустите временный под для тестирования:
```
bash
kubectl run test-pod --image=wbitt/network-multitool --rm -it -- sh
```
#### 4. Создать Service типа NodePort для доступа к nginx снаружи.
#### 5. Проверить доступ с локального компьютера или через браузер.




**Ответ**


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

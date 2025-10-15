## **Задание 1: Работа с ConfigMaps**
### **Задача**
Развернуть приложение (nginx + multitool), решить проблему конфигурации через ConfigMap и подключить веб-страницу.

### **Шаги выполнения**
1. **Создать Deployment** с двумя контейнерами
   - `nginx`
   - `multitool`
3. **Подключить веб-страницу** через ConfigMap
4. **Проверить доступность**

### **Что сдать на проверку**
- Манифесты:
  - `deployment.yaml`
  - `configmap-web.yaml`
- Скриншот вывода `curl` или браузера

---

**Ответ** 

#### Для запуска приложения создал 3 манифеста:

1) configmap-web.yaml

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
  namespace: default
data:
  default.conf: |
    server {
        listen 80;
        server_name localhost;
        root /usr/share/nginx/html;
        index index.html;
        
        location / {
            try_files $uri $uri/ =404;
        }
    }
  
  index.html: |
    <!DOCTYPE html>
    <html>
    <head>
        <title>Web Application</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; }
            .container { max-width: 800px; margin: 0 auto; }
            .header { background: #f0f0f0; padding: 20px; border-radius: 5px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>Welcome to Web Application</h1>
                <p>This page is served by Nginx with ConfigMap configuration</p>
            </div>
            <h2>Application Status</h2>
            <p>Nginx + Multitool deployment is running successfully!</p>
            <p>Current time: <span id="datetime"></span></p>
        </div>
        <script>
            document.getElementById('datetime').textContent = new Date().toLocaleString();
        </script>
    </body>
    </html>
    
```

2) deployment.yaml 

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
        volumeMounts:
        - name: nginx-config 
          mountPath: /etc/nginx/conf.d
          readOnly: true
        - name: web-content 
          mountPath: /usr/share/nginx/html
          readOnly: true
      

  ```

  3) service.yaml для доступа к приложению

  ```
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  selector:
    app: web-app
  ports:
    - name: http
      port: 80
      targetPort: 80
  type: NodePort

```

#### Запускаем приложение и сразу проверяем что все необходимые ресурсы были созданы:

<img width="1430" height="509" alt="task_4 1" src="https://github.com/user-attachments/assets/da498d5b-3d2f-4195-b706-55a679888fd2" />


#### Делаем port-forward для проверки с удаленного хоста и проверяем работу приложения:

```
kubectl port-forward service/web-service 8080:80 --address 0.0.0.0
```

<img width="1911" height="510" alt="task_4 3" src="https://github.com/user-attachments/assets/c7a6f3fe-6727-4869-a080-6f152b0acbdd" />


## **Задание 2: Настройка HTTPS с Secrets**  
### **Задача**  
Развернуть приложение с доступом по HTTPS, используя самоподписанный сертификат.

### **Шаги выполнения**  
1. **Сгенерировать SSL-сертификат**
```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt -subj "/CN=myapp.example.com"
```
2. **Создать Secret**
3. **Настроить Ingress**
4. **Проверить HTTPS-доступ**

### **Что сдать на проверку**  
- Манифесты:
  - `secret-tls.yaml`
  - `ingress-tls.yaml`
- Скриншот вывода `curl -k`


**Ответ**

## Начнем с того, что создадим 3 манифеста, deployment.yaml(развертка тестового приложения), secret-tls.yaml(манифест с сертификатом), ingress-tls.yaml(астраивает терминацию TLS на ingress контроллере) и сгенерируем сертификат.


1) Генерируем сертификат

```
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt -subj "/CN=myapp.example.com"

cat tls.crt | base64 -w 0
cat tls.key | base64 -w 0

```

2) secret-tls.yaml (значения data сокращены):

```

apiVersion: v1
kind: Secret
metadata:
  name: tls-secret
  namespace: default
type: kubernetes.io/tls
data:
  tls.crt: LS0tLS1Cyyy
  tls.key: LS0tLS1Cxxx

```

3) ingress-tls.yaml

```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-tls-ingress
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - myapp.example.com
    secretName: tls-secret
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: myapp-service
            port:
              number: 80
```

3) deployment.yaml

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: myapp-service
spec:
  selector:
    app: myapp
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
```

## Применяем манифесты, проверяем что ресурсы были созданы:

<img width="1013" height="413" alt="task_5 1" src="https://github.com/user-attachments/assets/be72733e-cf32-42b1-a580-5563d295ea0b" />

## Делаем curl запрос с флагом -k

<img width="1253" height="484" alt="task_5 2" src="https://github.com/user-attachments/assets/189df0ba-6947-45f8-a057-f704756940f5" />

## **Задание 3: Настройка RBAC**  
### **Задача**  
Создать пользователя с ограниченными правами (только просмотр логов и описания подов).

### **Шаги выполнения**  
1. **Включите RBAC в microk8s**
```bash
microk8s enable rbac
```
2. **Создать SSL-сертификат для пользователя**
```bash
openssl genrsa -out developer.key 2048
openssl req -new -key developer.key -out developer.csr -subj "/CN={ИМЯ ПОЛЬЗОВАТЕЛЯ}"
openssl x509 -req -in developer.csr -CA {CA серт вашего кластера} -CAkey {CA ключ вашего кластера} -CAcreateserial -out developer.crt -days 365
```
3. **Создать Role (только просмотр логов и описания подов) и RoleBinding**
4. **Проверить доступ**

### **Что сдать на проверку**  
- Манифесты:
  - `role-pod-reader.yaml`
  - `rolebinding-developer.yaml`
- Команды генерации сертификатов
- Скриншот проверки прав (`kubectl get pods --as=developer`)

---

**Ответ**

## Создаем сертификат ssl для пользователя, у меня будет developer:

<img width="1056" height="242" alt="task_6 1" src="https://github.com/user-attachments/assets/a3ce10a5-25ff-450a-93ff-1c46e2c7c282" />


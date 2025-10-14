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


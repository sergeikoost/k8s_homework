### Задание 1. Подготовить Helm-чарт для приложения

1. Необходимо упаковать приложение в чарт для деплоя в разные окружения. 
2. Каждый компонент приложения деплоится отдельным deployment’ом или statefulset’ом.
3. В переменных чарта измените образ приложения для изменения версии.

**Ответ**


#### Структура проекта для сбора в Helm, все манифесты приложу отдельно в ответе на задание. 

```
homework_7/
├── Chart.yaml
├── values.yaml
├── templates/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── configmap.yaml
│   └── secret.yaml
```
#### Собираю  helm package /home/kusk111serj/k8s_homeworks/homework_7, получаю файл nginx-0.0.1.tgz

### Задание 2. Запустить две версии в разных неймспейсах

1. Подготовив чарт, необходимо его проверить. Запуститe несколько копий приложения.
2. Одну версию в namespace=app1, вторую версию в том же неймспейсе, третью версию в namespace=app2.
3. Продемонстрируйте результат.

**Ответ**

#### Запускаем несколько копий приложения:

```
helm upgrade --install web1 nginx-0.0.1.tgz -n app1 --create-namespace
helm upgrade --install web2 nginx-0.0.1.tgz -n app1 --set containers.tag=1.22
helm upgrade --install web3 nginx-0.0.1.tgz -n app2 --create-namespace --set containers.tag=1.23
```

#### Проверяем корректность запуска:

<img width="1002" height="317" alt="task_7 1" src="https://github.com/user-attachments/assets/c4e66834-17f4-44f3-aeae-0decbc0a5bc1" />

<img width="719" height="149" alt="task_7 2" src="https://github.com/user-attachments/assets/1a12acd2-b992-412f-8092-6b6f51763ea0" />

<img width="807" height="478" alt="task_7 3" src="https://github.com/user-attachments/assets/fa034930-bcb6-411e-88fe-b16162a5af66" />

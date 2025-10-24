terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.92"
    }
  }
}

provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
  zone      = var.yc_zone
}

# Создание сервисного аккаунта для нод
resource "yandex_iam_service_account" "k8s-nodes" {
  name        = "k8s-nodes-sa"
  description = "Service account for Kubernetes nodes"
}

# Назначение ролей сервисному аккаунту
resource "yandex_resourcemanager_folder_iam_member" "editor" {
  folder_id = var.yc_folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.k8s-nodes.id}"
}

# Создание сети
resource "yandex_vpc_network" "k8s-network" {
  name = "k8s-network"
}

# Создание подсети
resource "yandex_vpc_subnet" "k8s-subnet" {
  name           = "k8s-subnet"
  zone           = var.yc_zone
  network_id     = yandex_vpc_network.k8s-network.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

# Создание security group
resource "yandex_vpc_security_group" "k8s-sg" {
  name        = "k8s-security-group"
  network_id  = yandex_vpc_network.k8s-network.id
  description = "Security group for Kubernetes cluster"

  # SSH доступ
  ingress {
    protocol       = "TCP"
    description    = "SSH"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  # Kubernetes API Server
  ingress {
    protocol       = "TCP"
    description    = "Kubernetes API server"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 6443
  }

  # etcd client API
  ingress {
    protocol       = "TCP"
    description    = "ETCD client"
    v4_cidr_blocks = [yandex_vpc_subnet.k8s-subnet.v4_cidr_blocks[0]]
    port           = 2379
  }

  # etcd peer API
  ingress {
    protocol       = "TCP"
    description    = "ETCD peer"
    v4_cidr_blocks = [yandex_vpc_subnet.k8s-subnet.v4_cidr_blocks[0]]
    port           = 2380
  }

  # Kubelet API
  ingress {
    protocol       = "TCP"
    description    = "Kubelet API"
    v4_cidr_blocks = [yandex_vpc_subnet.k8s-subnet.v4_cidr_blocks[0]]
    port           = 10250
  }

  # NodePort Services
  ingress {
    protocol       = "TCP"
    description    = "NodePort services"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 30000
    to_port        = 32767
  }

  # ICMP
  ingress {
    protocol       = "ICMP"
    description    = "ICMP"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  # Внутренняя коммуникация кластера
  ingress {
    protocol          = "ANY"
    description       = "Internal cluster communication"
    predefined_target = "self_security_group"
  }

  # Исходящий трафик
  egress {
    protocol       = "ANY"
    description    = "Outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Создание мастер-ноды
resource "yandex_compute_instance" "k8s-master" {
  name               = "k8s-master"
  platform_id        = "standard-v3"
  zone               = var.yc_zone
  service_account_id = yandex_iam_service_account.k8s-nodes.id

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd8vmcue7aajpmeo39kk" # Ubuntu 22.04
      size     = 20
      type     = "network-ssd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.k8s-subnet.id
    security_group_ids = [yandex_vpc_security_group.k8s-sg.id]
    ip_address         = "192.168.10.10"
    nat                = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
    user-data = templatefile("${path.module}/cloud-init-base.yaml", {
      node_hostname = "k8s-master"
      node_ip       = "192.168.10.10"
      node_role     = "master"
    })
  }

  scheduling_policy {
    preemptible = true
  }
}

# Создание worker-нод
resource "yandex_compute_instance" "k8s-worker" {
  count              = 4
  name               = "k8s-worker-${count.index + 1}"
  platform_id        = "standard-v3"
  zone               = var.yc_zone
  service_account_id = yandex_iam_service_account.k8s-nodes.id

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd8vmcue7aajpmeo39kk" # Ubuntu 22.04
      size     = 20
      type     = "network-ssd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.k8s-subnet.id
    security_group_ids = [yandex_vpc_security_group.k8s-sg.id]
    ip_address         = "192.168.10.${20 + count.index}"
    nat                = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
    user-data = templatefile("${path.module}/cloud-init-base.yaml", {
      node_hostname = "k8s-worker-${count.index + 1}"
      node_ip       = "192.168.10.${20 + count.index}"
      node_role     = "worker"
    })
  }

  scheduling_policy {
    preemptible = true
  }
}

# Output values
output "master_node_info" {
  value = {
    name = yandex_compute_instance.k8s-master.name
    ip   = yandex_compute_instance.k8s-master.network_interface.0.ip_address
    mac  = yandex_compute_instance.k8s-master.network_interface.0.mac_address
  }
}

output "worker_nodes_info" {
  value = [
    for worker in yandex_compute_instance.k8s-worker : {
      name = worker.name
      ip   = worker.network_interface.0.ip_address
      mac  = worker.network_interface.0.mac_address
    }
  ]
}

output "ssh_connection_commands" {
  value = {
    master = "ssh ubuntu@${yandex_compute_instance.k8s-master.network_interface.0.ip_address}"
    workers = [
      for worker in yandex_compute_instance.k8s-worker : "ssh ubuntu@${worker.network_interface.0.ip_address}"
    ]
  }
}
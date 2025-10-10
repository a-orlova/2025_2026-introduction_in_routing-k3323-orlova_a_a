University: [ITMO University](https://itmo.ru/ru/)

Faculty: [FICT](https://fict.itmo.ru)

Course: [Introduction in routing](https://github.com/itmo-ict-faculty/introduction-in-routing)

Year: 2025/2026

Group: K3323

Author: Orlova Alena Aleksandrovna

Lab: Lab1

Date of create: 10.10.2025

Date of finished: 13.10.2025

# Лабораторная работа №1 "Установка ContainerLab и развертывание тестовой сети связи"
# Оглавление
# Описание
В данной лабораторной работе вы познакомитесь с инструментом ContainerLab, развернете тестовую сеть связи, настроите оборудование на базе Linux и RouterOS.

# Цель работы
Ознакомиться с инструментом ContainerLab и методами работы с ним, изучить работу VLAN, IP адресации и т.д.

# Правила по оформлению
Правила по оформлению отчета по лабораторной работе вы можете изучить по [ссылке](https://itmo-ict-faculty.github.io/introduction-in-routing/education/labs2023_2024/reportdesign/)

# Ход работы
## Подготовка
Перед выполнением лабораторной работы было необходимо установить Docker на рабочий компьютер, установить make и склонировать hellt/vrnetlab. Также в проекте hellt/vrnetlab перейти в папку routeros, загрузить в эту папку chr-6.47.9.vmdk и с помощью make docker-image собрать образ. После этого было нужно установить ContainerLab используя специальный скрипт из официального репозитория:
```
#download and install the latest release (may require sudo)
bash -c "$(curl -sL https://get.containerlab.dev)"
```

<img width="718" height="128" alt="image" src="https://github.com/user-attachments/assets/c102457a-6801-4e26-8c25-91ba601136cb" />

## Настройка сети. YAML-файл

Теперь необходимо создать саму сеть корпоративного предприятия. Для собственного удобства сначала составлю структуру сети в виде таблицы:

| устройство         | назначение | интерфейсы |
|--------------------|----------|----------|
| R01.TEST           | центральный маршрутизатор   | eth1 — к SW01   |
| SW01.L3.01.TEST    | коммутатор 1го уровня   | eth1 — к R01, eth2 — к SW02.L3.01, eth3 — к SW02.L3.02   |
| SW02.L3.01.TEST    | коммутатор 2го уровня.1   | eth1 — к SW01, eth2 — к PC1   |
| SW02.L3.02.TEST    | коммутатор 2го уровня.2   | eth1 — к SW01, eth2 — к PC2   |
| PC1, PC2           | конечные устройства - пк | eth1 — к своему SW02 |

```
name: lab1-test-network

topology:
  nodes:
    R01.TEST:
      kind: vr-ros
      image: vrnetlab/mikrotik_routeros:6.47.9
      mgmt:
        ipv4-address: 172.20.20.2

    SW01.L3.01.TEST:
      kind: vr-ros
      image: vrnetlab/mikrotik_routeros:6.47.9
      mgmt:
        ipv4-address: 172.20.20.3

    SW02.L3.01.TEST:
      kind: vr-ros
      image: vrnetlab/mikrotik_routeros:6.47.9
      mgmt:
        ipv4-address: 172.20.20.4

    SW02.L3.02.TEST:
      kind: vr-ros
      image: vrnetlab/mikrotik_routeros:6.47.9
      mgmt:
        ipv4-address: 172.20.20.5

    PC1:
      kind: linux
      image: alpine:latest
      cmd: sleep infinity
      mgmt:
        ipv4-address: 172.20.20.6

    PC2:
      kind: linux
      image: alpine:latest
      cmd: sleep infinity
      mgmt:
        ipv4-address: 172.20.20.7

  links:
    - endpoints: ["R01.TEST:eth1", "SW01.L3.01.TEST:eth1"]
    - endpoints: ["SW01.L3.01.TEST:eth2", "SW02.L3.01.TEST:eth1"]
    - endpoints: ["SW01.L3.01.TEST:eth3", "SW02.L3.02.TEST:eth1"]
    - endpoints: ["SW02.L3.01.TEST:eth2", "PC1:eth1"]
    - endpoints: ["SW02.L3.02.TEST:eth2", "PC2:eth1"]

mgmt:
  network: static
  ipv4-subnet: 172.20.20.0/24

```


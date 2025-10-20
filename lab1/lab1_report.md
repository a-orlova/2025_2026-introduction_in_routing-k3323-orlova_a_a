University: [ITMO University](https://itmo.ru/ru/)

Faculty: [FICT](https://fict.itmo.ru)

Course: [Introduction in routing](https://github.com/itmo-ict-faculty/introduction-in-routing)

Year: 2025/2026

Group: K3323

Author: Orlova Alena Aleksandrovna

Lab: Lab1

Date of create: 10.10.2025

Date of finished: 20.10.2025

# Лабораторная работа №1 "Установка ContainerLab и развертывание тестовой сети связи"

# Описание
В данной лабораторной работе вы познакомитесь с инструментом ContainerLab, развернете тестовую сеть связи, настроите оборудование на базе Linux и RouterOS.

# Цель работы
Ознакомиться с инструментом ContainerLab и методами работы с ним, изучить работу VLAN, IP адресации и т.д.

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
      mgmt-ipv4: 172.20.20.2

    PC1:
      kind: linux
      image: alpine:latest
      cmd: sleep infinity
      mgmt-ipv4: 172.20.20.6

    PC2:
      kind: linux
      image: alpine:latest
      cmd: sleep infinity
      mgmt-ipv4: 172.20.20.7

    SW01.L3.01.TEST:
      kind: vr-ros
      image: vrnetlab/mikrotik_routeros:6.47.9
      mgmt-ipv4: 172.20.20.3

    SW02.L3.01.TEST:
      kind: vr-ros
      image: vrnetlab/mikrotik_routeros:6.47.9
      mgmt-ipv4: 172.20.20.4

    SW02.L3.02.TEST:
      kind: vr-ros
      image: vrnetlab/mikrotik_routeros:6.47.9
      mgmt-ipv4: 172.20.20.5

  links:
    - endpoints: ["R01.TEST:eth1", "SW01.L3.01.TEST:eth1"]
    - endpoints: ["SW01.L3.01.TEST:eth2", "SW02.L3.01.TEST:eth1"]
    - endpoints: ["SW01.L3.01.TEST:eth3", "SW02.L3.02.TEST:eth1"]
    - endpoints: ["SW02.L3.01.TEST:eth2", "PC1:eth1"]
    - endpoints: ["SW02.L3.02.TEST:eth2", "PC2:eth1"]

mgmt: #это сеть, используемая для управления и доступа к какому-либо устройству, обычно она изолирована от других сетей
  network: static
  ipv4-subnet: 172.20.20.0/24

```

После команды сборки *sudo containerlab deploy -t ~/containerlab/lab1/*
<img width="902" height="510" alt="image" src="https://github.com/user-attachments/assets/98a897d4-88cc-4fa2-9461-ec512a2ac592" />
<img width="1060" height="400" alt="image" src="https://github.com/user-attachments/assets/d57dc2c9-0e48-47d1-a94f-1c98aadab8b9" />

## Схема связи
С помощью команды *sudo containerlab graph -t ~/containerlab/lab1/lab1.yaml -o lab1-topology.svg* в браузере можно открыть готовую схему сети:

<img width="1082" height="774" alt="image" src="https://github.com/user-attachments/assets/0871c5dc-2b6a-4a72-8129-4a8f2cad0ce9" />

Также по заданию была составлена схема сети в draw.io:
<img width="1280" height="995" alt="image" src="https://github.com/user-attachments/assets/5b394ae8-4d7b-44ef-89af-ae3a224fe2dd" />

## Роутер R1
<img width="1000" height="630" alt="image" src="https://github.com/user-attachments/assets/2d2da0f3-5630-4b37-9dfa-191910c46375" />

Здесь я выполнила:
- создание влан-интерфейсов с помощью /interface vlan
- с помощью /interface wireless security-profiles настроен профиль безопасности по умолчанию
- создание dhcp-пулов, то есть два диапазона айпи-адресов для автоматической раздачи клиентам, использу. /ip pool
- теперь с помощью /ip dhcp-server создаются сами dhcp-сервера, привязанные к нужным вланам
- настроены айпи-адреса на интерфейсах, команда /ip address
- настройка dhcp-клиента на внешнем интерфейсе
- затем добавляю новые сети dhcp и шлюз, который будет назначаться клиентам
- установка имени устройства

## SW01
<img width="1140" height="472" alt="image" src="https://github.com/user-attachments/assets/c35feae2-7637-423f-bbf5-2015b8b67f3b" />
<img width="1133" height="128" alt="image" src="https://github.com/user-attachments/assets/f84a369b-31d1-4530-8bf2-38f39f28771b" />

Настраивая SW01:
- были созданы 2 сетевых моста, чтобы несколько портов могли работать в одном влан
- дальше созданы сами влан-интерфейсы, связала их с физическими интерфейсами
- опять команда /interface wireless security-profiles для настройки профиля безопасности
- с помощью /interface bridge port связываем мосты с виртуальными интерфейсами vlan
- конфгурирую dhcp-клиентов
- меняю имя свича

## SW02.1
<img width="1061" height="372" alt="image" src="https://github.com/user-attachments/assets/1b7dca9d-f655-45a9-9376-701a2ede8896" />

- создаю логический мост
- создаю и настраиваю влан
- классический профиль безопасности
- добавляю интерфейсы в мост
- настройка dhcp клиентов
- меняю имя системы

## SW02.2

Здесь происходит все то же самое, что и с предыдущим свичом:
<img width="1143" height="184" alt="image" src="https://github.com/user-attachments/assets/bb3db60c-d956-4681-a31f-2d2c2034ea00" />
<img width="1136" height="290" alt="image" src="https://github.com/user-attachments/assets/6c726eed-fdf3-4714-9e31-2fdd0c13cdec" />

## PC1 и PC2

Остается организовать связь между двумя компьютерами, которые находятся в разных VLAN. Сначала подключилась к каждому из пк:
```
sudo docker exec -it clab-lab1-test-network-PC1 sh
sudo docker exec -it clab-lab1-test-network-PC2 sh
```
И в каждом из них настравиаю итоговый маршрут связи между друг другом:
```
# PC1
ip route add 172.17.20.0/24 via 172.17.10.1 dev eth1
# PC2
ip route add 172.17.10.0/24 via 172.17.20.1 dev eth1
```

## Результаты пинга
<img width="756" height="277" alt="image" src="https://github.com/user-attachments/assets/0d93b647-84f3-456b-b5a9-7f95fad31c5c" />

<img width="1000" height="151" alt="image" src="https://github.com/user-attachments/assets/b1374839-0366-4743-8c4e-2b21938f567c" />

<img width="710" height="639" alt="image" src="https://github.com/user-attachments/assets/2a57b7ac-6dde-4b23-be67-5523035989fb" />
<img width="687" height="197" alt="image" src="https://github.com/user-attachments/assets/ab58a099-a7af-4ab9-a23f-d24744fe72d1" />




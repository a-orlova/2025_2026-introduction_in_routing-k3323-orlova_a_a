University: [ITMO University](https://itmo.ru/ru/)

Faculty: [FICT](https://fict.itmo.ru)

Course: [Introduction in routing](https://github.com/itmo-ict-faculty/introduction-in-routing)

Year: 2025/2026

Group: K3323

Author: Orlova Alena Aleksandrovna

Lab: Lab3

Date of create: 15.11.2025

Date of finished: 17.11.2025

# Лабораторная работа №3 "Эмуляция распределенной корпоративной сети связи, настройка OSPF и MPLS, организация первого EoMPLS"

# Описание
Наша компания "RogaIKopita Games" с прошлой лабораторной работы выросла до серьезного игрового концерна, ещё немного и они выпустят свой ответ Genshin Impact - Allmoney Impact. И вот для этой задачи они купили небольшую, но очень старую студию "Old Games" из Нью Йорка, при поглощении выяснилось что у этой студии много наработок в области компьютерной графики и совет директоров "RogaIKopita Games" решил взять эти наработки на вооружение. К сожалению исходники лежат на сервере "SGI Prism", в Нью-Йоркском офисе никто им пользоваться не умеет, а из-за короновируса сотрудники офиса из Санкт-Петерубурга не могут добраться в Нью-Йорк, чтобы забрать данные из "SGI Prism". Ваша задача подключить Нью-Йоркский офис к общей IP/MPLS сети и организовать EoMPLS между "SGI Prism" и компьютером инженеров в Санк-Петербурге.

# Цель работы
Изучить протоколы OSPF и MPLS, механизмы организации EoMPLS.

# Ход работы

## Схема сети

Описываю схему сети в файле lab3.yaml в соответствии с заданием.

```
name: lab3
mgmt:
  network: alena_mgmt
  ipv4-subnet: 172.16.16.0/24

topology:
  kinds:
    vr-ros:
      image: vrnetlab/mikrotik_routeros:6.47.9

  nodes:
    R01.SPB:
      kind: vr-ros
      mgmt-ipv4: 172.16.16.101
      startup-config: config/r01_SPB.rsc
    R01.HKI:
      kind: vr-ros
      mgmt-ipv4: 172.16.16.102
      startup-config: config/r01_HKI.rsc
    R01.MSK:
      kind: vr-ros
      mgmt-ipv4: 172.16.16.103
      startup-config: config/r01_MSK.rsc
    R01.LND:
      kind: vr-ros
      mgmt-ipv4: 172.16.16.104
      startup-config: config/r01_LND.rsc
    R01.LBN:
      kind: vr-ros
      mgmt-ipv4: 172.16.16.105
      startup-config: config/r01_LBN.rsc
    R01.NY:
      kind: vr-ros
      mgmt-ipv4: 172.16.16.106
      startup-config: config/r01_NY.rsc
    PC1:
      kind: linux
      image: alpine:latest
      mgmt-ipv4: 172.16.16.2
      binds:
        - ./config:/config
      exec:
        - sh /config/pc1.sh
    SGI_Prism:
      kind: linux
      image: alpine:latest
      mgmt-ipv4: 172.16.16.3
      binds:
        - ./config:/config
      exec:
        - sh /config/sgi_prism.sh


  links:
    - endpoints: ["R01.SPB:eth1","R01.HKI:eth1"]
    - endpoints: ["R01.SPB:eth2","R01.MSK:eth1"]
    - endpoints: ["R01.SPB:eth3","PC1:eth1"]
    - endpoints: ["R01.HKI:eth2","R01.LBN:eth2"]
    - endpoints: ["R01.HKI:eth3","R01.LND:eth1"]
    - endpoints: ["R01.MSK:eth2","R01.LBN:eth1"]
    - endpoints: ["R01.LND:eth2","R01.NY:eth1"]
    - endpoints: ["R01.LBN:eth3","R01.NY:eth2"]
    - endpoints: ["R01.NY:eth3", "SGI_Prism:eth1"]
```
Топология аналогична предыдущим лабораторным: 6 маршрутизаторов объединены в единую сеть через разные линковки, а также два линукс хоста - PC1 и SGI_Prism - он тоже выступает как компьютер. Все устройства управляются по mgmt-сети 172.16.16.0/24

Также создаю схему сети в draw.io:

![Схема сети](images/scheme_lab3.jpg)

С помощью команды sudo containerlab graph -t ~/containerlab/lab3/lab3.yaml -o lab3-topology.svg в браузере можно открыть готовую схему сети:

<img width="973" height="651" alt="image" src="https://github.com/user-attachments/assets/4d381625-f2f3-45e6-85ec-f4fda6702098" />

## Configs

### Конфигурация роутеров

На примере Нью-Йорка опишу конфиги для всех роутеров.

Сначала меняю имя системы:
```
/system identity
set name=r_NY
```

Добавляю нового пользователя, удаляю админа:
```
/user
add name=alena password=alena group=full
remove admin
```

Далее создаю ip-адреса на интерфейсах роутера согласно схеме:
```
/ip address
add address=10.20.6.2/30 interface=ether2
add address=10.20.7.2/30 interface=ether3
add address=192.168.11.1/24 interface=ether4
```

DHCP-сервер настраивается как обычно на роутерах в Нью-Йорке и Санкт-Петербруге:
```
/ip pool
add name=dhcp-pool ranges=192.168.11.10-192.168.11.100

/ip dhcp-server
add address-pool=dhcp-pool disabled=no interface=ether4 name=dhcp-server

/ip dhcp-server network
add address=192.168.11.0/24 gateway=192.168.11.1
```

#### Настройка динамической маршрутизации OSPF

bridge loopback создается на каждом роутере, такой виртуальный интерфейс никогда не отключается без внешнего вмешательства. Также каждому маршрутизатору даю loopback 10.255.255.x/32 (где x уникален для маршрутизатора) и использую его как router-id в OSPF:
```
/interface bridge
add name=loopback

/ip address 
add address=10.255.255.6/32 interface=loopback network=10.255.255.6
```

Указываю в router-id адрес loopback интерфейса, создаю зону - так как роутеров всего 6, достаточно одной зоны для всех, и также указываю имя зоны, а в сетях все физические подключения:
```
/routing ospf instance
add name=inst router-id=10.255.255.6

/routing ospf area
add name=backbone area-id=0.0.0.0 instance=inst

/routing ospf network
add area=backbone network=10.20.6.0/30
add area=backbone network=10.20.7.0/30
add area=backbone network=192.168.11.0/24
add area=backbone network=10.255.255.6/32
```

#### Настройка MPLS

Здесь включаю протокол LDP на каждом роутере, прописываю LSR-id и указываю интерфейсы, на которых будет работать MPLS. Также ограничиваю, какие префиксы будут получать ярлыки, но это необязательно. transport-address пишу тот же, что и адрес loopback для удобства, в lsr-id тоже указываю его:

```
/mpls ldp
set lsr-id=10.255.255.6
set enabled=yes transport-address=10.255.255.6

/mpls ldp advertise-filter 
add prefix=10.255.255.0/24 advertise=yes
add advertise=no

/mpls ldp accept-filter 
add prefix=10.255.255.0/24 accept=yes
add accept=no

/mpls ldp interface
add interface=ether2
add interface=ether3
```

#### Настройка VPLS

Разницы между EoMPLS и VPLS нет в RouteOs, поэтому здесь делаю настройку VPLS - это нужно только на питерском и американском роутерах. Сначала создается специальный интерфейс, затем в bridge loopback добавляется физический интерфейс, ведущий в рабочую сеть, и VPLS-интерфейс:

```
/interface bridge
add name=vpn

/interface vpls
add disabled=no name=SGIPC remote-peer=10.255.255.1 cisco-style=yes cisco-style-id=0

/interface bridge port
add interface=ether2 bridge=vpn
add interface=SGIPC bridge=vpn
```

### Конфигурация ПК

Скрипт для пк1 и SGI Prism аналогичен предыдущим работам - сначала включается нужный сетевой интерфейс, потом запускается dhcp-клиент на этом интерфейсе, также удаляется стандартный маршрут по умолчанию, потому что он является приоритетным, и если его не убрать, сама сеть будет перехватывать все запросы, и компьютеры не смогут общаться
```
#!/bin/sh
ip route del default via 172.16.16.1 dev eth0
udhcpc -i eth1
```

# Результаты

Успешный деплой проекта:

<img width="931" height="679" alt="image" src="https://github.com/user-attachments/assets/070479df-45ec-444e-9b26-6bf36d2ee238" />

Успешная работоспособность OSPF:

<img width="998" height="639" alt="image" src="https://github.com/user-attachments/assets/87773342-7b5c-488f-9863-accd61a3107c" />

<img width="978" height="657" alt="image" src="https://github.com/user-attachments/assets/132aa573-3d59-4a86-9ced-369b85b36834" />

<img width="981" height="581" alt="image" src="https://github.com/user-attachments/assets/6e6d9930-95ec-4641-8414-06990bb391d9" />

<img width="998" height="582" alt="image" src="https://github.com/user-attachments/assets/6b4a221f-c90a-472e-b1c9-66fbad519ef1" />

<img width="969" height="600" alt="image" src="https://github.com/user-attachments/assets/4baf6bc9-50ab-46ba-922d-8c001ddf23ff" />


Успешная работоспособность MPLS:

<img width="1045" height="381" alt="image" src="https://github.com/user-attachments/assets/6d384588-0e67-42d7-92d3-8646796b4eab" />

<img width="1042" height="453" alt="image" src="https://github.com/user-attachments/assets/52029ade-39e4-40a7-851d-d03e736e82e0" />

<img width="1044" height="328" alt="image" src="https://github.com/user-attachments/assets/d16854e8-c330-4f9a-b449-bc43c337bc99" />

<img width="1029" height="400" alt="image" src="https://github.com/user-attachments/assets/063ba0e8-d628-4e09-b06b-00d2aeb69686" />

<img width="1029" height="401" alt="image" src="https://github.com/user-attachments/assets/3b6cb678-5c3a-4ed7-a8fc-889afa1c0b78" />


Успешная работоспособность VPLS:




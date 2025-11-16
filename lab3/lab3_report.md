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
  network: mgmt_alena
  ipv4-subnet: 172.30.0.0/24

topology:
  kinds:
    vr-ros:
      image: vrnetlab/mikrotik_routeros:6.47.9

  nodes:
    R01.LND:
      kind: vr-ros
      mgmt-ipv4: 172.30.0.2
      startup-config: configs/r01_LND.rsc
    R01.HKI:
      kind: vr-ros
      mgmt-ipv4: 172.30.0.3
      startup-config: configs/r01_HKI.rsc
    R01.SPB:
      kind: vr-ros
      mgmt-ipv4: 172.30.0.4
      startup-config: configs/r01_SPB.rsc
    R01.MSK:
      kind: vr-ros
      mgmt-ipv4: 172.30.0.5
      startup-config: configs/r01_MSK.rsc
    R01.LBN:
      kind: vr-ros
      mgmt-ipv4: 172.20.0.6
      startup-config: configs/r01_LBN.rsc
    R01.NY:
      kind: vr-ros
      mgmt-ipv4: 172.30.0.7
      startup-config: configs/r01_NY.rsc
    PC1:
      kind: linux
      image: alpine:latest
      mgmt-ipv4: 172.30.0.101
      binds:
        - ./configs:/configs
      exec:
        - sh /configs/pc1.sh
    SGI_Prism:
      kind: linux
      image: alpine:latest
      mgmt-ipv4: 172.30.0.102
      binds:
        - ./configs:/configs
      exec:
        - sh /configs/sgi_prism.sh

  links:
    - endpoints: ["R01.SPB:eth1","R01.HKI:eth1"]
    - endpoints: ["R01.SPB:eth2","R01.MSK:eth1"]
    - endpoints: ["R01.SPB:eth3","PC1:eth1"]
    - endpoints: ["R01.HKI:eth2","R01.LBN:eth2"]
    - endpoints: ["R01.HKI:eth3","R01.LND:eth1"]
    - endpoints: ["R01.MSK:eth2","R01.LBN:eth1"]
    - endpoints: ["R01.LND:eth2","R01.NY:eth1"]
    - endpoints: ["R01.LBN:eth3","R01.NY:eth2"]
    - endpoints: ["R01.NY:eth3", "SGI-PRISM:eth1"]
```
Топология аналогична предыдущим лабораторным: 6 маршрутизаторов объединены в единую сеть через разные линковки, а также два линукс хоста - PC1 и SGI_Prism - он тоже выступает как компьютер. Все устройства управляются по mgmt-сети 172.20.0.0/24

Также создаю схему сети в draw.io:

![Схема сети](images/lab3_routing_scheme.jpg)

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
/ip address add address=10.0.17.6/24 interface=ether2
/ip address add address=10.0.16.6/24 interface=ether3
/ip address add address=192.168.20.1/24 interface=ether4
```

DHCP-сервер настраивается как обычно на роутерах в Нью-Йорке и Санкт-Петербруге:
```
/ip pool
add name=ny_pool ranges=192.168.20.100-192.168.20.254

/ip dhcp-server network
add address=192.168.20.0/24 gateway=192.168.20.1

/ip dhcp-server
add address-pool=ny_pool disabled=no interface=ether4 name=ds_ny
```

#### Настройка динамической маршрутизации OSPF

bridge loopback создается на каждом роутере, такой виртуальный интерфейс никогда не отключается без внешнего вмешательства. Также каждому маршрутизатору даю loopback 10.255.X.254/32 (где X уникален для маршрутизатора) и использую его как router-id в OSPF:
```
/interface bridge
add name=loopback

/ip address
add address=10.255.6.254/32 interface=loopback
```

Указываю в router-id адрес loopback интерфейса, создаю зону - так как роутеров всего 6, достаточно одной зоны для всех, и также указываю имя зоны, а в сетях все физические подключения:
```
/routing ospf instance
add name=inst router-id=10.255.6.254

/routing ospf area
add name=backbone area-id=0.0.0.0 instance=inst

/routing ospf network
add area=backbone network=10.20.16.0/30
add area=backbone network=10.20.17.0/30
add area=backbone network=192.168.20.0/24
add area=backbone network=10.255.6.254/32
```

#### Настройка MPLS

Здесь включаю протокол LDP на каждом роутере, прописываю LSR-id и указываю интерфейсы, на которых будет работать MPLS. transport-address пишу тот же, что и адрес loopback для удобства, в lsr-id тоже указываю его:

```
/mpls ldp
set enabled=yes lsr-id=10.255.6.254 transport-address=10.255.6.254

/mpls ldp interface
add interface=ether2
add interface=ether3
```

#### Настройка VPLS

Разницы между EoMPLS и VPLS нет в RouteOs, поэтому здесь делаю настройку VPLS - это нужно только на питерском и американском роутерах. Сначала создается специальный интерфейс, затем в bridge loopback добавляется физический интерфейс, ведущий в рабочую сеть, и VPLS-интерфейс:

```
/interface vpls
add name=vpls_SPB remote-peer=10.255.5.254 vpls-id=100:1 disabled=no

/interface bridge port
add bridge=loopback interface=ether4
add bridge=loopback interface=vpls_SPB
```

### Конфигурация ПК

Скрипт для пк1 и SGI Prism аналогичен предыдущим работам - сначала включается нужный сетевой интерфейс, потом запускается dhcp-клиент на этом интерфейсе, также удаляется стандартный маршрут по умолчанию, потому что он является приоритетным, и если его не убрать, сама сеть будет перехватывать все запросы, и компьютеры не смогут общаться
```
#!/bin/sh

ip link set eth1 up
udhcpc -i eth1 -q
ip route del default via 172.30.0.1 dev eth0
```

# Результаты

Успешный деплой проекта:

<img width="917" height="740" alt="image" src="https://github.com/user-attachments/assets/4ebc8971-68d6-4d4b-95dc-e78be7367c5b" />




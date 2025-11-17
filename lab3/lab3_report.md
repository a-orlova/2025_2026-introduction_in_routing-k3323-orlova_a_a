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

Скрипт для пк1 и SGI Prism аналогичен предыдущим работам - запускается dhcp-клиент на нужном интерфейсе, а также удаляется стандартный маршрут по умолчанию, потому что он является приоритетным, и если его не убрать, сама сеть будет перехватывать все запросы, и компьютеры не смогут общаться
```
#!/bin/sh
ip route del default via 172.16.16.1 dev eth0
udhcpc -i eth1
```

# Результаты

Успешный деплой проекта:

<img width="931" height="667" alt="image" src="https://github.com/user-attachments/assets/9038ec07-d7f5-49f5-81c7-5973cec9a072" />

Успешная работоспособность OSPF:

<img width="554" height="455" alt="image" src="https://github.com/user-attachments/assets/2885a78d-e7e5-451d-8341-a329c2935f2b" />

<img width="559" height="454" alt="image" src="https://github.com/user-attachments/assets/8e75208e-938c-4592-98a8-c3239a53618f" />

<img width="649" height="435" alt="image" src="https://github.com/user-attachments/assets/675ac3b5-fc91-42f0-b62b-353aa16d6dca" />

<img width="646" height="449" alt="image" src="https://github.com/user-attachments/assets/a2e5d0af-aa7e-4dd0-ac4c-ad4375ebb7a5" />

<img width="645" height="447" alt="image" src="https://github.com/user-attachments/assets/846e919b-858f-40c4-b933-2ca7ba9482c0" />

<img width="639" height="447" alt="image" src="https://github.com/user-attachments/assets/8ab18ad9-bcc1-42e6-8248-8fb08223cbbd" />

Успешная работоспособность MPLS:

<img width="1104" height="482" alt="image" src="https://github.com/user-attachments/assets/456d04af-79d2-4e37-a10c-9db5bca95ef3" />

<img width="1139" height="485" alt="image" src="https://github.com/user-attachments/assets/4f9e7ad0-86ec-4768-bfe7-dcf4103753c9" />

<img width="1137" height="531" alt="image" src="https://github.com/user-attachments/assets/efbdb2af-f017-4a88-9b41-3e53472d268f" />

<img width="1142" height="511" alt="image" src="https://github.com/user-attachments/assets/c8f62455-33e1-4b19-9ef7-f64d3df207f7" />

<img width="1135" height="409" alt="image" src="https://github.com/user-attachments/assets/464e8f44-8a97-4b01-ae39-ed94624d1b37" />

<img width="1134" height="467" alt="image" src="https://github.com/user-attachments/assets/ed58330c-d8ae-4777-9911-63a8102cf3a8" />

Успешная работоспособность VPLS:

<img width="409" height="134" alt="image" src="https://github.com/user-attachments/assets/29da6731-c95f-4cd7-bc71-aad60cd2f275" />
<img width="436" height="148" alt="image" src="https://github.com/user-attachments/assets/17b29977-81ca-45f1-8d38-2ad77e26459c" />

Успешный пинг между компьютерами:

<img width="576" height="310" alt="image" src="https://github.com/user-attachments/assets/389945c8-649a-4ac3-8204-edd859514b17" />

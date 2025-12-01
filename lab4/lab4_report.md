University: [ITMO University](https://itmo.ru/ru/)

Faculty: [FICT](https://fict.itmo.ru)

Course: [Introduction in routing](https://github.com/itmo-ict-faculty/introduction-in-routing)

Year: 2025/2026

Group: K3323

Author: Orlova Alena Aleksandrovna

Lab: Lab4

Date of create: 19.11.2025

Date of finished: 1.12.2025

# Лабораторная работа №4 "Эмуляция распределенной корпоративной сети связи, настройка iBGP, организация L3VPN, VPLS"

# Описание
Компания "RogaIKopita Games" выпустила игру "Allmoney Impact", нагрузка на арендные сервера возрасли и вам поставлена задача стать LIR и организовать свою AS чтобы перенести все сервера игры на свою инфраструктуру. После организации вашей AS коллеги из отдела DEVOPS попросили вас сделать L3VPN между 3 офисами для служебных нужд. (Рисунок 1) Данный L3VPN проработал пару недель и коллеги из отдела DEVOPS попросили вас сделать VPLS для служебных нужд.

# Цель работы
Изучить протоколы BGP, MPLS и правила организации L3VPN и VPLS.

# Ход работы

## Схема сети

Описываю схему сети в файле lab4_p1.yaml в соответствии с заданием.

```
name: lab4_p1
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
      startup-config: config/p1/r_SPB.rsc
    R01.HKI:
      kind: vr-ros
      mgmt-ipv4: 172.16.16.102
      startup-config: config/p1/r_HKI.rsc
    R01.SVL:
      kind: vr-ros
      mgmt-ipv4: 172.16.16.103
      startup-config: config/p1/r_SVL.rsc
    R01.LND:
      kind: vr-ros
      mgmt-ipv4: 172.16.16.104
      startup-config: config/p1/r_LND.rsc
    R01.LBN:
      kind: vr-ros
      mgmt-ipv4: 172.16.16.105
      startup-config: config/p1/r_LBN.rsc
    R01.NY:
      kind: vr-ros
      mgmt-ipv4: 172.16.16.106
      startup-config: config/pt1/r_NY.rsc
    PC1:
      kind: linux
      image: alpine:latest
      mgmt-ipv4: 172.16.16.2
      binds:
        - ./config:/config
      exec:
        - sh /config/pc.sh
    PC2:
      kind: linux
      image: alpine:latest
      mgmt-ipv4: 172.16.16.3
      binds:
        - ./config:/config
      exec:
        - sh /config/pc.sh
    PC3:
      kind: linux
      image: alpine:latest
      mgmt-ipv4: 172.16.16.4
      binds:
        - ./config:/config
      exec:
        - sh /config/pc.sh


  links:
    - endpoints: ["R01.SPB:eth1","R01.HKI:eth1"]
    - endpoints: ["R01.NY:eth1","R01.LND:eth1"]
    - endpoints: ["R01.SVL:eth1","R01.LBN:eth1"]
    - endpoints: ["R01.HKI:eth2","R01.LND:eth3"]
    - endpoints: ["R01.HKI:eth3","R01.LBN:eth2"]
    - endpoints: ["R01.LND:eth2","R01.LBN:eth3"]
    - endpoints: ["R01.SPB:eth2","PC1:eth1"]
    - endpoints: ["R01.NY:eth2","PC2:eth1"]
    - endpoints: ["R01.SVL:eth2","PC3:eth1"]
```
Топология для каждой части лабораторной аналогична предыдущим работам: 6 маршрутизаторов объединены в единую сеть через разные линковки, а также три линукс хоста - PC1, PC2, PC3. Все устройства управляются по mgmt-сети 172.16.16.0/24 в первой части, во второй - 172.16.18.0/24

Также создаю схему сети в draw.io:

![Схема сети](images/scheme_lab4.jpg)

С помощью команды sudo containerlab graph -t ~/containerlab/lab4/lab4.yaml -o lab4-topology.svg в браузере можно открыть готовую схему сети:

<img width="887" height="729" alt="image" src="https://github.com/user-attachments/assets/67377282-ddfd-47a1-91a3-076a1bde7ebb" />

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
add address=10.20.2.1/30 interface=ether2
add address=192.168.11.1/24 interface=ether3
```

DHCP-сервер настраивается как обычно на роутерах NY, SPB и SVL:
```
/ip pool
add name=dhcp-pool ranges=192.168.11.10-192.168.11.100

/ip dhcp-server
add address-pool=dhcp-pool disabled=no interface=ether3 name=dhcp-server

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
add area=backbone network=10.20.2.0/30
add area=backbone network=192.168.11.0/24
add area=backbone network=10.255.255.6/32
```

#### Настройка MPLS

Здесь включаю протокол LDP на каждом роутере, прописываю LSR-id и указываю интерфейсы, на которых будет работать MPLS. transport-address пишу тот же, что и адрес loopback для удобства, в lsr-id тоже указываю его:

```
/mpls ldp
set lsr-id=10.255.255.6
set enabled=yes transport-address=10.255.255.6

/mpls ldp interface
add interface=ether2
```

#### Настройка iBGP (часть 1)

Затем настраиваю iBGP: выбирается AS 65000, задаётся router-id, создаётся BGP-peer для подключения к Route Reflector через loopback, и анонсируется сеть loopback, чтобы BGP-сессия могла установиться независимо от физики:

```
/routing bgp instance
set default as=65000 router-id=10.255.255.6

/routing bgp peer
add name=peerLND remote-address=10.255.255.4 address-families=l2vpn,vpnv4 remote-as=65000 update-source=loopback route-reflect=no

/routing bgp network
add network=10.255.255.0/24
```

#### Настройка VRF на внешних роутерах (часть 1)

Далее создаю VRF: под него делается виртуальный интерфейс-мост, ему выдаётся адрес /32, и создаётся VRF с RD и RT 65000:100 — это идентификаторы, по которым маршруты данного офиса будут выделяться и обмениваться между PE-роутерами. В VRF включается импорт и экспорт RT, а также включается отдельный BGP-инстанс, который публикует подключённые маршруты VRF в BGP VPNv4. Таким образом, этот роутер становится PE-узлом и может передавать VRF-маршруты на RR и другим офисам для L3VPN.

```
/interface bridge 
add name=br100
/ip address
add address=10.100.1.2/32 interface=br100
/ip route vrf
add export-route-targets=65000:100 import-route-targets=65000:100 interfaces=br100 route-distinguisher=65000:100 routing-mark=VRF_DEVOPS
/routing bgp instance vrf
add redistribute-connected=yes routing-mark=VRF_DEVOPS
```

#### Настройка VPLS (часть 2)

Здесь в первую очередь по сравнению с предыдущей частью работы нужно поменять блок с настройкой MPLS: LDP включаю не только на ether2, но и на ether3, потому что ПК участвует в VPLS:

```
/mpls ldp
set lsr-id=10.255.255.6
set enabled=yes transport-address=10.255.255.6
/mpls ldp interface
add interface=ether2
add interface=ether3
```

В этой части VRF полностью удаляется, и BGP используется только для VPLS. Создаю виртуальный мост vpn, затем к нему добавляю порт ether3. После этого создаётся интерфейс BGP-VPLS, который использует тот же мост vpn и получает свои параметры VPLS. И также на мост назначается айпишник 10.100.1.6/24, чтобы этот PE мог быть достигнут внутри общей сети VPLS и чтобы компьютеры могли находиться в одном IP-сегменте:

```
/interface bridge
add name=vpn

/interface bridge port
add interface=ether3 bridge=vpn

/interface vpls bgp-vpls
add bridge=vpn export-route-targets=65000:100 import-route-targets=65000:100 name=vpls route-distinguisher=65000:100 site-id=6

/ip address
add address=10.100.1.6/24 interface=vpn
```

Также надо выбрать, на каком роутере поставить dhcp-сервер, чтобы задать айпи всем компьютерам в одной этой сети vpn. В моем случае - это SPB. На всех роутерах убираем раздачу dhcp-адресов из предыдущей части, на SPB создаём новый пул из сети впн и подключаем его к нему:

```
/ip pool
add name=vpn-dhcp-pool ranges=10.100.1.100-10.100.1.254
/ip dhcp-server
add address-pool=vpn-dhcp-pool disabled=no interface=vpn name=dhcp-vpls
/ip dhcp-server network
add address=10.100.1.0/24 gateway=10.100.1.1
```

### Конфигурация ПК

Скрипт для всех трех ПК аналогичен предыдущим работам - запускается dhcp-клиент на нужном интерфейсе, а также удаляется стандартный маршрут по умолчанию, потому что он является приоритетным, и если его не убрать, сама сеть будет перехватывать все запросы, и компьютеры не смогут общаться

```
#!/bin/sh
ip route del default via 172.16.16.1 dev eth0
udhcpc -i eth1
```

# Результаты

Успешный деплой проекта:

<img width="873" height="659" alt="image" src="https://github.com/user-attachments/assets/dbfa499b-1be7-4ba0-a0a9-193ca3c4ddc7" />

Успешная работоспособность OSPF:

<img width="649" height="419" alt="image" src="https://github.com/user-attachments/assets/7fc1af4b-23da-4e90-bb2e-e1884d7f5783" />

<img width="663" height="452" alt="image" src="https://github.com/user-attachments/assets/e52e602b-97e5-4e44-9f58-572d20b3a635" />

<img width="662" height="457" alt="image" src="https://github.com/user-attachments/assets/8b3cc52c-dd5a-4112-ae04-ddf1c909c44b" />

<img width="644" height="402" alt="image" src="https://github.com/user-attachments/assets/f2d4e23c-ff7f-4ab4-b3c1-3c6f65a7ae00" />

<img width="646" height="447" alt="image" src="https://github.com/user-attachments/assets/fb616761-2119-4fe6-963b-c4421fffa827" />

<img width="640" height="403" alt="image" src="https://github.com/user-attachments/assets/e5271fb2-9378-4a89-8d1e-f5eabe08aea0" />

Успешная работоспособность MPLS:

<img width="1003" height="654" alt="image" src="https://github.com/user-attachments/assets/816540d4-f083-4853-bb48-6a3bdd5c4a8e" />

<img width="1140" height="429" alt="image" src="https://github.com/user-attachments/assets/d7f0569d-96f6-4398-afe9-8e5daa85d727" />

<img width="1144" height="554" alt="image" src="https://github.com/user-attachments/assets/09770f6b-5643-433e-a8c6-0ad12ae11197" />

<img width="1143" height="529" alt="image" src="https://github.com/user-attachments/assets/608e7e66-2e37-4ac9-b015-49b1fa91f5b2" />

<img width="1140" height="548" alt="image" src="https://github.com/user-attachments/assets/7beff1f1-609d-4dc7-b34e-6b7ab3cf94e2" />

<img width="1141" height="642" alt="image" src="https://github.com/user-attachments/assets/fdb63002-3380-4311-b4e1-5d34476d4df1" />

Успешная работоспособность iBPG:

<img width="1172" height="187" alt="image" src="https://github.com/user-attachments/assets/ec4412a8-3d98-4d26-85b4-739b177910a4" />

<img width="1172" height="191" alt="image" src="https://github.com/user-attachments/assets/59137aa9-6d63-44e9-84e4-a29b5f46c75f" />

<img width="1171" height="187" alt="image" src="https://github.com/user-attachments/assets/6f96e791-8ec1-4093-ba8b-a527257bf679" />

Успешная работоспособность VRF:

<img width="982" height="263" alt="image" src="https://github.com/user-attachments/assets/16f44690-3fd6-4562-9252-a4ef2f053704" />

<img width="967" height="246" alt="image" src="https://github.com/user-attachments/assets/45283fbb-2bca-4331-9d09-8ca541046f5a" />

<img width="968" height="246" alt="image" src="https://github.com/user-attachments/assets/fa770bb1-e1b5-41b2-9eb5-73f3ef5cfc3b" />

Успешная раздача айпи-адресов через dhcp-сервер на SPB роутере:

<img width="898" height="121" alt="image" src="https://github.com/user-attachments/assets/7636711b-d213-43c3-8234-e38a5afee78a" />

Успешная работоспособность VPLS:

<img width="790" height="451" alt="image" src="https://github.com/user-attachments/assets/cd967cbe-a870-4b06-9b04-e62020ce7fc0" />

<img width="791" height="438" alt="image" src="https://github.com/user-attachments/assets/e9b4a603-4f99-4b4a-a0ac-8fa68bc7e56e" />

<img width="790" height="441" alt="image" src="https://github.com/user-attachments/assets/a89bd5d7-b31b-4202-b214-4623422c73bc" />


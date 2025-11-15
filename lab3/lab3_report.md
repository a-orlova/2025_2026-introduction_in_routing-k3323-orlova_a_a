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
  network: new_mgmt
  ipv4-subnet: 172.20.0.0/24

topology:
  kinds:
    vr-ros:
      image: vrnetlab/mikrotik_routeros:6.47.9

  nodes:
    R01.LND:
      kind: vr-ros
      mgmt-ipv4: 172.20.0.2
      startup-config: configs/r01_LND.rsc
    R01.HKI:
      kind: vr-ros
      mgmt-ipv4: 172.20.0.3
      startup-config: configs/r01_HKI.rsc
    R01.SPB:
      kind: vr-ros
      mgmt-ipv4: 172.20.0.4
      startup-config: configs/r01_SPB.rsc
    R01.MSK:
      kind: vr-ros
      mgmt-ipv4: 172.20.0.5
      startup-config: configs/r01_MSK.rsc
    R01.LBN:
      kind: vr-ros
      mgmt-ipv4: 172.20.0.6
      startup-config: configs/r01_LBN.rsc
    R01.NY:
      kind: vr-ros
      mgmt-ipv4: 172.20.0.7
      startup-config: configs/r01_NY.rsc
    PC1:
      kind: linux
      image: alpine:latest
      mgmt-ipv4: 172.20.0.101
      binds:
        - ./configs:/configs
      exec:
        - sh /configs/pc1.sh
    SGI_Prism:
      kind: linux
      mgmt-ipv4: 172.20.0.102
      binds:
        - ./configs:/configs
      exec:
        - sh /configs/sgi_prism.sh

  links:
    - endpoints: ["R01.LBN:eth1", "R01.NY:eth1"]
    - endpoints: ["R01.LBN:eth2", "R01.MSK:eth2"]
    - endpoints: ["R01.LBN:eth3", "R01.HKI:eth3"]
    - endpoints: ["R01.SPB:eth1", "R01.MSK:eth1"]
    - endpoints: ["R01.SPB:eth2", "R01.HKI:eth2"]
    - endpoints: ["R01.SPB:eth3", "PC1:eth1"]
    - endpoints: ["R01.NY:eth2", "R01.LND:eth2"]
    - endpoints: ["R01.NY:eth3", "SGI_Prism:eth1"]
    - endpoints: ["R01.LND:eth1", "R01.HKI:eth1"]
```
Топология аналогична предыдущим лабораторным: 6 маршрутизаторов объединены в единую сеть через разные линковки, а также два линукс хоста - PC1 и SGI_Prism - он тоже выступает как компьютер. Все устройства управляются по mgmt-сети 172.20.0.0/24

Также создаю схему сети в draw.io:

![Схема сети](images/lab3_scheme.jpg)

С помощью команды sudo containerlab graph -t ~/containerlab/lab3/lab3.yaml -o lab3-topology.svg в браузере можно открыть готовую схему сети:

???

## Configs

### Конфигурация роутеров

### Конфигурация ПК

# Результаты



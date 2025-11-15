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
  ipv4-subnet: 172.20.20.0/24

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
      mgmt-ipv4: 172.50.0.102
      binds:
        - ./configs:/configs
      exec:
        - sh /configs/sgi_prism.sh

  links:
    - endpoints: ["R01.BRL:eth1","R01.MSK:eth2"]
    - endpoints: ["R01.BRL:eth2","R01.FRT:eth1"]
    - endpoints: ["R01.MSK:eth1","R01.FRT:eth2"]
    - endpoints: ["R01.BRL:eth3","PC3:eth1"]
    - endpoints: ["R01.FRT:eth3","PC2:eth1"]
    - endpoints: ["R01.MSK:eth3","PC1:eth1"]
```

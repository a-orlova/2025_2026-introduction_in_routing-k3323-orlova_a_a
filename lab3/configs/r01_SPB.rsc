/system identity
set name=r_SPB
/user
add name=alena password=alena group=full
remove admin

/ip address
add address=10.20.1.1/30 interface=ether2
add address=10.20.2.1/30 interface=ether3
add address=192.168.10.1/24 interface=ether4

/ip pool
add name=dhcp-pool ranges=192.168.10.10-192.168.10.100
/ip dhcp-server
add address-pool=dhcp-pool disabled=no interface=ether4 name=dhcp-server
/ip dhcp-server network
add address=192.168.10.0/24 gateway=192.168.10.1

/interface bridge
add name=loopback
/ip address 
add address=10.255.255.1/32 interface=loopback network=10.255.255.1

/routing ospf instance
add name=inst router-id=10.255.255.1
/routing ospf area
add name=backbone area-id=0.0.0.0 instance=inst
/routing ospf network
add area=backbone network=10.20.1.0/30
add area=backbone network=10.20.2.0/30
add area=backbone network=192.168.10.0/24
add area=backbone network=10.255.255.1/32

/mpls ldp
set lsr-id=10.255.255.1
set enabled=yes transport-address=10.255.255.1
/mpls ldp advertise-filter 
add prefix=10.255.255.0/24 advertise=yes
add advertise=no
/mpls ldp accept-filter 
add prefix=10.255.255.0/24 accept=yes
add accept=no
/mpls ldp interface
add interface=ether2
add interface=ether3

/interface bridge
add name=vpn
/interface vpls
add disabled=no name=SGIPC remote-peer=10.255.255.6 cisco-style=yes cisco-style-id=0
/interface bridge port
add interface=ether2 bridge=vpn
add interface=SGIPC bridge=vpn


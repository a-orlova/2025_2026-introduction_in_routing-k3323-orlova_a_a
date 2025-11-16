/system identity
set name=r_NY
/user
add name=alena password=alena group=full
remove admin

/ip address
add address=10.20.6.2/30 interface=ether2
add address=10.20.7.2/30 interface=ether3
add address=192.168.11.1/24 interface=ether4

/ip pool
add name=dhcp-pool ranges=192.168.11.10-192.168.11.100
/ip dhcp-server
add address-pool=dhcp-pool disabled=no interface=ether4 name=dhcp-server
/ip dhcp-server network
add address=192.168.11.0/24 gateway=192.168.11.1

/interface bridge
add name=loopback
/ip address 
add address=10.255.255.6/32 interface=loopback network=10.255.255.6

/routing ospf instance
add name=inst router-id=10.255.255.6
/routing ospf area
add name=backbone area-id=0.0.0.0 instance=inst
/routing ospf network
add area=backbone network=10.20.6.0/30
add area=backbone network=10.20.7.0/30
add area=backbone network=192.168.11.0/24
add area=backbone network=10.255.255.6/32

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

/interface bridge
add name=vpn
/interface vpls
add disabled=no name=SGIPC remote-peer=10.255.255.1 cisco-style=yes cisco-style-id=0
/interface bridge port
add interface=ether2 bridge=vpn
add interface=SGIPC bridge=vpn


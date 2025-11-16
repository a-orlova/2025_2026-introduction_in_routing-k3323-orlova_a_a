/system identity
set name=r_SPB
/user
add name=alena password=alena group=full
remove admin

/ip address add address=10.0.11.1/24 interface=ether2
/ip address add address=10.0.12.1/24 interface=ether3
/ip address add address=192.168.10.1/24 interface=ether4

/ip pool
add name=spb_pool ranges=192.168.10.100-192.168.10.254
/ip dhcp-server network
add address=192.168.10.0/24 gateway=192.168.10.1
/ip dhcp-server
add address-pool=spb_pool disabled=no interface=ether4 name=ds_spb

/interface bridge
add name=loopback
/ip address
add address=10.255.255.1/32 interface=loopback network=10.255.255.1

/routing ospf instance
add name=inst router-id=10.255.255.1
/routing ospf area
add name=backbone area-id=0.0.0.0 instance=inst
/routing ospf network
add area=backbone network=10.0.11.0/24
add area=backbone network=10.0.12.0/24
add area=backbone network=192.168.10.0/24
add area=backbone network=10.255.255.1/32

/mpls ldp
set enabled=yes lsr-id=10.255.255.1 transport-address=10.255.255.1
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


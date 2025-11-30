/user
add name=alena password=alena group=full
remove admin
/system identity
set name=r_NY

/ip address
add address=10.20.2.1/30 interface=ether2
add address=192.168.11.1/24 interface=ether3

/interface bridge
add name=loopback
/ip address 
add address=10.255.255.6/32 interface=loopback network=10.255.255.6

/routing ospf instance
add name=inst router-id=10.255.255.6
/routing ospf area
add name=backbone area-id=0.0.0.0 instance=inst
/routing ospf network
add area=backbone network=10.20.2.0/30
add area=backbone network=192.168.11.0/24
add area=backbone network=10.255.255.6/32

/mpls ldp
set lsr-id=10.255.255.6
set enabled=yes transport-address=10.255.255.6
/mpls ldp interface
add interface=ether2
add interface=ether3

/routing bgp instance
set default as=65000 router-id=10.255.255.6
/routing bgp peer
add name=peerLND remote-address=10.255.255.4 address-families=l2vpn,vpnv4 remote-as=65000 update-source=loopback route-reflect=no 
/routing bgp network
add network=10.255.255.0/24

/interface bridge
add name=vpn
/interface bridge port
add interface=ether3 bridge=vpn
/interface vpls bgp-vpls
add bridge=vpn export-route-targets=65000:100 import-route-targets=65000:100 name=vpls route-distinguisher=65000:100 site-id=6
/ip address
add address=10.100.1.6/24 interface=vpn

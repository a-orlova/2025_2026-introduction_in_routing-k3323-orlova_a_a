/user
add name=alena password=alena group=full
remove admin
/system identity
set name=r_SVL

/ip address
add address=10.20.3.1/30 interface=ether2
add address=192.168.12.1/24 interface=ether3

/interface bridge
add name=loopback
/ip address 
add address=10.255.255.3/32 interface=loopback network=10.255.255.3

/routing ospf instance
add name=inst router-id=10.255.255.3
/routing ospf area
add name=backbone area-id=0.0.0.0 instance=inst
/routing ospf network
add area=backbone network=10.20.3.0/30
add area=backbone network=192.168.12.0/24
add area=backbone network=10.255.255.3/32

/mpls ldp
set lsr-id=10.255.255.3
set enabled=yes transport-address=10.255.255.3
/mpls ldp interface
add interface=ether2
add interface=ether3

/routing bgp instance
set default as=65000 router-id=10.255.255.3
/routing bgp peer
add name=peerLBN remote-address=10.255.255.5 address-families=l2vpn,vpnv4 remote-as=65000 update-source=loopback route-reflect=yes
/routing bgp network
add network=10.255.255.0/24

/interface bridge
add name=vpn
/interface bridge port
add interface=ether3 bridge=vpn
/interface vpls bgp-vpls
add bridge=vpn export-route-targets=65000:100 import-route-targets=65000:100 name=vpls route-distinguisher=65000:100 site-id=3
/ip address
add address=10.100.1.3/24 interface=vpn

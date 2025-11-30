/user
add name=alena password=alena group=full
remove admin
/system identity
set name=r_LND

/ip address
add address=10.20.2.2/30 interface=ether2
add address=10.20.13.1/30 interface=ether3
add address=10.20.11.2/30 interface=ether4

/interface bridge
add name=loopback
/ip address 
add address=10.255.255.4/32 interface=loopback network=10.255.255.4

/routing ospf instance
add name=inst router-id=10.255.255.4
/routing ospf area
add name=backbone area-id=0.0.0.0 instance=inst
/routing ospf network
add area=backbone network=10.20.2.0/30
add area=backbone network=10.20.11.0/30
add area=backbone network=10.20.13.0/30
add area=backbone network=10.255.255.4/32

/mpls ldp
set lsr-id=10.255.255.4
set enabled=yes transport-address=10.255.255.4
/mpls ldp interface
add interface=ether2
add interface=ether3
add interface=ether4

/routing bgp instance
set default as=65000 router-id=10.255.255.4
/routing bgp peer
add name=peerNY remote-address=10.255.255.6 address-families=l2vpn,vpnv4 remote-as=65000 update-source=loopback route-reflect=no
add name=peerHKI remote-address=10.255.255.2 address-families=l2vpn,vpnv4 remote-as=65000 update-source=loopback route-reflect=yes
add name=peerLBN remote-address=10.255.255.5 address-families=l2vpn,vpnv4 remote-as=65000 update-source=loopback route-reflect=yes
/routing bgp network
add network=10.255.255.0/24

/user
add name=alena password=alena group=full
remove admin
/system identity
set name=r_LBN

/ip address
add address=10.20.3.2/30 interface=ether2
add address=10.20.12.1/30 interface=ether3
add address=10.20.13.2/30 interface=ether4

/interface bridge
add name=loopback
/ip address 
add address=10.255.255.5/32 interface=loopback network=10.255.255.5

/routing ospf instance
add name=inst router-id=10.255.255.5
/routing ospf area
add name=backbone area-id=0.0.0.0 instance=inst
/routing ospf network
add area=backbone network=10.20.12.0/30
add area=backbone network=10.20.13.0/30
add area=backbone network=10.20.3.0/30
add area=backbone network=10.255.255.5/32

/mpls ldp
set lsr-id=10.255.255.5
set enabled=yes transport-address=10.255.255.5
/mpls ldp advertise-filter 
add prefix=10.255.255.0/24 advertise=yes
add advertise=no
/mpls ldp accept-filter 
add prefix=10.255.255.0/24 accept=yes
add accept=no
/mpls ldp interface
add interface=ether2
add interface=ether3
add interface=ether4

/routing bgp instance
set default as=65000 router-id=10.255.255.5
/routing bgp peer
add name=peerSVL remote-address=10.255.255.3 address-families=l2vpn,vpnv4 remote-as=65000 update-source=loopback route-reflect=no
add name=peerHKI remote-address=10.255.255.2 address-families=l2vpn,vpnv4 remote-as=65000 update-source=loopback route-reflect=yes
add name=peerLND remote-address=10.255.255.4 address-families=l2vpn,vpnv4 remote-as=65000 update-source=loopback route-reflect=yes
/routing bgp network
add network=10.255.255.0/24

/system identity
set name=r_LBN

/user
add name=alena password=alena group=full
remove admin

/ip address
add address=10.0.17.1/24 interface=ether2
add address=10.0.15.1/24 interface=ether3
add address=10.0.14.2/24 interface=ether4

/interface bridge
add name=loopback

/ip address
add address=10.255.3.254/32 interface=loopback

/routing ospf instance
add name=inst router-id=10.255.3.254

/routing ospf area
add name=backbone area-id=0.0.0.0 instance=inst

/routing ospf network
add area=backbone network=10.0.17.0/24
add area=backbone network=10.0.15.0/24
add area=backbone network=10.0.14.0/24
add area=backbone network=10.255.3.254/32

/mpls ldp
set enabled=yes lsr-id=10.255.3.254 transport-address=10.255.3.254

/mpls ldp interface
add interface=ether2
add interface=ether3
add interface=ether4

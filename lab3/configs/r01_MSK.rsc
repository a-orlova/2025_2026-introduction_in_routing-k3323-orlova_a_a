/system identity
set name=r_MSK

/user
add name=alena password=alena group=full
remove admin

/ip address
add address=10.0.12.2/24 interface=ether2
add address=10.0.15.2/24 interface=ether3

/interface bridge
add name=loopback

/ip address
add address=10.255.4.254/32 interface=loopback

/routing ospf instance
add name=inst router-id=10.255.4.254

/routing ospf area
add name=backbone area-id=0.0.0.0 instance=inst

/routing ospf network
add area=backbone network=10.0.12.0/24
add area=backbone network=10.0.15.0/24
add area=backbone network=10.255.4.254/32

/mpls ldp
set enabled=yes lsr-id=10.255.4.254 transport-address=10.255.4.254

/mpls ldp interface
add interface=ether2
add interface=ether3

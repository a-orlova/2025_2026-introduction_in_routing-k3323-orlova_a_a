/system identity
set name=r_LND
/user
add name=alena password=alena group=full
remove admin

/ip address add address=10.0.13.2/24 interface=ether2
/ip address add address=10.0.16.1/24 interface=ether3

/interface bridge
add name=loopback
/ip address
add address=10.255.255.4/32 interface=loopback network=10.255.255.4

/routing ospf instance
add name=inst router-id=10.255.255.4
/routing ospf area
add name=backbone area-id=0.0.0.0 instance=inst
/routing ospf network
add area=backbone network=10.0.13.0/24
add area=backbone network=10.0.16.0/24
add area=backbone network=10.255.255.4/32

/mpls ldp
set enabled=yes lsr-id=10.255.255.4 transport-address=10.255.255.4

/mpls ldp interface
add interface=ether2
add interface=ether3


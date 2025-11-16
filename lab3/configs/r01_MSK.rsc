/system identity
set name=r_MSK
/user
add name=alena password=alena group=full
remove admin

/ip address
add address=10.20.2.2/30 interface=ether2
add address=10.20.4.1/30 interface=ether3

/interface bridge
add name=loopback
/ip address 
add address=10.255.255.3/32 interface=loopback network=10.255.255.3

/routing ospf instance
add name=inst router-id=10.255.255.3
/routing ospf area
add name=backbone area-id=0.0.0.0 instance=inst
/routing ospf network
add area=backbone network=10.20.2.0/30
add area=backbone network=10.20.4.0/30
add area=backbone network=10.255.255.3/32

/mpls ldp
set lsr-id=10.255.255.3
set enabled=yes transport-address=10.255.255.3
/mpls ldp advertise-filter 
add prefix=10.255.255.0/24 advertise=yes
add advertise=no
/mpls ldp accept-filter 
add prefix=10.255.255.0/24 accept=yes
add accept=no
/mpls ldp interface
add interface=ether2
add interface=ether3

/system identity
set name=r_HKI
/user
add name=alena password=alena group=full
remove admin

/ip address
add address=10.20.1.2/30 interface=ether2
add address=10.20.5.1/30 interface=ether3
add address=10.20.3.1/30 interface=ether4

/interface bridge
add name=loopback
/ip address 
add address=10.255.255.2/32 interface=loopback network=10.255.255.2

/routing ospf instance
add name=inst router-id=10.255.255.2
/routing ospf area
add name=backbone area-id=0.0.0.0 instance=inst
/routing ospf network
add area=backbone network=10.20.1.0/30
add area=backbone network=10.20.3.0/30
add area=backbone network=10.20.5.0/30
add area=backbone network=10.255.255.2/32

/mpls ldp
set lsr-id=10.255.255.2
set enabled=yes transport-address=10.255.255.2
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

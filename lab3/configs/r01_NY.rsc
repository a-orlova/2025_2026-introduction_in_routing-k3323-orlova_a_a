/system identity
set name=r_NY

/user
add name=alena password=alena group=full
remove admin

/ip address add address=10.0.17.2/24 interface=ether2
/ip address add address=10.0.16.2/24 interface=ether3
/ip address add address=192.168.20.1/24 interface=ether4

/ip pool
add name=ny_pool ranges=192.168.20.100-192.168.20.254

/ip dhcp-server network
add address=192.168.20.0/24 gateway=192.168.20.1

/ip dhcp-server
add address-pool=ny_pool disabled=no interface=ether4 name=ds_ny

/interface bridge
add name=loopback

/ip address
add address=10.255.6.254/32 interface=loopback

/routing ospf instance
add name=inst router-id=10.255.6.254

/routing ospf area
add name=backbone area-id=0.0.0.0 instance=inst

/routing ospf network
add area=backbone network=10.20.16.0/24
add area=backbone network=10.20.17.0/24
add area=backbone network=192.168.20.0/24
add area=backbone network=10.255.6.254/32

/mpls ldp
set enabled=yes lsr-id=10.255.6.254 transport-address=10.255.6.254

/mpls ldp interface
add interface=ether2
add interface=ether3

/interface vpls
add name=vpls_SPB remote-peer=10.255.3.254 vpls-id=100:1 disabled=no

/interface bridge port
add bridge=loopback interface=ether4
add bridge=loopback interface=vpls_SPB


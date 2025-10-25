/ip address
add address=192.168.13.1/24 interface=ether2
add address=192.168.12.1/24 interface=ether3
add address=10.10.0.1/24 interface=ether4

/ip pool
add name=msk_pool ranges=10.10.0.10-10.10.0.254

/ip dhcp-server network
add address=10.10.0.0/24 gateway=10.10.0.1

/ip dhcp-server
add address-pool=msk_pool disabled=no interface=ether4 name=ds_msk

/ip route
add dst-address 10.20.0.0/24 gateway=192.168.12.2
add dst-address 10.30.0.0/24 gateway=192.168.13.3

/system identity
set name=r0_msk

/user
add name=alena password=alena group=full
remove admin

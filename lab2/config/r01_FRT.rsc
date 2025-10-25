/ip address
add address=192.168.12.2/24 interface=ether3
add address=192.168.23.2/24 interface=ether2
add address=10.20.0.1/24 interface=ether4

/ip pool
add name=dhcp_frt_pool ranges=10.20.0.100-10.20.0.254

/ip dhcp-server network
add address=10.20.0.0/24 gateway=10.20.0.1

/ip dhcp-server
add address-pool=dhcp_frt_pool disabled=no interface=ether4 name=dhcp_frt

/ip route
add dst-address 10.10.0.0/24 gateway=192.168.12.1
add dst-address 10.30.0.0/24 gateway=192.168.23.3

/system identity
set name=R_FRT

/user
add name=staffeev password=strongpassword group=full
remove admin

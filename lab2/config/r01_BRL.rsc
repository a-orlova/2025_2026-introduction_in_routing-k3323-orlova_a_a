/ip address
add address=192.168.13.3/24 interface=ether2
add address=192.168.23.3/24 interface=ether3
add address=10.30.0.1/24 interface=ether4

/ip pool
add name=dhcp_brl_pool ranges=10.30.0.100-10.30.0.254

/ip dhcp-server network
add address=10.30.0.0/24 gateway=10.30.0.1

/ip dhcp-server
add address-pool=dhcp_brl_pool disabled=no interface=ether4 name=dhcp_brl

/ip route
add dst-address 10.10.0.0/24 gateway=192.168.13.1
add dst-address 10.20.0.0/24 gateway=192.168.23.2

/system identity
set name=R_BRL

/user
add name=staffeev password=strongpassword group=full
remove admin

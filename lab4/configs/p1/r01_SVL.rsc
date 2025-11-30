/user
add name=alena password=alena group=full
remove admin
/system identity
set name=r_SVL

/ip address
add address=10.20.3.1/30 interface=ether2
add address=192.168.12.1/24 interface=ether3

/ip pool
add name=dhcp-pool ranges=192.168.12.10-192.168.12.100
/ip dhcp-server
add address-pool=dhcp-pool disabled=no interface=ether3 name=dhcp-server
/ip dhcp-server network
add address=192.168.12.0/24 gateway=192.168.12.1

/interface bridge
add name=loopback
/ip address 
add address=10.255.255.3/32 interface=loopback network=10.255.255.3

/routing ospf instance
add name=inst router-id=10.255.255.3
/routing ospf area
add name=backbone area-id=0.0.0.0 instance=inst
/routing ospf network
add area=backbone network=10.20.3.0/30
add area=backbone network=192.168.12.0/24
add area=backbone network=10.255.255.3/32

/mpls ldp
set lsr-id=10.255.255.3
set enabled=yes transport-address=10.255.255.3
/mpls ldp interface
add interface=ether2

/routing bgp instance
set default as=65000 router-id=10.255.255.3
/routing bgp peer
add name=peerLBN remote-address=10.255.255.5 address-families=l2vpn,vpnv4 remote-as=65000 update-source=loopback route-reflect=yes
/routing bgp network
add network=10.255.255.0/24

/interface bridge 
add name=br100
/ip address
add address=10.100.1.3/32 interface=br100
/ip route vrf
add export-route-targets=65000:100 import-route-targets=65000:100 interfaces=br100 route-distinguisher=65000:100 routing-mark=VRF_DEVOPS
/routing bgp instance vrf
add redistribute-connected=yes routing-mark=VRF_DEVOPS

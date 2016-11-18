#!/bin/bash -x

# Configure compute nodes
salt "cmp*" state.apply
salt "cmp*" state.apply

# Reboot compute nodes
echo "Rebooting compute nodes ..."
salt "cmp*" system.reboot

sleep 240

salt 'ctl01*' cmd.run "/usr/share/contrail-utils/provision_control.py --api_server_ip 172.16.10.254 --api_server_port 8082 --host_name ctl01 --host_ip 172.16.10.101 --router_asn 64512 --admin_password workshop --admin_user admin --admin_tenant_name admin --oper add"
salt 'ctl02*' cmd.run "/usr/share/contrail-utils/provision_control.py --api_server_ip 172.16.10.254 --api_server_port 8082 --host_name ctl02 --host_ip 172.16.10.102 --router_asn 64512 --admin_password workshop --admin_user admin --admin_tenant_name admin --oper add"
salt 'ctl03*' cmd.run "/usr/share/contrail-utils/provision_control.py --api_server_ip 172.16.10.254 --api_server_port 8082 --host_name ctl03 --host_ip 172.16.10.103 --router_asn 64512 --admin_password workshop --admin_user admin --admin_tenant_name admin --oper add"

salt 'ctl01*' cmd.run "/usr/share/contrail-utils/provision_vrouter.py --host_name cmp01 --host_ip 172.16.10.105 --api_server_ip 172.16.10.254 --oper add --admin_user admin --admin_password workshop --admin_tenant_name admin"

salt 'cmp01*' cmd.run "python /usr/share/contrail-utils/provision_vgw_interface.py --oper create --interface vgw1 --subnets 192.168.150.0/24 --routes 0.0.0.0/0 --vrf default-domain:admin:INET:INET"

salt 'cmp01*' cmd.run "/sbin/iptables -t nat -A POSTROUTING -j MASQUERADE"

salt 'ctl01*' cmd.run ". /root/keystonerc; neutron net-create INET --router:external"

salt 'ctl01*' cmd.run ". /root/keystonerc; neutron subnet-create --gateway 192.168.150.1 --disable-dhcp --name subext INET 192.168.150.0/24"
salt 'ctl01*' cmd.run ". /root/keystonerc; neutron net-create net1"
salt 'ctl01*' cmd.run ". /root/keystonerc; neutron subnet-create --name subnet1 net1 192.168.32.0/24"

salt 'ctl01*' cmd.run ". /root/keystonerc; neutron router-create router1"

salt 'ctl01*' cmd.run ". /root/keystonerc; neutron router-interface-add router1 subnet1"

salt 'ctl01*' cmd.run ". /root/keystonerc; neutron router-gateway-set router1 INET"

salt 'ctl01*' cmd.run "python /usr/share/contrail-utils/provision_linklocal.py --api_server_ip 172.16.10.254 --api_server_port 8082 --admin_user admin --admin_password workshop --admin_tenant_name admin --linklocal_service_name metadata --linklocal_service_ip 169.254.169.254 --linklocal_service_port 80 --ipfabric_service_ip 172.16.10.254 --ipfabric_service_port 8776"

salt 'ctl01*' cmd.run ". /root/keystonerc; neutron security-group-rule-create --direction ingress --ethertype IPv4 --protocol tcp --port-range-min 22 --port-range-max 22 default"
salt 'ctl01*' cmd.run ". /root/keystonerc; neutron security-group-rule-create --direction egress --ethertype IPv4 --protocol tcp --port-range-min 22 --port-range-max 22 default"

salt 'ctl01*' cmd.run ". /root/keystonerc; neutron security-group-rule-create --direction ingress --ethertype IPv4 --protocol icmp default"
salt 'ctl01*' cmd.run ". /root/keystonerc; neutron security-group-rule-create --direction egress --ethertype IPv4 --protocol icmp default"

salt 'ctl01*' cmd.run "wget http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-i386-disk.img"
salt 'ctl01*' cmd.run ". /root/keystonerc; glance image-create --name cirros --visibility public --disk-format qcow2 --container-format bare --progress < /root/cirros-0.3.4-i386-disk.img"

salt 'ctl01*' cmd.run ". /root/keystonerc; neutron floatingip-create INET"

salt -C '* and not cmp*' cmd.run "ip route add 192.168.150.0/24 via 172.16.10.105 dev weave"

salt 'ctl01*' cmd.run ". /root/keystonerc; nova boot --flavor m1.tiny --image cirros --nic net-name=net1 instance01.workshop.cloudlab.cz"
salt 'ctl01*' cmd.run ". /root/keystonerc; ip=\$(nova floating-ip-list | grep '192.168.150' | awk '{ print \$4 }');  nova floating-ip-associate instance01.workshop.cloudlab.cz \$ip"

FROM armhfbuild/debian

COPY . /home/dhcpd

RUN chmod +x /home/dhcpd/dnsmasq.sh

RUN DEBIAN_FRONTEND=noninteractive apt-get -y update && DEBIAN_FRONTEND=noninteractive apt-get -y install dnsmasq freeipmi ipmitool openipmi lsof sipcalc tmux

COPY etc/default/* /etc/default/

WORKDIR /home/dhcpd

# Expose DHCP
EXPOSE 67/udp
EXPOSE 68/udp

# default command
ENTRYPOINT ["/home/dhcpd/entrypoint.sh"]

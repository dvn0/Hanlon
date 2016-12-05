#!/bin/bash
hanlon image add -t mk -p ./web/hnl_mk_debug-image.2.0.1.iso -v 2.0.1 -n XXXhnl_mkXXX &
hanlon image add -t os -p ./web/VMware-VMvisor-Installer-6.0.0-2494585.x86_64.iso -v 2.0.1 -n XXXesx6XXX &
hanlon image add -t os -p ./web/coreos_production_iso_image.iso -v  557 -n XXXcoreosXXX &
hanlon image add -t os -p ./web/CentOS-6.6-x86_64-minimal.iso -v 6.6 -n XXXcentos6XXX &


Data acquisition software to be cross-compiled on the host computer targeted 
towards the Raspberry Pi 4 single board computer. The ``Makefile`` assumes 
a Buildroot cross-compilation framework is available on the host and the 
variable ``$BUILDROOT`` is set to this directory location. Furthermore, 
we assume that the ``/tmp`` directory is a RAMdisk at least 6 GB large 
(``size=6100M`` as an option to the /tmp entry with tmpfs type in 
/etc/fstab). During execution, make sure the Raspberry Pi 4 is running 
at full speed by executing 

``echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor``

since the Buildroot default configuration is to use the energy saving 
configuration with the processor running at lower (800 MHz) speed.

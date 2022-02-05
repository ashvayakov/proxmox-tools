@echo off

If /I %1 == password goto password
If /I %1 == hostname goto hostname
If /I %1 == ipv4 goto ipv4
If /I %1 == ipv4_dns goto ipv4_dns
If /I %1 == ipv4_gw goto ipv4_gw
If /I %1 == ipv6 goto ipv6
If /I %1 == ipv6_dns goto ipv6_dns
If /I %1 == ipv6_gw goto ipv6_gw
If /I %1 == reboot goto reboot

:ipv4
netsh interface ipv4 set address name="Ethernet" source=static addr=%2 mask=%3
REM exit applications
echo "IPv4: %2 / %3"
exit /B

:ipv4_dns
netsh interface ipv4 set dnsservers "Ethernet" static %2 primary
REM exit applications
echo "IPv4 DNS: %2"
exit /B

:ipv4_gw
netsh interface ipv4 add address "Ethernet" gateway=%2 gwmetric=0
REM exit applications
echo "IPv4 Gateway: %2"
exit /B

:ipv6
netsh interface ipv6 set address Ethernet address=%2/%3
REM exit applications
echo "IPv6: %2 / %3"
exit /B

:ipv6_dns
netsh interface ipv6 set dnsservers "Ethernet" static %2 primary
REM exit applications
echo "IPv6 DNS: %2"
exit /B

:ipv6_gw
netsh interface ipv6 add route ::/0 Ethernet %2
REM exit applications
echo "IPv6 Gateway: %2"
exit /B

:hostname
WMIC computersystem where caption='%COMPUTERNAME%' rename %2
netdom computername %COMPUTERNAME% /Add:%2.%3
netdom computername %COMPUTERNAME% /MakePrimary:%2.%3
REM exit applications
echo "Hostname is now: %2.%3"
exit /B

:password
net user %2 %3
REM exit applications
echo "User: %2 Password is now: %3"
exit /B

:reboot
shutdown /r /t 0
REM exit applications
echo "VM is rebooting"
exit /B
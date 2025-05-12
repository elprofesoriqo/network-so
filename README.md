Skaner sieciowy
 Wykorzystanie narzędzi takich jak ping i nmap do skanowania sieci.
 Skanowanie sieci lokalnej w celu wykrycia aktywnych urządzeń.
 Wykrywanie otwartych portów na urządzeniach w sieci.
 Opcja działania w tle, z zapisywaniem wyników skanowania w raportach.

do instalacji traceroute, ping, zenity


./main.sh -p ping -a 8.8.8.8 -f ping.txt
./main.sh -s 192.168.1.0/24 -t port
./main.sh -s 192.168.1.0/24 -t host -f hosty.txt
./main.sh -c config.rc

man ./network.1
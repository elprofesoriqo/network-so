#!/bin/bash

# Author           : Igor Jankowski
# Created On       : 2025-05-12
# Last Modified By : Igor Jankowski
# Last Modified On : 2025-05-12
# Version          : 1.0
#
# Description      : Network Scanner
# Opis
#
# Licensed under GPL (see /usr/share/common-licenses/GPL for more details
# or contact # the Free Software Foundation for a copy)



SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
. "$SCRIPT_DIR/scanner.rc"

CONFIG_FILE=""
OUTPUT_DIR=""
BACKGROUND=0
VERSION="1.0"

show_help() {
    man "$SCRIPT_DIR/network.1" | zenity --text-info --title="Help Manual" --width=600 --height=400
}

show_version() {
    zenity --info --text="Zenity Network Scanner v$VERSION" --title="Version"
}

parse_args() {
    while getopts ":c:bvhs:t:p:a:f:" opt; do
        case $opt in
            c) CONFIG_FILE="$OPTARG" ;;
            b) BACKGROUND=1 ;;
            v) show_version; exit 0 ;;
            h) show_help; exit 0 ;;
            s) SUBNET="$OPTARG" ;;
            t) SCAN_TYPE_CLI="$OPTARG" ;;
            p) POLECENIE="$OPTARG" ;;
            a) ADRES="$OPTARG" ;;
            f) OUTPUT_FILE="$OPTARG" ;;
            \?) zenity --error --text="Invalid option: -$OPTARG"; exit 1 ;;
            :) zenity --error --text="Option -$OPTARG requires an argument."; exit 1 ;;
        esac
    done


    if [[ -n "$POLECENIE" && -n "$ADRES" ]]; then
        local result=""
        if [[ "$POLECENIE" == "ping" ]]; then
            result=$(ping -c 4 "$ADRES" 2>&1)
        elif [[ "$POLECENIE" == "traceroute" ]]; then
            result=$(traceroute "$ADRES" 2>&1)
        fi
        echo "$result"
        if [[ -z "$OUTPUT_FILE" ]]; then
            read -p "Czy zapisać wynik do pliku? [t/N]: " save
            if [[ "$save" =~ ^[TtYy]$ ]]; then
                read -p "Podaj ścieżkę pliku: " file
                echo "$result" > "$file"
                echo "Wynik zapisany do $file"
            fi
        else
            echo "$result" > "$OUTPUT_FILE"
        fi
        exit 0
    elif [[ -n "$SUBNET" && -n "$SCAN_TYPE_CLI" ]]; then
        local result=""
        if [[ "$SCAN_TYPE_CLI" == "host" ]]; then
            result=$(nmap -sn "$SUBNET" 2>&1)
        elif [[ "$SCAN_TYPE_CLI" == "port" ]]; then
            result=""
            for ip in $(nmap -sn "$SUBNET" | grep "Nmap scan report for" | awk '{print $5}'); do
                result+="Skanowanie portów $ip:\n"
                result+="$(nmap -Pn "$ip")\n\n"
            done
        fi
        echo -e "$result"
        if [[ -z "$OUTPUT_FILE" ]]; then
            read -p "Czy zapisać wynik do pliku? [t/N]: " save
            if [[ "$save" =~ ^[TtYy]$ ]]; then
                read -p "Podaj ścieżkę pliku: " file
                echo -e "$result" > "$file"
                echo "Wynik zapisany do $file"
            fi
        else
            echo -e "$result" > "$OUTPUT_FILE"
        fi
        exit 0
    fi
}

load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        [[ -z "$SUBNET" ]] && . "$CONFIG_FILE"
        [[ -z "$SCAN_TYPE_CLI" && -n "$SCAN_TYPE" ]] && SCAN_TYPE_CLI="$SCAN_TYPE"
    else
        zenity --error --text="Config file not found!"
    fi
}

save_config() {
    local file
    file=$(zenity --file-selection --save --confirm-overwrite --title="Save Configuration" --filename="config.rc")
    [[ $? -ne 0 ]] && return
    cat > "$file" <<EOF
SUBNET="$SUBNET"
SCAN_TYPE="$SCAN_TYPE"
EOF
    zenity --info --text="Configuration saved."
}

config_window() {
    SUBNET=$(zenity --entry --title="Subnet" --text="Enter subnet to scan (e.g., 192.168.1.0/24):" --entry-text="${SUBNET:-192.168.1.0/24}")
    [[ $? -ne 0 ]] && return 1
    SCAN_TYPE=$(zenity --list --radiolist --title="Typ skanowania" \
        --column="Wybierz" --column="Typ" TRUE "Skan hostów (host discovery)" FALSE "Skan portów (port scan)" --height=200)
    [[ $? -ne 0 ]] && return 1
    return 0
}

main_menu() {
    while true; do
        MAIN_CHOICE=$(zenity --list --title="Network Scanner" --column="Wybierz sekcję" --height=250 \
            "Skan sieci" "Polecenia" "Instrukcja (man)")
        case "$MAIN_CHOICE" in
            "Skan sieci")
                scan_menu
                ;;
            "Polecenia")
                command_menu
                ;;
            "Instrukcja (man)")
                man "$SCRIPT_DIR/network.1" | zenity --text-info --title="Instrukcja network.1" --width=700 --height=600
                ;;
            ""|*)
                exit 0
                ;;
        esac
    done
}

scan_menu() {
    config_window || return
    run_scan "$SUBNET" "$SCAN_TYPE" 0
}

command_menu() {
    while true; do
        CMD_CHOICE=$(zenity --list --title="Polecenia" --column="Akcja" --height=200 \
            "Ping" "Traceroute" "Powrót")
        case "$CMD_CHOICE" in
            "Ping")
                # Pobiera adres IP lub host od użytkownika
                local host
                host=$(zenity --entry --title="Ping" --text="Podaj adres IP lub nazwę hosta do sprawdzenia:")
                [[ $? -ne 0 || -z "$host" ]] && continue # jesli nie tak to wróć do menu
                # Wykonanie polecenia
                local ping_result
                ping_result=$(ping -c 4 "$host" 2>&1)
                echo "$ping_result" | zenity --text-info --title="Wynik polecenia ping" --width=700 --height=400
                # Zapytaj, czy zapisać wynik do pliku
                if zenity --question --text="Czy chcesz zapisać wynik do pliku?"; then
                    local file
                    file=$(zenity --file-selection --save --confirm-overwrite --title="Zapisz wynik" --filename="ping_result.txt")
                    [[ $? -ne 0 ]] && continue
                    echo "$ping_result" > "$file"
                    zenity --info --text="Wynik zapisany do $file"
                fi
                ;;
            "Traceroute")
                local host
                host=$(zenity --entry --title="Traceroute" --text="Podaj adres IP lub nazwę hosta do sprawdzenia trasy:")
                [[ $? -ne 0 || -z "$host" ]] && continue
                # Wykonanie polecenia
                local trace_result
                trace_result=$(traceroute "$host" 2>&1)
                echo "$trace_result" | zenity --text-info --title="Wynik polecenia traceroute" --width=700 --height=500
                if zenity --question --text="Czy chcesz zapisać wynik do pliku?"; then
                    local file
                    file=$(zenity --file-selection --save --confirm-overwrite --title="Zapisz wynik" --filename="traceroute_result.txt")
                    [[ $? -ne 0 ]] && continue
                    echo "$trace_result" > "$file"
                    zenity --info --text="Wynik zapisany do $file"
                fi
                ;;
            "Powrót"|*)
                break
                ;;
        esac
    done
}

parse_args "$@"
[[ -n "$CONFIG_FILE" ]] && load_config
main_menu
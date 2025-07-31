#!/bin/bash

# Banner Function
banner() {
    clear
    echo -e "\e[1;92m"
    echo "@@@@@@@@@@   @@@@@@@@  @@@@@@@   @@@@@@    @@@@@@@@  @@@  @@@   @@@@@@    @@@@@@   @@@@@@@"
    echo "@@@@@@@@@@@  @@@@@@@@  @@@@@@@  @@@@@@@@  @@@@@@@@@  @@@  @@@  @@@@@@@@  @@@@@@@   @@@@@@@"
    echo "@@! @@! @@!  @@!         @@!    @@!  @@@  !@@        @@!  @@@  @@!  @@@  !@@         @@!   "
    echo "!@! !@! !@!  !@!         !@!    !@!  @!@  !@!        !@!  @!@  !@!  @!@  !@!         !@!   "
    echo "@!! !!@ @!@  @!!!:!      @!!    @!@!@!@!  !@! @!@!@  @!@!@!@!  @!@  !@!  !!@@!!      @!!   "
    echo "!@!   ! !@!  !!!!!:      !!!    !!!@!!!!  !!! !!@!!  !!!@!!!!  !@!  !!!   !!@!!!     !!!   "
    echo "!!:     !!:  !!:         !!:    !!:  !!!  :!!   !!:  !!:  !!!  !!:  !!!       !:!    !!:   "
    echo ":!:     :!:  :!:         :!:    :!:  !:!  :!:   !::  :!:  !:!  :!:  !:!      !:!     :!:   "
    echo ":::     ::    :: ::::     ::    ::   :::   ::: ::::  ::   :::  ::::: ::  :::: ::      ::  "
    echo " :      :    : :: ::      :      :   : :   :: :: :    :   : :   : :  :   :: : :       :   "
    echo -e "\e[0m"
    echo -e "\e[1;93m[~] MetaGhost v2.0 | Made by HackOps Academy | @_hack_ops_\e[0m"
    echo
}

# Menu Function
menu() {
    echo -e "\e[1;96mChoose an option:\e[0m"
    echo "  [1] Extract Metadata"
    echo "  [2] Remove Metadata"
    echo "  [3] Exit"
    echo -n -e "\n>> "
    read choice
    case $choice in
        1) extract_metadata ;;
        2) remove_metadata ;;
        3) echo -e "\e[1;91m[!] Exiting MetaGhost. Stay anonymous...\e[0m"; exit 0 ;;
        *) echo -e "\e[1;91m[!] Invalid choice. Try again.\e[0m"; sleep 1; clear; banner; menu ;;
    esac
}

# Check dependencies
check_dependencies() {
    if ! command -v exiftool &> /dev/null; then
        echo "[!] Installing Important tool..."
        pkg update -y && pkg install exiftool -y
    fi
}

# Extract metadata using exiftool (Improved Version)
extract_metadata() {
    echo -e "\n\e[1;94m[>] Enter path to image file to extract metadata:\e[0m"
    read image

    if [ ! -f "$image" ]; then
        echo -e "\e[1;91m[!] File not found!\e[0m"
        return
    fi

    mkdir -p reports

    filename=$(basename "$image")
    output="reports/metadata_${filename}.txt"

    echo -e "\e[1;92m[✔] Extracting metadata from: $filename\e[0m"
    sleep 1
    exiftool "$image" > "$output"
    cat "$output"
    echo
    echo -e "\e[1;96m[✔] Metadata saved to: $output\e[0m"
}

# Remove metadata using exiftool
remove_metadata() {
    echo -e "\n\e[1;94m[>] Enter path to image file to REMOVE metadata:\e[0m"
    read image

    if [ ! -f "$image" ]; then
        echo -e "\e[1;91m[!] File not found!\e[0m"
        return
    fi

    mkdir -p clean_images
    filename=$(basename "$image")
    output="clean_images/cleaned_${filename}"

    echo -e "\e[1;93m[!] Removing metadata...\e[0m"
    sleep 1
    exiftool -all= -o "$output" "$image"
    echo -e "\e[1;92m[✔] Metadata removed. Clean image saved as: $output\e[0m"
}

# Start Script
clear
banner
check_dependencies
while true; do
    menu
done

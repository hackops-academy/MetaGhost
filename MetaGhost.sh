#!/bin/bash

# Banner Function
banner() {
    clear
    echo -e "\e[1;95m"
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
    echo -e "\e[1;93m[~] MetaGhost | Made by HackOps Academy | @_hack_ops_\e[0m"
    echo
}

# Check dependencies
check_dependencies() {
    if ! command -v exiftool &> /dev/null; then
        echo "[!] exiftool not found. Installing..."
        pkg update && pkg install exiftool -y
    fi
}

# Extract metadata using exiftool
extract_metadata() {
    echo -e "\e[1;94m[>] Enter path to image file:\e[0m"
    read image
    if [ ! -f "$image" ]; then
        echo -e "\e[1;91m[!] File does not exist!\e[0m"
        exit 1
    fi

    echo -e "\e[1;92m[✔] Extracting metadata...\e[0m"
    sleep 1
    exiftool "$image" > "metadata_$image.txt"
    cat "metadata_$image.txt"
    echo
    echo -e "\e[1;96m[✔] Metadata saved to metadata_$image.txt\e[0m"
}

# Main
banner
check_dependencies
extract_metadata

# Outro
echo
echo -e "\e[1;92m[✔] Scan complete. All traces extracted.\e[0m"
echo -e "\e[1;91m[💀] Mission MetaGhost complete. Digital footprint indexed.\e[0m"
echo -e "\e[1;95m[📁] Report saved. Time to vanish...\e[0m"

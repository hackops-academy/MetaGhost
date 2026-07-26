#!/bin/bash

# ==============================================================================
#  METAGHOST v3.0 | Advanced Metadata Forensics & Anonymization Tool
#  Upgraded by : Hackops Academy Version Control batch 
# ==============================================================================

# --- Configuration & Colors ---
version="3.0"
report_dir="reports"
clean_dir="clean_output"
backup_dir="backups"

# ANSI Colors
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
PURPLE='\033[1;35m'
RESET='\033[0m'
BOLD='\033[1m'

# Trap Ctrl+C
trap ctrl_c INT
ctrl_c() {
    echo -e "\n${RED}[!] Exiting... Stay Safe.${RESET}"
    exit 1
}

# --- Utility Functions ---


banner() {
    clear
    echo -e "${PURPLE}"
    cat << "EOF"
   _____          __           ________.__                    __   
  /     \   _____/  |______   /  _____/|  |__   ____  _______/  |_ 
 /  \ /  \_/ __ \   __\__  \ /   \  ___|  |  \ /  _ \/  ___/\   __\
/    Y    \  ___/|  |  / __ \\    \_\  \   Y  (  <_> )___ \  |  |  
\____|__  /\___  >__| (____  /\______  /___|  /\____/____  > |__|  
        \/     \/          \/        \/     \/           \/       
EOF
    echo -e "${RESET}"
    echo -e "${CYAN}   :: v${version} :: Advanced Metadata Extraction & Scrubbing ::${RESET}"
    echo -e "${CYAN}   :: Made by hackops-academy | _hack_ops_::${RESET}"
    echo "--------------------------------------------------------------------------------"
}


spinner() {
    local pid=$!
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

check_dependencies() {
    echo -e "${YELLOW}[*] Checking core dependencies...${RESET}"
    if ! command -v exiftool &> /dev/null; then
        echo -e "${RED}[!] ExifTool not found. Attempting auto-install...${RESET}"
        
        if [ -f /data/data/com.termux/files/usr/bin/pkg ]; then
             pkg update -y && pkg install exiftool -y
        elif command -v apt &> /dev/null; then
             sudo apt update && sudo apt install libimage-exiftool-perl -y
        elif command -v brew &> /dev/null; then
             brew install exiftool
        elif command -v pacman &> /dev/null; then
             sudo pacman -S exiftool
        else
             echo -e "${RED}[X] Could not install automatically. Please install 'exiftool' manually.${RESET}"
             exit 1
        fi
    else
        echo -e "${GREEN}[✔] ExifTool is installed.${RESET}"
    fi
    sleep 1
}

# --- Core Modules ---

# 1. Advanced Extraction
extract_metadata() {
    echo -e "\n${BLUE}[INPUT] Enter path to file (Image/Video/PDF):${RESET}"
    read -e -p ">> " filepath
    # Remove quotes if user added them
    filepath=$(echo "$filepath" | tr -d "'\"")

    if [ ! -f "$filepath" ]; then
        echo -e "${RED}[!] File not found.${RESET}"; return
    fi

    filename=$(basename "$filepath")
    mkdir -p "$report_dir"
    report_file="${report_dir}/${filename}_report.html"

    echo -e "${YELLOW}[*] Analyzing deep metadata...${RESET}"
    
    # Generate HTML Header
    cat <<EOF > "$report_file"
    <html><head><style>
    body{font-family:monospace;background:#1a1a1a;color:#0f0;padding:20px;}
    h1{color:#fff;border-bottom:1px solid #555;}
    .risk{color:#ff3333;font-weight:bold;}
    table{width:100%;border-collapse:collapse;}
    td,th{border:1px solid #333;padding:8px;text-align:left;}
    tr:nth-child(even){background-color:#222;}
    </style></head><body>
    <h1>MetaGhost Report: $filename</h1>
    <table><tr><th>Tag</th><th>Value</th></tr>
EOF

    # Process and detect risks
    exiftool "$filepath" | while IFS=: read -r key val; do
        val=$(echo "$val" | xargs) # trim whitespace
        css_class=""
        
        # Risk detection logic
        if [[ "$key" == *"GPS"* ]] || [[ "$key" == *"Location"* ]]; then css_class='class="risk"'; fi
        if [[ "$key" == *"Creator"* ]] || [[ "$key" == *"Author"* ]]; then css_class='class="risk"'; fi
        if [[ "$key" == *"Device"* ]] || [[ "$key" == *"Model"* ]]; then css_class='class="risk"'; fi
        if [[ "$key" == *"Software"* ]] || [[ "$key" == *"OS"* ]]; then css_class='class="risk"'; fi

        echo "<tr><td>$key</td><td $css_class>$val</td></tr>" >> "$report_file"
    done

    echo "</table></body></html>" >> "$report_file"

    echo -e "${GREEN}[✔] Analysis Complete!${RESET}"
    echo -e "${CYAN}[>] HTML Report saved to: $report_file${RESET}"
    
    # Quick Terminal Summary of Risks
    echo -e "\n${RED}--- [ HIGH RISK DATA FOUND ] ---${RESET}"
    exiftool -grep "GPS|Creator|Model|Author" "$filepath"
    echo -e "${RED}--------------------------------${RESET}"
    read -p "Press Enter to continue..."
}

# 2. GPS Locator
gps_locator() {
    echo -e "\n${BLUE}[INPUT] Enter path to image for GPS extraction:${RESET}"
    read -e -p ">> " filepath
    filepath=$(echo "$filepath" | tr -d "'\"")

    if [ ! -f "$filepath" ]; then echo -e "${RED}[!] File not found.${RESET}"; return; fi

    echo -e "${YELLOW}[*] triangulating coordinates...${RESET}"
    
    # Extract decimal coordinates
    lat=$(exiftool -c "%.6f" -GPSLatitude -s3 "$filepath")
    lon=$(exiftool -c "%.6f" -GPSLongitude -s3 "$filepath")

    if [ -z "$lat" ] || [ -z "$lon" ]; then
        echo -e "${RED}[X] No GPS data found in this file.${RESET}"
    else
        # Handle Reference (N/S/E/W)
        lat_ref=$(exiftool -GPSLatitudeRef -s3 "$filepath")
        lon_ref=$(exiftool -GPSLongitudeRef -s3 "$filepath")
        
        # Adjust for S and W
        if [[ "$lat_ref" == "South" ]]; then lat="-$lat"; fi
        if [[ "$lon_ref" == "West" ]]; then lon="-$lon"; fi
        
        # Clean formatting
        lat=$(echo $lat | sed 's/ //g')
        lon=$(echo $lon | sed 's/ //g')

        map_link="https://www.google.com/maps?q=${lat},${lon}"
        
        echo -e "${GREEN}[✔] GPS Coordinates Found!${RESET}"
        echo -e "    Latitude : $lat"
        echo -e "    Longitude: $lon"
        echo -e "${CYAN}[>] Map Link: ${BOLD}$map_link${RESET}"
    fi
    read -p "Press Enter to continue..."
}

# 3. Secure Cleaning (With Backup)
remove_metadata() {
    echo -e "\n${BLUE}[INPUT] Enter path to file to SCRUB:${RESET}"
    read -e -p ">> " filepath
    filepath=$(echo "$filepath" | tr -d "'\"")

    if [ ! -f "$filepath" ]; then echo -e "${RED}[!] File not found.${RESET}"; return; fi

    filename=$(basename "$filepath")
    mkdir -p "$clean_dir"
    mkdir -p "$backup_dir"

    # Backup
    echo -e "${YELLOW}[*] Creating secure backup...${RESET}"
    cp "$filepath" "$backup_dir/${filename}.bak"
    
    output_file="$clean_dir/clean_${filename}"

    echo -e "${YELLOW}[*] Scrubbing all metadata tags...${RESET}"
    # Use exiftool to remove all, overwrite original in place? No, create new to be safe
    exiftool -all= -o "$output_file" "$filepath" &>/dev/null &
    spinner

    if [ -f "$output_file" ]; then
        echo -e "\n${GREEN}[✔] File Cleaned Successfully!${RESET}"
        echo -e "${CYAN}[>] Clean file: $output_file${RESET}"
        echo -e "${CYAN}[>] Backup at: $backup_dir/${filename}.bak${RESET}"
    else
        echo -e "\n${RED}[!] Scrubbing failed. Check file permissions.${RESET}"
    fi
    read -p "Press Enter to continue..."
}

# 4. Bulk Processing
bulk_process() {
    echo -e "\n${BLUE}[INPUT] Enter DIRECTORY path to scrub:${RESET}"
    read -e -p ">> " dirpath
    dirpath=$(echo "$dirpath" | tr -d "'\"")

    if [ ! -d "$dirpath" ]; then echo -e "${RED}[!] Directory not found.${RESET}"; return; fi

    mkdir -p "$clean_dir/bulk_clean"
    count=0
    
    echo -e "${YELLOW}[*] Starting bulk sanitization...${RESET}"
    
    for file in "$dirpath"/*; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            exiftool -all= -o "$clean_dir/bulk_clean/$filename" "$file" &>/dev/null
            ((count++))
            echo -e "    ${GREEN}[+] Cleaned:${RESET} $filename"
        fi
    done

    echo -e "\n${GREEN}[✔] Bulk Operation Complete.${RESET}"
    echo -e "${CYAN}[>] Processed $count files. Output: $clean_dir/bulk_clean/${RESET}"
    read -p "Press Enter to continue..."
}

# --- Main Logic ---

check_dependencies

while true; do
    banner
    echo -e "${BOLD}Select Operation Mode:${RESET}"
    echo -e "  ${CYAN}[1]${RESET} Deep Analysis (HTML Report)"
    echo -e "  ${CYAN}[2]${RESET} GPS Forensics (Map Locator)"
    echo -e "  ${CYAN}[3]${RESET} Secure Scrub (Single File + Backup)"
    echo -e "  ${CYAN}[4]${RESET} Bulk Scrub (Entire Directory)"
    echo -e "  ${CYAN}[0]${RESET} Exit"
    echo
    echo -n -e "${YELLOW}metaghost ~# ${RESET}"
    read choice

    case $choice in
        1) extract_metadata ;;
        2) gps_locator ;;
        3) remove_metadata ;;
        4) bulk_process ;;
        0) echo -e "${RED}[!] Going dark...${RESET}"; exit 0 ;;
        *) echo -e "${RED}[!] Invalid option.${RESET}"; sleep 1 ;;
    esac
done

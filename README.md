
# 🕵️‍♂️ MetaGhost v3.0 - Advanced Forensics & Anonymization

![banner](https://img.shields.io/badge/Made%20By-HackOps%20Academy-%23purple)
![Version](https://img.shields.io/badge/Version-3.0-orange)
![Shell](https://img.shields.io/badge/Made%20with-Bash-blue)
![Status](https://img.shields.io/badge/Status-Active-success)

**MetaGhost** is an advanced terminal-based image forensics and privacy tool developed by **HackOps Academy**.

Unlike basic tools, MetaGhost v3.0 goes beyond simple extraction. It performs **risk assessment**, generates **HTML reports**, locates **GPS coordinates** on Google Maps, and performs **secure bulk scrubbing** to anonymize your media.

---

## ⚡ Key Features (v3.0)

- **📊 HTML Risk Reporting:** Generates professional HTML reports that highlight "High Risk" metadata (Device ID, Location, Author) in red.
- **📍 GPS Forensics:** Automatically detects GPS tags and generates a clickable **Google Maps link**.
- **🛡️ Secure Scrubbing:** Removes all metadata while automatically creating a **backup** of the original file (safety first).
- **📂 Bulk Mode:** Sanitize an entire directory of photos or documents in seconds.
- **📱 Smart Detect:** Works seamlessly on **Termux (Android)**, **Linux**, and **macOS**.
- **🔒 Privacy Focused:** 100% offline. No data leaves your device.

---

## 🧠 Use Cases

1.  **OSINT Investigations:** Track the precise location where a photo was taken.
2.  **Privacy Protection:** Scrub GPS and device data before uploading photos to social media.
3.  **Forensic Analysis:** Identify if an image has been edited or identify the camera model/software used.

---

## 🚀 Installation

### For Termux (Android) & Linux

```bash
# Clone the repository
git clone [https://github.com/hackops-academy/MetaGhost](https://github.com/hackops-academy/MetaGhost)

# Enter the directory
cd MetaGhost

# Grant permission
chmod +x metaghost.sh

# Run the tool
./metaghost.sh
```
## 📖 Usage Guide
Once you run ./metaghost.sh, you will see the main menu:
1. **Deep Analysis (HTML Report)**
   • What it does: Scans a file and creates a .html file in the reports/ folder.
   • How to view:
   ```bash
   cd reports
   ls
   ```
### You can open the HTML file in your browser
termux-open image_report.html

2. **GPS Forensics**
   • What it does: Extracts            Latitude/Longitude and gives      you a direct link to Google       Maps.
3. **Secure Scrub (Single File)**
   • What it does: Removes             metadata from one specific        file.
   • Safety: It creates a backup       of your original file in the      backups/ folder before            cleaning.
   • Output: The clean file is         saved in clean_output/.
4. **Bulk Scrub (Directory)**
   • What it does: Removes             metadata from every image in      a specific folder.
   • Output: All clean images are      saved in                          clean_output/bulk_clean/.

## 📂 File Management (Termux Users)
Since Termux uses a private file system, here is how to move your cleaned images to your phone's Gallery/Downloads.
### To move a cleaned image to Internal Storage:###
```bash
# 1. Go to the output folder
cd clean_output

# 2. List files to see the name
ls

# 3. Move the file to your Downloads folder
mv clean_image.jpg /sdcard/Download/
```
### To view the text content of a report:###
```bash
cd reports
cat filename_report.html
# OR if you have 'bat' installed
bat filename_report.html
```
## ⚠️ Disclaimer
This tool is designed for educational purposes, digital forensics, and privacy protection. HackOps Academy is not responsible for any misuse of this tool. Always ensure you have permission before analyzing files that do not belong to you.
<p align="center">
Made with ❤️ by HackOps Academy
</p>


# 🕵️‍♂️ MetaGhost - Image Metadata Extractor

![banner](https://img.shields.io/badge/Made%20By-HackOps%20Academy-%23purple)  
**MetaGhost** is a powerful terminal-based image metadata extractor built for ethical hackers, forensic investigators, and OSINT researchers. It digs deep into hidden EXIF metadata stored inside image files — timestamps, GPS, camera model, software used, and more.

---

## 📸 Features

- ✅ Extracts complete EXIF metadata from image files
- ✅ Works seamlessly in **Termux (Android)** and **Linux**
- ✅ Automatically installs dependencies (`exiftool`)
- ✅ Saves extracted metadata into a text file
- ✅ Stylish hacker-themed banner and mission outro
- ✅ 100% offline tool — no external API required

---

## 🧠 Use Cases

- Digital Forensics & OSINT
- Track the origin of shared images
- Identify GPS coordinates or tampering
- Analyze timestamp history and camera model

---

## 🚀 Installation & Usage (in Termux)

```bash
pkg update && pkg upgrade
pkg install unzip
unzip MetaGhost.zip
chmod +x MetaGhost.sh
./MetaGhost.sh

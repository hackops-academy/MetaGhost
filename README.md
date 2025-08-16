# 🕵️‍♂️ MetaGhost - Metadata Recon & Remover Tool

![banner](https://img.shields.io/badge/Made%20By-HackOps%20Academy-%23purple)  
![Shell](https://img.shields.io/badge/Made%20with-Bash-blue)
![Status](https://img.shields.io/badge/Status-Active-success)
![PRs](https://img.shields.io/badge/PRs-welcome-brightgreen)


**MetaGhost**  is a Termux-based image forensics tool developed by **HackOps Academy**. It allows you to **extract** hidden metadata from image files (EXIF) and **clean** them to protect user privacy.

---

## 📸 Features

- ✅ Extracts complete EXIF metadata from image files
- ✅ Works seamlessly in **Termux (Android)** and **Linux**
- ✅ Saves extracted metadata into a text file
- ✅ It can extract and remove metadata from image and save the results in a separate directory 
- ✅ 100% offline tool — no external API required

---

## 🧠 Use Cases

- Digital Forensics & OSINT
- Track the origin of shared images
- Identify GPS coordinates or tampering
- Analyze timestamp history and camera model
- Also for removing all metadata for privacy 
---

## 🚀 Installation  (in Termux)

```bash
git clone https://github.com/hackops-academy/MetaGhost
cd MetaGhost
chmod +x MetaGhost.sh
./MetaGhost.sh
```
To run this tool any time you have to just go to it's directory which is MetaGhost and run  ./MetaGhost.sh

```bash
cd MetaGhost
./MetaGhost.sh
```

The clean image is saved to the directory named clean_images and the details of images you collected is saved in reports.

If you want to see the clean image you can run 
```bash
cd clean_images
ls
bat [ new name of image/copy and paste the name]
```
And if you want to see the report of extracted metadata you can run 
```bash
cd reports
ls
bat [name of image]
```
To save the image locally you can run 
```bash
cd clean_images
ls
mv [paste the nme of image] /sdcard/Download/
```

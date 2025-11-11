# 🚀 DooOS - 16-bit Operating System

<div align="center">

**Minimal 16-bit OS with FAT12 Read-Only Filesystem**

*Experience the fundamentals of operating system development*

</div>

## 📖 About DooOS

**DooOS** is an 16-bit operating system written entirely in assembly language. Designed for developers and students interested in low-level programming, DooOS demonstrates core OS concepts including bootloading, memory management, filesystems, and system calls. Running in x86 real mode, it provides a hands-on approach to understanding how operating systems work at their most fundamental level.

## ✨ Features & Capabilities

### 🆕 Version 0.2 Highlights
- **📁 FAT12 Filesystem Support** - Complete read-only implementation of the FAT12 filesystem standard
- **🔍 File System Navigation** - Browse directories and view file listings with detailed information
- **📄 File Content Access** - Read and display text files directly from the filesystem
- **💾 Disk Operations** - Low-level floppy disk access with proper error handling
- **🛡️ Enhanced Stability** - Improved system reliability and comprehensive error reporting

### 🖥️ Core System Architecture
- **🔧 Custom Bootloader** - MBR-compliant 512-byte boot sector with proper BIOS parameter handling
- **⚙️ Real Mode Kernel** - Full 16-bit kernel with interrupt handling and memory management
- **📞 System Service API** - Comprehensive INT 0x21 interface for application development
- **🎨 Advanced Shell** - Color-coded terminal interface with command history and completion
- **💿 Storage Drivers** - Robust floppy disk controller support for 1.44MB media

## 🛠️ Technical Specifications

### System Architecture
- **🏗️ Processor Architecture**: x86-compatible (16-bit Real Mode)
- **💾 Filesystem Support**: FAT12 (Fully Read-Only Implementation)
- **💿 Storage Media**: Standard 1.44MB 3.5" floppy disks
- **🧠 Memory Model**: Conventional memory architecture with segmented addressing
- **📟 Boot Method**: Traditional BIOS/MBR boot process

### FAT12 Implementation
- **📊 BIOS Parameter Block** - Complete BPB parsing and validation
- **📁 Root Directory Access** - Efficient directory entry reading and caching
- **🔗 FAT Table Processing** - File Allocation Table traversal with cluster chain following
- **📄 File Content Reading** - Cluster-based file reading with buffer management

## 📦 Command Reference
Вот измененная таблица команд, соответствующая вашей операционной системе DooOS:

| Command | Syntax | Description |
|---------|---------|-------------|
| `help` | `help` | Show available commands and usage |
| `create` | `create` | Create a new file in memory |
| `edit` | `edit` | Edit file content (memory files only) |
| `files` | `files` | List all files (FAT12 and memory) |
| `open` | `open` | Open and view file content |
| `run` | `run` | Execute a .doo program |
| `clear` | `clear` | Clear the screen |
| `reboot` | `reboot` | Reboot the system |

## 🔧 Building from Source

### Prerequisites
- **NASM Assembler** (Netwide Assembler) version 2.13 or newer
- **QEMU** emulator or physical x86-compatible hardware
- **Make** utility (optional, for build automation)
- **FAT12-formatted disk image** for testing filesystem features

### Compilation Instructions
```bash
# Compile bootloader component
nasm -f bin boot.asm -o boot.bin

# Compile kernel with system services
nasm -f bin kernel.asm -o kernel.bin

# Combine into final binary image
cat boot.bin kernel.bin > OS.bin

Automated Build Script

🚀 Running DooOS

Using QEMU Emulator

# Basic emulation with floppy support
qemu-system-i386 -fda OS.bin -boot a

# With additional debugging features
qemu-system-i386 -fda OS.bin -boot a -d cpu_reset -no-reboot

# Basic emulation with floppy support
qemu-system-i386 -fda OS.bin -boot a

# With additional debugging features
qemu-system-i386 -fda OS.bin -boot a -d cpu_reset -no-reboot

Physical Hardware Deployment

Write OS.bin to boot sector of FAT12-formatted floppy
Ensure system BIOS is configured for floppy boot
Insert media and boot from floppy drive
🎯 Getting Started Guide

First-Time Setup

Build the System - Compile using the provided instructions
Prepare Storage - Create a FAT12 disk image with test files
Configure Emulator - Set up QEMU with proper floppy emulation
Initial Boot - Start the system and verify basic functionality
Exploring the System

System Information - Use info command to view OS status
File Browsing - Navigate directories with dir command
File Reading - Examine file contents using type command
System Exploration - Experiment with different file operations
📈 Development Roadmap

Version 0.3 (Next Release)

✨ FAT12 Write Support - File creation, deletion, and modification
✨ Text Editor - Built-in editor for file creation and editing
✨ Extended File Operations - Copy, move, and rename capabilities
✨ Advanced Error Handling - Comprehensive error reporting and recovery

Current Version (0.2)

Read-only filesystem (no file writing)
Single directory support (no subdirectories)
Basic text file support only
Limited to 1.44MB storage capacity
No multiprocessing or memory protection


Core Contributors

DooLiving - Lead Developer, Kernel Architecture, Bootloader Design
PRoX2011 - x16-PRos Output API, System Call Interface (MIT Licensed)
Special Thanks

To the open source community and OS development enthusiasts who provided valuable feedback and testing during development.

📄 License Information

text

Копировать

Скачать
DooOS Kernel - Copyright © 2025 DOOLIVING
x16-PRos Output API - Copyright © 2025 PRoX2011 (MIT License)
FAT12 Implementation - Copyright © 2025 DooOS Development Team

This project is provided for educational purposes.
Commercial use requires explicit permission from the authors.
🔗 Resources & References

Source Code: Available on project repository
Documentation: Comprehensive technical documentation
Community Forum: Discussion and support community
Issue Tracking: Bug reports and feature requests
<div align="center">
🌟 Star the project if you find it helpful!

Happy coding and exploring the world of operating systems! 🎉

</div> ```

# 🚀 DooOS - 16-bit Operating System

## 🎯 What is DooOS?

**DooOS** is a functional 16-bit operating system running in Real Mode. Built from scratch for enthusiasts who want a minimal but working OS.

> **Note**: "x86" refers to the processor architecture (Intel-compatible CPUs), while "16-bit" indicates the operating mode and memory addressing.

## ⚡ Core Features

### 🖥️ System Architecture
- **Custom Bootloader** - MBR-compliant 512-byte boot sector
- **Real Mode Kernel** - Full 16-bit kernel with proper segment management
- **Interrupt-Driven API** - INT 0x21 for system services

### 💾 File System
- **DooFS** - Custom in-memory file system
- **File Operations** - Create, list, edit, and delete files
- **Program Support** - Execute `.doo` script files

### 🎨 User Interface
- **Colorful Shell** - Green prompts, red errors, cyan info
- **Interactive Commands** - Real command-line interface
- **Program Runner** - Execute multi-command scripts

## 🛠️ Technical Specifications

### Architecture Clarification
- **CPU Architecture**: x86 (Intel-compatible processors)
- **Operating Mode**: 16-bit Real Mode
- **Memory Addressing**: 16-bit segments and offsets

### Memory Map

0x0000-0x7BFF - Free Memory
0x7C00-0x7DFF - Bootloader
0x7E00-0x8DFF - Kernel (4KB)
0x9000-0x93FF - File System (1KB)


### File System Structure
- **Max Files**: 5
- **File Entry**: 80 bytes (16 name + 64 content)
- **Location**: 0x9000 in RAM

## 📦 Commands

| Command | Description |
|---------|-------------|
| `help` | Show available commands |
| `create` | Create a new file |
| `files` | List all files |
| `open` | Edit existing file |
| `run` | Execute .doo program |
| `reboot` | Restart the system |

## 🎮 .doo Programs

Create executable scripts with `.doo` extension:

```bash
# example.doo
print - Hello from DooOS!
print - This is a running program.

🔧 Building & Running
Requirements
NASM Assembler

QEMU or physical x86 computer

1.44MB floppy image support

Compilation

nasm -f bin boot.asm -o boot.bin
nasm -f bin kernel.asm -o kernel.bin
copy /b boot.bin + kernel.bin OS.bin

Runing

qemu-system-x86_64 -fda OS.bin


🚀 Quick Start
1. Build the OS: Run the compilation commands

2. Boot: Load OS.bin in QEMU or write to USB

3. Use: Type help to see available commands

4. Create Files: Use create to make new files

5. Run Programs: Write .doo files and execute with run

📝 License
DooOS Kernel - © 2025 DOOLIVING
x16-PRos Output API - © 2025 PRoX2011 (MIT License)

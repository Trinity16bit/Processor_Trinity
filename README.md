# 🚀 Processor-Trinity: 16-Bit Custom RISC Architecture

## 📌 Overview
Processor-Trinity is a custom-designed, 16-bit Reduced Instruction Set Computer (RISC) microprocessor developed from scratch. Designed by a core team of second-year Electronics and Communication Engineering (ECE) undergraduates at NIT Puducherry, this project serves as a practical, hands-on exploration of digital system design, instruction set architecture (ISA), and processor datapath routing.

We built this processor to bridge the gap between theoretical computer architecture and real-world VLSI implementation, with the ultimate goal of transitioning these skills into advanced RISC-V development.

## 🏗️ Architectural Specifications
The Trinity architecture follows a classic RISC philosophy, emphasizing a streamlined instruction set, uniform instruction length, and a load/store memory model.

* **Architecture Type:** 16-bit RISC (Harvard Architecture)
* **Instruction Size:** 16-bit fixed-width instructions
* **Opcode:** 4-bit (bits [15:12]), allowing up to 16 base instructions
* **Registers:** 8 General-Purpose Registers (R0 - R7), 16-bit each
* **Immediate Value:** 9-bit immediate (sign-extended to 16-bit for ALU operations)
* **Program Counter (PC):** 12-bit, enabling up to 4K instruction addressability
* **Memory Integration:** * Instruction Memory: ROM (256 x 16-bit)
    * Data Memory: SRAM (256 x 16-bit)

## ⚙️ Core Datapath & Modules
Our processor integrates several carefully routed custom modules:
1.  **Control Unit:** Decodes the 4-bit opcode and generates the necessary control signals for memory access, ALU operations, and multiplexer routing.
2.  **Arithmetic Logic Unit (ALU):** Capable of executing ADD, SUB, MUL, DIV, AND, OR, and other essential operations. 
3.  **Flag Register:** 4-bit status register tracking Zero (Z), Carry (C), Negative (N), and Overflow (V) conditions directly from the ALU.
4.  **Writeback Multiplexer:** Selects between ALU computational results and Data Memory read data for register writeback.
5.  **Sign Extender:** Converts 9-bit immediate values from the instruction into 16-bit operands for the ALU.

## 👥 The Trinity Team
This architecture is proudly designed and developed by:
* **Jaikrishnan P** - Core Architecture & Logic Design
* **Mohamed Faiz N** - Digital System Design
* **T Pavithra** - Digital System Design

*Second-Year B.Tech ECE (2024-2028 Batch) | National Institute of Technology, Puducherry (NITPY)*

## 🔮 Future Roadmap
* RTL coding using Verilog HDL.
* Simulation and waveform verification.
* FPGA synthesis and implementation.
* Migration to 32-bit RISC-V standard architecture.

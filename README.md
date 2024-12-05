# 32bitARM_like_CPU_design

## Instruction Set

### **Data Processing Instruction**

| 31:28       | 27:26                  | 25:20            | 19:16      | 15:12       | 11:0      |
|-------------|------------------------|------------------|------------|-------------|-----------|
| `cond`      | `type of instruction` | `funt`           | `Rn`       | `Rd`        | `Src2`    |
| Condition   | `00` - Data Processing| Function Field   | First Source Register  | Destination Register | Operand   |

#### **Details of `funt` (25:20) and `Src2` (11:0):**

- **Function Field (`funt`):**
  | Bit      | Field       | Description                                   |
  |----------|-------------|-----------------------------------------------|
  | 25       | `I`         | Immediate (`1`) or Register (`0`)             |
  | 24:21    | `cmd`       | Command (e.g., ADD, SUB, AND, ORR)            |
  | 20       | `S`         | Signed (`1`) or Unsigned (`0`)                |

- **Second Operand (`Src2`):**
  - **If Immediate (`I=1`):**
    | Bit    | Field       | Description                                   |
    |--------|-------------|-----------------------------------------------|
    | 11:8   | `rot`       | Rotation                                      |
    | 7:0    | `imm8`      | 8-bit Immediate Value                         |

  - **If Register (`I=0`):**
    | Bit    | Field       | Description                                   |
    |--------|-------------|-----------------------------------------------|
    | 11:7   | `shamt5`    | Shift Amount                                  |
    | 6:5    | `sh`        | Shift Type                                    |
    | 4:0    | `Rm`        | Second Source Register                        |

---

### **Memory Instruction**

| 31:28       | 27:26                  | 25:20            | 19:16      | 15:12       | 11:0      |
|-------------|------------------------|------------------|------------|-------------|-----------|
| `cond`      | `type of instruction` | `funt`           | `Rn`       | `Rd`        | `Src2`    |
| Condition   | `01` - Memory          | Function Field   | Base Reg   | Destination/Source | Offset    |

#### **Details of `funt` (25:20) and `Src2` (11:0):**

- **Function Field (`funt`):**
  | Bit      | Field       | Description                                   |
  |----------|-------------|-----------------------------------------------|
  | 25       | `I`         | Immediate (`1`) or Register (`0`)             |
  | 24       | `P`         | Pre/Post Indexing                             |
  | 23       | `U`         | Up (`1`) or Down (`0`) Offset                 |
  | 22       | `B`         | Byte (`1`) or Word (`0`) Access               |
  | 21       | `W`         | Write-back (`1`) or No Write-back (`0`)       |
  | 20       | `L`         | Load (`1`) or Store (`0`)                     |

- **Second Operand (`Src2`):**
  - **If Immediate (`I=1`):**
    | Bit    | Field       | Description                                   |
    |--------|-------------|-----------------------------------------------|
    | 11:0   | `imm12`     | 12-bit Immediate Offset                       |

  - **If Register (`I=0`):**
    | Bit    | Field       | Description                                   |
    |--------|-------------|-----------------------------------------------|
    | 11:7   | `shamt5`    | Shift Amount                                  |
    | 6:5    | `sh`        | Shift Type                                    |
    | 4:0    | `Rm`        | Offset Register                               |

---

### **Branch Instruction**

| 31:28       | 27:26                  | 25:24      | 23:0       |
|-------------|------------------------|------------|------------|
| `cond`      | `type of instruction` | `0L`       | `Imm24`    |
| Condition   | `10` - Branch          | Link Field | Offset     |

#### **Details of `0L` (25:24) and `Imm24` (23:0):**

- **Link Field (`0L`):**
  | Bit      | Field       | Description                                   |
  |----------|-------------|-----------------------------------------------|
  | 25       | `0`         | Always `0`                                    |
  | 24       | `L`         | Branch with Link (`1`) or Regular Branch (`0`)|

- **Immediate Offset (`Imm24`):**
  | Bit      | Field       | Description                                   |
  |----------|-------------|-----------------------------------------------|
  | 23:0     | `Imm24`     | Sign-extended and left-shifted by 2           |
  |          |             | Target Address: `PC + (Imm24 << 2)`           |

---

## Mnemonics
    
### **Instruction mnemonics from ARM LRM (Used in design)**

Data Processing: ADD SUB AND ORR 

Memory Operation: STR and LDR 

Branch: B 

### **Conditional mnemonics from ARM LRM**

![WhatsApp Image 2024-12-03 at 13 30 34_e0b9d3fd](https://github.com/user-attachments/assets/6a794e82-798c-4c2c-afeb-7da60a956cea)

ref: Digital Design and Computer Architecture ARM edition by Harris

---
## Micro Architecture Top View

![32cpu overview](https://github.com/user-attachments/assets/456d560d-4701-4ff0-9988-70b5811e8e6b)

---

## Datapath

### Memory Instruction Datapath

Memory instructions (`LDR` and `STR`) involve transferring data between registers and memory. The datapath for these instructions revolves around decoding the instruction, calculating the effective address using the base register (`Rn`) and an offset, and performing the appropriate memory access operation. Control signals like `I`, `P`, `U`, `W`, and `L` determine the exact behavior of the operation.

#### LDR (Load Instruction)

- **Effective Address Calculation**: 
  - If `I=1`: Compute the effective address by adding/subtracting the 12-bit immediate (`imm12`) to/from the base register (`Rn`).
  - If `I=0`: Use the base register (`Rn`) and a shifted offset from `Rm` (based on `shamt5` and `sh`).
- **Memory Access**: Read data from memory using the computed address.
- **Destination Register Update**: Load the read data into the destination register (`Rd`).
- **Optional Write-Back**: If `P=0` and `W=1`, update the base register (`Rn`) with the effective address.

  ![WhatsApp Image 2024-12-03 at 18 35 55_247a0e6e](https://github.com/user-attachments/assets/107fb7a7-cb54-463d-9e51-3b0236eec4d4)


#### STR (Store Instruction)

- **Effective Address Calculation**: 
  - Similar to `LDR`, compute the effective address using either an immediate offset or a shifted register offset.
- **Memory Access**: Write data from the source register (`Rd`) into memory at the computed address.
- **Optional Write-Back**: If `P=0` and `W=1`, update the base register (`Rn`) with the effective address.

![WhatsApp Image 2024-12-03 at 18 37 24_38eb6853](https://github.com/user-attachments/assets/d230fa4f-2d10-499a-82f6-935742a4cc53)

---

### Data Processing Instruction Datapath

Data processing instructions involve arithmetic, logical, and data manipulation operations. The datapath for these instructions processes operands from either immediate values or registers, executes the specified command (`cmd`), and stores the result in the destination register (`Rd`). The control signal `I` determines whether the second operand (`Src2`) is immediate or register-based.

#### Immediate Mode (`I=1`)

- **Operand Fetch**: 
  - Extract the 8-bit immediate value (`imm8`) and rotate it by the specified `rot` value (4 bits) to align it for the operation.
  - Retrieve the first source operand from the register (`Rn`).
- **Operation Execution**: Perform the specified command (`cmd`) such as ADD, SUB, AND, ORR, etc., using the first source operand (`Rn`) and the processed immediate value.
- **Result Storage**: Write the computed result into the destination register (`Rd`).
- **Flags Update**: If `S=1`, update condition flags (e.g., Zero, Negative, Carry, Overflow).

![WhatsApp Image 2024-12-03 at 19 02 43_943340b4](https://github.com/user-attachments/assets/171349bb-2e1e-4788-bed5-d77650705454)


#### Register Mode (`I=0`)

- **Operand Fetch**: 
  - Retrieve the first source operand from the register (`Rn`).
  - Obtain the second operand from the register (`Rm`) and apply the specified shift (`sh`) and shift amount (`shamt5`) for alignment.
- **Operation Execution**: Execute the specified command (`cmd`) using the first source operand (`Rn`) and the shifted second operand (`Rm`).
- **Result Storage**: Store the result in the destination register (`Rd`).
- **Flags Update**: If `S=1`, update condition flags based on the result.

![WhatsApp Image 2024-12-03 at 19 15 38_a337ae8d](https://github.com/user-attachments/assets/51f844d5-2fb0-42f9-b88a-1d02c183a089)

---

### Branch Instruction Datapath

Branch instructions enable program flow control by updating the program counter (PC) to jump to a target address. For a regular branch (`B`), the instruction computes the target address using the immediate offset (`Imm24`) and updates the PC accordingly. The `L` bit is set to `0` for regular branches.

#### Regular Branch (`B`)

- **Offset Calculation**: 
  - Extract the 24-bit immediate offset (`Imm24`) from the instruction.
  - Sign-extend `Imm24` to 32 bits and left-shift it by 2 to align it to word boundaries.
- **Target Address Computation**: 
  - Add the computed offset to the current value of the PC to determine the target address (`PC + (Imm24 << 2)`).
- **PC Update**: 
  - The PC is updated to the calculated target address, effectively jumping to the new instruction location.

![WhatsApp Image 2024-12-03 at 19 19 19_dd399a67](https://github.com/user-attachments/assets/a26d63bb-0c6f-48e8-a16b-dfdc4bf1eb21)

### Final Datapath

![WhatsApp Image 2024-12-04 at 13 19 17_d4c7edb9](https://github.com/user-attachments/assets/3967fe60-2d40-46bf-a6ef-821620513a0e)

---

## Micro Architecture 

Integrating controler with the datapath gives us the main Micro Architecture. Here Controller is treated as a Black Box.

![WhatsApp Image 2024-12-02 at 18 05 23_78d8007b](https://github.com/user-attachments/assets/6bb2e541-1912-4ee8-b1e5-d6959ad55d76)


## Demystifying Controller

Removing the Controller BlackBox, we unveil two critical components inside: **Decoder** and **Conditional Logic**. These work together to control the flow of operations based on the current instruction and condition flags.

![Controller Overview](https://github.com/user-attachments/assets/822ba4a9-3815-4601-95b2-6be4fa1eacb4)

### Decoder

The **Decoder** module is responsible for interpreting the instruction passed to the controller and generating the corresponding control signals. This is achieved through its subcomponents: **PC Logic**, **Main Decoder**, and **ALU Decoder**. 

- **PC Logic** decides whether the next instruction should be fetched from the next sequential address or jump based on certain conditions.
- **Main Decoder** decodes the operation field and function codes from the instruction, producing control signals like `RegWrite`, `MemWrite`, `ALUSrc`, and `ImmSrc`.
- **ALU Decoder** specifically manages control signals related to the ALU operation, determining which arithmetic or logical function the ALU should perform (e.g., ADD, SUB, AND, ORR). 

![Decoder](https://github.com/user-attachments/assets/cb1800fd-5518-4de5-950b-f219fbace3ef)

### PC Logic
The **PC Logic** is crucial in controlling the program counter. It decides whether to update the PC to the next sequential address or to jump to a new address depending on branch conditions or other control signals. This logic interacts directly with the flags set by the ALU and condition checks from the `Condlogic`.

### Main Decoder
The **Main Decoder** extracts operation and function bits from the instruction and produces various control signals. For instance, it might set the ALU source or define how the result should be stored (e.g., to registers or memory). Based on the instruction type (e.g., data-processing, load/store), it configures these control signals accordingly.

### ALU Decoder
The **ALU Decoder** focuses on translating the function code to a specific ALU operation, such as addition, subtraction, logical AND, or OR. It checks the instruction's function field and determines what kind of operation the ALU should perform. It also determines whether the result should affect condition flags like zero, negative, carry, or overflow.

### Conditional Logic

The **Conditional Logic** block ensures that certain operations (like writing to registers or memory) occur only if certain conditions, based on the flags set by previous operations, are met. These conditions could be checks for equality (EQ), negative result (MI), or overflow (VS), among others. This logic evaluates the condition code and decides whether the operation should proceed.

**Inside Conditional Logic:**

1. **Flag Storage (Flip-Flops)**: 
   - **Flip-Flops (flopenr)** store condition flags (e.g., zero, negative, carry, overflow) set by the ALU or other operations. These flip-flops are controlled by the `FlagWrite` signal, which enables updating of flags when needed.
   - The flags are updated only if `FlagWrite` is asserted, which is typically determined by the type of instruction or operation being executed (e.g., comparison, arithmetic, or logical operations).

2. **Conditional Check (`condcheck`)**:
   - The **condcheck** block evaluates the stored flags and compares them with the condition codes (`Cond`), determining whether the specific operation should proceed based on the current state of the flags.
   - For example, if the condition is "zero" (EQ), the `CondEx` signal is asserted when the zero flag is set. This means the operation will proceed if the condition is met.

3. **Control Signal Generation**:
   - Based on the evaluated condition (`CondEx`), the **Conditional Logic** generates control signals like `RegWrite`, `MemWrite`, and `PCSrc`.
   - If `CondEx` is true (i.e., the condition is met), these signals may be asserted to enable register writes, memory writes, or branch operations (e.g., updating the program counter).

![Conditional Logic](https://github.com/user-attachments/assets/19cf078c-eeef-4539-b367-ea0597210f24)

---

### Connections in Conditional Logic

In the **Conditional Logic** module, the **flip-flops (FF)** play a crucial role in storing and passing the flags set by the ALU operation. Specifically, the **flopenr** modules are used to store the 2-bit flags (`FlagWrite`) for each condition (e.g., `neg`, `zero`, `carry`, `overflow`). These flags are written to flip-flops based on the control signal and then used by the `condcheck` module to determine if the condition for branching or other control signals is met.

- **Flip-flops (flopenr)**: These are used to store the current state of flags (`Flags[3:2]` for certain flags and `Flags[1:0]` for others). The flags are written into flip-flops only when the `FlagWrite` control signal is asserted, indicating that the flags should be updated.
  
- **Conditional Check (`condcheck`)**: This block reads the stored flag values (`Flags`) and evaluates the condition code (`Cond`). It outputs the `CondEx` signal, which determines whether a particular control operation should be executed based on the condition flags.

  - For example, if the condition is for "zero" (EQ), the `CondEx` signal is asserted when the zero flag is set, signaling that the operation (such as memory write, register write, or PC update) should proceed.

- **Control Signals**: Based on the evaluated condition (`CondEx`), other control signals like `RegWrite`, `MemWrite`, and `PCSrc` are conditionally asserted. For instance, if `CondEx` is true, `RegWrite` and `MemWrite` might be enabled.

---



























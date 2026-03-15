# FPGA Implementation of a Multiplierless TDM Spiking Neural Network

![Language](https://img.shields.io/badge/Language-Verilog-blue)
![Validation](https://img.shields.io/badge/Validation-Python/Numpy-green)
![Target](https://img.shields.io/badge/Target-Xilinx_Artix--7-orange)
![Synthesis](https://img.shields.io/badge/Synthesis-Yosys_|_Vivado-red)

A digital hardware implementation of a 500-neuron Spiking Neural Network (SNN) based on the **FitzHugh-Nagumo (FHN)** model. This project utilizes a custom power-of-2 approximation to eliminate hardware multipliers and a **Time-Division Multiplexing (TDM)** controller to share a single arithmetic core across the network.

The design was synthesized for a Xilinx Artix-7 FPGA, utilizing native Block RAM (BRAM) for state storage and achieving **< 2% resource utilization** at an operating frequency of **125+ MHz**.

---

## ⚙️ Technical Highlights

### 1. Multiplierless Datapath (Shift-and-Add)
The biological FHN model includes a cubic nonlinear term ($v - v^3/3$) which typically requires DSP slices for multiplication. To reduce hardware utilization, this term is approximated using a power-of-two function:
$$g(v) = r \cdot v + s \cdot (2^{-v} - 2^v)$$
By selecting appropriate coefficients ($r=4, s=2.89 \approx 3$), all multiplications are replaced with hardware-friendly logical shifts and adders (e.g., $x \times 3$ becomes `(x << 1) + x`).

### 2. Fixed-Point Exponential Approximation (`pow2.v`)
The $2^x$ exponential is calculated without lookup tables. The 16-bit fixed-point input is split into integer ($\lfloor x \rfloor$) and fractional ($\{x\}$) parts. The function evaluates as $Pow2(x) = (1.\{x\}) \times 2^{\lfloor x \rfloor}$, implemented natively using combinational shifters.

### 3. 5-Stage TDM Pipeline
To process 500 neurons efficiently, the system uses a single pipelined computational core. State variables ($V$ and $W$) are stored in BRAM. The TDM controller manages memory addressing and schedules the updates across 5 stages:
1. **Fetch:** Read $V$ and $W$ for Neuron $N$ from BRAM.
2. **Non-linear:** Calculate the $Pow2$ fractional extractions and shifts.
3. **Accumulate:** Sum the linear terms, non-linear forces, and input stimulus ($I$).
4. **Integrate:** Apply a deadzone threshold for stability and execute Euler integration ($dV, dW$).
5. **Store:** Write the updated states back to BRAM.

---

## 📊 Synthesis Results

*Target Architecture: Xilinx Artix-7*

| Resource Type | Utilization | Description |
| :--- | :--- | :--- |
| **Block RAM (RAMB18E1)** | 2 | Stores 500 sets of 16-bit $V$ and $W$ state variables. |
| **LUTs** | ~282 | Combinational logic for the 5-stage FHN core and routing. |
| **Flip-Flops (FDRE)** | 268 | Pipeline stage registers and TDM control pointers. |
| **Carry Chains (CARRY4)** | 51 | Dedicated arithmetic routing for adders/subtractors. |
| **DSP48 Slices** | **0** | Confirms 100% multiplierless implementation. |
| **Max Frequency ($F_{max}$)**| ~125 - 200 MHz | Yields a throughput of 1 neuron update per clock cycle. |
| **Numerical Accuracy** | RMSE < 0.3 | Validated against a floating-point Python reference model. |

*Note: Calculations use a 16-bit signed fixed-point format (1 Sign bit + 3 Integer bits + 12 Fractional bits).*

---

## 📂 Repository Structure

    .
    ├── rtl/                          # Verilog Source Code
    │   ├── core.v                    # 5-stage FHN arithmetic pipeline
    │   ├── tdm.v                     # TDM memory controller and pipeline scheduler
    │   └── pow2.v                    # Shift-based 2^x approximation logic
    ├── sim/                          # Simulation 
    │   └── tb_tdm.v                  # Testbench injecting static/dynamic currents
    ├── scripts/                      # Validation
    │   └── analyze.py                # Python model for RMSE calculation and plotting
    └── README.md                     

---

## 🛠️ Simulation & Verification

### Prerequisites
* **Icarus Verilog** (or Vivado Simulator)
* **Python 3.x** (`numpy`, `pandas`, `matplotlib`)

### Execution
1. **Run the RTL Testbench:**
   The testbench initializes the BRAM and applies configurable stimulus currents (`i_stim`) to selected neurons. It outputs the fixed-point voltage states to `data.csv`.
   
       iverilog -g2012 -o snn_sim rtl/pow2.v rtl/core.v rtl/tdm.v sim/tb_tdm.v
       ./snn_sim

2. **Run Python Validation:**
   The analysis script processes the same stimulus through an ideal floating-point mathematical model and overlays the results against the Verilog output.
   
       python scripts/analyze.py

---

## 📖 References

This hardware design is based on the architectural concepts and mathematical approximations proposed in:

> **Low-Power Resource-Efficient FPGA Implementation of Modified FitzHugh-Nagumo Neuron for Spiking Neural Networks** > *Reza Badiei, Somayeh Timarchi, and Alireza Zakaleh* > IEEE Transactions on Circuits and Systems—II: Express Briefs, Vol. 72, No. 11, November 2025.

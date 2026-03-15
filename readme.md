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

The biological FHN model includes a cubic nonlinear term that typically requires DSP slices for multiplication. To reduce hardware utilization, this term is approximated using a power-of-two function:

$$g(v) = r \cdot v + s \cdot (2^{-v} - 2^v)$$

By selecting coefficients r=4 and s=2.89, rounded to s=3 in hardware, all multiplications are replaced with logical shifts and adders. For example, multiplication by 3 becomes `(x << 1) + x`.

### 2. Fixed-Point Exponential Approximation

The 2^x exponential is calculated without lookup tables inside `approx_pow2_unit.v`. The 16-bit fixed-point input is split into integer and fractional parts, and the result is evaluated as:

$$Pow2(x) = (1.\{x\}) \times 2^{\lfloor x \rfloor}$$

This is implemented entirely with combinational shifters — no DSP slices or memory required.

### 3. 5-Stage TDM Pipeline

A single pipelined arithmetic core is time-shared across all 500 neurons. State variables V and W are stored in BRAM. The TDM controller cycles through each neuron across 5 pipeline stages:

1. **Fetch** — Read V and W for Neuron N from BRAM
2. **Non-linear** — Compute Pow2 fractional extractions and shifts
3. **Accumulate** — Sum linear terms, non-linear forces, and input stimulus I
4. **Integrate** — Apply deadzone threshold and execute Euler integration (dV, dW)
5. **Store** — Write updated states back to BRAM

After the initial 5-cycle pipeline fill, throughput reaches **1 neuron update per clock cycle**.

---

## 📊 Synthesis Results

*Target Architecture: Xilinx Artix-7*

| Resource Type | Utilization | Description |
| :--- | :--- | :--- |
| Block RAM (RAMB18E1) | 2 | Stores 500 sets of 16-bit V and W state variables |
| LUTs | ~282 | Combinational logic for the 5-stage FHN core |
| Flip-Flops (FDRE) | 268 | Pipeline registers and TDM control pointers |
| Carry Chains (CARRY4) | 51 | Dedicated arithmetic routing for adders/subtractors |
| DSP48 Slices | **0** | Confirms 100% multiplierless implementation |
| Max Frequency (Fmax) | ~125-200 MHz | 1 neuron update per cycle in steady state |
| Numerical Accuracy | RMSE < 0.3 | Validated against floating-point Python reference |

*All calculations use a 16-bit signed fixed-point format: 1 sign bit, 3 integer bits, 12 fractional bits.*

---

## 📂 Repository Structure

    .
    ├── docs/                             # Reference materials and standards
    │   ├── research_paper.pdf            # Base architecture reference (Badiei et al.)
    │   └── verilog_2001_standard.pdf     # Verilog-2001 language standard
    ├── results/                          # Simulation outputs and validation plots
    │   ├── frequency_vs_stimulus_graph.png
    │   ├── neuron_0_behaviour.png
    │   ├── neuron_150_behaviour.png
    │   └── neuron_498_behaviour.png
    ├── rtl/                              # Verilog source code
    │   ├── approx_pow2_unit.v            # Shift-based 2^x approximation logic
    │   ├── fhn_neuron_core.v             # 5-stage pipelined FHN arithmetic core
    │   └── neuron_tdm_controller.v       # TDM memory controller and scheduler
    ├── scripts/                          # Automation and validation
    │   ├── neuron_stimulus_dynamics.py   # Advanced stimulus response analysis
    │   ├── plot_neuron_dynamics.py       # Floating-point reference model and plots
    │   └── run_simulation.sh             # Bash simulation automation
    └── sim/                              # Simulation
        └── testbench_fhn.v               # System-level testbench

---

## 🛠️ Simulation and Verification

### Prerequisites

- Icarus Verilog for RTL compilation
- Python 3.x with numpy, pandas, and matplotlib

### Step 1 — Run the RTL Simulation

The bash script compiles all RTL sources and the testbench, initializes BRAM, and injects stimulus currents. Output is written to `data.csv`.

    cd scripts
    bash run_simulation.sh

### Step 2 — Run Python Validation

The analysis script runs the same stimulus through a floating-point reference model, computes RMSE against the RTL output, and generates comparison plots.

    python plot_neuron_dynamics.py

---

## 📖 References

This hardware design is based on the architectural concepts and mathematical approximations proposed in:

> **Low-Power Resource-Efficient FPGA Implementation of Modified FitzHugh-Nagumo Neuron for Spiking Neural Networks**
> *Reza Badiei, Somayeh Timarchi, and Alireza Zakaleh*
> IEEE Transactions on Circuits and Systems II: Express Briefs, Vol. 72, No. 11, November 2025.

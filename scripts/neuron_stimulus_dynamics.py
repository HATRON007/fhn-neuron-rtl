import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

FILE_NAME = "data.csv"
SCALING_FACTOR = 4096.0

IDS_TO_PLOT = [0, 150, 498] 

DT  = 2**-7
TAU = 2.0
A   = 0.7
B   = 0.5

def get_pow2_approx(x):
    # def hw_pow2(val):
        # val_int = np.floor(val)
        # val_frac = val - val_int
        # return (1.0 + val_frac) * (2.0 ** val_int)
    term_neg = 2**(-x)
    term_pos = 2**(x)
    return term_neg - term_pos

def run_ideal_model(stimulus_array):
    steps = len(stimulus_array)
    v_out = np.zeros(steps)
    v = -1.19
    w = -0.625
    threshold = 450.0 / SCALING_FACTOR

    for k in range(steps):
        I = stimulus_array[k]
        g_v = 3.0 * get_pow2_approx(v)
        linear_v = 5.0 * v
        force = linear_v + g_v - w + I
        
        if -threshold < force < threshold:
            force = 0.0
            
        dv = DT * force
        dw = (DT / TAU) * (v + A - B * w)
        v = v + dv
        w = w + dw
        v_out[k] = v
        
    return v_out

print(f"Loading {FILE_NAME}...")
df = pd.read_csv(FILE_NAME)

print("Generating dynamic comparison plots...")

for n_id in IDS_TO_PLOT:
    subset = df[df['neuron_id'] == n_id].reset_index(drop=True)
    
    if subset.empty:
        print(f"Skipping Neuron {n_id} (No data).")
        continue

    v_hw = subset['v_float'].values
    t_axis = subset['time_ns'].values
    num_steps = len(v_hw)

    i_stim = np.zeros(num_steps)
    
    if n_id == 0:
        i_stim[:] = 1.0
        title_text = "Neuron 0 (Constant 1.0)"

    elif n_id == 150:
        limit1 = min(3500, num_steps)
        i_stim[0:limit1] = 0.5
        
        if num_steps > 3500:
            limit2 = min(7000, num_steps)
            i_stim[3500:limit2] = 0.0
            
        if num_steps > 7000:
            i_stim[7000:] = 1.0
            
        title_text = "Neuron 150 (Dynamic: 0.5 -> 0.0 -> 1.0)"

    elif n_id == 498:
        title_text = "Neuron 498 (Constant 0.0)"

    v_model = run_ideal_model(i_stim)

    error = v_hw - v_model
    rmse = np.sqrt(np.mean(error**2))

    plt.figure(figsize=(10, 6))
    
    plt.subplot(2, 1, 1)
    plt.plot(t_axis, v_model, 'r--', linewidth=2, label='Python Model')
    plt.plot(t_axis, v_hw, 'b-', alpha=0.6, label='Verilog Hardware')
    plt.ylabel("Membrane Potential (V)")
    plt.title(f"{title_text} | RMSE: {rmse:.4f}")
    plt.legend(loc='upper right')
    plt.grid(True, linestyle='--', alpha=0.6)

    plt.subplot(2, 1, 2)
    plt.plot(t_axis, i_stim, 'g-', linewidth=2, label='Input Current (I)')
    plt.ylabel("Current (I)")
    plt.xlabel("Simulation Time (ns)")
    plt.legend(loc='upper right')
    plt.grid(True, linestyle='--', alpha=0.6)
    
    plt.tight_layout()
    
    filename = f"neuron_{n_id}_dynamic_validation.png"
    plt.savefig(filename)
    print(f"Saved {filename}")

    plt.show()
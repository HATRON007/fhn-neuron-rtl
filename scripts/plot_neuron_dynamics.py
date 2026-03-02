import numpy as np
import matplotlib.pyplot as plt

DT  = 2**-7
TAU = 2.0
A   = 0.7
B   = 0.5
num_steps = 50000

def get_pow2_approx(x):
    def hw_pow2(val):
        val_int = np.floor(val)
        val_frac = val - val_int
        return (1.0 + val_frac) * (2.0 ** val_int)
    return hw_pow2(-x) - hw_pow2(x)

currents = np.arange(0.0, 2.0, 0.1)
frequencies = []
amplitudes = []

for I_val in currents:
    v = -1.1
    w = -0.625
    spikes = 0
    v_max = -10
    v_min = 10

    for k in range(num_steps):
        g_v = 3.0 * get_pow2_approx(v)
        linear_v = 5.0 * v
        force = linear_v + g_v - w + I_val

        threshold = 450.0 / 4096.0
        if -threshold < force < threshold:
            force = 0.0

        dv = DT * force
        dw = (DT / TAU) * (v + A - B * w)

        v_old = v
        v = v + dv
        w = w + dw

        if k > 10000:
            v_max = max(v_max, v)
            v_min = min(v_min, v)

        if v_old < 0 and v >= 0:
            spikes += 1

    frequencies.append(spikes)
    if v_max > -9:
        amplitudes.append(v_max - v_min)
    else:
        amplitudes.append(0)

fig, ax1 = plt.subplots(figsize=(10, 6))

color = 'tab:red'
ax1.set_xlabel('Input Current (I)')
ax1.set_ylabel('Spike Count (Frequency)', color=color)
ax1.plot(currents, frequencies, color=color, marker='o')
ax1.tick_params(axis='y', labelcolor=color)
ax1.grid(True)

ax2 = ax1.twinx()
color = 'tab:blue'
ax2.set_ylabel('Peak-to-Peak Amplitude (V)', color=color)
ax2.plot(currents, amplitudes, color=color, linestyle='--', marker='x')
ax2.tick_params(axis='y', labelcolor=color)

plt.title("Frequency & Amplitude vs Input Current")
plt.savefig("fi_curve.png")
plt.show()

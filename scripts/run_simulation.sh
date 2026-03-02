#!/bin/bash

echo "Compiling Verilog..."
iverilog -g2012 -o fhn_sim pow2.v core.v tdm.v testbench.v
if [ $? -ne 0 ]; then
    echo "Verilog compilation failed!"
    exit 1
fi

echo "Running VVP Simulation..."
vvp fhn_sim
if [ $? -ne 0 ]; then
    echo "Simulation failed!"
    exit 1
fi

echo "Running Python Plot Script..."
python -u "/home/hatron_007/Documents/internship/code/py.py"
if [ $? -ne 0 ]; then
    echo "Python script failed!"
    exit 1
fi

echo "All steps completed successfully!"


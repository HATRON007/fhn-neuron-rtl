`timescale 1ns / 1ps

module tb_tdm;

    parameter NEURON_COUNT = 500;
    parameter DATA_WIDTH = 16;
    
    reg clk;
    reg rst;
    reg signed [DATA_WIDTH-1:0] i_stim;
    reg [$clog2(NEURON_COUNT)-1:0] monitor_id;
    wire signed [DATA_WIDTH-1:0] v_mon;
    wire signed [DATA_WIDTH-1:0] w_mon;

    integer sim_step_count = 0;

    tdm_controller #(
        .neuron_count(NEURON_COUNT),
        .pipeline_depth(5),
        .data_width(DATA_WIDTH)
    ) uut (
        .clk(clk),
        .rst(rst),
        .i_stim(i_stim),
        .monitor_id(monitor_id),
        .v_out_monitor(v_mon),
        .w_out_monitor(w_mon)
    );

    integer file;
    real v_real;

    initial clk = 0;
    always #5 clk = ~clk; 

    always @(posedge clk) begin
        if (rst) begin
            i_stim <= 0;
            sim_step_count <= 0;
        end else begin
            if (uut.ptr_read == NEURON_COUNT-1) 
                sim_step_count <= sim_step_count + 1;

            case (uut.ptr_read)
                0:   i_stim <= 16'd4096;
                
                150: begin
                    if (sim_step_count < 3500)
                        i_stim <= 16'd2048;
                    else if (sim_step_count < 7000)
                        i_stim <= 16'd0;
                    else
                        i_stim <= 16'd4096;
                end
                default: i_stim <= 16'd0;
            endcase
        end
    end

    initial begin
        file = $fopen("data.csv", "w");
        $fdisplay(file, "time_ns,neuron_id,v_float,i_raw");
        
        monitor_id = 0;
        i_stim = 0;
        rst = 1;
        #100;
        
        rst = 0;
        #100;
        
        repeat(NEURON_COUNT * 10000) begin
            @(posedge clk);
        end

        $fclose(file);
        $finish;
    end

    always @(posedge clk) begin
        if (!rst) begin
            if(uut.pipeline_primed) begin
                v_real = $signed(uut.core_v_out) / 4096.0;
                $fdisplay(file, "%0d,%0d,%0f,%0d", $time, uut.ptr_write, v_real, $signed(i_stim));
            end
        end
    end

endmodule
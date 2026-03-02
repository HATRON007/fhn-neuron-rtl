module tdm_controller #(
    parameter neuron_count = 500,
    parameter pipeline_depth = 5,
    parameter data_width = 16
)(
    input wire clk,
    input wire rst,
    input wire signed [data_width-1 : 0] i_stim,
    input wire [$clog2(neuron_count)-1 : 0] monitor_id,
    output reg signed [data_width-1 : 0] v_out_monitor,
    output reg signed [data_width-1 : 0] w_out_monitor
);

    (* ram_style = "block" *) reg signed [data_width-1 : 0] ram_v [0 : neuron_count-1];
    (* ram_style = "block" *) reg signed [data_width-1 : 0] ram_w [0 : neuron_count-1];
    
    localparam ptr_width = $clog2(neuron_count);

    reg [ptr_width-1 : 0] ptr_read;
    reg [ptr_width-1 : 0] ptr_write;
    reg pipeline_primed;

    reg signed [data_width-1 : 0] core_v_in, core_w_in;
    
    (* keep *) wire signed [data_width-1 : 0] core_v_out, core_w_out;

    core core_tdm (
        .clk(clk),
        .rst(rst),
        .i(i_stim),
        .v(core_v_in),
        .w_in(core_w_in),
        .v_out(core_v_out),
        .w_out(core_w_out) 
    );

    integer k;

    initial begin
        for(k=0; k<neuron_count; k=k+1) begin
            ram_v[k] = 16'hECE1; // -1.19V
            ram_w[k] = 16'hF600; // -0.625
        end
    end

    always @(posedge clk) begin
      if(rst) begin
        ptr_read <= 0;
        ptr_write <= neuron_count - pipeline_depth;
        pipeline_primed <= 0;
        
        v_out_monitor <= 0;
        w_out_monitor <= 0;
      end

      else begin
        if (pipeline_primed) begin
            ram_v[ptr_write] <= core_v_out;
            ram_w[ptr_write] <= core_w_out;
        end

        if(ptr_write == monitor_id) begin
            v_out_monitor <= core_v_out;
            w_out_monitor <= core_w_out;
        end

        core_v_in <= ram_v[ptr_read];
        core_w_in <= ram_w[ptr_read];

        if(ptr_read == neuron_count-1) ptr_read <= 0;
        else ptr_read <= ptr_read + 1;

        if(ptr_write == neuron_count-1) begin
            ptr_write <= 0;
            pipeline_primed <= 1;
        end else begin
            ptr_write <= ptr_write + 1;
        end
      end
    end

endmodule
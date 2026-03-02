module core #(    
    localparam tau_shift = 1,
    localparam time_shift = 7,
    localparam total_shift = tau_shift + time_shift,

    localparam int_width = 3,
    localparam frc_width = 12,
    localparam w = 1 + int_width + frc_width
)(
    input  wire clk,
    input  wire rst,
    input  wire signed [w-1 : 0] i,
    input  wire signed [w-1 : 0] v,
    input  wire signed [w-1 : 0] w_in,
    output reg  signed [w-1 : 0] v_out,
    output reg  signed [w-1 : 0] w_out
);
    reg signed [w-1 : 0] z1_v, z1_posV, z1_negV, z1_w, z1_y1, z1_i;
    wire signed [w-1 : 0] pow2_pos, pow2_neg;
    wire signed [19 : 0] diff_ext, y2, y4;


    localparam signed [w-1 : 0] a = 16'd2867;
    localparam signed [19 : 0] THRESHOLD = 20'd175;

    pow_2_function #(
        .w(w),
        .int_width(int_width), 
        .frc_width(frc_width)
    ) positve_v (.x(v), .y(pow2_pos));

    pow_2_function #(
        .w(w),
        .int_width(int_width),
        .frc_width(frc_width)
    ) negative_v (.x(-v), .y(pow2_neg));

    always @(posedge clk) begin
        z1_v <= v;
        z1_w <= w_in;
        z1_i <= i;
        z1_y1 <= v + a - (w_in >>> 1);
        z1_posV <= pow2_pos;
        z1_negV <= pow2_neg;
    end
    
    reg signed [19 : 0]z2_5v, z2_3pow;
    reg signed [w-1 : 0] z2_v, z2_i, z2_w, z2_y3;

    assign diff_ext = {{4{z1_negV[w-1]}}, z1_negV} - {{4{z1_posV[w-1]}}, z1_posV};
    assign y2 = (({{4{z1_v[w-1]}}, z1_v}) <<< 2) + ({{4{z1_v[w-1]}}, z1_v});

    always @(posedge clk) begin 
        z2_v <= z1_v;
        z2_i <= z1_i;
        z2_5v <= y2;
        z2_w <= z1_w;
        z2_3pow <= (diff_ext <<< 1) + diff_ext;
        z2_y3 <= ((z1_y1 + 128) >>> total_shift);
    end

    assign y4 = z2_3pow + z2_5v - ({{4{z2_w[w-1]}}, z2_w}) + {{4{z2_i[w-1]}}, z2_i};
    reg signed [w-1 : 0] z3_v, z3_w;
    reg signed [19 : 0] z3_dv;
    always @(posedge clk) begin
        z3_v <= z2_v;
        z3_dv <= (y4 > -THRESHOLD && y4 < THRESHOLD) ? 20'd0 : y4;
        z3_w <= z2_y3 + z2_w;
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            v_out <= 16'hECE1;
            w_out <= 16'hF600;
        end
        else begin
            v_out <= z3_v + $signed((z3_dv + 64) >>> time_shift);
            w_out <= z3_w;
        end
    end

endmodule
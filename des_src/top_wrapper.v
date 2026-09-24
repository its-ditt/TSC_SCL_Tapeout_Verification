module soc_top_wrapper (

    // =========================================================
    // EXTERNAL CHIP INPUTS
    // =========================================================
    input        clk,
    input        rst_n,
    input        load_mode,
    input  [1:0] data_in,
    input        qbit_strobe,

    // =========================================================
    // EXTERNAL CHIP OUTPUT
    // =========================================================
    output [31:0] result_out
);

    // =========================================================
    // INTERNAL PAD-TO-CORE SIGNALS
    // =========================================================

    wire        clk_pad;
    wire        clk_buf;

    wire        rst_n_pad;
    wire        load_mode_pad;
    wire        qbit_strobe_pad;

    wire [1:0]  data_in_pad;

    wire [31:0] result_out_pad;


    // =========================================================
    // CLOCK INPUT PAD
    // =========================================================

    pc3d01 pc3d01_clk (
        .PAD (clk),
        .CIN (clk_pad)
    );


    // =========================================================
    // CLOCK BUFFER
    // =========================================================

    pc3c01 pc3c01_clk_buf (
        .CCLK (clk_pad),
        .CP   (clk_buf)
    );


    // =========================================================
    // RESET INPUT PAD
    // =========================================================

    pc3d01 pc3d01_rst_n (
        .PAD (rst_n),
        .CIN (rst_n_pad)
    );


    // =========================================================
    // LOAD MODE INPUT PAD
    // =========================================================

    pc3d01 pc3d01_load_mode (
        .PAD (load_mode),
        .CIN (load_mode_pad)
    );


    // =========================================================
    // QBIT STROBE INPUT PAD
    // =========================================================

    pc3d01 pc3d01_qbit_strobe (
        .PAD (qbit_strobe),
        .CIN (qbit_strobe_pad)
    );


    // =========================================================
    // DATA INPUT PADS : data_in[1:0]
    // =========================================================

    pc3d01 pc3d01_data_in0 (
        .PAD (data_in[0]),
        .CIN (data_in_pad[0])
    );

    pc3d01 pc3d01_data_in1 (
        .PAD (data_in[1]),
        .CIN (data_in_pad[1])
    );


    // =========================================================
    // SOC CORE
    // =========================================================

    soc_top dut (

        .clk         (clk_buf),
        .rst_n       (rst_n_pad),

        .result_out  (result_out_pad),

        .load_mode   (load_mode_pad),
        .data_in     (data_in_pad),
        .qbit_strobe (qbit_strobe_pad)

    );


    // =========================================================
    // RESULT OUTPUT PADS : result_out[31:0]
    // =========================================================

    pc3o01 pc3o01_result_out0 (
        .PAD (result_out[0]),
        .I   (result_out_pad[0])
    );

    pc3o01 pc3o01_result_out1 (
        .PAD (result_out[1]),
        .I   (result_out_pad[1])
    );

    pc3o01 pc3o01_result_out2 (
        .PAD (result_out[2]),
        .I   (result_out_pad[2])
    );

    pc3o01 pc3o01_result_out3 (
        .PAD (result_out[3]),
        .I   (result_out_pad[3])
    );

    pc3o01 pc3o01_result_out4 (
        .PAD (result_out[4]),
        .I   (result_out_pad[4])
    );

    pc3o01 pc3o01_result_out5 (
        .PAD (result_out[5]),
        .I   (result_out_pad[5])
    );

    pc3o01 pc3o01_result_out6 (
        .PAD (result_out[6]),
        .I   (result_out_pad[6])
    );

    pc3o01 pc3o01_result_out7 (
        .PAD (result_out[7]),
        .I   (result_out_pad[7])
    );

    pc3o01 pc3o01_result_out8 (
        .PAD (result_out[8]),
        .I   (result_out_pad[8])
    );

    pc3o01 pc3o01_result_out9 (
        .PAD (result_out[9]),
        .I   (result_out_pad[9])
    );

    pc3o01 pc3o01_result_out10 (
        .PAD (result_out[10]),
        .I   (result_out_pad[10])
    );

    pc3o01 pc3o01_result_out11 (
        .PAD (result_out[11]),
        .I   (result_out_pad[11])
    );

    pc3o01 pc3o01_result_out12 (
        .PAD (result_out[12]),
        .I   (result_out_pad[12])
    );

    pc3o01 pc3o01_result_out13 (
        .PAD (result_out[13]),
        .I   (result_out_pad[13])
    );

    pc3o01 pc3o01_result_out14 (
        .PAD (result_out[14]),
        .I   (result_out_pad[14])
    );

    pc3o01 pc3o01_result_out15 (
        .PAD (result_out[15]),
        .I   (result_out_pad[15])
    );

    pc3o01 pc3o01_result_out16 (
        .PAD (result_out[16]),
        .I   (result_out_pad[16])
    );

    pc3o01 pc3o01_result_out17 (
        .PAD (result_out[17]),
        .I   (result_out_pad[17])
    );

    pc3o01 pc3o01_result_out18 (
        .PAD (result_out[18]),
        .I   (result_out_pad[18])
    );

    pc3o01 pc3o01_result_out19 (
        .PAD (result_out[19]),
        .I   (result_out_pad[19])
    );

    pc3o01 pc3o01_result_out20 (
        .PAD (result_out[20]),
        .I   (result_out_pad[20])
    );

    pc3o01 pc3o01_result_out21 (
        .PAD (result_out[21]),
        .I   (result_out_pad[21])
    );

    pc3o01 pc3o01_result_out22 (
        .PAD (result_out[22]),
        .I   (result_out_pad[22])
    );

    pc3o01 pc3o01_result_out23 (
        .PAD (result_out[23]),
        .I   (result_out_pad[23])
    );

    pc3o01 pc3o01_result_out24 (
        .PAD (result_out[24]),
        .I   (result_out_pad[24])
    );

    pc3o01 pc3o01_result_out25 (
        .PAD (result_out[25]),
        .I   (result_out_pad[25])
    );

    pc3o01 pc3o01_result_out26 (
        .PAD (result_out[26]),
        .I   (result_out_pad[26])
    );

    pc3o01 pc3o01_result_out27 (
        .PAD (result_out[27]),
        .I   (result_out_pad[27])
    );

    pc3o01 pc3o01_result_out28 (
        .PAD (result_out[28]),
        .I   (result_out_pad[28])
    );

    pc3o01 pc3o01_result_out29 (
        .PAD (result_out[29]),
        .I   (result_out_pad[29])
    );

    pc3o01 pc3o01_result_out30 (
        .PAD (result_out[30]),
        .I   (result_out_pad[30])
    );

    pc3o01 pc3o01_result_out31 (
        .PAD (result_out[31]),
        .I   (result_out_pad[31])
    );

endmodule

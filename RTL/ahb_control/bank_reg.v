module bank_reg(
    input clock,
    
    input [5:0] address_w,
    input [5:0] address_r,
    
    input en_write,     
    input [31:0] data_w,
    output [31:0] data_r
);
// Register file storage
reg [31:0] bank [0:47];


always @(posedge clock)
    if (en_write)
        bank[address_w] <= data_w;

assign data_r = bank[address_r];

endmodule
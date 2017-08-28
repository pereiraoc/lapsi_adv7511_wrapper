module ahb_control
#(
    // slave input parameters
    parameter T_clk         // HCLK minimum clock period
    parameter T_isrst       // HRESETn deasserted setup time before HCLK
    parameter T_ihrst       // HRESETn deasserted hold time after HCLK
    parameter T_issel       // HSELx setup time before HCLK
    parameter T_ihsel       // HSELx hold time after HCLK
    parameter T_istr        // Transfer type setup time before HCLK
    parameter T_ihtr        // Transfer type hold time after HCLK
    parameter T_isa         // HADDR[31:0] setup time before HCLK
    parameter T_iha         // HADDR[31:0] hold time after HCLK
    parameter T_isctl       // HWRITE, HSIZE[2:0] and HBURST[2:0] control signal setup time before HCLK
    parameter T_ihctl       // HWRITE, HSIZE[2:0] and HBURST[2:0] control signal hold time after HCLK
    parameter T_iswd        // Write data setup time before HCLK
    parameter T_ihwd        // Write data hold time after HCLK
    parameter T_isrdy       // Ready setup time before HCLK
    parameter T_ihrdy       // Ready hold time after HCLK
    
    // SPLIT-capable only
    //
    //parameter T_ismst     // Master number setup time before HCLK
    //parameter T_ihmst     // Master number hold time after HCLK 
    //parameter T_ismlck    // Master locked setup time before HCLK
    //parameter T_ihmlck    // Master locked hold time after HCLK 
    //
    
    // slave output parameters
    parameter T_ovrsp       // Response valid time after HCLK
    parameter T_ohrsp       // Response hold time after HCLK
    parameter T_ovrdy       // Ready valid time after HCLK
    parameter T_ohrdy       // Ready hold time after HCLK
    
    // SPLIT-capable only
    //
    //parameter T_ovsplt    // Split valid time after HCLK
    //parameter T_ohsplt    // Split hold time after HCLK
    //
)
(
    input HCLK,
    input HRESET,
    input HADDR [31:0],
    input HTRANS[1:0],  // Indicates the type of the current transfer, which can be
                        // NON SEQUENTIAL, SEQUENTIAL, IDLE or BUSY
    input HWRITE,       // When HIGH this signal indicates a write transfer
    input HSIZE [2:0],  // Indicates the size of the transfer, which is tipically
                        // byte (8-bit), halfword (16-bit) or word (32-but). The protocol
                        // allows for larger transfer sizes up to a maximum of 1024 bits.
    input HBURST [2:0], // Indicates if the transfer forms part of a burst. Four, eight and sixteen
                        // beat burst are supported and the burst may be either incrementing or wrapping
    input HPROT [3:0],  // The protection control signals provide additional information about a bus
                        // access and are primarily intended for use by any module that wishes to
                        // implement some level of protection.
                        // The signals indicate if the transfer is an opcode fetch or data acess,
                        // as well as if the transfer is a privileged mode acess or user mode access.
                        // For bus masters with a memory management unit these signals also indicate
                        // wheather the current access is cacheable or bufferable.
    input HWDATA [31:0],
    input HSEL,         
    output HRDATE [31:0],
    output HREADY,      // When HIGH the HREADY signal indicates that a transfer has finished on the
                        // bus. This signal may be driven LOW to extend a transfer.
                        // NOTE: Slaves on the bus require HREADY as both an input and an output signal.
    output HRESP [1:0], // The transfer response provides additional information on the status of a 
                        // transfer. Four different responses are privided,
                        // OKAY, ERROR, RETRY and SPLIT.
);


parameter IDLE = 2'b00, ACCESS_READ = 2'b01, ACCESS_WRITE = 2'b10, DONE = 2'b11;

reg [1:0]   state, next_state;

///PRIMEIRO ALWAYS - DEFINE STATE
always @(posedge HCLOCK, posedge HRESET)
begin
    if ( HRESET )
        state <= IDLE;
    else
        state <= next_state;
end

///SEGUNDO ALWAYS - DEFINE NEXT STATE    
always @*
begin
    case (state)
    IDLE: if (HSEL)
            if (HWRITE)
                next_state = ACCESS_WRITE; 
            else
                next_state = ACCESS_READ;
          else
            next_state = IDLE;
    
    ACCESS_WRITE: next_state = DONE;
    ACCESS_READ:  next_state = DONE;
    DONE: next_state = IDLE;
    endcase
end

///TERCEIRO ALWAYS - DEFINE SAIDAS (PODE SER CLOCKED OU *)
always @(posedge HCLOCK, posedge HRESET)
begin
    if (HRESET)
    begin
        dataToBank      <= 0;
        addressToBank   <= 0;
        writeEnBank     <= 0;      
    end
    else
    begin
        case (state)
        IDLE: if (HSEL)                     
              begin
                    if (HWRITE)
                    begin
                        addressBank <= HADDR;
                        dataToBank  <= HWDATA;
                    end
                    else
                    begin
                        HRDATA <= dataFromBank;
                    end
                end
        ACCESS_WRITE: writeEnBank <= 1;
        ACCESS_READ:  
        DONE: writeEnBank <= 0;
        endcase
    end
end


wire addressFromBank;

assign addressFromBank = HSEL ? HADDR : addressFromBlocks;




    
bank_reg bank_reg(
    .clock(HCLK),
    .address_w(addressToBank),
    .address_r(addressFromBank),
    .en_write(writeEnBank),
    .data_r(dataFromBank),
    .data_w(dataToBank)
);


    
    
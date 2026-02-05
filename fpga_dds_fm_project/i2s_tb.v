`timescale 1ns / 1ps

`define CH_WIDTH 32

module tb_i2s;

    // --- Sygnały ---
    reg i2s_ck;
    reg i2s_ws;
    reg i2s_sd;
    
    wire [`CH_WIDTH-1:0] first_channel;
    wire [`CH_WIDTH-1:0] second_channel;
    wire data_updated;

    // --- Instancja DUT ---
    i2s dut (
        .i2s_ck(i2s_ck),
        .i2s_ws(i2s_ws),
        .i2s_sd(i2s_sd),
        .first_channel(first_channel),
        .second_channel(second_channel),
        .data_updated(data_updated)
    );

    // --- Zegar 10MHz ---
    initial begin
        i2s_ck = 0;
        forever #50 i2s_ck = ~i2s_ck;
    end
    
    initial begin
        $dumpfile("i2s_wave.vcd");
        $dumpvars(0, tb_i2s);
    end

    // --- Task wysyłający MSB First (STM32 style) ---
    task send_frame(input [31:0] left_data, input [31:0] right_data);
        integer i;
        begin
            // 1. Kanał LEWY (WS=1). Wysyłamy bity od 31 do 0.
            i2s_ws = 1; 
            for (i = 31; i >= 0; i = i - 1) begin
                i2s_sd = left_data[i];
                @(negedge i2s_ck); 
            end

            // 2. Kanał PRAWY (WS=0). Wysyłamy bity od 31 do 0.
            i2s_ws = 0;
            for (i = 31; i >= 0; i = i - 1) begin
                i2s_sd = right_data[i];
                @(negedge i2s_ck);
            end
        end
    endtask

    // --- Monitor ---
    always @(posedge data_updated) begin
        $display("[TIME %0t ns] Ramka: Lewy=0x%h | Prawy=0x%h", 
                 $time, first_channel, second_channel);
    end

    // --- Scenariusz ---
    integer k;
    initial begin
        // Inicjalizacja na zero (bez X)
        i2s_ws = 0; i2s_sd = 0;
        #200;

        $display("=== START SYMULACJI ===");

        // Test 1: Sprawdzenie poprawności bitów (5=0101, A=1010)
        for (k = 0; k < 4; k = k + 1) begin
            send_frame(32'h55555555, 32'hAAAAAAAA);
        end

        // Test 2: Różne wartości
        send_frame(32'hDEADBEEF, 32'hCAFEBABE);
        
        // Test 3: Ciągłość
        send_frame(32'hF0F0F0F0, 32'h0F0F0F0F);

        // Zakończenie: wymuszenie ostatniego zatrzasku (WS -> 1)
        i2s_ws = 1; 
        i2s_sd = 0;
        #2000;
        
        $display("=== KONIEC ===");
        $finish;
    end

endmodule
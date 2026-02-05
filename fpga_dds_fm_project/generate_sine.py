import math

SAMPLES = 250
AMPLITUDE = 1800

print("    always @(posedge clk) begin")
print("        case(addr)")

for i in range(SAMPLES):
    rad = 2 * math.pi * i / SAMPLES
    val = int(round(AMPLITUDE * math.sin(rad)))
    
    print(f"            8'd{i:<3} : current_pilot_val <= {'-' if val < 0 else ''}12'sd{abs(val)};")

print("            default: current_pilot_val <= 12'sd0;")
print("        endcase")
print("    end")
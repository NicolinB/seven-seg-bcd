# seven_seg_bcd

4-digit BCD counter (0000–9999) with 7-segment display driver in VHDL for the Intel DE10-Lite.

## Board mapping (DE10-Lite)

| Signal | Pin |
|--------|-----|
| Clock 50 MHz | MAX10_CLK1_50 |
| Reset to 0000 (active low) | KEY[0] |
| Enable counting | SW[0] |
| Units digit | HEX0 |
| Tens digit | HEX1 |
| Hundreds digit | HEX2 |
| Thousands digit | HEX3 |

## Synthesis

Open `seven_seg_bcd.qpf` in **Quartus Prime**, compile, and program the DE10-Lite.

Turn **SW[0] ON** to start counting. Press **KEY[0]** to reset to 0000.

> Active-low 7-segment encoding: lookup table covers digits 0–9 in `gfedcba` bit order.

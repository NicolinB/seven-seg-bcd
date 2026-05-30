-- ============================================================
-- seven_seg_bcd.vhd
-- 4-digit BCD counter with 7-segment display driver
--
-- Counts from 0000 to 9999 (one increment per second).
-- Each digit is driven by a separate HEX output.
--
-- DE10-Lite mapping:
--   MAX10_CLK1_50  -> 50 MHz clock
--   KEY[0]         -> Reset counter to 0000 (active low)
--   SW[0]          -> Enable counting (ON = count, OFF = pause)
--   HEX0           -> Units       (rightmost digit)
--   HEX1           -> Tens
--   HEX2           -> Hundreds
--   HEX3           -> Thousands   (leftmost digit)
--
-- 7-segment encoding: active low (0 = segment ON, 1 = segment OFF)
-- Bit order: HEX[6:0] = gfedcba
--
-- Author: Barbaros Nicolin
-- ============================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity seven_seg_bcd is
    port (
        MAX10_CLK1_50 : in  STD_LOGIC;
        KEY           : in  STD_LOGIC_VECTOR(1 downto 0);
        SW            : in  STD_LOGIC_VECTOR(9 downto 0);
        HEX0          : out STD_LOGIC_VECTOR(6 downto 0);
        HEX1          : out STD_LOGIC_VECTOR(6 downto 0);
        HEX2          : out STD_LOGIC_VECTOR(6 downto 0);
        HEX3          : out STD_LOGIC_VECTOR(6 downto 0)
    );
end seven_seg_bcd;

architecture Behavioral of seven_seg_bcd is

    -- ── BCD to 7-segment lookup table ─────────────────────────
    -- Active low: bit = 0 means segment is ON
    -- Bit order: gfedcba (bit 6 = g, bit 0 = a)
    type Seg7_ROM is array(0 to 9) of STD_LOGIC_VECTOR(6 downto 0);
    constant SEG7 : Seg7_ROM := (
        0 => "1000000",   -- 0: a,b,c,d,e,f ON  | g OFF
        1 => "1111001",   -- 1: b,c ON
        2 => "0100100",   -- 2: a,b,d,e,g ON
        3 => "0110000",   -- 3: a,b,c,d,g ON
        4 => "0011001",   -- 4: b,c,f,g ON
        5 => "0010010",   -- 5: a,c,d,f,g ON
        6 => "0000010",   -- 6: a,c,d,e,f,g ON
        7 => "1111000",   -- 7: a,b,c ON
        8 => "0000000",   -- 8: all segments ON
        9 => "0010000"    -- 9: a,b,c,d,f,g ON
    );

    -- ── Clock divider: 50 MHz → 1 Hz ──────────────────────────
    constant CLK_DIV : integer := 50_000_000;
    signal cnt_clk : integer range 0 to CLK_DIV - 1 := 0;
    signal tick    : STD_LOGIC := '0';

    -- ── BCD digit registers ────────────────────────────────────
    signal d0 : integer range 0 to 9 := 0;   -- units
    signal d1 : integer range 0 to 9 := 0;   -- tens
    signal d2 : integer range 0 to 9 := 0;   -- hundreds
    signal d3 : integer range 0 to 9 := 0;   -- thousands

    signal rst_n   : STD_LOGIC;
    signal enable  : STD_LOGIC;

begin

    rst_n  <= KEY(0);
    enable <= SW(0);

    -- ── 1-second tick generator ────────────────────────────────
    clk_div : process(MAX10_CLK1_50, rst_n)
    begin
        if rst_n = '0' then
            cnt_clk <= 0;
            tick    <= '0';
        elsif rising_edge(MAX10_CLK1_50) then
            tick <= '0';
            if cnt_clk = CLK_DIV - 1 then
                cnt_clk <= 0;
                tick    <= '1';
            else
                cnt_clk <= cnt_clk + 1;
            end if;
        end if;
    end process clk_div;

    -- ── BCD counter ────────────────────────────────────────────
    -- Counts d3 d2 d1 d0 from 0000 to 9999, then wraps to 0000
    counter : process(MAX10_CLK1_50, rst_n)
    begin
        if rst_n = '0' then
            d0 <= 0; d1 <= 0; d2 <= 0; d3 <= 0;
        elsif rising_edge(MAX10_CLK1_50) then
            if tick = '1' and enable = '1' then

                -- Increment with carry propagation
                if d0 = 9 then
                    d0 <= 0;
                    if d1 = 9 then
                        d1 <= 0;
                        if d2 = 9 then
                            d2 <= 0;
                            if d3 = 9 then
                                d3 <= 0;   -- 9999 -> 0000
                            else
                                d3 <= d3 + 1;
                            end if;
                        else
                            d2 <= d2 + 1;
                        end if;
                    else
                        d1 <= d1 + 1;
                    end if;
                else
                    d0 <= d0 + 1;
                end if;

            end if;
        end if;
    end process counter;

    -- ── Map BCD digits to 7-segment displays ──────────────────
    HEX0 <= SEG7(d0);
    HEX1 <= SEG7(d1);
    HEX2 <= SEG7(d2);
    HEX3 <= SEG7(d3);

end Behavioral;

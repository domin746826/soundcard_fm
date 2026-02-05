library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity main is
    port (
        led1: out std_logic;
        led2: out std_logic;
        btn1: in std_logic;
        btn2: in std_logic;
        btn3: in std_logic;
        clk10m: in std_logic
    );
end entity;


architecture rtl of main is
    -- signal sum: unsigned(1 downto 0);
    signal Ticks: unsigned(23 downto 0);
    signal led_tim: unsigned(1 downto 0);
begin

    process(clk10m) is
    begin
        if rising_edge(clk10m) then
            if Ticks < 1_000_000 then
                Ticks <= Ticks + 1;
            else
                Ticks <= (others => '0');
                if led_tim < 3 then
                    led_tim <= led_tim + 1;
                else
                    led_tim <= (others => '0');
                end if;
            end if;
        end if;
    end process;

    (led1, led2) <= not led_tim;

    -- sum <= ('0' & btn1) + ('0' & btn2) + ('0' & btn3);
    -- (led1, led2) <= not sum;



end architecture;
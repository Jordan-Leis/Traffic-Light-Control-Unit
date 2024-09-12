-- Jordan Leis & Christopher Pederson
library ieee;
use ieee.std_logic_1164.all;

-- Entity declaration for holding_register
entity holding_register is 
    port (
        clk          : in std_logic;   -- Clock signal input
        reset        : in std_logic;   -- Reset signal input
        register_clr : in std_logic;   -- Register clear signal input
        din          : in std_logic;   -- Data input
        dout         : out std_logic   -- Data output
    );
end holding_register;

-- Architecture definition for holding_register
architecture circuit of holding_register is
    signal sreg      : std_logic;  -- Register to hold the current data
    signal temp_hold : std_logic;  -- Temporary signal for intermediate logic
begin
    -- Combinational logic to determine the next state of the register
    temp_hold <= (sreg OR din) AND (reset NOR register_clr);

    -- Synchronous process triggered by the clock signal
    synced_system : process(clk)
    begin
        -- On the rising edge of the clock, update the register and output
        if rising_edge(clk) then
            sreg <= temp_hold;  -- Update register with the computed value
            dout <= temp_hold;  -- Update output with the computed value
        end if;
    end process;
end circuit;

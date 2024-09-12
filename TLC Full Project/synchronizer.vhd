-- Jordan Leis & Christopher Pederson
library ieee;
use ieee.std_logic_1164.all;

-- Entity declaration for synchronizer
entity synchronizer is port (
        clk    : in std_logic;   -- Clock signal input
        reset  : in std_logic;   -- Reset signal input
        din    : in std_logic;   -- Data input
        dout   : out std_logic   -- Data output
    );
end synchronizer;

-- Architecture definition for synchronizer
architecture circuit of synchronizer is
    signal sreg : std_logic_vector(1 downto 0); -- 2-bit register to hold the synchronized data
begin
    -- Process triggered by the clock signal
    process(clk)
    begin
        -- reset: when reset is active, clear the register
        if reset = '1' then 
            sreg <= "00";
        -- On the rising edge of the clock signal, shift the data through the register
        elsif rising_edge(clk) then
            sreg(1) <= sreg(0);  -- Shift the previous value to the next stage
            sreg(0) <= din;      -- Load new data into the first stage
        end if;
    end process;
    
    -- Assign the output to the second stage of the register
    dout <= sreg(1);
end circuit;

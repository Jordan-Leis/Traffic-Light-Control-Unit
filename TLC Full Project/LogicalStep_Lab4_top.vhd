-- Jordan Leis & Christopher Pederson
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

-- Entity declaration for top file
ENTITY LogicalStep_Lab4_top IS
   PORT
	(
		clkin_50	    : in	std_logic;							-- The 50 MHz FPGA Clockinput
		rst_n			: in	std_logic;							-- The RESET input (ACTIVE LOW)
		pb_n			: in	std_logic_vector(3 downto 0); -- The push-button inputs (ACTIVE LOW)
		sw   			: in  	std_logic_vector(7 downto 0); -- The switch inputs
		leds			: out 	std_logic_vector(7 downto 0);	-- for displaying the the lab4 project details
	-------------------------------------------------------------
	-- you can add temporary output ports here if you need to debug your design 
	-- or to add internal signals for your simulations
	-------------------------------------------------------------
	
		seg7_data 	: out 	std_logic_vector(6 downto 0); -- 7-bit outputs to a 7-segment
		seg7_char1  : out	std_logic;							-- seg7 digi selectors
		seg7_char2  : out	std_logic							-- seg7 digi selectors
		
-- Extra signals for the Waveform	
--		sm_clken_1	: out std_logic;
--		blink_sig_1	: out std_logic;
--		NS_green_1	: out std_logic;
--		NS_yellow_1	: out std_logic;
--		NS_red_1		: out std_logic;
--		
--		EW_green_1	: out std_logic;
--		EW_yellow_1	: out std_logic;
--		EW_red_1		: out std_logic;
--		State_Number_1 : out std_logic_vector(3 downto 0)
		
		
	);
END LogicalStep_Lab4_top;
-- Architecture declaration for top file
ARCHITECTURE SimpleCircuit OF LogicalStep_Lab4_top IS
   component segment7_mux port (
          clk        	: in  	std_logic := '0';
			 DIN2 			: in  	std_logic_vector(6 downto 0);	--bits 6 to 0 represent segments G,F,E,D,C,B,A
			 DIN1 			: in  	std_logic_vector(6 downto 0); --bits 6 to 0 represent segments G,F,E,D,C,B,A
			 DOUT				: out	std_logic_vector(6 downto 0);
			 DIG2				: out	std_logic;
			 DIG1				: out	std_logic
   );
   end component;

   component clock_generator port (
			sim_mode			: in boolean;
			reset				: in std_logic;
         clkin      		: in  std_logic;
			sm_clken			: out	std_logic;
			blink		  		: out std_logic
  );
   end component;

    component pb_filters port (
			clkin					: in std_logic;
			rst_n					: in std_logic;
			rst_n_filtered		: out std_logic;
			pb_n					: in  std_logic_vector (3 downto 0);
			pb_n_filtered		: out	std_logic_vector(3 downto 0)							 
 );
   end component;

	component pb_inverters port (
			rst_n					: in  std_logic;
			rst				   : out	std_logic;							 
			pb_n_filtered	   : in  std_logic_vector (3 downto 0);
			pb						: out	std_logic_vector(3 downto 0)							 
  );
   end component;
	
	component synchronizer port(
			clk					: in std_logic; -- clock input for synchronizers
			reset					: in std_logic; -- synch reset
			din					: in std_logic; -- input for synch
			dout					: out std_logic -- output for synch
  );
   end component; 
  component holding_register port (
			clk					: in std_logic; -- clock input for holding register
			reset					: in std_logic; -- reset input for holding register
			register_clr		: in std_logic; -- clear for holding register
			din					: in std_logic; -- input for holding register
			dout					: out std_logic -- output for holding register
  );
  end component;

component State_Machine port (
      clk			: in std_logic; -- clock input for state machine (SM)
		reset			: in std_logic; -- reset for SM (brings back to S0)
		clk_enable	: in std_logic; -- clock enable for SM (SM can only move between states when enabled)
		blink_sig	: in std_logic; -- blink signal to power the first 2 states
		
		NS_walk_req	: in std_logic; -- the input to request to cross NS
		EW_walk_req : in std_logic; -- the input to request to cross EW
		
		
		NS_reg_clear	: out std_logic; -- clears the NW register's state
		EW_reg_clear	: out std_logic; -- clears the EW register's state
		
		NS_walk		: out std_logic; -- signal for pedestrians to walk across NS
		EW_walk		: out std_logic; -- signal for pedestrians to walk across EW
		
		NS_green		: out std_logic; -- green NS signal (1 when NS is green, 0 otherwise)
		NS_yellow	: out std_logic; -- Yellow NS signal (1 when NS is yellow, 0 otherwise)
		NS_red		: out std_logic; -- Red NS signal (1 when NS is red, 0 otherwise)
		
		EW_green		: out std_logic; -- green EW signal (1 when NS is green, 0 otherwise)
		EW_yellow	: out std_logic; -- Yellow EW signal (1 when NS is yellow, 0 otherwise)
		EW_red		: out std_logic; -- Red EW signal (1 when NS is red, 0 otherwise)
		State_Number : out std_logic_vector(3 downto 0); -- holds the current state of the SM
		state_debug : out std_logic_vector(3 downto 0)  -- debug used for testing purposes (not a part of the lab)
        );
    end component; 
----------------------------------------------------------------------------------------------------
	CONSTANT	sim_mode										: boolean := FALSE;  -- set to FALSE for LogicalStep board downloads																						-- set to TRUE for SIMULATIONS
	SIGNAL rst, rst_n_filtered, synch_rst			: std_logic;
	SIGNAL sm_clken, blink_sig							: std_logic; 
	SIGNAL pb_n_filtered, pb							: std_logic_vector(3 downto 0); 
	SIGNAL synch_out_EW, synch_out_NS				: std_logic; -- signals for synchronizer outputs
--	SIGNAL clk_sig        								: std_logic; 
-- SIGNAL reset_sig      								: std_logic;
-- SIGNAL clk_enable_sig 								: std_logic; test signals
    
   SIGNAL NS_walk_sig   								: std_logic; -- signal to indicate it is safe to cross NS
   SIGNAL EW_walk_sig   								: std_logic; -- signal to indicate it is safe to cross EW
		
   SIGNAL NS_green_sig   								: std_logic; -- green light signal for NS
   SIGNAL NS_yellow_sig 							 	: std_logic; -- yellow light signal for NS
   SIGNAL NS_red_sig     								: std_logic; -- red light signal for NS
    
   SIGNAL EW_green_sig   								: std_logic; -- green light signal for EW
   SIGNAL EW_yellow_sig  								: std_logic; -- yellow light signal for EW
   SIGNAL EW_red_sig     								: std_logic; -- red light signal for EW
	
	SIGNAL NS_crossing_display 						: std_logic_vector(6 downto 0); -- the seven seg display signal for NS
	SIGNAL EW_crossing_display							: std_logic_vector(6 downto 0); -- the seven seg display signal for EW
	SIGNAL state_debug_sig 								: std_logic_vector(3 downto 0); -- SM debug signal
	SIGNAL NS_holding_register							: std_logic; -- NS register output signal
	SIGNAL EW_holding_register 						: std_logic; -- EW register output signal
	SIGNAL NS_register_clr								: std_logic; -- NS register clear signal
	SIGNAL EW_register_clr								: std_logic; -- EW register clear signal
	SIGNAL State_Number									: std_logic_vector(3 downto 0); -- current state of SM
	
BEGIN
----------------------------------------------------------------------------------------------------
INST0: pb_filters					port map (clkin_50, rst_n, rst_n_filtered, pb_n, pb_n_filtered);
INST1: pb_inverters				port map (rst_n_filtered, rst, pb_n_filtered, pb);
INST2: synchronizer     		port map (clkin_50,'0', rst, synch_rst); -- synch instance that just outputs synch_rst
-- NOTE: sync_rst is really important as it makes sure all of our resets are synchronized to prevent metastability
INST3: clock_generator 			port map (sim_mode, synch_rst, clkin_50, sm_clken, blink_sig);

synch_EW: synchronizer 			port map (clkin_50,synch_rst, pb(1), synch_out_EW); -- sych instance for EW
-- ensures that the input from the pbs is synchronized to prevent metastability
Synch_NS: synchronizer 			port map (clkin_50,synch_rst, pb(0), synch_out_NS); -- synch instance for NS, same as above

holder_EW: holding_register 	port map	(clkin_50,synch_rst, EW_register_clr, synch_out_EW, EW_holding_register);
-- this holds the input from pbs until the SM is able to do the proper state skip and clear the register for EW
holder_NS: holding_register 	port map	(clkin_50,synch_rst, NS_register_clr, synch_out_NS, NS_holding_register);
-- same as above
State_Machine_inst: State_Machine	port map (clkin_50, synch_rst, sm_clken, blink_sig, NS_holding_register, 
EW_holding_register, NS_register_clr, EW_register_clr, NS_walk_sig, EW_walk_sig, NS_green_sig, NS_yellow_sig, 
NS_red_sig, EW_green_sig, EW_yellow_sig, EW_red_sig, State_Number(3 downto 0), state_debug_sig(3 downto 0));

-- this is the SM instance, it outputs the state of the lights depending on its internal state. 

seg7_mux_inst: segment7_mux port map (clkin_50, NS_crossing_display, EW_crossing_display, seg7_data, seg7_char2, seg7_char1);

NS_crossing_display <= NS_yellow_sig & "00" & NS_green_sig & '0' & '0' & NS_red_sig;

-- This is the concatination of the all of traffic signals , their order is incredibly important for the 7segmux to properly
-- display the necessary colour light

EW_crossing_display <= EW_yellow_sig & '0' & '0' & EW_green_sig & '0' & '0' & EW_red_sig;

-- same as above

leds(3) <= EW_holding_register;
leds(1) <= NS_holding_register;

-- shows if the pbs have been pressed within the current cycle 


leds(2) <= EW_walk_sig;
leds(0) <= NS_walk_sig;

-- displays when it is safe for pedestrians to walk across NS/EW



leds(7 downto 4) <= State_Number(3 downto 0);

-- outputs current state of SM as a binary number to Leds 7 - 4


--		sm_clken_1  <= sm_clken;
--		blink_sig_1	<= blink_sig;
--		NS_green_1	<=	NS_green_sig;
--		NS_yellow_1	<=	NS_yellow_sig;
--		NS_red_1		<=	NS_red_sig;
--		
--		EW_green_1	<=	EW_green_sig;	
--		EW_yellow_1	<=	EW_yellow_sig;
--		EW_red_1		<=	EW_red_sig;
--		State_Number_1 <= State_Number(3 downto 0);

-- additional signal assignment for waveform

END SimpleCircuit;

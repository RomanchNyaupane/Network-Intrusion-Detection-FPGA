library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity mac_ring_memory_tb is
end mac_ring_memory_tb;

architecture Behavioral of mac_ring_memory_tb is
    component mac_ring_memory
        Port (
            clk             : in  std_logic;
            rst             : in  std_logic;
            tx_req          : in  std_logic;
            tx_complete_ack : in  std_logic;
            rd_data         : out std_logic_vector(7 downto 0);
            tx_complete     : out std_logic
        );
    end component;

    -- Inputs
    signal clk             : std_logic := '0';
    signal rst             : std_logic := '0';
    signal tx_req          : std_logic := '0';
    signal tx_complete_ack : std_logic := '0';

    -- Outputs
    signal rd_data     : std_logic_vector(7 downto 0);
    signal tx_complete : std_logic;

    -- Clock period definitions
    constant clk_period : time := 10 ns;

begin
    -- Instantiate the Unit Under Test (UUT)
    uut: mac_ring_memory port map (
        clk => clk,
        rst => rst,
        tx_req => tx_req,
        tx_complete_ack => tx_complete_ack,
        rd_data => rd_data,
        tx_complete => tx_complete
    );

    -- Clock process definitions
    clk_process: process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    -- Stimulus process
    stim_proc: process
    begin
        -- Initial reset
        rst <= '1';
        wait for clk_period*2;
        rst <= '0';
        wait for clk_period;
        
        -- Test 1: Normal operation - read all 12 bytes
        for i in 0 to 11 loop
            tx_req <= '1';
            wait for clk_period;
            tx_req <= '0';
            wait for clk_period;
            
            -- Verify data output (alternates between source and dest MAC)
            if i < 6 then
                -- First 6 bytes should be source MAC
                case i is
                    when 0 => assert rd_data = x"AA" report "Byte 0 mismatch" severity error;
                    when 1 => assert rd_data = x"BB" report "Byte 1 mismatch" severity error;
                    when 2 => assert rd_data = x"CC" report "Byte 2 mismatch" severity error;
                    when 3 => assert rd_data = x"DD" report "Byte 3 mismatch" severity error;
                    when 4 => assert rd_data = x"EE" report "Byte 4 mismatch" severity error;
                    when 5 => assert rd_data = x"FF" report "Byte 5 mismatch" severity error;
                    when others => null;
                end case;
            else
                -- Last 6 bytes should be destination MAC
                case i is
                    when 6 => assert rd_data = x"11" report "Byte 6 mismatch" severity error;
                    when 7 => assert rd_data = x"22" report "Byte 7 mismatch" severity error;
                    when 8 => assert rd_data = x"33" report "Byte 8 mismatch" severity error;
                    when 9 => assert rd_data = x"44" report "Byte 9 mismatch" severity error;
                    when 10 => assert rd_data = x"55" report "Byte 10 mismatch" severity error;
                    when 11 => assert rd_data = x"66" report "Byte 11 mismatch" severity error;
                    when others => null;
                end case;
            end if;
        end loop;
        
        -- Verify tx_complete is asserted after last byte
        assert tx_complete = '1' report "tx_complete not asserted after last byte" severity error;
        
        -- Acknowledge completion
        tx_complete_ack <= '1';
        wait for clk_period;
        tx_complete_ack <= '0';
        wait for clk_period;
        
        -- Verify tx_complete is cleared
        assert tx_complete = '0' report "tx_complete not cleared after ack" severity error;
        
        -- Test 2: Reset during transmission
        -- Start transmission
        tx_req <= '1';
        wait for clk_period;
        tx_req <= '0';
        wait for clk_period;
        
        -- Apply reset
        rst <= '1';
        wait for clk_period;
        rst <= '0';
        wait for clk_period;
        
        -- Verify read pointer reset (should output first byte again)
        tx_req <= '1';
        wait for clk_period;
        tx_req <= '0';
        wait for clk_period;
        assert rd_data = x"AA" report "Read pointer not reset properly" severity error;
        
        -- Test 3: Wrap-around test
        -- Read all 12 bytes again
        for i in 0 to 11 loop
            tx_req <= '1';
            wait for clk_period;
            tx_req <= '0';
            wait for clk_period;
        end loop;
        
        -- Verify wrap-around (next read should be first byte again)
        tx_req <= '1';
        wait for clk_period;
        tx_req <= '0';
        wait for clk_period;
        assert rd_data = x"AA" report "Wrap-around failed" severity error;
        
        -- Test 4: tx_complete_ack without tx_complete
        tx_complete_ack <= '1';
        wait for clk_period;
        tx_complete_ack <= '0';
        wait for clk_period;
        -- Should have no effect
        
        -- Test complete
        wait for clk_period*2;
        report "Testbench completed successfully" severity note;
        wait;
    end process;

end Behavioral;
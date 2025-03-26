library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Input_FIFO_addr_mux is
    Port (
        IFAM_sel    : in  std_logic;  -- Select signal (0 or 1)
        IFAM_in0    : in  std_logic_vector(7 downto 0); -- Input line 0
        IFAM_in1    : in  std_logic_vector(7 downto 0); -- Input line 1
        IFAM_out_mux: out std_logic_vector(7 downto 0)  -- Selected output
    );
end Input_FIFO_addr_mux;

architecture Behavioral of Input_FIFO_addr_mux is
begin
    process (IFAM_sel, IFAM_in0, IFAM_in1)
    begin
        if IFAM_sel = '0' then
            IFAM_out_mux <= IFAM_in0;
        else
            IFAM_out_mux <= IFAM_in1;
        end if;
    end process;
end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Frame_Assm_addr_demux is
    Port (
        sel    : in  std_logic;  -- Select signal (0 or 1)
        in_data: in  std_logic_vector(7 downto 0); -- 8-bit input
        out0   : out std_logic_vector(7 downto 0); -- 8-bit output line 0
        out1   : out std_logic_vector(7 downto 0)  -- 8-bit output line 1
    );
end Frame_Assm_addr_demux;

architecture Behavioral of Frame_Assm_addr_demux is
begin
    process (sel, in_data)
    begin
        if sel = '0' then
            out0 <= in_data;  -- Route input to out0
            out1 <= (others => '0');  -- Reset out1
        else
            out0 <= (others => '0');  -- Reset out0
            out1 <= in_data;  -- Route input to out1
        end if;
    end process;
end Behavioral;

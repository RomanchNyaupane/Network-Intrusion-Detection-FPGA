library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Tx_FIFO_data_mux is
    Port (
        TFDM_sel    : in  std_logic_vector(1 downto 0);  -- 2-bit Select signal (00, 01, 10)
        TFDM_in0    : in  std_logic_vector(7 downto 0); -- Input line 0
        TFDM_in1    : in  std_logic_vector(7 downto 0); -- Input line 1
        TFDM_in2    : in  std_logic_vector(7 downto 0); -- Input line 2
        TFDM_out_mux: out std_logic_vector(7 downto 0)  -- Selected output
    );
end Tx_FIFO_data_mux;

architecture Behavioral of Tx_FIFO_data_mux is
begin
    process (TFDM_sel, TFDM_in0, TFDM_in1, TFDM_in2)
    begin
        case sel is
            when "00"   => out_mux <= in0;
            when "01"   => out_mux <= in1;
            when "10"   => out_mux <= in2;
            when others => out_mux <= (others => '0'); -- Default case (optional)
        end case;
    end process;
end Behavioral;

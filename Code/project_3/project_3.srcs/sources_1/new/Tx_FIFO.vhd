library IEEE;
use IEEE.std_logic_1164.all;

entity Tx_FIFO is
    port(
    --data and address ports
    data_in : in std_logic_vector(7 downto 0);
    data_out : out std_logic_vector(7 downto 0);
    address : in integer range 0 to 2047;
    address_valid : in std_logic;
    data_valid : out std_logic; --send acknowledgement to let others know device is ready (to be written)
    
    --control ports
    read_en : in std_logic; --enable before reading data
    write_en : in std_logic; --enable before writing data
    reset : in std_logic;
    clk : in std_logic
    );
end Tx_FIFO;

architecture behavioral of Tx_FIFO is
type MAC_fifo_mem is array(0 to 2047) of std_logic_vector(7 downto 0);
signal MAC_fifo : MAC_fifo_mem;
signal data_out_reg : std_logic_vector(7 downto 0) := "00000000";
signal address_holder : integer range 0 to 2047;

begin
process(clk) begin
if rising_edge(clk) then

    if address_valid = '1' then
        address_holder <= address;
    end if;

    if reset = '1' then
        data_out_reg <= "00000000";
    else
        if read_en = '1' and write_en = '0' then
            data_out_reg <= MAC_fifo(address_holder);
        end if;
        if write_en = '1' and read_en = '0' then
            data_valid <= '1';
            MAC_fifo(address_holder) <= data_in;
            else
            data_valid <= '0'
        end if;
    end if;
end if;
end process;
data_out<=data_out_reg;
end behavioral;
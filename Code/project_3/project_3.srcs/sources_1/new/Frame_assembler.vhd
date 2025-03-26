library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Frame_assembler is
port(
    --frame assembler will be responsible for writing preambles and sfd. it will then trigger other modules to write on tx module and provides address to these modules
    data_out : out std_logic_vector(7 downto 0);
    address_out : out integer range 0 to 2047;
    
    change_state : in std_logic; --from tx_controller
    
    fifo_data_ready : out std_logic; --check fifo buffer(tx fifo) before transmitting
    fifo_data_ready_ack : in std_logic; --fifo buffer ready acknowledgement(tx_fifo)
    tx_fifo_address_valid : out std_logic; --assert valid address
    tx_fifo_write_en : out std_logic;   --
    
    mac_tx_req : out std_logic;
    
    
    assm_start : in std_logic; --start frame assembly(from tx controller)
    assm_start_ack : out std_logic; --send frame assembly acknowledgement to tx controller
    preamble_end : out std_logic; --send to tx controller
    SFD_end : out std_logic; --send to tx controller
    MAC_over : out std_logic; --send to tx controller
    length_over : out std_logic; --send to tx controller
    payload_over : out std_logic; --send to tx controller
    crc_over : out std_logic --send to tx controller
    --based on these signals, the tx controller modifies select lines in mux, updates status register, etc
    );
end Frame_assembler;

architecture Behavioral of Frame_assembler is
signal tx_fifo_address_pointer : integer range 0 to 2047;
signal input_fifo_address_pointer : integer range 0 to 2047;
signal mac_register_address_count : integer range 0 to 11; --count mac address access count

  type t_state is (
    IDLE,
    PREAMBLE,
    SFD,
    DEST_MAC,
    SRC_MAC,
    ETHERTYPE,
    PAYLOAD,
    WAIT_CRC,
    DONE
  );
  signal state : t_state := IDLE;
  
begin

process(clk)
begin
    if rising_edge(clk) then
        -- Default signal assignments
        fifo_data_ready <= '0';
        assm_start_ack <= '0';
        preamble_end <= '0';
        SFD_end <= '0';
        MAC_over <= '0';
        length_over <= '0';
        payload_over <= '0';
        crc_over <= '0';
        
        case state is
        
        when IDLE =>
            tx_fifo_address_pointer <= 0;
            mac_register_address_count <= 0;
            input_fifo_address_pointer <= 0;
            
            if assm_start = '1' then
                state <= PREAMBLE;
                assm_start_ack <= '1';
            end if;
                     
            
            when PREAMBLE =>
                -- Continuous outputs while in this state
                address_out <= tx_fifo_address_pointer;
                data_out <= x"55";  -- Preamble byte
                fifo_data_ready <= '1';  -- Always assert ready while in this state
                
                -- FIFO handshake handling (independent of state transition)
                if fifo_data_ready_ack = '1' then
                    tx_fifo_write_en <= '1';  -- Pulse write enable when FIFO acknowledges
                    tx_fifo_address_pointer <= tx_fifo_address_pointer + 1;
                end if;
                
                -- State transition logic (evaluated every cycle)
                if tx_fifo_address_pointer = 6 then  -- After sending 7 bytes
                    preamble_end <= '1';
                    if change_state = '1' then
                        state <= SFD;
                    end if;
                end if;
            
            when SFD =>
                -- Continuous outputs while in this state
                address_out <= tx_fifo_address_pointer;
                tx_fifo_address_valid <= '1';
                data_out <= x"D5";  -- SFD byte
                fifo_data_ready <= '1';  -- Data is always ready in this state
                
                -- FIFO handshake handling
                if fifo_data_ready_ack = '1' then
                    tx_fifo_write_en <= '1';  -- Pulse write enable
                    tx_fifo_address_pointer <= tx_fifo_address_pointer + 1;
                end if;
                
                -- State transition logic (independent of handshake)
                SFD_end <= '1';  -- Can be asserted continuously or modified as needed
                if change_state = '1' then
                    state <= DEST_MAC;
                end if;

                 when DEST_MAC =>
                    -- Continuous outputs
                    address_out <= tx_fifo_address_pointer;
                    tx_fifo_address_valid <= '1';
                    fifo_data_ready <= '1';   -- Always ready while in this state
                
                    -- FIFO handshake handling
                    if fifo_data_ready_ack = '1' then
                        tx_fifo_write_en <= '1';
                        MAC_tx_req <= '1';    -- Request next byte from MAC module
                        tx_fifo_address_pointer <= tx_fifo_address_pointer + 1;
                        
                        -- Auto-advance after 6 bytes (no need for external counter)
                        if tx_fifo_address_pointer = 13 then  -- Start from pointer 7 (0-6 = 7 bytes)
                            MAC_over <= '1';    --end of destination mac address transmission
                            if change_state = '1' then
                                state <= SRC_MAC;
                            end if;
                        end if;
                    else
                        MAC_tx_req <= '0';
                    end if;
                    
                    
                  when SRC_MAC =>
                    -- Same signals as DEST_MAC
                    address_out <= tx_fifo_address_pointer;
                    tx_fifo_address_valid <= '1';
                    fifo_data_ready <= '1';
                
                    if fifo_data_ready_ack = '1' then
                        tx_fifo_write_en <= '1';
                        MAC_tx_req <= '1';
                        tx_fifo_address_pointer <= tx_fifo_address_pointer + 1;
                        
                        -- Auto-advance after 6 source bytes (total 12 bytes from MAC module)
                        if tx_fifo_address_pointer = 19 then
                            MAC_over <= '1';
                            if change_state = '1' then
                                state <= ETHERTYPE;
                            end if;
                        end if;
                    else
                        MAC_tx_req <= '0';
                    end if;
            
end process;
end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Tx_module is
--  Port ( );
end Tx_module;

architecture Structural of Tx_module is
signal input_fifo_address : integer range 0 to 2047;
signal input_fifo_data_out : std_logic_vector(7 downto 0);
signal mac_data_out : std_logic_vector(7 downto 0);


  -- Component declarations
  component Input_FIFO is
    Port (
      IF_data_in : in std_logic_vector(7 downto 0);
      IF_data_out : out std_logic_vector(7 downto 0);
      IF_address : in integer range 0 to 2047
    );
  end component;

  component Input_FIFO_addr_mux is
    Port (
        IFAM_sel    : in  std_logic;  -- Select signal (0 or 1)
        IFAM_in0    : in  std_logic_vector(7 downto 0); -- Input line 0
        IFAM_in1    : in  std_logic_vector(7 downto 0); -- Input line 1
        IFAM_out_mux: out std_logic_vector(7 downto 0)  -- Selected output
    );
  end component;

  component Tx_FIFO_data_mux is
    Port (
        TFDM_sel    : in  std_logic_vector(1 downto 0);  -- 2-bit Select signal (00, 01, 10)
        TFDM_in0    : in  std_logic_vector(7 downto 0); -- Input line 0
        TFDM_in1    : in  std_logic_vector(7 downto 0); -- Input line 1
        TFDM_in2    : in  std_logic_vector(7 downto 0); -- Input line 2
        TFDM_out_mux: out std_logic_vector(7 downto 0)  -- Selected output
    );
  end component;

  component MAC_address is
    Port (
           MAC_rd_data         : out std_logic_vector(7 downto 0) -- 8-bit read data
    );
  end component;

  component TX_FIFO is
    Port (
      clk          : in  std_logic;
      reset_n      : in  std_logic;
      data_in      : in  std_logic_vector(7 downto 0);
      wr_en        : in  std_logic;
      data_out     : out std_logic_vector(7 downto 0);
      rd_en        : in  std_logic;
      fifo_full    : out std_logic;
      fifo_empty   : out std_logic
    );
  end component;

  component TX_controller is
    Port (
      clk          : in  std_logic;
      reset_n      : in  std_logic;
      tx_start     : in  std_logic;
      ip_done      : in  std_logic;
      header_done  : in  std_logic;
      crc_done     : in  std_logic;
      fifo_full    : in  std_logic;
      fifo_empty   : in  std_logic;
      phy_collision: in  std_logic;
      assemble_start: out std_logic;
      crc_reset    : out std_logic;
      crc_en       : out std_logic;
      ip_start     : out std_logic;
      tx_done      : out std_logic
    );
  end component;

  component PHY_interface is
    Port (
      clk          : in  std_logic;
      reset_n      : in  std_logic;
      data_in      : in  std_logic_vector(7 downto 0);
      fifo_empty   : in  std_logic;
      phy_txd      : out std_logic_vector(7 downto 0);
      phy_tx_en    : out std_logic;
      rd_en        : out std_logic
    );
  end component;

  -- Internal signals
  signal ip_data_to_assembler : std_logic_vector(7 downto 0);
  signal ip_start, ip_done    : std_logic;
  signal src_mac, dest_mac    : std_logic_vector(47 downto 0);
  signal mac_request, mac_ready : std_logic;
  signal frame_data, fifo_data_in, fifo_data_out : std_logic_vector(7 downto 0);
  signal data_valid, fifo_wr_en, fifo_rd_en : std_logic;
  signal fifo_full, fifo_empty : std_logic;
  signal assemble_start, header_done : std_logic;
  signal crc_reset, crc_en, crc_done : std_logic;
  signal crc_value : std_logic_vector(31 downto 0);

begin

  -- Component instantiations
  U1: Input_FIFO
    port map (
      IF_address           => input_fifo_address,
      IF_data_out          => input_fifo_data_out
    );

  U2: Input_FIFO_addr_mux
    port map (
      IFAM_out_mux         => input_fifo_address,
    );

  U3: Tx_FIFO_data_mux
    port map (
      TFDM_in0             => input_fifo_data_out,
      TFDM_in1             => mac_data_out
    );

  U4: MAC_address
    port map (
      MAC_rd_data          => mac_data_out
    );

  -- Mux: Frame data or CRC bytes to FIFO
  fifo_data_in <= frame_data when crc_done = '0' else
                  crc_value(31 downto 24) when data_valid = '1' else
                  crc_value(23 downto 16) when data_valid = '1' else
                  crc_value(15 downto 8)  when data_valid = '1' else
                  crc_value(7 downto 0);

  fifo_wr_en <= data_valid or (crc_done and not fifo_full);

  U5: TX_FIFO
    port map (
      clk          => clk_125MHz,
      reset_n      => reset_n,
      data_in      => fifo_data_in,
      wr_en        => fifo_wr_en,
      data_out     => fifo_data_out,
      rd_en        => fifo_rd_en,
      fifo_full    => fifo_full,
      fifo_empty   => fifo_empty
    );

  U6: TX_controller
    port map (
      clk          => clk_125MHz,
      reset_n      => reset_n,
      tx_start     => tx_start,
      ip_done      => ip_done,
      header_done  => header_done,
      crc_done     => crc_done,
      fifo_full    => fifo_full,
      fifo_empty   => fifo_empty,
      phy_collision=> phy_collision,
      assemble_start => assemble_start,
      crc_reset    => crc_reset,
      crc_en       => crc_en,
      ip_start     => ip_start,
      tx_done      => tx_done
    );

  U7: PHY_interface
    port map (
      clk          => clk_125MHz,
      reset_n      => reset_n,
      data_in      => fifo_data_out,
      fifo_empty   => fifo_empty,
      phy_txd      => phy_txd,
      phy_tx_en    => phy_tx_en,
      rd_en        => fifo_rd_en
    );

  -- MAC request tied to assemble_start
  mac_request <= assemble_start;

end Structural;
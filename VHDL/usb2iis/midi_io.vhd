library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

library axi_uartlite_v1_02_a;
  use axi_uartlite_v1_02_a.all;

  use work.common_types.all;

entity uart_rx is
  generic 
  (
    C_FAMILY         : string               := "virtex6";
    C_DATA_BITS      : integer range 5 to 8 := 8;
    C_USE_PARITY     : integer range 0 to 1 := 0;
    C_ODD_PARITY     : integer range 0 to 1 := 0
  );
  port 
  (
    Clk          : in  std_logic;
    Reset        : in  std_logic;
    EN_16x_Baud  : in  std_logic;
    RX           : in  std_logic;
    ready        : in  std_logic;
    data         : out std_logic_vector(0 to C_DATA_BITS-1);
    valid        : out std_logic;
    fifo_reset   : in  std_logic
  );
end uart_rx;

architecture rtl of uart_rx is
  signal rx_atad : std_logic_vector( 0 to C_DATA_BITS-1);
  signal rx_read : std_logic;
  signal rx_present : std_logic;
begin
  
  g_invert : for J in 0 to C_DATA_BITS-1 generate
    data(J) <= rx_atad(J);
  end generate;

  valid <= rx_present;
  -------------------------------------------------------------------------
  rx_read <= ready and rx_present;
  -------------------------------------------------------------------------
  -- UARTLITE_RX_I : Instansiating the receive module
  -------------------------------------------------------------------------
  UARTLITE_RX_I : entity axi_uartlite_v1_02_a.uartlite_rx
    generic map
    (
      C_FAMILY         => C_FAMILY,
      C_DATA_BITS      => C_DATA_BITS,
      C_USE_PARITY     => C_USE_PARITY,
      C_ODD_PARITY     => C_ODD_PARITY
    )
    port map
    (
      Clk              => Clk,
      Reset            => Reset,
      EN_16x_Baud      => en_16x_Baud,
      RX               => RX,
      Read_RX_FIFO     => rx_read,
      Reset_RX_FIFO    => fifo_reset,
      RX_Data          => rx_atad,
      RX_Data_Present  => rx_present,
      RX_Buffer_Full   => open,
      RX_Frame_Error   => open,
      RX_Overrun_Error => open,
      RX_Parity_Error  => open
    );

end architecture;
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

library axi_uartlite_v1_02_a;
  use axi_uartlite_v1_02_a.all;

  use work.common_types.all;

entity uart_tx is
  generic 
  (
    C_FAMILY         : string               := "virtex6";
    C_DATA_BITS      : integer range 5 to 8 := 8;
    C_USE_PARITY     : integer range 0 to 1 := 0;
    C_ODD_PARITY     : integer range 0 to 1 := 0
  );
  port 
  (
    Clk          : in  std_logic;
    Reset        : in  std_logic;
    EN_16x_Baud  : in  std_logic;
    TX           : out  std_logic;
    ready        : out  std_logic;
    data         : in std_logic_vector(0 to C_DATA_BITS-1);
    valid        : in std_logic
  );
end uart_tx;

architecture rtl of uart_tx is
  signal tx_atad : std_logic_vector( 0 to C_DATA_BITS-1);
  signal tx_write: std_logic;
  signal tx_full : std_logic;
begin

  g_invert : for J in 0 to C_DATA_BITS-1 generate
    tx_atad(J) <= data(J);
  end generate;

  ready <= not tx_full;
  tx_write <= valid and not tx_full;


  -------------------------------------------------------------------------
  -- UARTLITE_TX_I : Instansiating the transmit module
  -------------------------------------------------------------------------
  UARTLITE_TX_I : entity axi_uartlite_v1_02_a.uartlite_tx
    generic map
    (
      C_FAMILY        => C_FAMILY,
      C_DATA_BITS     => C_DATA_BITS,
      C_USE_PARITY    => C_USE_PARITY,
      C_ODD_PARITY    => C_ODD_PARITY
    )
    port map
    (
      Clk             => Clk,
      Reset           => Reset,
      EN_16x_Baud     => en_16x_Baud,
      TX              => tx,
      Write_TX_FIFO   => tx_write,
      Reset_TX_FIFO   => reset,
      TX_Data         => tx_atad,
      TX_Buffer_Full  => tx_full,
      TX_Buffer_Empty => open
    );

end architecture;

-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------


library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

library axi_uartlite_v1_02_a;
  use axi_uartlite_v1_02_a.all;

  use work.common_types.all;

entity midi_io is
  generic ( 
    NR_CHANNELS: INTEGER := 7
  );
  port (
    clk  : in STD_LOGIC;
    reset: in STD_LOGIC;
    rx      : in  STD_LOGIC_VECTOR( NR_CHANNELS downto 1);
    rx_data : out slv8_array;
    rx_valid: out STD_LOGIC_VECTOR( NR_CHANNELS downto 1);
    rx_ready: in  STD_LOGIC_VECTOR( NR_CHANNELS downto 1);
    rx_fifo_reset : in std_logic;

    tx      : out STD_LOGIC_VECTOR( NR_CHANNELS downto 1);
    tx_data : in  slv8_array;
    tx_ready: out STD_LOGIC_VECTOR( NR_CHANNELS downto 1);
    tx_valid: in  STD_LOGIC_VECTOR( NR_CHANNELS downto 1)
  );
end midi_io;

architecture rtl of midi_io is

  function CALC_RATIO ( C_S_AXI_ACLK_FREQ_HZ : integer;
                        C_BAUDRATE         : integer ) return Integer is

    constant C_BAUDRATE_16_BY_2: integer := (16 * C_BAUDRATE) / 2;
    constant REMAINDER         : integer := 
    C_S_AXI_ACLK_FREQ_HZ rem (16 * C_BAUDRATE);
    constant RATIO             : integer := 
    C_S_AXI_ACLK_FREQ_HZ / (16 * C_BAUDRATE);   

  begin
    if (C_BAUDRATE_16_BY_2 < REMAINDER) then
      return (RATIO + 1);
    else  
      return RATIO;
    end if;
  end function CALC_RATIO;

   constant RATIO         : integer := CALC_RATIO( 48_000_000, 31250 );
   constant C_FAMILY      : string := "spartan6";
   constant C_DATA_BITS   : integer := 8;
   constant C_USE_PARITY  : integer := 0;
   constant C_ODD_PARITY  : integer := 0;

   signal en_16x_Baud     : std_logic;
   
begin

  BAUD_RATE_I : entity axi_uartlite_v1_02_a.baudrate
    generic map
    (
      C_RATIO      => RATIO
    )
    port map
    (
      Clk          => Clk,
      Reset        => Reset,
      EN_16x_Baud  => en_16x_Baud
    );

  g_uart_xcvrs : for I in 1 to NR_CHANNELS generate

    uart_rx_inst: entity work.uart_rx
      generic map (
        C_FAMILY     => C_FAMILY,
        C_DATA_BITS  => C_DATA_BITS,
        C_USE_PARITY => C_USE_PARITY,
        C_ODD_PARITY => C_ODD_PARITY
      )
      port map (
        Clk          => Clk,
        Reset        => Reset,
        EN_16x_Baud  => EN_16x_Baud,
        RX           => RX(I),
        ready        => rx_ready(I),
        data         => rx_data(I),
        valid        => rx_valid(I),
        fifo_reset   => rx_fifo_reset
      );
    
    uart_tx_inst: entity work.uart_tx
      generic map (
        C_FAMILY     => C_FAMILY,
        C_DATA_BITS  => C_DATA_BITS,
        C_USE_PARITY => C_USE_PARITY,
        C_ODD_PARITY => C_ODD_PARITY
      )
      port map (
        Clk          => Clk,
        Reset        => Reset,
        EN_16x_Baud  => EN_16x_Baud,
        TX           => TX(I),
        ready        => tx_ready(I),
        data         => tx_data(I),
        valid        => tx_valid(I)
      );
  end generate;
end architecture rtl;

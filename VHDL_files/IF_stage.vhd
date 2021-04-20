library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity IF_stage is
    generic (RAM_SIZE : integer := 32768);
    port (
        clock : in std_logic;
        --jump target as returned for branch or jump 
        jump_target : in integer range 0 to RAM_SIZE - 1;
        --specifies if the jump target is valid
        valid_jump_target : in std_logic;
        --bit for stalling
        if_stall : in std_logic;
        ------------------------------------------------------------------------------
        --raw instruction data to decode
        instruction_data : out std_logic_vector(31 downto 0);
        --program counter of next instruction ie pc+4
        pc_next : out integer range 0 to RAM_SIZE - 1
    );
end IF_stage;

architecture behavior of IF_stage is
    component instruction_memory is
        port (
            i_address : in integer range 0 to RAM_SIZE - 1;
            o_readdata : out std_logic_vector (31 downto 0)
        );
    end component;

    signal instruction_data_buffer : std_logic_vector(31 downto 0) := (others => '0');--TODO initialize to stall
    signal program_counter : integer range 0 to RAM_SIZE - 1 := 0;
    signal pc_next_buffer : integer range 0 to RAM_SIZE - 1 := 0;
begin
    pm_IM : instruction_memory
    port map(
        --to simplify synchronization of instruction memory, o_waitrequest and i_imread are removed
        --data is instantaneously read from memory, as allowed from the project instructions:
        --"You may alter the memory model as you see fit (e.g., set the memory delay to 1 clock cycle, if it makes your life easier)."
        i_address => program_counter,
        o_readdata => instruction_data_buffer
    );

    IF_logic_process : process (clock)
    begin
        if (rising_edge(clock)) then
            case valid_jump_target is
                when '1' =>
                    --jump when valid
                    program_counter <= jump_target;
                when others =>
                    --increment normaly otherwise if no stall
                    if (if_stall = '1') then
                        program_counter <= program_counter;
                    else 
                        program_counter <= program_counter + 4;
                    
                    end if;
            end case;
            
            -- TODO logic for the IF stage. Write the values for the next stage on the buffer signals
            -- Because signal values are only updated at the end of the process, those values will be available to ID on the next clock cycle only
        end if;
    end process;
    
    pc_next <= program_counter +4;
    instruction_data <= instruction_data_buffer;

end;
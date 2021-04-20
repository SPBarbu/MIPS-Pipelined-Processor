library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pipelined_processor is
    generic (RAM_SIZE : integer := 32768);
end pipelined_processor;

architecture behavior of pipelined_processor is
    component IF_stage is
        port (
            clock : in std_logic;
            jump_target : in integer range 0 to RAM_SIZE - 1;
            valid_jump_target : in std_logic;
            instruction_data : out std_logic_vector(31 downto 0);
            pc_next : out integer range 0 to RAM_SIZE - 1;
            if_stall : in std_logic
        );
    end component;
    component ID_stage is
        port (
            clock : in std_logic;
            instruction_data : in std_logic_vector(31 downto 0);
            immediate_data_wb : in std_logic_vector(31 downto 0);
            register_reference_wb : in std_logic_vector (4 downto 0);
            write_register : in std_logic;
            pc_next : in integer range 0 to RAM_SIZE - 1;
            instruction_decoded : out std_logic_vector(5 downto 0);
            immediate_data_1 : out std_logic_vector(31 downto 0);
            immediate_data_2 : out std_logic_vector(31 downto 0);
            immediate_data_3 : out std_logic_vector(31 downto 0);
            register_reference : out std_logic_vector (4 downto 0);
            jump_target : out integer range 0 to RAM_SIZE - 1;
            valid_jump_target : out std_logic;
            regwritetotext : in std_logic;
            id_stall : in std_logic
        );
    end component;
    component EX_stage is
        port (
            clock : in std_logic;
            current_instruction : in std_logic_vector(5 downto 0);
            immediate_data_1 : in std_logic_vector(31 downto 0);
            immediate_data_2 : in std_logic_vector(31 downto 0);
            immediate_data_3 : in std_logic_vector(31 downto 0);
            register_reference_current : in std_logic_vector (4 downto 0);
            instruction_next_stage : out std_logic_vector(5 downto 0);
            immediate_data_ex_out : out std_logic_vector(31 downto 0);
            immediate_data_ex_out_2 : out std_logic_vector(31 downto 0);
            register_reference_next_stage : out std_logic_vector (4 downto 0)
        );
    end component;
    component MEM_stage is
        port (
            clock : in std_logic;
            current_instruction : in std_logic_vector(5 downto 0);
            immediate_data_mem_in : in std_logic_vector(31 downto 0);
            immediate_data_mem_in_2 : in std_logic_vector(31 downto 0);
            register_reference_current : in std_logic_vector (4 downto 0);
            instruction_next_stage : out std_logic_vector(5 downto 0);
            immediate_data_mem_out : out std_logic_vector(31 downto 0);
            register_reference_next_stage : out std_logic_vector (4 downto 0);
            memwritetotext : in std_logic
        );
    end component;
    component WB_stage is
        port (
            clock : in std_logic;
            current_instruction : in std_logic_vector(5 downto 0);
            immediate_data_mem_in : in std_logic_vector(31 downto 0);
            register_reference_current : in std_logic_vector (4 downto 0);
            immediate_data_wb : out std_logic_vector(31 downto 0);
            register_reference_wb : out std_logic_vector (4 downto 0);
            write_register : out std_logic
        );
    end component;

    signal clock : std_logic := '0';
    signal clock_period : time := 1 ns;
    --interstage signals
    signal IF_ID_instruction_data : std_logic_vector(31 downto 0);
    signal IF_ID_pc_next : integer range 0 to RAM_SIZE - 1;
    signal ID_IF_jump_target : integer range 0 to RAM_SIZE - 1;
    signal ID_IF_valid_jump_target : std_logic;
    signal ID_EX_instruction : std_logic_vector(5 downto 0);
    signal ID_EX_immediate_data_1 : std_logic_vector(31 downto 0);
    signal ID_EX_immediate_data_2 : std_logic_vector(31 downto 0);
    signal ID_EX_immediate_data_3 : std_logic_vector(31 downto 0);
    signal ID_EX_register_reference : std_logic_vector (4 downto 0);
    signal EX_MEM_instruction : std_logic_vector(5 downto 0);
    signal EX_MEM_immediate_data : std_logic_vector(31 downto 0);
    signal EX_MEM_immediate_data_2 : std_logic_vector(31 downto 0);
    signal EX_MEM_register_reference : std_logic_vector (4 downto 0);
    signal MEM_WB_instruction : std_logic_vector(5 downto 0);
    signal MEM_WB_immediate_data : std_logic_vector(31 downto 0);
    signal MEM_WB_register_reference : std_logic_vector (4 downto 0);
    signal WB_ID_immediate_data : std_logic_vector(31 downto 0);
    signal WB_ID_register_reference : std_logic_vector (4 downto 0);
    signal WB_ID_write_register : std_logic;
    signal ground : std_logic := '0';
    --stalling signals
    signal stall : std_logic := '0';
    --BTW:to monitor a signal from a component:
    -->expose it as an output of the component
    -->add a reference signal here
    -->map the output to the reference in the port map of the component in this file
    -->add the reference signal to the wave in the tcl file in the AddWave function
begin
    pm_if : IF_stage
    port map(
        clock => clock,
        jump_target => ID_IF_jump_target,
        valid_jump_target => ID_IF_valid_jump_target,
        instruction_data => IF_ID_instruction_data,
        pc_next => IF_ID_pc_next,
        if_stall => stall
    );
    pm_id : ID_stage
    port map(
        clock => clock,
        instruction_data => IF_ID_instruction_data,
        immediate_data_wb => WB_ID_immediate_data,
        register_reference_wb => WB_ID_register_reference,
        write_register => WB_ID_write_register,
        pc_next => IF_ID_pc_next,
        instruction_decoded => ID_EX_instruction,
        immediate_data_1 => ID_EX_immediate_data_1,
        immediate_data_2 => ID_EX_immediate_data_2,
        immediate_data_3 => ID_EX_immediate_data_3,
        register_reference => ID_EX_register_reference,
        jump_target => ID_IF_jump_target,
        valid_jump_target => ID_IF_valid_jump_target,
        regwritetotext => ground,
        id_stall => stall
    );
    pm_ex : EX_stage
    port map(
        clock => clock,
        current_instruction => ID_EX_instruction,
        immediate_data_1 => ID_EX_immediate_data_1,
        immediate_data_2 => ID_EX_immediate_data_2,
        immediate_data_3 => ID_EX_immediate_data_3,
        register_reference_current => ID_EX_register_reference,
        instruction_next_stage => EX_MEM_instruction,
        immediate_data_ex_out => EX_MEM_immediate_data,
        immediate_data_ex_out_2 => EX_MEM_immediate_data_2,
        register_reference_next_stage => EX_MEM_register_reference
    );
    pm_mem : MEM_stage
    port map(
        clock => clock,
        current_instruction => EX_MEM_instruction,
        immediate_data_mem_in => EX_MEM_immediate_data,
        immediate_data_mem_in_2 => EX_MEM_immediate_data_2,
        register_reference_current => EX_MEM_register_reference,
        instruction_next_stage => MEM_WB_instruction,
        immediate_data_mem_out => MEM_WB_immediate_data,
        register_reference_next_stage => MEM_WB_register_reference,
        memwritetotext => ground
    );
    pm_wb : WB_stage
    port map(
        clock => clock,
        current_instruction => MEM_WB_instruction,
        immediate_data_mem_in => MEM_WB_immediate_data,
        register_reference_current => MEM_WB_register_reference,
        immediate_data_wb => WB_ID_immediate_data,
        register_reference_wb => WB_ID_register_reference,
        write_register => WB_ID_write_register
    );

    clock_process : process
    --variables for the registers in ID
    variable rs : std_logic_vector(4 downto 0);
    variable rt : std_logic_vector(4 downto 0);
    variable rd : std_logic_vector(4 downto 0);
    begin
        --TODO remove. Keep only while testing
        --simulate clock
        clock <= '0';
        rs := IF_ID_instruction_data(25 downto 21);
        rt := IF_ID_instruction_data(20 downto 16);
        rd := IF_ID_instruction_data(15 downto 11);
        --if register op, check rs, rt, rd in EX, MEM, and WB stage for hazard excluding jump
        if ((IF_ID_instruction_data(31 downto 26) = "000000" )and (IF_ID_instruction_data(5 downto 0) /= "001000" )) then
            if ((rs = ID_EX_register_reference) or (rt = ID_EX_register_reference) or (rd = ID_EX_register_reference) or
            (rs = EX_MEM_register_reference) or (rt = EX_MEM_register_reference) or (rd = EX_MEM_register_reference) or
            (rs = MEM_WB_register_reference) or (rs = MEM_WB_register_reference) or (rd = MEM_WB_register_reference) or (rs = WB_ID_register_reference)
            or (rt = WB_ID_register_reference) or (rd = WB_ID_register_reference)) and (rs /= "00000") then
                stall <= '1';
            else
                stall <= '0';
            end if;
        -- if immediate op not including jumps
        elsif (IF_ID_instruction_data(31 downto 26) /= "000010") and (IF_ID_instruction_data(31 downto 26) /= "000011") then
            if ((rs = ID_EX_register_reference) or (rt = ID_EX_register_reference) or
            (rs = EX_MEM_register_reference) or (rt = EX_MEM_register_reference) or
            (rs = MEM_WB_register_reference) or (rs = MEM_WB_register_reference) or (rs = WB_ID_register_reference) or (rt = WB_ID_register_reference)) and (rs /= "00000") then
                stall <= '1';
            else
                stall <= '0';
            end if;
        end if;
        wait for clock_period/2;
        clock <= '1';
        stall <='0';
        wait for clock_period/2;
        
    end process;

    write_reg : process
    begin
        wait for 12 ns;
        ground <= '1';
        wait for clock_period/2;
        ground <= '0';
        wait;
    end process;

    -- stall_process : process
    -- --variables for the registers in ID
    -- variable rs : std_logic_vector(4 downto 0);
    -- variable rt : std_logic_vector(4 downto 0);
    -- variable rd : std_logic_vector(4 downto 0);
    -- begin
    --     --sign
    --     if (rising_edge(clock)) then
    --         rs := IF_ID_instruction_data(25 downto 21);
    --         rt := IF_ID_instruction_data(20 downto 16);
    --         rd := IF_ID_instruction_data(15 downto 11);
    --         --if register op, check rs, rt, rd in EX, MEM, and WB stage for hazard excluding jump
    --         if ((IF_ID_instruction_data(31 downto 26) = "000000" )and (IF_ID_instruction_data(5 downto 0) /= "001000" )) then
    --             if ((rs = ID_EX_register_reference) or (rt = ID_EX_register_reference) or (rd = ID_EX_register_reference) or
    --             (rs = EX_MEM_register_reference) or (rt = EX_MEM_register_reference) or (rd = EX_MEM_register_reference) or
    --             (rs = MEM_WB_register_reference) or (rs = MEM_WB_register_reference) or (rd = MEM_WB_register_reference)) and (rs /= "00000") then
    --                 stall <= '1';
    --                 -- IF_ID_instruction_data <= "00000000000000000000000000100000";
    --             else
    --                 stall <= '0';
    --             end if;
    --         --if immediate op not including jumps
    --         elsif (IF_ID_instruction_data(31 downto 26) /= "000010") and (IF_ID_instruction_data(31 downto 26) /= "000011") then
    --             if ((rs = ID_EX_register_reference) or (rt = ID_EX_register_reference) or
    --             (rs = EX_MEM_register_reference) or (rt = EX_MEM_register_reference) or
    --             (rs = MEM_WB_register_reference) or (rs = MEM_WB_register_reference)) and (rs /= "00000") then
    --                 stall <= '1';
    --                 -- IF_ID_instruction_data <= "00000000000000000000000000100000";
    --             else
    --                 stall <= '0';
    --             end if;
    --         end if;
    --     end if;
    -- end process;
end;
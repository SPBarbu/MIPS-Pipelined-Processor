LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY pipelined_processor IS
    GENERIC (RAM_SIZE : INTEGER := 32768);
END pipelined_processor;

ARCHITECTURE behavior OF pipelined_processor IS
    COMPONENT IF_stage IS
        PORT (
            clock : IN STD_LOGIC;
            jump_target : IN INTEGER RANGE 0 TO RAM_SIZE - 1;
            valid_jump_target : IN STD_LOGIC;
            instruction_data : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            pc_next : OUT INTEGER RANGE 0 TO RAM_SIZE - 1;
            if_stall : IN STD_LOGIC
        );
    END COMPONENT;
    COMPONENT ID_stage IS
        PORT (
            clock : IN STD_LOGIC;
            instruction_data : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            immediate_data_wb : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            register_reference_wb : IN STD_LOGIC_VECTOR (4 DOWNTO 0);
            write_register : IN STD_LOGIC;
            pc_next : IN INTEGER RANGE 0 TO RAM_SIZE - 1;
            instruction_decoded : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
            immediate_data_1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            immediate_data_2 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            immediate_data_3 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            register_reference : OUT STD_LOGIC_VECTOR (4 DOWNTO 0);
            jump_target : OUT INTEGER RANGE 0 TO RAM_SIZE - 1;
            valid_jump_target : OUT STD_LOGIC;
            regwritetotext : IN STD_LOGIC;
            id_stall : IN STD_LOGIC
        );
    END COMPONENT;
    COMPONENT EX_stage IS
        PORT (
            clock : IN STD_LOGIC;
            current_instruction : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
            immediate_data_1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            immediate_data_2 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            immediate_data_3 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            register_reference_current : IN STD_LOGIC_VECTOR (4 DOWNTO 0);
            instruction_next_stage : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
            immediate_data_ex_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            immediate_data_ex_out_2 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            register_reference_next_stage : OUT STD_LOGIC_VECTOR (4 DOWNTO 0)
        );
    END COMPONENT;
    COMPONENT MEM_stage IS
        PORT (
            clock : IN STD_LOGIC;
            current_instruction : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
            immediate_data_mem_in : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            immediate_data_mem_in_2 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            register_reference_current : IN STD_LOGIC_VECTOR (4 DOWNTO 0);
            instruction_next_stage : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
            immediate_data_mem_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            register_reference_next_stage : OUT STD_LOGIC_VECTOR (4 DOWNTO 0);
            memwritetotext : IN STD_LOGIC
        );
    END COMPONENT;
    COMPONENT WB_stage IS
        PORT (
            clock : IN STD_LOGIC;
            current_instruction : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
            immediate_data_mem_in : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            register_reference_current : IN STD_LOGIC_VECTOR (4 DOWNTO 0);
            immediate_data_wb : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            register_reference_wb : OUT STD_LOGIC_VECTOR (4 DOWNTO 0);
            write_register : OUT STD_LOGIC
        );
    END COMPONENT;

    SIGNAL clock : STD_LOGIC := '0';
    SIGNAL clock_period : TIME := 1 ns;
    --interstage signals
    SIGNAL IF_ID_instruction_data : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL IF_ID_pc_next : INTEGER RANGE 0 TO RAM_SIZE - 1;
    SIGNAL ID_IF_jump_target : INTEGER RANGE 0 TO RAM_SIZE - 1;
    SIGNAL ID_IF_valid_jump_target : STD_LOGIC;
    SIGNAL ID_EX_instruction : STD_LOGIC_VECTOR(5 DOWNTO 0);
    SIGNAL ID_EX_immediate_data_1 : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL ID_EX_immediate_data_2 : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL ID_EX_immediate_data_3 : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL ID_EX_register_reference : STD_LOGIC_VECTOR (4 DOWNTO 0);
    SIGNAL EX_MEM_instruction : STD_LOGIC_VECTOR(5 DOWNTO 0);
    SIGNAL EX_MEM_immediate_data : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL EX_MEM_immediate_data_2 : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL EX_MEM_register_reference : STD_LOGIC_VECTOR (4 DOWNTO 0);
    SIGNAL MEM_WB_instruction : STD_LOGIC_VECTOR(5 DOWNTO 0);
    SIGNAL MEM_WB_immediate_data : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL MEM_WB_register_reference : STD_LOGIC_VECTOR (4 DOWNTO 0);
    SIGNAL WB_ID_immediate_data : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL WB_ID_register_reference : STD_LOGIC_VECTOR (4 DOWNTO 0);
    SIGNAL WB_ID_write_register : STD_LOGIC;
    SIGNAL ground : STD_LOGIC := '0';
    --stalling signals
    SIGNAL stall : STD_LOGIC := '0';
    --BTW:to monitor a signal from a component:
    -->expose it as an output of the component
    -->add a reference signal here
    -->map the output to the reference in the port map of the component in this file
    -->add the reference signal to the wave in the tcl file in the AddWave function
BEGIN
    pm_if : IF_stage
    PORT MAP(
        clock => clock,
        jump_target => ID_IF_jump_target,
        valid_jump_target => ID_IF_valid_jump_target,
        instruction_data => IF_ID_instruction_data,
        pc_next => IF_ID_pc_next,
        if_stall => stall
    );
    pm_id : ID_stage
    PORT MAP(
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
    PORT MAP(
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
    PORT MAP(
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
    PORT MAP(
        clock => clock,
        current_instruction => MEM_WB_instruction,
        immediate_data_mem_in => MEM_WB_immediate_data,
        register_reference_current => MEM_WB_register_reference,
        immediate_data_wb => WB_ID_immediate_data,
        register_reference_wb => WB_ID_register_reference,
        write_register => WB_ID_write_register
    );

    clock_process : PROCESS
        --variables for the registers in ID
        VARIABLE rs : STD_LOGIC_VECTOR(4 DOWNTO 0);
        VARIABLE rt : STD_LOGIC_VECTOR(4 DOWNTO 0);
        VARIABLE rd : STD_LOGIC_VECTOR(4 DOWNTO 0);
    BEGIN
        --simulate clock
        clock <= '0';

        --LOGIC FOR HAZARD DETECTION
        --set rs, rt, rd to the current instruction fetched by ID
        rs := IF_ID_instruction_data(25 DOWNTO 21);
        rt := IF_ID_instruction_data(20 DOWNTO 16);
        rd := IF_ID_instruction_data(15 DOWNTO 11);
        --if register op, check rs, rt, rd in EX, MEM, and WB stage for hazard excluding jump, mult, div and shifts
        IF ((IF_ID_instruction_data(31 DOWNTO 26) = "000000") AND (IF_ID_instruction_data(5 DOWNTO 0) /= "001000") AND ((IF_ID_instruction_data(5 DOWNTO 0) /= "011000") AND (IF_ID_instruction_data(5 DOWNTO 0) /= "011010"
            AND (IF_ID_instruction_data(5 DOWNTO 0) /= "000000") AND (IF_ID_instruction_data(5 DOWNTO 0) /= "000010") AND (IF_ID_instruction_data(5 DOWNTO 0) /= "000011")))) THEN
            --check rs, rt, rd, in EX, MEM, and WB
            IF ((rs = ID_EX_register_reference) OR (rt = ID_EX_register_reference) OR (rd = ID_EX_register_reference) OR
                (rs = EX_MEM_register_reference) OR (rt = EX_MEM_register_reference) OR (rd = EX_MEM_register_reference) OR
                (rs = MEM_WB_register_reference) OR (rt = MEM_WB_register_reference) OR (rd = MEM_WB_register_reference) OR (rs = WB_ID_register_reference)
                OR (rt = WB_ID_register_reference) OR (rd = WB_ID_register_reference)) AND (rs /= "00000") THEN
                stall <= '1';
            ELSE
                stall <= '0';
            END IF;
            --shifts, check only rt, rd in EX, MEM, and WB
        ELSIF (IF_ID_instruction_data(31 DOWNTO 26) = "000000") AND ((IF_ID_instruction_data(5 DOWNTO 0) = "000000") OR (IF_ID_instruction_data(5 DOWNTO 0) = "000010") OR (IF_ID_instruction_data(5 DOWNTO 0) = "000011")) THEN
            IF ((rt = ID_EX_register_reference) OR (rd = ID_EX_register_reference) OR
                (rt = EX_MEM_register_reference) OR (rd = EX_MEM_register_reference) OR
                (rt = MEM_WB_register_reference) OR (rd = MEM_WB_register_reference)
                OR (rt = WB_ID_register_reference) OR (rd = WB_ID_register_reference)) THEN
                stall <= '1';
            ELSE
                stall <= '0';
            END IF;
            -- if immediate op not including jumps
        ELSIF (IF_ID_instruction_data(31 DOWNTO 26) /= "000010") AND (IF_ID_instruction_data(31 DOWNTO 26) /= "000011") THEN
            --lui is special, dont check rs
            IF (IF_ID_instruction_data(31 DOWNTO 26) = "001111") THEN
                IF ((rt = ID_EX_register_reference) OR (rt = EX_MEM_register_reference) OR
                    (rt = MEM_WB_register_reference) OR (rt = WB_ID_register_reference)) THEN
                    stall <= '1';
                ELSE
                    stall <= '0';
                END IF;
                --for the rest, check rs, rt in EX, MEM, and WB
            ELSIF ((rs = ID_EX_register_reference) OR (rt = ID_EX_register_reference) OR
                (rs = EX_MEM_register_reference) OR (rt = EX_MEM_register_reference) OR
                (rs = MEM_WB_register_reference) OR (rt = MEM_WB_register_reference) OR (rs = WB_ID_register_reference) OR (rt = WB_ID_register_reference)) AND (rs /= "00000") THEN
                stall <= '1';
            ELSE
                stall <= '0';
            END IF;
        END IF;
        WAIT FOR clock_period/2;
        clock <= '1';
        stall <= '0';
        WAIT FOR clock_period/2;

    END PROCESS;

    --process for writing back to memory.txt and registers.txt
    --memwritetotext and regwritetotext are wired to ground, set it to 1 for write to file
    write_reg : PROCESS
    BEGIN
        WAIT FOR 999999 ns;
        ground <= '1';
        WAIT FOR clock_period;
        ground <= '0';
        WAIT;
    END PROCESS;
END;
add $0, $0, $0
sub $0, $0, $0
addi $0, $0, 0
mult $0, $0
div $0, $0
slt $0, $0, $0
slti $0, $0, 0
and $0, $0, $0
or $0, $0, $0
nor $0, $0, $0
xor $0, $0, $0
andi $0, $0, 0
ori $0, $0, 0
xori $0, $0, 0
mfhi $0
mflo $0
lui $0, 0
sll $0, $0, $0
srl $0, $0, $0
sra $0, $0, $0
lw $0, 0($0)
sw $0, 0($0)
test: beq $0, $0, test
bne $0, $0, test
j test
jr $0
jal test
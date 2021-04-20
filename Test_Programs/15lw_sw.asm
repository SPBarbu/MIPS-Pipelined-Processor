addi $1, $1, 1
addi $2, $2, 4
sw $1, 0($2)
lw $3, 0($2)
EoP: beq $0, $0, EoP
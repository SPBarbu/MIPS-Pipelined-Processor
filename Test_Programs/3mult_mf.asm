addi $1, $1, 1
addi $2, $2, 2
mult $1, $2
mflo $12
mult $1, $2
mfhi $13
EoP: beq $0, $0, EoP
addi $1, $1, 1
addi $2, $2, 2
div $2, $1
mflo $12
div $2, $1
mfhi $13
EoP: beq $0, $0, EoP
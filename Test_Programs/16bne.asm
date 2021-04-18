addi $1, $1, 2
addi $2, $2, 1
test: sub $1, $1, $2
EoP: beq $0, $0, EoP
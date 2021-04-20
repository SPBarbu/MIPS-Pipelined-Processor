addi $1, $1, 2
addi $2, $2, 1
test: sub $1, $1, $2
add $0, $0, $0
add $0, $0, $0
add $0, $0, $0
add $0, $0, $0
add $0, $0, $0
bne $0, $1, test
EoP: beq $0, $0, EoP
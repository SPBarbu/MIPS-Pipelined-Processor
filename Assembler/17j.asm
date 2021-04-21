#modified from https://stackoverflow.com/questions/4206363/the-functions-procedures-in-mips
#we need some way to store program counter or remember last position with a register????
#not entirely sure how to put something effective for ra, using r0 containing address 0x0 as placeholder

addi $1, $1, 1
addi $2, $2, 3
jal procedure # call procedure
EoP: beq $0, $0, EoP

procedure: sub $1, $1, $1
jr $2 # return
addi $4, $4, 1
# Marcel Jarosz, ARKO 2020L, Final version
# EAN-13 Barcode Generator
# Input: In the .data section
# Output: barcode.bmp
.data
	# BMP file header for monochromatic 856 x 360 image
	header: .byte 0x42 0x4D 0xBE 0x70 0x00 0x00 0x00 0x00 0x00 0x00 0x3E 0x00 0x00 0x00 0x28 0x00 0x00 0x00 0x58 0x03 0x00 0x00 0x68 0x01 0x00 0x00 0x01 0x00 0x01 0x00 0x00 0x00 0x00 0x00 0x80 0x70 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0xFF 0xFF 0xFF 0x00
	# Byte arrays for fast margins creation
	mover: .byte 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 
	start_stop: .byte 0x00 0xFF 0x00
	middle_chk: .byte 0xFF 0x00 0xFF 0x00 0xFF
	white_chunk: .byte 0xFF
	long_white_chunk: .byte 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 
	mid_size_white_chunk: .byte 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF
	# Name of the output file
	bmp_file: .asciiz "barcode.bmp"
	# Input
	input: .asciiz "590227720655"									# change here for different barcode
	# Hardcoded data required to create the barcode
	encoding: .asciiz "AAAAAAAABABBAABBABAABBBAABAABBABBAABABBBAAABABABABABBAABBABA"
	c_code: .asciiz "1110010110011011011001000010101110010011101010000100010010010001110100"	# a and b codes can be defined using a c code
	# String to confirm correct binary conversion
	msg: .asciiz "\nDone! "
	# Result array
	result: .space 256
	# Lookup table for fast binary to color conversion
	lookup: .byte 0xFF 0x00

# Performs multiplication by 7 using logical shifting
# Args: 	%out - data to multiply
#		%temp - temp data holder
# Result:	% out - result of the multiplication
.macro mul7(%out, %temp)
move %temp, %out
sll %out, %out, 3		# changed multiplication for logical shift
subu %out, %out, %temp		# finalizing %out*=7 multiplication
.end_macro	

# Performs multiplication by 3 using logical shifting
# Args: 	%out - data to multiply
#		%temp - temp data holder
# Result:	% out - result of the multiplication
.macro mul3(%out, %temp)
move %temp, %out
sll %out, %out, 2		# changed multiplication for logical shift
subu %out, %out, %temp		# finalizing %out*=3 multiplication
.end_macro	
			
.text
# MAIN PROGRAM
# the program does not work with wrong input
main:
	la $t0, input
	li $t1, 1	# iterator
	li $t2, 0	# sum

data_preparation:
	jal creating_control_digit	# generating control digit
	jal get_sequence_type		# setting pointers for correct sequence type
	
creating_binary_barcode_stripes_representation:	# As the most important part of the program, this element will not be moved down to FUNCTIONS
	build_result:
		# t0 iterates through input
		# t1 lbu for input
		# t2 iterates through types
		# t3 lbu for types
		# t4 iterates through result
		# t5 iterator through type
		# t6 iterator for bin length
		# t7 iterates through binary definitions
		li $t5, 0
		la $t4, result
		li $s2, '0'		# const 0 for easy usage
		li $s3, '1'		# const 1 for easy usage
		jal adding_pre_post_stripes
		type_and_input_iter:
			beq $t5, 6, middle_checkpoint
			bgt $t5, 6, c_addition
			lbu $t1, 0($t0)
			addi $t1, $t1, -48
			lbu $t3, 0($t2)
			li $t6, 0
			beq $t3, 'A', a_type
			beq $t3, 'B', b_type
			beq $t3, 'C', c_type
			j type_and_input_iter
		a_type:				# changing c_code to a_code and saving it	
			mul7 $t1, $t9
			la $t7, c_code($t1)
			addi $t5, $t5, 1
			addi $t0, $t0, 1
			addi $t2, $t2, 1
			iter_a:
				beq $t6, 7, type_and_input_iter
				lbu $s0, 0($t7)
				beq $s0, '0', zero_iter_a	# 
				beq $s0, '1', one_iter_a
				j iter_a
			zero_iter_a:		
				addi $s0, $s0, 1
				j iters_increase_and_save
			one_iter_a:
				addi $s0, $s0, -1
			iters_increase_and_save:
				sb $s0, ($t4)
				addi $t4, $t4, 1
				addi $t7, $t7, 1
				addi $t6, $t6, 1
				j iter_a
			
		b_type:				# changing c_code to b_code and saving it
			mul7 $t1, $t9
			li $t6, 0
			addi $t1, $t1, 6
			addi $t5, $t5, 1
			addi $t0, $t0, 1
			addi $t2, $t2, 1
			la $t7, c_code($t1)
			iter_b:
				beq $t6, 7, type_and_input_iter
				lbu $s0, 0($t7)
				sb $s0, ($t4)
				addi $t4, $t4, 1
				sub $t7, $t7, 1
				addi $t6, $t6, 1
				j iter_b
		c_type:				# adding c_code
			mul7 $t1, $t9
			la $t7, c_code($t1)
			addi $t5, $t5, 1
			addi $t0, $t0, 1
			addi $t2, $t2, 1
			iter_c:
				beq $t6, 7, type_and_input_iter
				lbu $s0, 0($t7)
				sb $s0, ($t4)
				addi $t4, $t4, 1
				addi $t7, $t7, 1
				addi $t6, $t6, 1
				j iter_c

		middle_checkpoint:
			sb $s2, 0($t4)
			sb $s3, 1($t4)
			sb $s2, 2($t4)
			sb $s3, 3($t4)
			sb $s2, 4($t4)
			addi $t4, $t4, 5

		c_addition:			# right half is always c_code only
			lbu $t1, 0($t0)
			addi $t1, $t1, -48	# char to int conversion
			li $t6, 0
			blt $t5, 12, c_type

		jal adding_pre_post_stripes
printing_result:		
	jal print_binary_result		# prints binary representation of the barcode
	
preparing_to_save_the_data:	
	jal prepare_to_save
	jal opening_the_file_and_saving_the_header
	
saving_to_file:
	jal saving_down_margin_and_extended_checkpoints		
	jal reset_temps
	jal saving_the_bars
	jal saving_upper_margin
	
the_end:
	li $v0, 16		# closing the file
	syscall
	li $v0, 10		# exiting
	syscall
	
# FUNCTIONS
creating_control_digit:
	get_control_digit:
		lbu $t3, 0($t0)
		ble $t3, ' ', put_control_digit		# checks whether the string has ended
		beq $t1, 1, odd				# $t1 informs whether number is odd or even one in the sequence
		addi $t3, $t3, -48			# changes character to digit
		mul3 $t3, $t9
		add $t2, $t2, $t3
		addi $t1, $t1, 1
		addi $t0, $t0, 1
		j get_control_digit
	odd:
		addi $t3, $t3, -48
		add $t2, $t2, $t3
		sub $t1, $t1, 1		
		addi $t0, $t0, 1
		j get_control_digit
	
	put_control_digit:
		subu $t2, $zero, $t2	# negates the number
		div $t2, $t2, 10	
		mfhi $t2		# gets mod10 from a number
		beq $t2, 10, skip
		addi $t2, $t2, 10
	skip:
		addi $t2, $t2, 48	# int to char conversion
		sb $t2, ($t0)		# stores the control digit at the end of the input code
		jr $ra			# returns
	
get_sequence_type:
	la $t0, input
	li $t1, 0
	lbu $t3, 0($t0)
	addi $t3, $t3, -48
	mulo $t3, $t3, 6		# changing this multiplication for logical shifts will not result in better performance
	la $t2, encoding($t3) 		# t2 is pointing on the beggining of the type data $t1 remains as an iterator
	addi $t0, $t0, 1
	jr $ra	

print_binary_result:
	li $v0, 4
	la $a0, msg			# printing "Done"
	syscall
	li $v0, 4
	la $a0, result			# printing result in binary
	syscall
	jr $ra
	
adding_pre_post_stripes:		# adding required first 3 stripes
	sb $s3, 0($t4)
	sb $s2, 1($t4)
	sb $s3, 2($t4)
	addi $t4, $t4, 3
	jr $ra

prepare_to_save:
	reserve_space:
		li $v0, 9	# reserves space on a stack
		li $a0, 10000	# size of the stack
		syscall
		move $s5, $v0 	# pointing on the first element of the stack
		move $t1, $s5	# temporary stack pointer
		la $t0, result
		
	save_data_to_heap:
		lbu $t2, 0($t0)
		ble $t2, ' ', save_data
		addi $t2, $t2, -48	# changing char to int
		lb $t2, lookup($t2)	# getting correct color from lookup table 0x00 for black and 0xFF for white
		sb $t2, ($t1)		# storing byte on heap
		addi $t1, $t1, 1
		addi $t0, $t0, 1
		j save_data_to_heap
	save_data:
		jr $ra
		
opening_the_file_and_saving_the_header:
	li 	$v0, 13				# open file to which barcode will be saved
	la 	$a0, bmp_file			# name of file
	li 	$a1, 1				# flag
	la 	$a2, 0				# mode
	syscall
	move 	$s0, $v0
	li	$v0, 15				# save bmp header to file
	move	$a0, $s0			# descriptor
	la	$a1, header			# start of data
	li	$a2, 62				# data length
	syscall		
	li $t4, 0
	jr $ra
	
saving_down_margin_and_extended_checkpoints:
	main_loop:
		ble $t4, 20, white_loop
		bge $t4, 40, barcode
		left_margin:
			li	$v0, 15				# saving empty left margin
			la	$a1, mover			
			li	$a2, 6				# data length
			syscall
			li	$v0, 15				# saving extended margin stripes to file
			la	$a1, start_stop			
			li	$a2, 3				# data length
			syscall
			li $t5, 0
		inside_pre_loop:
			li	$v0, 15				# saving empty left middle part
			la	$a1, long_white_chunk			
			li	$a2, 42				# data length
			syscall
		middle_checkpoint_add:
			li $t5, 0
			li	$v0, 15				# saving extended middle stripes
			la	$a1, middle_chk			
			li	$a2, 5				
			syscall
		inside_pre_loop_2:
			li	$v0, 15				# saving empty right middle part
			la	$a1, long_white_chunk			
			li	$a2, 42				# data length
			syscall
		right_margin:
			li	$v0, 15				# saving extended margin stripes to file
			la	$a1, start_stop			
			li	$a2, 3				# data length
			syscall
			li	$v0, 15				# saving empty right margin 
			la	$a1, mover			
			li	$a2, 7				# data length
			syscall	
		return_up:
			addi $t4, $t4, 1
			j main_loop
	white_loop:
		li $t5, 0 				# till 107
		inside_white_loop:
			beq $t5, 4, return_up
			li	$v0, 15				# saving empty blank space on on the bottom
			la	$a1, mid_size_white_chunk			
			li	$a2, 27				# data length
			addi $t5, $t5, 1			
			syscall
			j inside_white_loop
	barcode:
		jr $ra

reset_temps:	
	li $t4, 0
	li $t6, 0
	jr $ra
	
saving_the_bars:
	loop:
		bge $t4, 300, after_loop
		li	$v0, 15				# saving left margin
		la	$a1, mover			
		li	$a2, 6				# data length
		syscall
		li	$v0, 15	
		la	$a1, ($s5)			# binary stripes data
		li	$a2, 95				# data length
		syscall
		li	$v0, 15				# saving right margin
		la	$a1, mover			
		li	$a2, 7				# data length
		syscall
		addi $t4, $t4, 1
		j loop
	after_loop:
		jr $ra
		
saving_upper_margin:
	post_loop:
		beq $t6, 200, close
		addi $t6, $t6, 1
		li $t5, 0 				# till 107
		inside_post_loop:
			beq $t5, 107, post_loop
			li	$v0, 15				# saving empty space above barcode for better readability
			la	$a1, white_chunk			
			li	$a2, 1				# data length
			addi $t5, $t5, 1			
			syscall
			j inside_post_loop
	close:
		jr $ra

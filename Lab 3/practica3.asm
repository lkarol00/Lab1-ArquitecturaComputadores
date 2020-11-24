.data
	cadena: 	.space 	40
	file_in:	.asciiz "source.txt"
	file_out:	.asciiz "result.txt"
	msg: 		.asciiz "Ingrese la cadena que desea contar: "
	msgAdv: 	.asciiz "La cadena que ha ingresado es vacía o tiene una longitud mayor a 40. Digítela nuevamente. "
	sentence:	.byte 	0x0A, 0x0D, 0x0A, 0x0D
	sentence_cont:	.asciiz "Número de veces de la cadena "
	
.align 2
	input_buffer:	.space 2000

.text
	addi $s5, $s5, 0	#Inicializar auxiliar para realizar LoopCadena
	addi $s6, $s6, 0	#Inicializar auxiliar para realizar LongitudCadena
	
# Open (for reading) a file
	li $v0, 13		# System call for open file
	la $a0, file_in		# Input file name
	li $a1, 0		# Open for reading (flag = 0)
	li $a2, 0		# Mode is ignored
	syscall			# Open a file (file descriptor returned in $v0)
	move $s0, $v0		# Copy file descriptor

# Open (for writing) a file that does not exist
	li $v0, 13		# System call for open file
	la $a0, file_out	# Input file name
	li $a1, 9		# Open for writing and appending (flag = 9)
	li $a2, 0		# Mode is ignored
	syscall			# Open a file (file descriptor returned in $v0)
	move $s1, $v0		# Copy file descriptor

# Read from previously opened file
	li $v0, 14		# System call for reading from file
	move $a0, $s0		# File descriptor
	la $a1, input_buffer	# Address of input buffer
	li $a2, 20000		# Maximum number of characters to read
	syscall			# Read from file
	jal LoopCadena

WriteFile:
	move $s4, $ra		# Almacenar valor de la instrucción que llamó al método
	
	# Añadir frase a un archivo
	li $v0, 15		# System call for write to a file
	move $a0, $s1		# Restore file descriptor (open for writing)
	la $a1, sentence	# Address of buffer from which to write
	li $a2, 33		# Number of characters to write
	syscall			# write to file
	
	la $a1, cadena		# Dirección cadena
	jal LongitudCadena	# Calcula la longitud de la cadena y lo almacena en $s6

	li $v0, 15		# System call for write to a file
	move $a0, $s1		# Restore file descriptor (open for writing)
	la $a1, cadena		# Address of buffer from which to write
	move $a2, $s6		# Number of characters to write
	syscall
	li $s6, 0		# Inicializar contador en 0
	
	jal NumeroABuffer	# El método convierte un número de dos dígitos en un buffer
	
	li   $v0, 15       	# system call for write to file
	move $a0, $s1      	# file descriptor 
	move $a1, $s3  		# address of buffer from which to write
	li   $a2, 4        	# Number of characters to write
	syscall            	
	
	jr $s4

LongitudCadena:
	lbu $t0, ($a1)
	bge $s6, 41, MensajeAdvertencia		# La cadena tiene longitud > 40
	addi $s6, $s6, 1			# Aumentar auxiliar que contiene la longitud
	addi $a1, $a1, 1	
		
	bne $t0, '\n', LongitudCadena		# Cuando $t0 no sea igual a '\n' volverá a llamar a la función
	beq $s6, 1, MensajeAdvertencia		# La cadena está vacía
	addi $s6, $s6, 1			# Se agrega 1 para crear un espacio entre el número y la cadena cuando se imprimen

	jr $ra
	
## Pasar de número a Buffer	

NumeroABuffer:
	li $v0, 9
	li $a0, 3		# Reservar 3 bytes para 3 caracteres
	syscall
	move $s3, $v0

	li $t0, 10		# $t0 = 10
	
	divu  $t6, $t0		# Se hace la división de $t6/$t0
	mfhi $t1		# De aquí se obtiene el divisor
	mflo $t2		# De aquí se obtiene el residuo

	addi $s3, $s3, 2    	# Apunta al final del buffer ya que se empieza desde el final de la línea
	li $t3, 10      	# Se comienza agregando un salto de línea \n
	sb $t3, 0($s3)		
	addi $s3, $s3, -1

	beq $t6, -1, TextoVacio	# Si $t6 = -1, el archivo está vacío
	addi $t3, $t1, 48	# El código ascii del 0 es el 48, por lo tanto, dependiendo del número
				# se va sumando a 48 para que acceda al número en código ascii
	sb $t3, 0($s3)		# Aquí se agrega el primer número de derecha a izquierda
	addi $s3, $s3, -1   	

	addi $t3, $t2, 48
	sb $t3, 0($s3)		# Aquí se agrega el segundo número
				
	jr $ra
	
TextoVacio:			# Cuando el texto es vacío, devuelve un valor de -1
	li $t3, 49		# El código ascii del 1 es 49
	sb $t3, 0($s3)		
	addi $s3, $s3, -1   	

	li $t3, 45		# El código ascii del - es 45
	sb $t3, 0($s3)		
				
	jr $ra
	
##############################################################
#	Proceso para contar las cadenas
##############################################################

LoopCadena:
	jal InputCadena
	li $s6, 0		# Inicializar contador en 0
	la $a0, input_buffer	# Dirección del texto
	la $a1, cadena		# Dirección de cadena
	
	jal Inicializar
	
	move $t6, $v0
	jal WriteFile
	
	addi $s5, $s5, 1
	beq $s5, 3, Exit
	
	b LoopCadena

InputCadena:
	li $v0, 4		# Imprimir mensaje de entrada
	la $a0, msg
	syscall
	
	li $v0, 8		
	la $a0, cadena		# Almacenar el valor ingresado en cadena
	la $a1, 40
	syscall
	
	la $a1, cadena		# Dirección cadena
	b LongitudCadena
	
	jr $ra

MensajeAdvertencia:
	li $v0, 4		# Imprimir mensaje de entrada
	la $a0, msgAdv
	syscall
	
	b InputCadena

Inicializar:
	li   $t0, -1		# Contador de la cadena del texto, es -1 cuando la cadena está vacía 
	move $t1, $a0		# a $t1 le asigna el valor almacenado el $a0
	move $t2, $a1		# a $t4 le asigna el valor almacenado el $a1
	lbu $t3, ($t1)
	beqz $t3, Fin		# $t3 = 0 significa que la cadena está vacía entonces lo redirecciona al final
	li $t0, 0		# iniciliza el contador de cadenas en 0
		
Bucle:	
	lbu $t3, ($t1)			# almacena una letra del texto
	lbu $t4, ($t2)			# almacena una letra de la cadena	
	beqz $t3, Fin			# si la letra es 0 en la cadena, lo redirecciona al final
	beq $t3, '\r', Avanzar		# cuando se da esta situación significa que hay un enter
	beq $t3, $t4, IndexSubCadena	# si las letras son iguales, se dirige a IndexSubCadena
	addi $t1, $t1, 1
	move $t2, $a1
	b Bucle
	
Avanzar:
	addi $t1, $t1, 2 		# Lo aumenta en dos para evitar el '\r' y el '\n'
	b Bucle

IndexSubCadena:	
	addi $t1, $t1, 1	# aumenta el index en la cadena
	addi $t2, $t2, 1	# aumenta el index en la subcadena
	lbu $t5, ($t2)		# almacena el valor siguiente
	beq $t5, '\n', Contador	# si la letra siguiente es igual a '\n'(indica el final de la cadena), llama a contador
	b Bucle

Contador:
	addi $t0, $t0, 1	# aumenta en 1 el contador de cadenas
	move $t2, $a1		# inicializa la dirección de la subcadena
	b Bucle

Fin: 	move $v0, $t0
	jr $ra
	
##############################################################
#	Fin proceso para contar cadenas 
##############################################################

Exit:	
	# Close the files
	li   $v0, 16       # system call for close file
	move $a0, $s0      # file descriptor to close
	syscall            # close file
	
	li   $v0, 16       # system call for close file
	move $a0, $s1      # file descriptor to close
	syscall            # close file

	li   $v0, 10		
	syscall

.text
.file	"input_output.s"
.intel_syntax noprefix

.section	.rodata
	#	функция void array_input(struct container *array, char *file_name)
	#	строковые литералы (константы), которые используются в array_input
.LC0:
	.string	"r"
	.align 8
.LC1:
	.string	"No enough memory for the array"
.LC2:
	.string	"%d"
	.text
	.globl	array_input
	.type	array_input, @function
	
array_input:						#	точка входа в функцию array_input
	#	ввод массива из файла
	#	пролог входа в функцию (сохраняем прежний rbp на стеке, задаем новые указатели на границы фрейма)
	push	rbp
	mov	rbp, rsp					#	начало фрейма rbp = rsp
	push rbx						#	сохраняем старое значение rbx
	push r12						#	сохраняем старое значение r12
	

	# сохраняем переданные через регистры rdi, rsi аргументы
	mov	rbx, rdi					#	сохраняет в rbx первый аргумент из rdi (struct container *array)
	mov	r12, rsi					#	сохраняет в r12 второй аргумент из rsi (char *file_name)
	
	mov	rax, QWORD PTR 8[rbx]		#	rax = array->capacity = *(array + 8)
	test	rax, rax
	jne	.L2							#	if (!array->capacity) then... else goto .L2

	#	"инициализируем" пустой container и для начала выделяем память под 20 элементов
	mov	QWORD PTR 8[rbx], 20		#	array->capacity = 20, (capacity = *(array + 8), rbx = array)
	mov	QWORD PTR [rbx], 0			#	array->len = 0, (len = *(array), rbx = array)
	mov	rdi, QWORD PTR 8[rbx]		#	rdi = array->capacity
	sal	rdi, 2						#	rdi = array->capacity * sizeof(int) - первый аргумент, (sizeof(int) = 4)					
	call	malloc@PLT				#	rax = malloc(array->capacity * sizeof(int))
	mov QWORD PTR 16[rbx], rax		#	16[rbx] = array->arr = malloc(array->capacity * sizeof(int))

.L2:	#	открываем файл для чтения
	lea	rsi, .LC0[rip]				#	rsi = "r" (указатель на строку) - второй аргумент
	mov	rdi, r12					#	rdi = file_name (из r12)- первый аргумент
	call	fopen@PLT				#	rax = fopen(rdi = file_name, rsi = "r")
	mov	r12, rax					#	r12 = istream = fopen(file_name, "r") (сохраняем в r12 новую переменную, file_name теряется)
	jmp	.L3

.L6:								#	тело цикла while (условие находится на метке .L3)
	mov	rdx, QWORD PTR [rbx]		#	rdx = array->len (rbx = array)
	mov	rax, QWORD PTR 8[rbx]		#	rax = array->capacity (8[rbx] = array->capacity)
	cmp	rdx, rax
	jne	.L4							#	if (array->len == array->capacity) then {...} else {goto .L4}

	#	выделяем больше места для массива с помощью realloc
	mov	rsi, QWORD PTR 8[rbx]		#	rsi = array->capacity (8[rbx] = array->capacity)
	sal rsi, 3						#	rsi = 8 * array->capacity = 2 * array->capacity * sizeof(int) - второй аргумент
	mov	rdi, QWORD PTR 16[rbx]		#	rdi = array->arr = 16[rbx] - первый аргумент
	call	realloc@PLT				#	rax = realloc(rdi, rsi) = realloc(array->arr, 2 * array->capacity * sizeof(int))
	mov	QWORD PTR 16[rbx], rax		#	16[rbx] = array->arr = rax

	#	проверяем, смогли ли мы выделить больше памяти
	mov	rax, QWORD PTR 16[rbx]		#	rax = array->arr (rbx = array)
	test	rax, rax
	jne	.L5				#	if (!array->arr) then {...} else {goto .L5}

	#	не смогли выделить память - заканчиваем программу
	mov	rdi, r12					#	rdi = istream = r12 - первый аргумент
	call	fclose@PLT				#	fclose(rdi = istream) - закрываем поток

	mov	rcx, QWORD PTR stderr[rip]	#	rcx = stderr - 4 аргумент
	mov	edx, 30						#	edx = 30 = len("No enough memory for the array") = кол-во выводимых объектов - третий аргумент
	mov	esi, 1						#	esi = 1 = sizeof(char) - второй аргумент
	lea	rdi, .LC1[rip]				#	rdi = "No enough memory for the array" (указатель на строку) - первый аргумент
	call	fwrite@PLT				#	fwrite("No enough memory for the array", 1, 30, stderr)
	mov	edi, 1
	call	exit@PLT				#	exit(1 = edi)

	#	смогли выделить память, тогда изменяем capacity
.L5:								#	if (array->arr)
	mov	rax, QWORD PTR 8[rbx]		#	rax = array->capacity, (rbx = array -> 8[rbx] = *(array + 8))
	sal rax, 1						#	rax = array->capacity * 2	
	mov	QWORD PTR 8[rbx], rax		#	8[rbx] = array->capacity = array->capacity * 2

	#	считываем следующий элемент массива с помощью fscanf
.L4:
	mov	rdx, QWORD PTR 16[rbx]		#	rdx = array->arr	(rbx = array -> 16[rbx] = *(array + 16) = array->arr)
	mov	rax, QWORD PTR [rbx]		#	rax = array->len
	sal	rax, 2						#	rax = 4 * rax = sizeof(int) * array->len

	add	rdx, rax					#	rdx = array->arr + sizeof(int) * array->len - третий аргумент
									#	это адрес array->arr[array->len] (в этот адрес будем записывать)
	lea	rsi, .LC2[rip]				#	rsi = "%d" (указатель на строку) - второй аргумент
	mov	rdi, r12					#	rdi = r12 = istream - первый аргумент
	mov	eax, 0
	call	__isoc99_fscanf@PLT		#	fscanf(istream, "%d", array->arr + array->len) = fscanf(rdi, rsi, rdx)

	#	++array->len;
	mov	rax, QWORD PTR [rbx]		#	rax = array->len
	lea	rdx, 1[rax]					#	rdx = rax + 1 = array->len + 1
	mov	QWORD PTR [rbx], rdx		#	[rbx] = array->len = rdx = array->len + 1

	#	условие продолжения цикла - пока не достигли конца файла
.L3:
	mov	rdi, r12					#	rdi = r12 = istream  -первый аргумент
	call	feof@PLT				#	feof(rdi = istream)
	test	eax, eax
	je	.L6							#	if feof(istream) == 0 (не достигнут конец файла)

	#	закрываем поток ввода
	mov	rdi, r12					#	rdi = istream - первый аргумент
	call	fclose@PLT				#	fclose(istream)
	nop

	pop r12							#	восстанавливаем r12
	pop rbx							#	восстанавливаем rbx
	pop rbp							#	восстанавливаем rbp
	ret								#	выход из функции
	.size	array_input, .-array_input


	.section	.rodata
	#	функция void array_output(struct container *array, char *file_name)
	#	строковые литералы (константы), которые используются в array_output
.LC3:
	.string	"w"
.LC4:
	.string	"%d "
	.text
	.globl	array_output
	.type	array_output, @function
array_output:						#	точка входа в функцию array_output
	#	вывод массива в файл

	#	пролог входа в функцию (сохраняем прежний rbp на стеке, задаем новые указатели на границы фрейма)
	push	rbp
	mov	rbp, rsp					#	начало фрейма rbp = rsp
	push rbx						#	сохраняем старое значение rbx
	push r12						#	сохраняем старое значение r12
	push r13						#	сохраняем старое значение r13
	sub	rsp, 8						#	конец фрейма rsp -= 8

	mov	rbx, rdi					#	сохраняет в rbx первый аргумент из rdi (struct container *array)
	mov	r12, rsi					#	сохраняет в r12 второй аргумент из rsi (char *file_name)

	#	открываем файл для записи
	lea	rsi, .LC3[rip]				#	rsi = "w" (указатель на строку) - второй аргумент
	mov	rdi, r12					#	rdi = file_name - первый аргумент
	call	fopen@PLT				#	rax = fopen(file_name, "w") = fopen(rdi, rsi)
	mov	r12, rax					# 	r12 = FILE *ostream = fopen(file_name, "w") (значение file_name теряется)

	# 	цикл for
	mov	r13, 0						#	size_t i = 0 - сохраняем локальный счетчик в регистр r13
	jmp	.L9							#	условие цикла for на метке .L9

.L10:								#	тело цикла for
	mov	rax, QWORD PTR 16[rbx]		#	rax = *(array + 16) = array->arr (array = rbx)
	mov edx, DWORD PTR [rax + 4*r13]	#	edx = *(array->arr + 4 * i) = array->arr[i] - третий аргумент
	lea	rsi, .LC4[rip]				#	rsi = "%d" (pointer to the string) - второй аргумент
	mov	rdi, r12					#	rdi = r12 = ostream - первый аргумент
	mov	eax, 0
	call	fprintf@PLT				#	fprintf(rdi = ostream, rsi = "%d", rdx = array->arr[i])
	add	r13, 1						#	i += 1 (i = r13)

.L9:								#	условие цикла for (i < array->len)
	cmp	r13, QWORD PTR [rbx]		#	cmp r13 = i, [rbx] = arrray->len
	jb	.L10						#	if (i < array->len) {goto .L10}

	#	закрываем поток для записи
	mov	rdi, r12					#	rdi = r12 = ostream
	call	fclose@PLT				#	fclose(rdi = ostream)
	nop

	add rsp, 8
	pop r13							#	восстанавливаем r13
	pop r12							#	восстанавливаем r12
	pop rbx							#	восстанавливаем rbx
	pop rbp
	ret								#	выход из функции
	.size	array_output, .-array_output

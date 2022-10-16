	.file	"code.c"
	.intel_syntax noprefix
	.text
	.section	.rodata

	#	функция array_input
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
	sub	rsp, 32						#	конец фрейма rsp -= 32 (размер фрейма 32 байта)

	# сохраняем на стек переданные через регистры аргументы
	mov	QWORD PTR -24[rbp], rdi		#	сохраняет на стек (-24[rbp]) первый аргумент из rdi (struct container *array в Си)
	mov	QWORD PTR -32[rbp], rsi		#	сохраняет на стек (-32[rbp]) второй аргумент из rsi (char *file_name в Си)
	
	mov	rax, QWORD PTR -24[rbp]
	mov	rax, QWORD PTR 8[rax]		#	rax = array->capacity = *(array + 8)
	test	rax, rax
	jne	.L2							#	if (!array->capacity) then... else goto .L2
	mov	rax, QWORD PTR -24[rbp]
	mov	QWORD PTR 8[rax], 20		#	array->capacity = 20 (capacity = *(array + 8))
	mov	rax, QWORD PTR -24[rbp]
	mov	QWORD PTR [rax], 0			#	array->len = 0 (len = *(array))
	mov	rax, QWORD PTR -24[rbp]
	mov	rax, QWORD PTR 8[rax]
	sal	rax, 2						#	rax = array->capacity * sizeof(int) (sizeof(int) = 4)
	mov	rdi, rax					
	call	malloc@PLT				#	rax = malloc(array->capacity * sizeof(int))
	mov	rdx, rax					#	сохраняем результат malloc (указатель) в rdx
	mov	rax, QWORD PTR -24[rbp]
	mov	QWORD PTR 16[rax], rdx		#	array->arr = *(array + 16) = rdx = malloc(array->capacity * sizeof(int))

.L2:
	mov	rax, QWORD PTR -32[rbp]		
	lea	rsi, .LC0[rip]				#	rsi = "r" (указатель на строку)
	mov	rdi, rax					#	rdi = file_name
	call	fopen@PLT
	mov	QWORD PTR -8[rbp], rax		#	istream = fopen(file_name, "r") (istream - локальная переменная на стеке -8[rbp])
	jmp	.L3

.L6:								#	тело цикла while (условие находится на метке .L3)
	mov	rax, QWORD PTR -24[rbp]
	mov	rdx, QWORD PTR [rax]		#	rdx = array->len
	mov	rax, QWORD PTR -24[rbp]		
	mov	rax, QWORD PTR 8[rax]		#	rax = array->capacity
	cmp	rdx, rax
	jne	.L4							#	if (array->len == array->capacity) then {...} else {goto .L4}

	#	выделяем больше места для массива
	mov	rax, QWORD PTR -24[rbp]
	mov	rax, QWORD PTR 8[rax]		#	rax = array->capacity
	lea	rdx, 0[0+rax*8]				#	rdx = 8 * array->capacity = 2 * array->capacity * sizeof(int) (lea использовано для быстрого умножения)
	mov	rax, QWORD PTR -24[rbp]
	mov	rax, QWORD PTR 16[rax]		#	rax = array->arr
	mov	rsi, rdx					#	rsi = 8 * array->capacity
	mov	rdi, rax					#	rdi = array->arr
	call	realloc@PLT				#	rax = realloc(rdi, rsi) = realloc(array->arr, 2 * array->capacity * sizeof(int))
	mov	rdx, QWORD PTR -24[rbp]		#	-24[rbp] = struct container *array
	mov	QWORD PTR 16[rdx], rax		#	array->arr = rax = realloc(array->arr, 2 * array->capacity * sizeof(int))
	mov	rax, QWORD PTR -24[rbp]		
	mov	rax, QWORD PTR 16[rax]		#	rax = array->arr
	test	rax, rax
	jne	.L5							#	if (!array->arr) then {...} else {goto .L5}

	mov	rax, QWORD PTR -8[rbp]
	mov	rdi, rax					#	rdi = istream = -8[rbp]
	call	fclose@PLT				#	fclose(istream)
	mov	rax, QWORD PTR stderr[rip]
	mov	rcx, rax					#	rcx = stderr
	mov	edx, 30						#	edx = 30 = len("No enough memory for the array") = кол-во выводимых объектов
	mov	esi, 1						#	esi = 1 = sizeof(char)
	lea	rdi, .LC1[rip]				#	rdi = "No enough memory for the array" (указатель на строку)
	call	fwrite@PLT				#	fwrite("No enough memory for the array", 1, 30, stderr)
	mov	edi, 1
	call	exit@PLT				#	exit(1 = edi)

.L5:								#	if (array->arr)
	mov	rax, QWORD PTR -24[rbp]		#	rax = -24[rbp] = array
	mov	rax, QWORD PTR 8[rax]		#	rax = array->capacity
	lea	rdx, [rax+rax]				#	rdx = array->capacity * 2 (rax + rax = 2*rax)
	mov	rax, QWORD PTR -24[rbp]	
	mov	QWORD PTR 8[rax], rdx		#	array->capacity = rdx = array->capacity * 2

.L4:
	mov	rax, QWORD PTR -24[rbp]		#	rax = -24[rbp] = array
	mov	rdx, QWORD PTR 16[rax]		#	rdx = array->arr
	mov	rax, QWORD PTR -24[rbp]
	mov	rax, QWORD PTR [rax]		#	rax = array->len
	sal	rax, 2						#	rax = 4 * rax = sizeof(int) * array->len
	add	rdx, rax					#	rdx = array->arr + sizeof(int) * array->len
									#	это адрес array->arr[array->len] (в этот адрес будем записывать)
	mov	rax, QWORD PTR -8[rbp]		#	rax = istream = -8[rbp]
	lea	rsi, .LC2[rip]				#	rsi = "%d" (указатель на строку)
	mov	rdi, rax					#	rdi = rax = istream = -8[rbp]
	mov	eax, 0
	call	__isoc99_fscanf@PLT		#	in c fscanf(istream, "%d", array->arr + array->len) = fscanf(rdi, rsi, rdx)
	mov	rax, QWORD PTR -24[rbp]		#	rax = -24[rbp] = array
	mov	rax, QWORD PTR [rax]		#	rax = array->len
	lea	rdx, 1[rax]					#	rdx = rax + 1 = array->len + 1
	mov	rax, QWORD PTR -24[rbp]
	mov	QWORD PTR [rax], rdx		#	array->len = rdx = array->len + 1

.L3:
	mov	rax, QWORD PTR -8[rbp]
	mov	rdi, rax					#	rdi = istream
	call	feof@PLT				#	feof(istream)
	test	eax, eax
	je	.L6							#	if feof(istream) == 0 (не достигнут конец файла)

	mov	rax, QWORD PTR -8[rbp]
	mov	rdi, rax					#	rdi = istream
	call	fclose@PLT				#	fclose(istream)
	nop
	leave							#	восстановить rbp, rsp для выхода из функции
	ret								#	выход из функции
	.size	array_input, .-array_input


	.section	.rodata
	#	функция array_ouput
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
	sub	rsp, 32						#	конец фрейма rsp -= 32 (размер фрейма 32 байта)
	mov	QWORD PTR -24[rbp], rdi		#	сохраняет на стек (-24[rbp]) первый аргумент из rdi (struct container *array в Си)
	mov	QWORD PTR -32[rbp], rsi		#	сохраняет на стек (-32[rbp]) второй аргумент из rsi (char *file_name в Си)
	mov	rax, QWORD PTR -32[rbp]		#	rax = -32[rbp] = file_name
	lea	rsi, .LC3[rip]				#	rsi = "w" (указатель на строку)
	mov	rdi, rax					#	rdi = file_name
	call	fopen@PLT				#	rax = fopen(file_name, "w") = fopen(rdi, rsi)
	mov	QWORD PTR -8[rbp], rax		# 	FILE *ostream = -8[rbp] = fopen(file_name, "w") (сохраняем указатель на файл на стек)
	mov	QWORD PTR -16[rbp], 0		#	size_t i = 0 - сохраняем локальный счетчик на стек (-16[rbp])
	jmp	.L9							#	условие цикла for на метке .L9

.L10:								#	тело цикла for
	mov	rax, QWORD PTR -24[rbp]		#	rax = -24[rbp] = array
	mov	rax, QWORD PTR 16[rax]		#	rax = *(array + 16) = array->arr
	mov	rdx, QWORD PTR -16[rbp]		#	rdx = i
	sal	rdx, 2						#	rdx *= 4 = sizeof(int)
	add	rax, rdx					#	rax = array->arr + sizeof(int) * i = &(array->arr[i])
	mov	edx, DWORD PTR [rax]		#	edx = array->arr[i]
	mov	rax, QWORD PTR -8[rbp]		#	rax = ostream = -8[rbp]
	lea	rsi, .LC4[rip]				#	rsi = "%d" (pointer to the string)
	mov	rdi, rax					#	rdi = ostream
	mov	eax, 0
	call	fprintf@PLT				#	fprintf(ostream, "%d", array->arr[i])
	add	QWORD PTR -16[rbp], 1		#	i += 1 (i = -16[rbp])

.L9:								#	условие цикла for (i < array->len)
	mov	rax, QWORD PTR -24[rbp]		#	rax = -24[rbp] = array
	mov	rax, QWORD PTR [rax]		#	rax = array->len
	cmp	QWORD PTR -16[rbp], rax		#	cmp i, arrray->len
	jb	.L10						#	if (i < array->len) {goto .L10}

	mov	rax, QWORD PTR -8[rbp]		#	rax = -8[rbp] = ostream
	mov	rdi, rax
	call	fclose@PLT				#	fclose(rdi = ostream)
	nop
	leave							#	восстановить rbp, rsp для выхода из функции
	ret								#	выход из функции
	.size	array_output, .-array_output


	.section	.rodata
	#	функция construct_new_array
	#	строковые литералы (константы), которые используются в array_output
.LC5:
	.string	"No memory for a new array"
	.text
	.globl	construct_new_array
	.type	construct_new_array, @function
construct_new_array:				#	точка входа в функцию construct_new_array
	#	создание нового массива из положительных элементов данного

	#	пролог входа в функцию (сохраняем прежний rbp на стеке, задаем новые указатели на границы фрейма)
	push	rbp
	mov	rbp, rsp					#	начало фрейма rbp = rsp
	sub	rsp, 64						#	конец фрейма rsp -= 64 (размер фрейма 64 байта)

	#	так как функция возвращает структуру, то компилятор уже зарезервировал место для нее
	#	на стеке в вызывающей функции (в данном случае в main)
	# 	и первый передаваемый аргумент rdi как раз содержит указатель на это зарезервированное место

	mov	QWORD PTR -56[rbp], rdi		#	сохраняет на стек (-56[rbp]) первый аргумент из rdi - указатель на возвращаемую структуру struct container
	mov	QWORD PTR -64[rbp], rsi		#	сохраняет на стек (-64[rbp]) второй аргумент из rsi (struct container *array в Си)
	mov	rax, QWORD PTR -64[rbp]		#	rax = -64[rbp] = array
	mov	rax, QWORD PTR [rax]		#	rax = *array = array->len

									#	struct container result - локальная структура объявляется на стеке, &result = -32[rbp]
									#	sizeof(result) = 12, result.len = -32[rbp], result.capacity = -24[rbp], result.arr = -16[rbp]
	mov	QWORD PTR -24[rbp], rax		#	result.capacity = rex = array->len (&result.capacity = &result + 8 = -24[rbp])
	mov	rax, QWORD PTR -64[rbp]		#	rax = array = -64[rbp]
	mov	rax, QWORD PTR [rax]		#	rax = *array = array->len
	sal	rax, 2						#	rax = rax * 4 = array->len * sizeof(int)
	mov	rdi, rax
	call	malloc@PLT				#	rax = malloc(rdi = array->len * sizeof(int))
	mov	QWORD PTR -16[rbp], rax		#	result.arr = (&result + 16) = -16[rbp] = malloc(array->len * sizeof(int))
	mov	QWORD PTR -32[rbp], 0		#	result.len = -32[rbp] = 0
	mov	rax, QWORD PTR -16[rbp]		#	rax = result.arr
	test	rax, rax
	jne	.L12						#	if (!result.arr) then {...} else {goto .L12}

	#	finish program, if can't allocate memory
	mov	rax, QWORD PTR stderr[rip]	#	rax = stderr
	mov	rcx, rax					#	rcx = stderr
	mov	edx, 25						#	edx = 25 = len("No memory for a new array") - кол-во выводимых объектов
	mov	esi, 1						#	esi = 1 (sizeof(char)) - размер выводимых объектов
	lea	rdi, .LC5[rip]				#	rdi = "No memory for a new array" (pointer to the string)
	call	fwrite@PLT				#	fwrite("No memory for a new array", 1, 25, stderr) = fwrite(rdi, rsi, rdx, rcx)
	mov	edi, 1						
	call	exit@PLT				#	exit(edi = 1)

.L12:								#	if (result.arr), то есть смогли выделить память для массива
	mov	QWORD PTR -40[rbp], 0		#	size_t i = 0 - сохраняем локальну переменную на стеке (-40[rbp])	
	jmp	.L13						#	условие цикла for на метке .L13	

.L15:								#	тело цикла for
	mov	rax, QWORD PTR -64[rbp]		#	rax = array
	mov	rax, QWORD PTR 16[rax]		#	rax = array->arr = *(array + 16)
	mov	rdx, QWORD PTR -40[rbp]		#	rdx = i
	sal	rdx, 2						#	i *= 4 (i *= sizeof(int))
	add	rax, rdx					#	rax = array->arr + i *sizeof(int) = &array->arr[i]
	mov	eax, DWORD PTR [rax]		#	eax = array->int[i]
	test	eax, eax
	jle	.L14						#	if (array->int > 0) then {...} else {goto .L14}

	mov	rax, QWORD PTR -64[rbp]		#	rax = array
	mov	rax, QWORD PTR 16[rax]		#	rax = array->arr = *(array + 16)
	mov	rdx, QWORD PTR -40[rbp]		#	rdx = i
	sal	rdx, 2						#	rdx = i * sizeof(int)	
	add	rax, rdx					#	rax = array->arr + i *sizeof(int) = &array->arr[i]
	mov	rdx, QWORD PTR -16[rbp]		#	rdx = result.arr
	mov	rcx, QWORD PTR -32[rbp]		#	rcx = result.len
	sal	rcx, 2						#	rcx = result.len * sizeof(int) = 4 * result.len
	add	rdx, rcx					#	rdx = result.arr + result.len * sizeof(int) = &result.arr[result.len]
	mov	eax, DWORD PTR [rax]		#	eax = array->arr[i]
	mov	DWORD PTR [rdx], eax		#	result.arr[result.len] = array->arr[i]
	mov	rax, QWORD PTR -32[rbp]		#	rax = result.len
	add	rax, 1						#	rax = result.len + 1
	mov	QWORD PTR -32[rbp], rax		#	result.len = result.len + 1

.L14:
	add	QWORD PTR -40[rbp], 1		#	i += 1 (i = -40[rbp])

.L13:								#	условие цикла for (i < array->len)
	mov	rax, QWORD PTR -64[rbp]		#	rax = -64[rbp] = array
	mov	rax, QWORD PTR [rax]		#	rax = *array = array->len
	cmp	QWORD PTR -40[rbp], rax		#	cmp  i, array->len (i = -40[rbp])
	jb	.L15						#	if (i < array->len) {goto .L15 (тело цикла for)}
	
	#	теперь надо скопировать все три значения из result в память, выделенную для результата на стеке вызывающей функции -56[rbp]
	mov	rcx, QWORD PTR -56[rbp]		#	rcx = указатель на возвращаемую структуру
	mov	rax, QWORD PTR -32[rbp]		#	rax = result.len
	mov	rdx, QWORD PTR -24[rbp]		#	rdx = result.capacity
	mov	QWORD PTR [rcx], rax		#	копируем result.len в возвращаемую структуру
	mov	QWORD PTR 8[rcx], rdx		#	копируем result.capacity в возвращаемую структуру
	mov	rax, QWORD PTR -16[rbp]		#	rax = result.arr
	mov	QWORD PTR 16[rcx], rax		#	копируем result.arr в возвращаемую структуру

	mov	rax, QWORD PTR -56[rbp]		#	rax = ссылка на возвращаемую структуру
	leave							#	восстановить rbp, rsp для выхода из функции
	ret								#	выход из функции
	.size	construct_new_array, .-construct_new_array
	
	
	.globl	free_memory
	.type	free_memory, @function
free_memory:						#	точка входа в функцию free_memory (для высвобождения динамической памяти)
	#	пролог входа в функцию (сохраняем прежний rbp на стеке, задаем новые указатели на границы фрейма)
	push	rbp	
	mov	rbp, rsp					#	начало фрейма rbp = rsp
	sub	rsp, 16						#	конец фрейма rsp -= 16 (размер фрейма 16 байта)

	mov	QWORD PTR -8[rbp], rdi		#	сохраняем первый аргумент из rdi на стек в -8[rbp] (struct container *array в Си)
	mov	rax, QWORD PTR -8[rbp]		#	rax = array
	mov	rax, QWORD PTR 16[rax]		#	rax = array->arr
	mov	rdi, rax
	call	free@PLT				#	free(array->arr = rdi)
	nop
	leave							#	возвращаем rbp, rsp в прежнее состояние (старые границы фрейма)
	ret								#	выход из функции
	.size	free_memory, .-free_memory


	.section	.rodata
	#	функция main
	.align 8
	
	#	строковые литералы (константы), которые используются в main
.LC6:
	.string	"2 argements excepted - input file and output file"
	.text
	.globl	main
	.type	main, @function
main:
	#	пролог входа в функцию (сохраняем прежний rbp на стеке, задаем новые указатели на границы фрейма)	
	push	rbp
	mov	rbp, rsp					#	начало фрейма rbp = rsp
	sub	rsp, 80						#	конец фрейма rsp -= 80 (размер фрейма 80 байтов)

	mov	DWORD PTR -68[rbp], edi		#	сохраняем первый аргумент командной строки int argc из edi на стек (-68[rbp])
	mov	QWORD PTR -80[rbp], rsi		#	сохраняем второй аргумент командной строки char** argv из rsi на стек (-80[rbp])


									#	оставляем "канарейку" для безопасности, чтобы мы могли понять, если данные на стеке затерлись
									#	в процессе некорректной работы программы (например, слишком большого ввода данных)
	mov	rax, QWORD PTR fs:40		#	получение стекового индикатора
	mov	QWORD PTR -8[rbp], rax		#	и его сохранение на стеке
	xor	eax, eax

	cmp	DWORD PTR -68[rbp], 2		#	cmp argc, 2
	jg	.L19						#	if (argc < 3) then {...} else {goto .L19}

	#	incorrect input - 2 arguments excepted
	mov	rax, QWORD PTR stderr[rip]	#	rax = stderr
	mov	rcx, rax					# 	rcx = stderr
	mov	edx, 49						#	edx = 49 = len("2 argements excepted - input file and output file") - кол-во выводимых объектов
	mov	esi, 1						#	esi = 1 = sizeof(char) - размер выводимых объектов
	lea	rdi, .LC6[rip]				#	rdi = "2 argements excepted - input file and output file" (pointer to the string)
	call	fwrite@PLT				#	fwrite("2 argements excepted - input file and output file", 1, 49, stderr) - вывод ошибки
	mov	edi, 1
	call	exit@PLT				#	exit(1) - аварийный выход

.L19:								#	было введено больше 2 аргументов

	#	инициализация локальной struct container a на стеке
	mov	QWORD PTR -64[rbp], 0		#	a.len = 0
	mov	QWORD PTR -56[rbp], 0		#	a.capacity = 0
	mov	QWORD PTR -48[rbp], 0		#	a.arr = 0

	#	чтение массива A
	mov	rax, QWORD PTR -80[rbp]		#	rax = argv
	add	rax, 8						#	rax = &argv[1] = argv + sizeof(char*)
	mov	rdx, QWORD PTR [rax]		#	rdx = argv[1]
	lea	rax, -64[rbp]				#	rax = &a
	mov	rsi, rdx
	mov	rdi, rax
	call	array_input				#	array_input(rdi = &a, rsi = argv[1])


	lea	rax, -32[rbp]				#	зарезервировали память с адресом по адресу -32[rbp] под struct container,
									#	который нам вернет функция construct_new_array (rax = &b)

	lea	rdx, -64[rbp]				#	rdx = &a
	mov	rsi, rdx
	mov	rdi, rax					#	передаем адрес зарезервированной памяти как аргумент (&b),
									#	чтобы функция сама записала туда возвращаемое значение
	call	construct_new_array		#	struct container b = construct_new_array(&a)

	#	вывод массива B
	mov	rax, QWORD PTR -80[rbp]		#	rax = argv
	add	rax, 16						#	rax = &argv[2]
	mov	rdx, QWORD PTR [rax]		#	rdx = argv[2]
	lea	rax, -32[rbp]				#	rax = &b
	mov	rsi, rdx					
	mov	rdi, rax
	call	array_output			#	array_output(&b, argv[2])

	#	очистка динамической памяти
	lea	rax, -64[rbp]				#	rax = &a
	mov	rdi, rax					
	call	free_memory				#	free_memory(&a)

	lea	rax, -32[rbp]				#	rax = &b
	mov	rdi, rax
	call	free_memory				#	free_memory(&b)

	mov	eax, 0
	mov	rcx, QWORD PTR -8[rbp]
	xor	rcx, QWORD PTR fs:40		#	проверяем, "жива" ли канарейка - не затерлись ли данные
	je	.L21
	call	__stack_chk_fail@PLT	#	"канарейка умерла", данные в стеке повреждены

.L21:
	leave							#	возвращаем регистры-указатели на фрейм стека в прежнеее состояние
	ret								#	выходим из main, возвращаем eax = 0
	.size	main, .-main
	.ident	"GCC: (Ubuntu 9.4.0-1ubuntu1~20.04.1) 9.4.0"
	.section	.note.GNU-stack,"",@progbits

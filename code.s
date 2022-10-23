	.file	"new_code.c"
	.intel_syntax noprefix
	.text

	.globl	TIME_FLAG
	.bss	#	секция с глобальными переменными
	.type	TIME_FLAG, @object
	.size	TIME_FLAG, 1
TIME_FLAG:
	.zero	1

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
	sub	rsp, 32						#	конец фрейма rsp -= 32 (размер фрейма 32 байта)

	# сохраняем на стек переданные через регистры аргументы
	mov	QWORD PTR -24[rbp], rdi		#	сохраняет на стек (-24[rbp]) первый аргумент из rdi (struct container *array в Си)
	mov	QWORD PTR -32[rbp], rsi		#	сохраняет на стек (-32[rbp]) второй аргумент из rsi (char *file_name в Си)
	
	mov	rax, QWORD PTR -24[rbp]		#	rax = array (-24[rbp])
	mov	rax, QWORD PTR 8[rax]		#	rax = array->capacity = *(array + 8)
	test	rax, rax
	jne	.L2							#	if (!array->capacity) then... else goto .L2

	#	"инициализируем" пустой container и для начала выделяем память под 20 элементов
	mov	rax, QWORD PTR -24[rbp]		#	#	rax = array (-24[rbp])
	mov	QWORD PTR 8[rax], 20		#	array->capacity = 20 (capacity = *(array + 8))
	mov	rax, QWORD PTR -24[rbp]
	mov	QWORD PTR [rax], 0			#	array->len = 0 (len = *(array))
	mov	rax, QWORD PTR -24[rbp]
	mov	rax, QWORD PTR 8[rax]
	sal	rax, 2						#	rax = array->capacity * sizeof(int) (sizeof(int) = 4)
	mov	rdi, rax					
	call	malloc@PLT				#	rax = malloc(array->capacity * sizeof(int))
	mov	rdx, rax					#	сохраняем результат malloc (указатель) из rax в rdx
	mov	rax, QWORD PTR -24[rbp]
	mov	QWORD PTR 16[rax], rdx		#	array->arr = *(array + 16) = rdx = malloc(array->capacity * sizeof(int))


.L2:	#	открываем файл для чтения
	mov	rax, QWORD PTR -32[rbp]		
	lea	rsi, .LC0[rip]				#	rsi = "r" (указатель на строку) - второй аргумент
	mov	rdi, rax					#	rdi = file_name	- первый аргумент
	call	fopen@PLT				#	eax = fopen(rdi, rsi)
	mov	QWORD PTR -8[rbp], rax		#	istream = fopen(file_name, "r") (istream - локальная переменная на стеке -8[rbp])
	jmp	.L3

.L6:								#	тело цикла while (условие находится на метке .L3)
	mov	rax, QWORD PTR -24[rbp]		#	rax = array (-24[rbp])
	mov	rdx, QWORD PTR [rax]		#	rdx = array->len
	mov	rax, QWORD PTR -24[rbp]		
	mov	rax, QWORD PTR 8[rax]		#	rax = array->capacity
	cmp	rdx, rax
	jne	.L4							#	if (array->len == array->capacity) then {...} else {goto .L4}

	#	выделяем больше места для массива с помощью realloc
	mov	rax, QWORD PTR -24[rbp]		#	rax = array (-24[rbp])
	mov	rax, QWORD PTR 8[rax]		#	rax = array->capacity
	lea	rdx, 0[0+rax*8]				#	rdx = 8 * array->capacity = 2 * array->capacity * sizeof(int) (lea использовано для быстрого умножения)
	mov	rax, QWORD PTR -24[rbp]
	mov	rax, QWORD PTR 16[rax]		#	rax = array->arr
	mov	rsi, rdx					#	rsi = 8 * array->capacity - второй аргумент
	mov	rdi, rax					#	rdi = array->arr - первый аргумент
	call	realloc@PLT				#	rax = realloc(rdi, rsi) = realloc(array->arr, 2 * array->capacity * sizeof(int))
	mov	rdx, QWORD PTR -24[rbp]		#	-24[rbp] = struct container *array
	mov	QWORD PTR 16[rdx], rax		#	array->arr = rax = realloc(array->arr, 2 * array->capacity * sizeof(int))

	#	проверяем, смогли ли мы выделить больше памяти
	mov	rax, QWORD PTR -24[rbp]		#	rax = array (-24[rbp])
	mov	rax, QWORD PTR 16[rax]		#	rax = array->arr
	test	rax, rax
	jne	.L5				#	if (!array->arr) then {...} else {goto .L5}

	#	не смогли выделить память - заканчиваем программу
	mov	rax, QWORD PTR -8[rbp]
	mov	rdi, rax					#	rdi = istream = -8[rbp] - первый аргумент
	call	fclose@PLT				#	fclose(istream)
	mov	rax, QWORD PTR stderr[rip]
	mov	rcx, rax					#	rcx = stderr - 4 аргумент
	mov	edx, 30						#	edx = 30 = len("No enough memory for the array") = кол-во выводимых объектов - третий аргумент
	mov	esi, 1						#	esi = 1 = sizeof(char) - второй аргумент
	lea	rdi, .LC1[rip]				#	rdi = "No enough memory for the array" (указатель на строку) - первый аргумент
	call	fwrite@PLT				#	fwrite("No enough memory for the array", 1, 30, stderr)
	mov	edi, 1
	call	exit@PLT				#	exit(1 = edi)

	#	смогли выделить память, изменяем capacity
.L5:								#	if (array->arr)
	mov	rax, QWORD PTR -24[rbp]		#	rax = -24[rbp] = array
	mov	rax, QWORD PTR 8[rax]		#	rax = array->capacity
	lea	rdx, [rax+rax]				#	rdx = array->capacity * 2 (rax + rax = 2*rax)
	mov	rax, QWORD PTR -24[rbp]	
	mov	QWORD PTR 8[rax], rdx		#	array->capacity = rdx = array->capacity * 2

	#	считываем следующий элемент массива с помощью fscanf
.L4:
	mov	rax, QWORD PTR -24[rbp]		#	rax = -24[rbp] = array
	mov	rdx, QWORD PTR 16[rax]		#	rdx = array->arr
	mov	rax, QWORD PTR -24[rbp]
	mov	rax, QWORD PTR [rax]		#	rax = array->len
	sal	rax, 2						#	rax = 4 * rax = sizeof(int) * array->len
	add	rdx, rax					#	rdx = array->arr + sizeof(int) * array->len - третий аргумент
									#	это адрес array->arr[array->len] (в этот адрес будем записывать)
	mov	rax, QWORD PTR -8[rbp]		#	rax = istream = -8[rbp]
	lea	rsi, .LC2[rip]				#	rsi = "%d" (указатель на строку) - второй аргумент
	mov	rdi, rax					#	rdi = rax = istream = -8[rbp] - первый аргумент
	mov	eax, 0
	call	__isoc99_fscanf@PLT		#	fscanf(istream, "%d", array->arr + array->len) = fscanf(rdi, rsi, rdx)

	#	++array->len;
	mov	rax, QWORD PTR -24[rbp]		#	rax = -24[rbp] = array
	mov	rax, QWORD PTR [rax]		#	rax = array->len
	lea	rdx, 1[rax]					#	rdx = rax + 1 = array->len + 1
	mov	rax, QWORD PTR -24[rbp]
	mov	QWORD PTR [rax], rdx		#	array->len = rdx = array->len + 1

	#	условие продолжения цикла - пока не достигли конца файла
.L3:
	mov	rax, QWORD PTR -8[rbp]
	mov	rdi, rax					#	rdi = istream  -первый аргумент
	call	feof@PLT				#	feof(istream)
	test	eax, eax
	je	.L6							#	if feof(istream) == 0 (не достигнут конец файла)

	#	закрываем поток ввода
	mov	rax, QWORD PTR -8[rbp]
	mov	rdi, rax					#	rdi = istream - первый аргумент
	call	fclose@PLT				#	fclose(istream)
	nop
	leave							#	восстановить rbp, rsp для выхода из функции
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
	sub	rsp, 32						#	конец фрейма rsp -= 32 (размер фрейма 32 байта)
	mov	QWORD PTR -24[rbp], rdi		#	сохраняет на стек (-24[rbp]) первый аргумент из rdi (struct container *array в Си)
	mov	QWORD PTR -32[rbp], rsi		#	сохраняет на стек (-32[rbp]) второй аргумент из rsi (char *file_name в Си)

	#	открываем файл для записи
	mov	rax, QWORD PTR -32[rbp]		#	rax = -32[rbp] = file_name
	lea	rsi, .LC3[rip]				#	rsi = "w" (указатель на строку) - второй аргумент
	mov	rdi, rax					#	rdi = file_name - первый аргумент
	call	fopen@PLT				#	rax = fopen(file_name, "w") = fopen(rdi, rsi)
	mov	QWORD PTR -8[rbp], rax		# 	FILE *ostream = -8[rbp] = fopen(file_name, "w") (сохраняем указатель на файл на стек)

	# 	цикл for
	mov	QWORD PTR -16[rbp], 0		#	size_t i = 0 - сохраняем локальный счетчик на стек (-16[rbp])
	jmp	.L9							#	условие цикла for на метке .L9

.L10:								#	тело цикла for
	mov	rax, QWORD PTR -24[rbp]		#	rax = -24[rbp] = array
	mov	rax, QWORD PTR 16[rax]		#	rax = *(array + 16) = array->arr
	mov	rdx, QWORD PTR -16[rbp]		#	rdx = i
	sal	rdx, 2						#	rdx *= 4 = sizeof(int)
	add	rax, rdx					#	rax = array->arr + sizeof(int) * i = &(array->arr[i])
	mov	edx, DWORD PTR [rax]		#	edx = array->arr[i]  - третий аргумент
	mov	rax, QWORD PTR -8[rbp]		#	rax = ostream = -8[rbp]
	lea	rsi, .LC4[rip]				#	rsi = "%d" (pointer to the string) - второй аргумент
	mov	rdi, rax					#	rdi = ostream - первый аргумент
	mov	eax, 0
	call	fprintf@PLT				#	fprintf(rdi = ostream, rsi = "%d", rdx = array->arr[i])
	add	QWORD PTR -16[rbp], 1		#	i += 1 (i = -16[rbp])

.L9:								#	условие цикла for (i < array->len)
	mov	rax, QWORD PTR -24[rbp]		#	rax = -24[rbp] = array
	mov	rax, QWORD PTR [rax]		#	rax = array->len
	cmp	QWORD PTR -16[rbp], rax		#	cmp i, arrray->len
	jb	.L10						#	if (i < array->len) {goto .L10}

	#	закрываем поток для записи
	mov	rax, QWORD PTR -8[rbp]		#	rax = -8[rbp] = ostream
	mov	rdi, rax
	call	fclose@PLT				#	fclose(rdi = ostream)
	nop
	leave							#	восстановить rbp, rsp для выхода из функции
	ret								#	выход из функции
	.size	array_output, .-array_output


	.globl	random_array
	.type	random_array, @function
	#	функция void random_array(struct container *array, size_t size)
random_array:
	#	пролог входа в функцию (сохраняем прежний rbp на стеке, задаем новые указатели на границы фрейма)
	push	rbp
	mov	rbp, rsp					#	начало фрейма rbp = rsp
	push	rbx						#	сохраняем регистр rbx на стеке (будем его изменять)
	sub	rsp, 40						#	конец фрейма rsp -= 40 (размер фрейма 48 байтов)

	#	сохраняем аргументы из регистров на стек
	mov	QWORD PTR -40[rbp], rdi		#	сохраняет на стек (-40[rbp]) первый аргумент из rdi (struct container *array)
	mov	QWORD PTR -48[rbp], rsi		# 	сохраняет на стек (-48[rbp]) второй аргумент из rsi (size_t size)

	#	"инициализируем" массив под нужную длину, то есть выделяем память
	mov	rax, QWORD PTR -40[rbp]		#	rax = array (-40[rbp])
	mov	rdx, QWORD PTR -48[rbp]		#	rdx = size (-48[rbp])
	mov	QWORD PTR 8[rax], rdx		#	array->capacity = size (rdx)
	mov	rax, QWORD PTR -40[rbp]		#	rax = array
	mov	rdx, QWORD PTR -48[rbp]		#	rdx = size
	mov	QWORD PTR [rax], rdx		#	array->len = size (rdx)
	mov	rax, QWORD PTR -48[rbp]		#	rax = size
	sal	rax, 2						#	rax = 4 * size = sizeof(int) * size
	mov	rdi, rax					#	rdi = sizeof(int) * size - первый аргумент
	call	malloc@PLT				#	rax = malloc(rdi = sizeof(int) * size) - вызываем функцию
	mov	rdx, rax					#	rdx = malloc(4 * size) - указатель на массив
	mov	rax, QWORD PTR -40[rbp]		#	rax = array
	mov	QWORD PTR 16[rax], rdx		#	array->arr = rdx = malloc(4 * size)

	#	srand(time(NULL)) - задаем начало последовательности rand для рандомных чисел
	mov	edi, 0						#	edi = NULL - первый аргумент
	call	time@PLT				#	eax = time(NULL)
	mov	edi, eax					#	edi = time(NULL) - первый аргумент
	call	srand@PLT				#	srand(edi = time(0)) - вызвали функцию


	#	цикл for  - генерируем массив
	mov	QWORD PTR -24[rbp], 0		#	size_t i = 0 - локальный счетчик на стеке (-24[rbp])
	jmp	.L12

	#	тело цикла for
.L14:
	#	array->arr[i] = rand()
	mov	rax, QWORD PTR -40[rbp]		#	rax = array
	mov	rax, QWORD PTR 16[rax]		#	rax = array->arr
	mov	rdx, QWORD PTR -24[rbp]		#	rdx = i
	sal	rdx, 2						#	rdx *= 4 = sizeof(int)
	lea	rbx, [rax+rdx]				#	rbx = array->arr + sizeof(int) * i = &array->arr[i]
	call	rand@PLT				#	rax = rand()
	mov	DWORD PTR [rbx], eax		#	array->arr[i] = rand() = rax

	#	искусственно генерируем отрицательные числа
	call	rand@PLT				#	rax = rand()
	and	eax, 1						#	eax = rand() & 1 - младший бит
	test	eax, eax				
	je	.L13						#	if (eax == 0) {goto .L13 - число положительное}

	#	(eax = 1) -> делаем число отрицательным
	mov	rax, QWORD PTR -40[rbp]		#	rax = array (-40[rbp])
	mov	rax, QWORD PTR 16[rax]		#	rax = array->arr
	mov	rdx, QWORD PTR -24[rbp]		#	rdx = i (-24[rbp])
	sal	rdx, 2						#	rdx *= 4 = sizeof(int)
	add	rax, rdx					#	rax = array->arr + sizeof(int) * i = &array->arr[i]
	mov	edx, DWORD PTR [rax]		#	edx = array->arr[i]
	mov	rax, QWORD PTR -40[rbp]		
	mov	rax, QWORD PTR 16[rax]		#	rax = array->arr
	mov	rcx, QWORD PTR -24[rbp]		#	rcx = i
	sal	rcx, 2
	add	rax, rcx					#	rax = array->arr + sizeof(int) * i = &array->arr[i]
	neg	edx							#	rdx = -array->arr[i]
	mov	DWORD PTR [rax], edx		#	array->arr[i] = edx = -array->arr[i]

	#	условие продолжения цикла
.L13:
	add	QWORD PTR -24[rbp], 1		#	i += 1

	#	условие цикла for (i < array->len)
.L12:
	mov	rax, QWORD PTR -40[rbp]		#	rax = array
	mov	rax, QWORD PTR [rax]		#	rax = array->len
	cmp	QWORD PTR -24[rbp], rax		#	cmp i, array->len
	jb	.L14						#	if (i < array->len) {goto.L14 - тело цикла}

	nop
	nop
	add	rsp, 40						#	передвигаем границы фрейма
	pop	rbx							#	восстанавливаем старое rbx из стека
	pop	rbp
	ret								#	выход из функции
	.size	random_array, .-random_array



	.section	.rodata
	#	функция struct container construct_new_array(struct container *array)
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
	mov	rbp, rsp			#	начало фрейма rbp = rsp
	sub	rsp, 64				#	конец фрейма rsp -= 64 (размер фрейма 64 байта)

	#	так как функция возвращает структуру, то компилятор уже зарезервировал место для нее
	#	на стеке в вызывающей функции (в данном случае в main)
	# 	и первый передаваемый аргумент rdi как раз содержит указатель на это зарезервированное место

	mov	QWORD PTR -56[rbp], rdi		#	сохраняет на стек (-56[rbp]) первый аргумент из rdi - указатель на возвращаемую структуру struct container
	mov	QWORD PTR -64[rbp], rsi		#	сохраняет на стек (-64[rbp]) второй аргумент из rsi (struct container *array в Си)
	mov	rax, QWORD PTR -64[rbp]		#	rax = -64[rbp] = array
	mov	rax, QWORD PTR [rax]		#	rax = *array = array->len

	#	struct container result - локальная структура объявляется на стеке, &result = -32[rbp]
	#	sizeof(result) = 12, result.len = -32[rbp], result.capacity = -24[rbp], result.arr = -16[rbp]

	mov	QWORD PTR -24[rbp], rax		#	result.capacity = rax = array->len (&result.capacity = &result + 8 = -24[rbp])
	mov	rax, QWORD PTR -64[rbp]		#	rax = array = -64[rbp]
	mov	rax, QWORD PTR [rax]		#	rax = *array = array->len
	sal	rax, 2						#	rax = rax * 4 = array->len * sizeof(int)
	mov	rdi, rax					#	rdi = array->len * sizeof(int) - первый аргумент
	call	malloc@PLT				#	rax = malloc(rdi = array->len * sizeof(int))
	mov	QWORD PTR -16[rbp], rax		#	result.arr = rax = malloc(array->len * 4) (&result.arr = &result + 16 = -16[rbp])

	#	проверка, смогли ли мы выделить память
	mov	rax, QWORD PTR -16[rbp]		#	rax = array.arr
	test	rax, rax
	jne	.L16						#	if (!result.arr) then {...} else {goto .L16} 

	#	finish program, if can't allocate memory
	mov	rax, QWORD PTR stderr[rip]	#	rax = stderr
	mov	rcx, rax					#	rcx = stderr - четвертый аргумент
	mov	edx, 25						#	edx = 25 = len("No memory for a new array") - кол-во выводимых объектов - третий аргумент
	mov	esi, 1						#	esi = 1 (sizeof(char)) - размер выводимых объектов - второй аргумент
	lea	rdi, .LC5[rip]				#	rdi = "No memory for a new array" (pointer to the string) - первый аргумент
	call	fwrite@PLT				#	fwrite("No memory for a new array", 1, 25, stderr) = fwrite(rdi, rsi, rdx, rcx)
	mov	edi, 1						#	edi = 1 - первый аргумент
	call	exit@PLT				#	exit(edi = 1) - аварийный выход из программы

	#	смогли выделить память, продолжаем работу
.L16:
	#	цикл for c run - прогоняем создание массива несколько раз для более видимых замеров памяти
	mov	QWORD PTR -48[rbp], 0		#	size_t run = 0  (-48[rbp]) - сохраняем локальный счетчик на стек
	jmp	.L17						#	условие цикла for

	#	тело цикла for - создание массива из положительных чисел данного
.L21:
	mov	QWORD PTR -32[rbp], 0		#	result.len = 0 (&result.len = &result) - длину нужно обновлять каждый прогон
	mov	QWORD PTR -40[rbp], 0		#	size_t i = 0 - сохраняем локальну переменную на стеке (-40[rbp])	
	jmp	.L18						#	условие цикла for на метке .L18

	#	тело цикла for
.L20:
	mov	rax, QWORD PTR -64[rbp]		#	rax = array (-64[rbp])
	mov	rax, QWORD PTR 16[rax]		#	rax = array->arr = *(array + 16)
	mov	rdx, QWORD PTR -40[rbp]		#	rdx = i (-40[rbp] - локальный счетчик)
	sal	rdx, 2						#	i *= 4 (i *= sizeof(int))
	add	rax, rdx					#	rax = array->arr + i *sizeof(int) = &array->arr[i]
	mov	eax, DWORD PTR [rax]		#	eax = array->int[i]
	test	eax, eax
	jle	.L19						#	if (array->int > 0) then {...} else {goto .L14}

	#	число положительное -> добавляем в массив
	mov	rax, QWORD PTR -64[rbp]		#	rax = array (-64[rbp])
	mov	rax, QWORD PTR 16[rax]		#	rax = array->arr = *(array + 16)
	mov	rdx, QWORD PTR -40[rbp]		#	rdx = i (-40[rbp] - локальный счетчик)
	sal	rdx, 2						#	rdx = i * sizeof(int)	
	add	rax, rdx					#	rax = array->arr + i *sizeof(int) = &array->arr[i]
	mov	rdx, QWORD PTR -16[rbp]		#	rdx = result.arr (&result.arr = &result + 16 = -16[rbp])
	mov	rcx, QWORD PTR -32[rbp]		#	rcx = result.len
	sal	rcx, 2						#	rcx = result.len * sizeof(int) = 4 * result.len
	add	rdx, rcx					#	rdx = result.arr + result.len * sizeof(int) = &result.arr[result.len]
	mov	eax, DWORD PTR [rax]		#	eax = array->arr[i]
	mov	DWORD PTR [rdx], eax		#	result.arr[result.len] = array->arr[i]
	mov	rax, QWORD PTR -32[rbp]		#	rax = result.len (&result.len = &result)
	add	rax, 1						#	rax = result.len + 1
	mov	QWORD PTR -32[rbp], rax		#	result.len = result.len + 1
.L19:
	add	QWORD PTR -40[rbp], 1		#	i += 1 (i = -40[rbp]) - инкрементируем счетчик

.L18:								#	условие цикла for (i < array->len)
	mov	rax, QWORD PTR -64[rbp]		#	rax = -64[rbp] = array
	mov	rax, QWORD PTR [rax]		#	rax = *array = array->len
	cmp	QWORD PTR -40[rbp], rax		#	cmp  i, array->len (i = -40[rbp])
	jb	.L20						#	if (i < array->len) {goto .L15 (тело цикла for)}

	add	QWORD PTR -48[rbp], 1		#	run += 1 (run = [48[rbp]]) - инкрементируем счетчик

	#	условие цикла for с run для замера времени
.L17:
	movzx	eax, BYTE PTR TIME_FLAG[rip]	#	eax = TIME_FLAG
	movsx	eax, al							#	знаковое расширение al до eax
	imul	eax, eax, 500					#	знаковое умножение eax *= 500 - кол-во доп прогонов для замера времени
	add	eax, 1								#	eax += 1 (нужен хотя бы один прогон, если TIME_FLAG = 0)
	cdqe									#	расширение eax до rax
	cmp	QWORD PTR -48[rbp], rax				#	cmp run, 1 + 500 * TIME_FLAG (rax)	
	jb	.L21								#	if (run < 1 + 500 * TIME_FLAG) {goto .L21} - тело цикла


	#	теперь надо скопировать все три значения из result в память, выделенную для результата на стеке вызывающей функции -56[rbp]
	mov	rcx, QWORD PTR -56[rbp]		#	rcx = указатель на возвращаемую структуру
	mov	rax, QWORD PTR -32[rbp]		#	rax = result.len
	mov	rdx, QWORD PTR -24[rbp]		#	rdx = result.capacity
	mov	QWORD PTR [rcx], rax		#	копируем result.len в возвращаемую структуру
	mov	QWORD PTR 8[rcx], rdx		#	копируем result.capacity в возвращаемую структуру
	mov	rax, QWORD PTR -16[rbp]		#	rax = result.arr
	mov	QWORD PTR 16[rcx], rax		#	копируем result.arr в возвращаемую структуру

	mov	rax, QWORD PTR -56[rbp]		#	rax = ссылка на возвращаемую структуру
	leave					#	восстановить rbp, rsp для выхода из функции
	ret					#	выход из функции
	.size	construct_new_array, .-construct_new_array


	.globl	free_memory
	.type	free_memory, @function
	#	функция void free_memory(struct container *array)
free_memory:						#	точка входа в функцию free_memory (для высвобождения динамической памяти)
	#	пролог входа в функцию (сохраняем прежний rbp на стеке, задаем новые указатели на границы фрейма)
	push	rbp	
	mov	rbp, rsp					#	начало фрейма rbp = rsp
	sub	rsp, 16						#	конец фрейма rsp -= 16 (размер фрейма 16 байта)

	mov	QWORD PTR -8[rbp], rdi		#	сохраняем первый аргумент из rdi на стек в -8[rbp] (struct container *array)
	mov	rax, QWORD PTR -8[rbp]		#	rax = array
	mov	rax, QWORD PTR 16[rax]		#	rax = array->arr
	
	mov	rdi, rax					#	rdi = array->arr - первый аргумент
	call	free@PLT				#	free(array->arr = rdi) - вызываем функцию
	nop
	leave							#	возвращаем rbp, rsp в прежнее состояние (старые границы фрейма)
	ret								#	выход из функции
	.size	free_memory, .-free_memory

	#	функция main
	.section	.rodata		#	секция с данными 
	.align 8
	#	строковые литералы (константы), которые используются в main
.LC6:
	.string	"2 argements excepted - input file and output file"
.LC7:
	.string	"--rand"
.LC8:
	.string	"--time"
.LC10:
	.string	"Process time:%f seconds\n"
	.text		#	секция с кодом
	.globl	main
	.type	main, @function
main:
	#	пролог входа в функцию (сохраняем прежний rbp на стеке, задаем новые указатели на границы фрейма)
	push	rbp
	mov	rbp, rsp	#	начало фрейма rbp = rsp
	sub	rsp, 144	#	конец фрейма rsp -= 80 (размер фрейма 80 байтов)

	#	два аргумента argc и argv передаются в main через rdi и rsi соответственно
	mov	DWORD PTR -132[rbp], edi	#	сохраняем int argc из edi на стек (-132[rbp])
	mov	QWORD PTR -144[rbp], rsi	#	сохраняем char **argv из esi на стек (-144[rbp])

	#	оставляем "канарейку" для безопасности, чтобы мы могли понять, если данные на стеке затерлись
	#	в процессе некорректной работы программы (например, слишком большого ввода данных)
	mov	rax, QWORD PTR fs:40		#	получение стекового индикатора
	mov	QWORD PTR -8[rbp], rax		#	и его сохранение на стеке
	xor	eax, eax

	#	проверяем, ввели ли файлы для ввода/вывода в качестве аргументов cmd
	cmp	DWORD PTR -132[rbp], 2		#	cmp argc, 2
	jg	.L25						#	if (argc < 3) then {...} else {goto .L19}

	#	incorrect input - 2 arguments excepted
	mov	rax, QWORD PTR stderr[rip]	#	rax = stderr
	mov	rcx, rax					# 	rcx = stderr - 4 аргумент
	mov	edx, 49						#	edx = 49 = len("2 argements excepted - input file and output file") - кол-во выводимых объектов - третий аргумент
	mov	esi, 1						#	esi = 1 = sizeof(char) - размер выводимых объектов - второй аргумент
	lea	rdi, .LC6[rip]				#	rdi = "2 argements excepted - input file and output file" (pointer to the string) - первый агрумент
	call	fwrite@PLT				#	fwrite("2 argements excepted - input file and output file", 1, 49, stderr) - вывод ошибки
	mov	edi, 1
	call	exit@PLT				#	exit(1) - аварийный выход

.L25:		#	было введено больше 2 аргументов

	mov	rax, QWORD PTR -144[rbp]	#	rax = argv (сохранен на стеке в -144[rbp])
	mov	rax, QWORD PTR 8[rax]		#	rax = argv[1]
	mov	QWORD PTR -104[rbp], rax	#	char *input = argv[1] - сохраняем локальную переменную на стек -104[rbp]

	mov	rax, QWORD PTR -144[rbp]	#	rax = argv
	mov	rax, QWORD PTR 16[rax]		#	rax = argv[2]
	mov	QWORD PTR -96[rbp], rax		#	char *output = argv[2] - сохраняем локальную переменную на стек -96[rbp]

	mov	QWORD PTR -120[rbp], 0		#	size_t size_random = 0 - сохраняем локальную переменную на стек -120[rbp]

	#	цикл for (size_t i = 3; i < argc; ++i)
	mov	QWORD PTR -112[rbp], 3		#	size_t i = 3 - сохраняем локальный счетчик цикла for на цикл (-112[rbp])
	jmp	.L26

.L30:
	mov	rax, QWORD PTR -112[rbp]	#	rax = i (-112[rbp])
	lea	rdx, 0[0+rax*8]				#	rdx = 8 * i = i * sizeof(char *)
	mov	rax, QWORD PTR -144[rbp]	#	rax = argv
	add	rax, rdx					#	rax = argv + i * sizeof(char*) = &argv[i]
	mov	rax, QWORD PTR [rax]		#	rax = argv[i]

	lea	rsi, .LC7[rip]				#	rsi = "--rand" (pointer to the string) - второй аргумент (передаем через rsi)
	mov	rdi, rax					#	rdi = argv[i] - первый аргумент (передаем через rdi)
	call	strcmp@PLT				#	eax = strcmp(rdi = argv[i], rsi = "--rand)

	test	eax, eax				#	if (eax != 0 (argv[i] != "--rand")) {goto .L27}
	jne	.L27	
	#	if (argv[i] == "--rand")
	mov	rax, QWORD PTR -112[rbp]	#	rax = i (-112[rbp])
	lea	rdx, 1[rax]					#	rdx = i + 1
	mov	eax, DWORD PTR -132[rbp]	#	eax = argc
	cdqe							#	eax -> rax (расширение значения argc из int в long long)
	cmp	rdx, rax					#	cmp i + 1, argc
	jnb	.L28						#	if (!(i + 1 < argc)) {goto .L28}

	#	тело условного выражения if (i + 1 < argc)
	mov	rax, QWORD PTR -112[rbp]	#	rax = i (-112[rbp])
	add	rax, 1						#	rax = i + 1
	lea	rdx, 0[0+rax*8]				#	rdx = sizeof(char*) * (i + 1)
	mov	rax, QWORD PTR -144[rbp]	#	rax = argv (-144[rbp])
	add	rax, rdx					#	rax = argv + sizeof(char*) * (i + 1) = &argv[i + 1]
	mov	rax, QWORD PTR [rax]		#	rax = argv[i + 1]

	mov	rdi, rax					#	rdi = argv[i + 1] - первый аргумент (передаем через rdi)
	call	atoi@PLT				#	atoi(rdi = argv[i])
	cdqe							#	eax -> rax (расширение из int в long long) (rax = atoi (argv[i]))
	mov	QWORD PTR -120[rbp], rax	#	size_random = rax = atoi (argv[i]) (сохранение значения в локальную переменную на стеке)

.L28:
	cmp	QWORD PTR -120[rbp], 0		#	cmp size_random, 0
	jne	.L27						#	if (size_random != 0) {goto .L27}

	#	if (size_random = 0) - у опции --rand нет аргумента -> задаем дефолтное значение
	mov	QWORD PTR -120[rbp], 1000	#	size_random = 1000


.L27:
	mov	rax, QWORD PTR -112[rbp]	#	rax = i (-112[rbp])
	lea	rdx, 0[0+rax*8]				#	rdx = 8 * i = i * sizeof(char *)
	mov	rax, QWORD PTR -144[rbp]	#	rax = argv
	add	rax, rdx					#	rax = argv + i * sizeof(char*) = &argv[i]
	mov	rax, QWORD PTR [rax]		#	rax = argv[i]

	lea	rsi, .LC8[rip]				#	rsi = "--time" (pointer to the string) - второй аргумент (передаем через rsi)
	mov	rdi, rax					#	rdi = argv[i] - первый аргумент (передаем через rdi)
	call	strcmp@PLT				#	eax = strcmp(rdi = argv[i], rsi = "--time")

	test	eax, eax				
	jne	.L29						#	if (eax != 0 (argv[i] != "--rand")) {goto .L29}
	#	if (argv[i] == "--time") - устанавливаем флаг замера времени
	mov	BYTE PTR TIME_FLAG[rip], 1	#	TIME_FLAG = 1

.L29:
	add	QWORD PTR -112[rbp], 1		#	++i - инкемент локального счетчика цикла for

.L26:								#	условие i < argc в цикле for
	mov	eax, DWORD PTR -132[rbp]	#	eax = argc (-132[rbp])
	cdqe							#	eax -> rax (расширение значения argc из int в long long)
	cmp	QWORD PTR -112[rbp], rax	#	cmp i, argc
	jb	.L30						#	if (i < argc) {goto .L30 (тело цикла for)} 


	#	инициализация локальной struct container a на стеке
	mov	QWORD PTR -64[rbp], 0		#	a.len = 0
	mov	QWORD PTR -56[rbp], 0		#	a.capacity = 0
	mov	QWORD PTR -48[rbp], 0		#	a.arr = 0

	#	заполнение массива A (struct container a)
	cmp	QWORD PTR -120[rbp], 0		#	cmp size_random, 0
	je	.L31						#	if (size_random == 0) {then goto .L31} -  если не нужно запускать генератор рандомного массива
	
	#	генерация массива А с помощью рандома
	mov	rdx, QWORD PTR -120[rbp]	#	rdx = size_random
	lea	rax, -64[rbp]				#	rax = &a - адрес массива А
	mov	rsi, rdx					#	rsi = size_random - второй аргумент (передаем через rsi)			
	mov	rdi, rax					#	rdi = &a - первый аргумент (передаем через rdi)
	call	random_array			#	random_array(&a = rdi, size_random = rdi) - вызов функции
	#	вывод сгенерированного массива в input (для генерации тестов)
	mov	rdx, QWORD PTR -104[rbp]	#	rdx = input (-104[rbp])
	lea	rax, -64[rbp]				#	rax = &a - адрес массива А
	mov	rsi, rdx					#	rsi = input - второй аргумент (передаем через rsi)
	mov	rdi, rax					#	rdi = &a - первый аргумент (передаем через rdi)
	call	array_output			#	array_output(&a = rdi, input = rsi) - вызов функции
	jmp	.L32						


	#	чтение массива А из файла (если не запущен генератор)
.L31:
	mov	rdx, QWORD PTR -104[rbp]	#	rdx = input (-104[rbp])
	lea	rax, -64[rbp]				#	rax = &a - адрес массива А
	mov	rsi, rdx					#	rsi = input - второй аргумент (передаем через rsi)
	mov	rdi, rax					#	rdi = &a - первый аргумент (передаем через rdi)
	call	array_input				#	array_input(&a = rdi, input = rsi) - вызов функции


.L32:
	call	clock@PLT				#	rax = clock() - вызов функции без аргументов
	mov	QWORD PTR -88[rbp], rax		#	time_start = rax = clock() - сохраняем значение в виде локальной переменной на стеке (-88[rbp])
	
	#	зарезервировали память по адресу -32[rbp] под struct container,
	#	который нам вернет функция construct_new_array (причем сразу сделали её локальной переменной b)
	lea	rax, -32[rbp]				#	rax = &b

	lea	rdx, -64[rbp]				#	rdx = &a

	#	создание массива B из положительных элементов А
	mov	rsi, rdx					#	rsi = &a - второй аргумент (передаем через rsi)
	mov	rdi, rax					#	rdi = &b - первый аргумент (передаем через rdi)
									#	в Си этот первый аргумент передается неявно
	call	construct_new_array		#	construct_new_array(&b = rdi, &a = rsi)

	call	clock@PLT				#	rax = clock() - вызов функции без аргументов
	mov	QWORD PTR -80[rbp], rax		#	time_end = rax = clock() - сохраняем значение в виде локальной переменной на стеке (-88[rbp])
	
	#	вывод полученного массива B (struct container b)
	mov	rdx, QWORD PTR -96[rbp]		#	rdx = output
	lea	rax, -32[rbp]				#	rax = &b
	mov	rsi, rdx					#	rsi = output - второй аргумент (передаем через rsi)
	mov	rdi, rax					#	rdi = &b - первый аргумент (передаем через rdi)
	call	array_output			#	array_output(&b = rdi, output = rsi)


	movzx	eax, BYTE PTR TIME_FLAG[rip]	#	eax = TIME_FLAG (с беззнаковым расширением)
	test	al, al					
	je	.L33						#	if (TIME_FLAG == 0) {goto .L33} - если не нужно выводить замеры времени
	
	#	if (TIME_FLAG == 1) - если нужно выводить замеры времени
	mov	rax, QWORD PTR -80[rbp]		#	rax = time_end (-80[rbp])
	sub	rax, QWORD PTR -88[rbp]		#	rax = time_end - time_start

	#	работа с числами с плавающей точкой
	cvtsi2sd	xmm0, rax			#	xmm0 = (double) (time_end - time_start) - конвертация int в double
	movsd	xmm1, QWORD PTR .LC9[rip]	#	xmm1 = CLOCKS_PER_SEC 
	divsd	xmm0, xmm1				#	xmm0 /= xmm1 (xmm0 = (time_end - time_start) / CLOCKS_PER_SEC) - деление чисел с плавающей точкой
	movsd	QWORD PTR -72[rbp], xmm0	#	cpu_time_used = xmm0 (сохраняем локальную переменную на стеке по адресу -72[rbp])
	mov	rax, QWORD PTR -72[rbp]		#	rax = cpu_time_used (-72[rbp])
	movq	xmm0, rax				#	xmm0 = cpu_time_used - второй аргумент
	lea	rdi, .LC10[rip]				#	rdi = "Process time:%f seconds\n" (pointer to str) - первый аргумент
	mov	eax, 1		
	call	printf@PLT				#	вызов printf(rdi, xmm0) - вывод затраченного времени

	#	очистка динамической памяти, выделенной под массивы
.L33:
	lea	rax, -64[rbp]				#	rax = &a
	mov	rdi, rax					#	rdi = &a - первый аргумент
	call	free_memory				#	free_memory(&a = rdi) - вызов функции

	lea	rax, -32[rbp]				#	rax = &b
	mov	rdi, rax					#	rdi = &b - первый аргумент
	call	free_memory				#	free_memory(&b = rdi) - вызов функции

	#	проверка стека
	mov	eax, 0
	mov	rcx, QWORD PTR -8[rbp]
	xor	rcx, QWORD PTR fs:40		#	проверяем, "жива" ли канарейка - не затерлись ли данные
	je	.L35
	call	__stack_chk_fail@PLT	#	"канарейка умерла", данные в стеке повреждены
.L35:
	leave							#	возвращаем регистры-указатели на фрейм стека в прежнеее состояние
	ret								#	выходим из main, возвращаем eax = 0 (если канарейка жива)
	.size	main, .-main
	.section	.rodata
	.align 8
.LC9:			# CLOCKS_PER_SEC
	.long	0
	.long	1093567616
	.ident	"GCC: (Ubuntu 9.4.0-1ubuntu1~20.04.1) 9.4.0"
	.section	.note.GNU-stack,"",@progbits

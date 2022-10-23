	.file	"main.s"
	.intel_syntax noprefix
	.text

	.globl	TIME_FLAG
	.bss	#	секция с глобальными переменными
	.type	TIME_FLAG, @object
	.size	TIME_FLAG, 1
TIME_FLAG:
	.zero	1

	.text

	.extern array_input
	.extern array_output

	.globl	random_array
	.type	random_array, @function
	#	функция void random_array(struct container *array, size_t size)
random_array:
	#	пролог входа в функцию (сохраняем прежний rbp на стеке, задаем новые указатели на границы фрейма)
	push	rbp
	mov	rbp, rsp					#	начало фрейма rbp = rsp
	push	rbx						#	сохраняем регистр rbx на стеке (будем его изменять)
	push	r12						#	сохраняем регистр r12 на стеке (будем его изменять)
	push	r13						#	сохраняем регистр r13 на стеке (будем его изменять)
	push 	r14						#	сохраняем регистр r14 на стеке (будем его изменять)

	#	сохраняем аргументы в регистры, которые не будут изменяться после вызовов функций
	mov	rbx, rdi					#	сохраняет в регистр rbx первый аргумент из rdi (struct container *array)
	mov	r12, rsi					# 	сохраняет в регистр r12 второй аргумент из rsi (size_t size)

	#	"инициализируем" массив под нужную длину, то есть выделяем память
	mov	QWORD PTR 8[rbx], r12		#	8[rbx] = array->capacity = size = r12, (8[rbx] = *(array + 8))
	mov	QWORD PTR [rbx], r12		#	[rbx] = array->len = size = r12

	lea rdi, [4 * r12]				#	rdi = size * sizeof(int) - первый аргумент
	call	malloc@PLT				#	rax = malloc(rdi = sizeof(int) * size) - вызываем функцию
	mov	QWORD PTR 16[rbx], rax		#	16[rbx] = array->arr = rax = malloc(4 * size)

	#	srand(time(NULL)) - задаем начало последовательности rand для рандомных чисел
	mov	edi, 0						#	edi = NULL - первый аргумент
	call	time@PLT				#	eax = time(NULL)
	mov	edi, eax					#	edi = time(NULL) - первый аргумент
	call	srand@PLT				#	srand(edi = time(0)) - вызвали функцию


	#	цикл for  - генерируем массив
	mov	r13, 0		#	size_t i = 0 - локальный счетчик храним в регистре r13
	jmp	.L12

	#	тело цикла for
.L14:
	#	array->arr[i] = rand()
	call	rand@PLT				#	eax = rand()
	mov rdx, QWORD PTR 16[rbx]		#	rdx = array->arr = 16[rbx]
	lea r14, [rdx + 4 * r13]		#	r14 = (array->arr + 4 * i) = &(array->arr[i])
	mov DWORD PTR [r14], eax		#	[r14] = array->arr[i] = rand() = rax

	#	искусственно генерируем отрицательные числа
	call	rand@PLT				#	rax = rand()
	and	eax, 1						#	eax = rand() & 1 - младший бит
	test	eax, eax				
	je	.L13						#	if (eax == 0) {goto .L13 - число положительное}

	#	(eax = 1) -> делаем число отрицательным
	mov	eax, DWORD PTR [r14]		#	eax = [r14] = array->arr[i]
	neg eax							#	eax = -array->arr[i]
	mov DWORD PTR [r14], eax		#	[r14] = array->arr[i] = eax = -array->arr[i]

	#	условие продолжения цикла
.L13:
	add	r13, 1						#	i += 1, i = r13

	#	условие цикла for (i < array->len)
.L12:
	cmp	r13, r12					#	cmp i, size (r13 = i, r12 = size = array->len)
	jb	.L14						#	if (i < array->len) {goto.L14 - тело цикла}

	nop

	pop r14							#	восстанавливаем старое r14 из стека
	pop r13							#	восстанавливаем старое r13 из стека
	pop r12							#	восстанавливаем старое r12 из стека
	pop	rbx							#	восстанавливаем старое rbx из стека
	pop	rbp
	ret								#	выход из функции
	.size	random_array, .-random_array


	.section	.rodata
	#	функция struct container construct_new_array(struct container *array)
	#	строковые литералы (константы), которые используются в construct_new_array
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
	push rbx				#	сохраняем регистр rbx на стеке (будем его изменять)
	push r12				#	сохраняем регистр r12 на стеке (будем его изменять)
	push r13				#	сохраняем регистр r13 на стеке (будем его изменять)

	#	так как функция возвращает структуру, то компилятор уже зарезервировал место для нее
	#	на стеке в вызывающей функции (в данном случае в main)
	# 	и первый передаваемый аргумент rdi как раз содержит указатель на это зарезервированное место

	mov	rbx, rdi			#	сохраняет в регистр rbx первый аргумент из rdi - указатель на возвращаемую структуру struct container
							#	не будем создавать отдельную локальную структуру, как делал компилятор, а сразу будем работать со структурой по адресу rbx
							#	будем "звать" структуру по адресу rbx - result (хоть в программе на Cи этот указатель не имеет имени,
							#	но идейно его заменяет локальная структура result, поэтому для упрощения назовем его так же, а локальную структуру использовать не будем)

	mov	r12, rsi					#	сохраняет в регистр r12 второй аргумент из rsi (struct container *array в Си)

	#	sizeof(result) = 12, result.len = -32[rbp], result.capacity = -24[rbp], result.arr = -16[rbp]

	#	выделяем необходимую память для хранения нового массивва result
	mov	rax, QWORD PTR [r12]		#	rax = *array = array->len
	mov	QWORD PTR 8[rbx], rax		#	8[rbx] = result->capacity = rax = array->len (&result->capacity = &result + 8 = 8[rbx])
	lea rdi, [0 + 4*rax]			#	rdi = 4 * array->len = sizeof(int) * array->len - первый аргумент
	call	malloc@PLT				#	rax = malloc(rdi = array->len * sizeof(int))
	mov	QWORD PTR 16[rbx], rax		#	result->arr = rax = malloc(array->len * 4) (&result->arr = &result + 16 = 16[rbx])

	#	проверка, смогли ли мы выделить память
	mov	rax, QWORD PTR 16[rbx]		#	rax = array->arr
	test	rax, rax
	jne	.L16						#	if (!result->arr) then {...} else {goto .L16} 

	#	finish program, if can't allocate memory
	mov	rcx, QWORD PTR stderr[rip]	#	rcx = stderr - четвертый аргумент
	mov	edx, 25						#	edx = 25 = len("No memory for a new array") - кол-во выводимых объектов - третий аргумент
	mov	esi, 1						#	esi = 1 (sizeof(char)) - размер выводимых объектов - второй аргумент
	lea	rdi, .LC5[rip]				#	rdi = "No memory for a new array" (pointer to the string) - первый аргумент
	call	fwrite@PLT				#	fwrite("No memory for a new array", 1, 25, stderr) = fwrite(rdi, rsi, rdx, rcx)
	mov	edi, 1						#	edi = 1 - первый аргумент
	call	exit@PLT				#	exit(edi = 1) - аварийный выход из программы

	#	смогли выделить память, продолжаем работу

	#	дальше мы не вызываем функции, поэтому можно спокойно пользоваться регистрами
	# 	rdi, rsi и т.д. для хранения переменных (т.к значения не потеряются)
.L16:
	#	цикл for c run - прогоняем создание массива несколько раз для более видимых замеров памяти
	mov	rdi, 0						#	size_t run = 0 - сохраняем локальный счетчик в регистр rdi
	jmp	.L17						#	условие цикла for

	#	тело цикла for - создание массива из положительных чисел данного
.L21:
	mov	QWORD PTR [rbx], 0			#	result->len = 0 (&result->len = &result = rbx) - длину нужно обновлять каждый прогон

	mov rcx, QWORD PTR 16[r12]		#	rcx = array->arr - указатель на элемент массива array, который мы считываем (указывает на начало)
	mov rsi, QWORD PTR [r12]		#	rsi = array->len
	lea rsi, [rcx + 4 * rsi]		#	rsi = &array->arr[array->len] - указатель на конец массива array

	mov r13, QWORD PTR 16[rbx]		#	r13 = result->arr - указатель на конец массива result (сейчас указывает на начало)
	jmp	.L18						#	условие цикла for на метке .L18

	#	пока (rcx != rsi) - пока считываемый элемент не равен концу массива
	#	тело цикла for
.L20:
	mov	edx, DWORD PTR [rcx]		#	edx = array->int[i]
	test	edx, edx
	jle	.L19						#	if (array->int > 0) then {...} else {goto .L14}

	#	число положительное -> добавляем в массив
	mov DWORD PTR [r13], edx		#	result->arr[result->len] = array->arr[i] (r13 - указатель на конец result->arr)
	add r13, 4						#	r13 - указатель на элемент массива (адрес), поэтому r13 += sizeof(int) = 4
	add DWORD PTR [rbx], 1			#	++result->len, (rbx = result)

.L19:
	add	rcx, 4						#	rcx - указатель на элемент массива (адрес), поэтому rcx += sizeof(int) = 4

.L18:								#	условие цикла for (i < array->len)
	cmp	rcx, rsi					#	cmp  &array->arr[i], &array->arr[array->len] = cmp i, array->len
	jb	.L20						#	if (i < array->len) {goto .L15 (тело цикла for)}

	add	rdi, 1		#	run += 1 (run = [48[rbp]]) - инкрементируем счетчик

	#	условие цикла for с run для замера времени
.L17:
	movzx	eax, BYTE PTR TIME_FLAG[rip]	#	eax = TIME_FLAG
	movsx	eax, al							#	знаковое расширение al до eax
	imul	eax, eax, 500					#	знаковое умножение eax *= 500 - кол-во доп прогонов для замера времени
	add	eax, 1								#	eax += 1 (нужен хотя бы один прогон, если TIME_FLAG = 0)
	cdqe									#	расширение eax до rax
	cmp	rdi, rax							#	cmp run (rdi), 1 + 500 * TIME_FLAG (rax)	
	jb	.L21								#	if (run < 1 + 500 * TIME_FLAG) {goto .L21} - тело цикла

	mov	rax, rbx					#	rax = ссылка на возвращаемую структуру
	
	pop r13							#	восстанавливаем старое r13 из стека
	pop r12							#	восстанавливаем старое r12 из стека
	pop rbx							#	восстанавливаем старое rbx из стека
	pop rbp
	ret					#	выход из функции
	.size	construct_new_array, .-construct_new_array


	.globl	free_memory
	.type	free_memory, @function
	#	функция void free_memory(struct container *array)
free_memory:						#	точка входа в функцию free_memory (для высвобождения динамической памяти)
	#	пролог входа в функцию (сохраняем прежний rbp на стеке, задаем новые указатели на границы фрейма)
	push	rbp	
	mov	rbp, rsp					#	начало фрейма rbp = rsp
	sub	rsp, 16						#	конец фрейма rsp -= 16

	mov rdi, QWORD PTR 16[rdi]		#	rdi = *(rdi + 16) = *(array + 16) = array->arr - первый аргумент
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
	push rbx
	push r12
	push r13
	push r14

	sub	rsp, 144	#	конец фрейма rsp -= 144

	#	два аргумента argc и argv передаются в main через rdi и rsi соответственно
	mov	ebx, edi	#	сохраняем int argc из edi в регистр ebx
	mov	r12, rsi	#	сохраняем char **argv из esi в регистр r12

	#	оставляем "канарейку" для безопасности, чтобы мы могли понять, если данные на стеке затерлись
	#	в процессе некорректной работы программы (например, слишком большого ввода данных)
	mov	rax, QWORD PTR fs:40		#	получение стекового индикатора
	mov	QWORD PTR -40[rbp], rax		#	и его сохранение на стеке
	xor	eax, eax

	#	проверяем, ввели ли файлы для ввода/вывода в качестве аргументов cmd
	cmp	rbx, 2						#	cmp argc, 2
	jg	.L25						#	if (argc < 3) then {...} else {goto .L19}

	#	incorrect input - 2 arguments excepted
	mov	rcx, QWORD PTR stderr[rip]	# 	rcx = stderr - 4 аргумент
	mov	edx, 49						#	edx = 49 = len("2 argements excepted - input file and output file") - кол-во выводимых объектов - третий аргумент
	mov	esi, 1						#	esi = 1 = sizeof(char) - размер выводимых объектов - второй аргумент
	lea	rdi, .LC6[rip]				#	rdi = "2 argements excepted - input file and output file" (pointer to the string) - первый агрумент
	call	fwrite@PLT				#	fwrite("2 argements excepted - input file and output file", 1, 49, stderr) - вывод ошибки
	mov	edi, 1
	call	exit@PLT				#	exit(1) - аварийный выход

.L25:		#	было введено больше или равно 2 аргументов

	mov	r13, 0						#	size_t size_random = 0 - сохраняем локальную переменную в регистр r13

	#	цикл for (size_t i = 3; i < argc; ++i)
	mov	r14, 3						#	size_t i = 3 - сохраняем локальный счетчик цикла for в регистр r14
	jmp	.L26

.L30:
	lea	rsi, .LC7[rip]					#	rsi = "--rand" (pointer to the string) - второй аргумент (передаем через rsi)
	mov	rdi, QWORD PTR [r12 + 8*r14]	#	rdi = *(argv + i*sizeof(char *)) = argv[i] - первый аргумент
	call	strcmp@PLT					#	eax = strcmp(rdi = argv[i], rsi = "--rand)

	test	eax, eax				#	if (eax != 0 (argv[i] != "--rand")) {goto .L27}
	jne	.L27
	#	if (argv[i] == "--rand")
	lea	rdx, 1[r14]					#	rdx = i + 1 (r14 = i)
	cmp	edx, ebx					#	cmp i + 1 = edx, argc = ebx
	jnb	.L28						#	if (!(i + 1 < argc)) {goto .L28}

	#	тело условного выражения if (i + 1 < argc)
	mov	rdi, QWORD PTR [r12+rdx*8]	#	rdi = *(argv + sizeof(char*)*(i + 1)) = argv[i] - первый аргумент
	call	atoi@PLT				#	atoi(rdi = argv[i])
	cdqe							#	eax -> rax (расширение из int в long long) (rax = atoi (argv[i]))
	mov	r13, rax					#	size_random = rax = atoi (argv[i]) (сохранение значения в регистр r13)

.L28:
	cmp	r13, 0						#	cmp size_random, 0
	jne	.L27						#	if (size_random != 0) {goto .L27}

	#	if (size_random = 0) - у опции --rand нет аргумента -> задаем дефолтное значение
	mov	r13, 1000					#	size_random = 1000 (r13 = size_random)

.L27:
	lea	rsi, .LC8[rip]				#	rsi = "--time" (pointer to the string) - второй аргумент (передаем через rsi)
	mov	rdi, QWORD PTR [r12 + 8*r14]	#	rdi = *(argv + i*sizeof(char *)) = argv[i] - первый аргумент
	call	strcmp@PLT				#	eax = strcmp(rdi = argv[i], rsi = "--time")

	test	eax, eax				
	jne	.L29						#	if (eax != 0 (argv[i] != "--rand")) {goto .L29}
	#	if (argv[i] == "--time") - устанавливаем флаг замера времени
	mov	BYTE PTR TIME_FLAG[rip], 1	#	TIME_FLAG = 1

.L29:
	add	r14, 1						#	++i - инкемент локального счетчика цикла for

.L26:								#	условие i < argc в цикле for
	cmp	r14d, ebx					#	cmp i = r14, argc = ebx
	jb	.L30						#	if (i < argc) {goto .L30 (тело цикла for)} 


	#	инициализация локальной struct container a на стеке
	mov	QWORD PTR -72[rbp], 0		#	a.len = 0
	mov	QWORD PTR -64[rbp], 0		#	a.capacity = 0
	mov	QWORD PTR -56[rbp], 0		#	a.arr = 0

	#	заполнение массива A (struct container a)
	cmp	r13, 0						#	cmp size_random, 0
	je	.L31						#	if (size_random == 0) {then goto .L31} -  если не нужно запускать генератор рандомного массива
	
	#	генерация массива А с помощью рандома
	mov	rsi, r13					#	rsi = size_random - второй аргумент (передаем через rsi)			
	lea	rdi, -72[rbp]				#	rdi = &a - первый аргумент (передаем через rdi)
	call	random_array			#	random_array(&a = rdi, size_random = rdi) - вызов функции
	#	вывод сгенерированного массива в input (для генерации тестов)
	mov rsi, QWORD PTR 8[r12]		#	rsi = argv[1] - указатель на имя с входными данными (r12 = argv)
	lea	rdi, -72[rbp]				#	rdi = &a - первый аргумент (передаем через rdi)
	call	array_output			#	array_output(&a = rdi, input = rsi) - вызов функции
	jmp	.L32						


	#	чтение массива А из файла (если не запущен генератор)
.L31:
	mov rsi, QWORD PTR 8[r12]		#	rsi = argv[1] - указатель на имя с входными данными (r12 = argv)
	lea	rdi, -72[rbp]				#	rdi = &a - первый аргумент (передаем через rdi)
	call	array_input				#	array_input(&a = rdi, input = rsi) - вызов функции


.L32:
	call	clock@PLT				#	rax = clock() - вызов функции без аргументов
	mov	QWORD PTR -104[rbp], rax	#	time_start = rax = clock() - сохраняем значение в виде локальной переменной на стеке (-104[rbp])
	
	#	зарезервировали память по адресу -96[rbp] под struct container,
	#	который нам вернет функция construct_new_array (причем сразу сделали её локальной переменной b)
	lea	rax, -96[rbp]				#	rax = &b

	lea	rdx, -72[rbp]				#	rdx = &a

	#	создание массива B из положительных элементов А
	mov	rsi, rdx					#	rsi = &a - второй аргумент (передаем через rsi)
	mov	rdi, rax					#	rdi = &b - первый аргумент (передаем через rdi)
									#	в Си этот первый аргумент передается неявно
	call	construct_new_array		#	construct_new_array(&b = rdi, &a = rsi)

	call	clock@PLT				#	rax = clock() - вызов функции без аргументов
	mov	QWORD PTR -112[rbp], rax	#	time_end = rax = clock() - сохраняем значение в виде локальной переменной на стеке (-112[rbp])
	
	#	вывод полученного массива B (struct container b)
	mov	rsi, QWORD PTR 16[r12]		#	rsi = argv[2] - второй аргумент (r12 = argv)
	lea	rdi, -96[rbp]				#	rdi = &b - первый аргумент (передаем через rdi)
	call	array_output			#	array_output(&b = rdi, output = rsi)


	movzx	eax, BYTE PTR TIME_FLAG[rip]	#	eax = TIME_FLAG (с беззнаковым расширением)
	test	al, al					
	je	.L33						#	if (TIME_FLAG == 0) {goto .L33} - если не нужно выводить замеры времени
	
	#	if (TIME_FLAG == 1) - если нужно выводить замеры времени
	mov	rax, QWORD PTR -112[rbp]		#	rax = time_end (-80[rbp])
	sub	rax, QWORD PTR -104[rbp]		#	rax = time_end - time_start

	#	работа с числами с плавающей точкой
	cvtsi2sd	xmm0, rax			#	xmm0 = (double) (time_end - time_start) - конвертация int в double
	movsd	xmm1, QWORD PTR .LC9[rip]	#	xmm1 = CLOCKS_PER_SEC 
	divsd	xmm0, xmm1				#	xmm0 /= xmm1 (xmm0 = (time_end - time_start) / CLOCKS_PER_SEC) - деление чисел с плавающей точкой
	movsd	QWORD PTR -72[rbp], xmm0	#	cpu_time_used = xmm0 (сохраняем локальную переменную на стеке по адресу -72[rbp])
	mov	rax, QWORD PTR -72[rbp]		#	rax = cpu_time_used (-72[rbp])
	movq	xmm0, rax				#	xmm0 = cpu_time_used - второй аргумент
	lea	rdi, .LC10[rip]				#	rdi = "Process time:%f seconds\n" (pointer to str) - первый аргумент
	mov	eax, 1		
	call	printf@PLT				#	вызов priстароеntf(rdi, xmm0) - вывод затраченного времени

	#	очистка динамической памяти, выделенной под массивы
.L33:
	lea	rdi, -72[rbp]				#	rdi = &a - первый аргумент
	call	free_memory				#	free_memory(&a = rdi) - вызов функции

	lea	rdi, -96[rbp]				#	rdi = &b - первый аргумент
	call	free_memory				#	free_memory(&b = rdi) - вызов функции

	#	проверка стека
	mov	eax, 0
	mov	rcx, QWORD PTR -40[rbp]
	xor	rcx, QWORD PTR fs:40		#	проверяем, "жива" ли канарейка - не затерлись ли данные
	je	.L35
	call	__stack_chk_fail@PLT	#	"канарейка умерла", данные в стеке повреждены
.L35:
	add rsp, 144
	pop r14							#	восстанавливаем старое r14 из стека
	pop r13							#	восстанавливаем старое r13 из стека
	pop r12							#	восстанавливаем старое r12 из стека
	pop	rbx							#	восстанавливаем старое rbx из стека
	pop	rbp
	ret								#	выходим из main, возвращаем eax = 0 (если канарейка жива)
	.size	main, .-main
	.section	.rodata
	.align 8
.LC9:			# CLOCKS_PER_SEC
	.long	0
	.long	1093567616
	.ident	"GCC: (Ubuntu 9.4.0-1ubuntu1~20.04.1) 9.4.0"
	.section	.note.GNU-stack,"",@progbits

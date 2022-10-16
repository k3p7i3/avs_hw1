# Индивидуальное домашнее задание №1. Вариант 1.

### Задание: 
### Сформировать массив B из положительных элементов массива А.

## Отчет:

### Написание программы на языке С

Написали программу на языке С *(code.c)*.

Программа принимает два аргумента: название файла с входными данными и название файла для вывода данных.
В программе реализованы функции для ввода массива из файла, вывода массива из файла, для формирования нового массива из
положительных чисел заданного массива, а также структура container - для удобного хранения массивов и их длины. 

Память для массивов выделяется динамически. 
Если не получилось выделить достаточное количество памяти для хранения какого-либо из массивов, 
то программа выводит сообщение об ошибке и завершает свое выполнение.

### Трансформация в ассемблер

С помощью gcc получим программу на языке ассемблера.
Для этого введем в терминал следующую команду:
  
  > **gcc -O0 -Wall -masm=intel -S -fno-asynchronous-unwind-tables -fcf-protection=none code.c -o code1.s**
  
За счет использования вышеперечисленных аргументов командной строки наша программа станет более компактной,
так как будут убраны лишние макросы.
  
  

#include "stdio.h"
#include "stdlib.h"
#include "time.h"
#include "getopt.h"
#include "string.h"

char TIME_FLAG = 0; // flag to know if we should measure time

struct container {
    size_t len;
    size_t capacity;
    int *arr;
};

void array_input(struct container *array, char *file_name)
{
    // if array is empty, then allocate memory for it
    if (!array->capacity) {
        array->capacity = 20;
        array->len = 0;
        array->arr = malloc(array->capacity * sizeof(int));
    }

    FILE *istream = fopen(file_name, "r");

    while (!feof(istream)) {
        // if there's no free space, then allocate more memory
        if (array->len == array->capacity) {
            array->arr = realloc(array->arr, 2 * array->capacity * sizeof(int));
            // if can't allocate more memory, then finish input
            if (!array->arr) {
                fclose(istream);
                fprintf(stderr, "No enough memory for the array");
                exit(1);
            }
            array->capacity *= 2;
        }

        // input new value and increment len
        fscanf(istream, "%d", array->arr + array->len);
        ++array->len;
    }

    fclose(istream);

    return;
}

void array_output(struct container *array, char *file_name) {
    FILE *ostream = fopen(file_name, "w");
    for (size_t i = 0; i < array->len; ++i) {
        fprintf(ostream, "%d ", array->arr[i]);
    }
    fclose(ostream);
}

void random_array(struct container *array, size_t size) {

    array->capacity = size;
    array->len = size;
    array->arr = malloc(size * sizeof(int));

    srand(time(NULL));
    for (size_t i = 0; i < array->len; ++i) {
        array->arr[i] = rand();
        //  rand generate not negative numbers, so add them artificially
        if (rand() & 1) {
            array->arr[i] = -array->arr[i];
        }
    }
}

struct container construct_new_array(struct container *array) {
    struct container result;
    result.capacity = array->len;
    result.arr = malloc(array->len * sizeof(int));

    // if couldn't allocate memory, then finish
    if (!result.arr) {
        fprintf(stderr, "No memory for a new array");
        exit(1);
    }

    //  run the cycle several times if we measure time
    for (size_t run = 0; run < 1 + 500 * TIME_FLAG; ++run) {

        result.len = 0;
        // construct result with positive numbers of array
        for (size_t i = 0; i < array->len; ++i)
        {
            if (array->arr[i] > 0)
            {
                result.arr[result.len] = array->arr[i];
                ++result.len;
            }
        }
    }
    return result;
}

void free_memory(struct container *array) {
    free(array->arr);
}

int main(int argc, char **argv) {
    //  get all options and arguments from cmd
    if (argc < 3) {
        fprintf(stderr, "2 argements excepted - input file and output file");
        exit(1);
    }
    char *input = argv[1];
    char *output = argv[2];

    size_t size_random = 0; // size for random generated array (if size == 0 then just read arr from file)

    for (size_t i = 3; i < argc; ++i)
    {
        if (!strcmp(argv[i], "--rand")) { // option to generate a random array
            if (i + 1 < argc) {
                size_random = atoi(argv[i + 1]); // get size of generated array
            }
            if (!size_random) { // if there's no argument, then default size = 1000
                size_random = 1000;
            }
        }

        if (!strcmp(argv[i], "--time")) { // option to measure time
            TIME_FLAG = 1;
        }
    }

    struct container a = {0, 0, 0};
    if (size_random) {
        random_array(&a, size_random);
        array_output(&a, input); // output the generated array so we can test the programm
    } else {
        array_input(&a, input);
    }

    clock_t time_start, time_end; // measure time for construct_new array
    time_start = clock();
    struct container b = construct_new_array(&a);
    time_end = clock();

    array_output(&b, output); // output the result

    if (TIME_FLAG) {    // print time
        double cpu_time_used = ((double)(time_end - time_start)) / CLOCKS_PER_SEC;
        printf("Process time:%f seconds\n", cpu_time_used);
    }

    // free memory
    free_memory(&a);
    free_memory(&b);
    return 0;
}
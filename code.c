#include "stdio.h"
#include "stdlib.h"

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

struct container construct_new_array(struct container *array) {
    struct container result;
    result.capacity = array->len;
    result.arr = malloc(array->len * sizeof(int));
    result.len = 0;

    // if couldn't allocate memory, then finish
    if (!result.arr) {
        fprintf(stderr, "No memory for a new array");
        exit(1);
    }

    // construct result with positive numbers of array
    for (size_t i = 0; i < array->len; ++i) {
        if (array->arr[i] > 0) {
            result.arr[result.len] = array->arr[i];
            ++result.len;
        }
    }

    return result;
}

void free_memory(struct container *array) {
    free(array->arr);
}

int main(int argc, char **argv) {
    if (argc < 3) {
        fprintf(stderr, "2 argements excepted - input file and output file");
        exit(1);
    }
    
    struct container a = {0, 0, 0};
    array_input(&a, argv[1]);

    struct container b = construct_new_array(&a);
    array_output(&b, argv[2]);

    // free memory
    free_memory(&a);
    free_memory(&b);
    return 0;
}
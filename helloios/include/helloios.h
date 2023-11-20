#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

char *get_greetings(void);

/**
 * Gets a personalized greeting from Rust.
 *
 * # Safety
 * This function is unsafe because it dereferences a raw pointer. The caller
 * must ensure that `to` is a valid pointer to a null-terminated string or is null.
 * Passing an invalid pointer (not null-terminated or pointing to unallocated memory)
 * can lead to undefined behavior.
 */
char *say_hello(const char *to);

/**
 * Gets a personalized greeting from Rust.
 *
 * # Safety
 * This function is unsafe because it dereferences a raw pointer. The caller
 * must ensure that `str` is a valid pointer to a null-terminated string or is null.
 * Passing an invalid pointer (not null-terminated or pointing to unallocated memory)
 * can lead to undefined behavior.
 */
void free_string(char *str);

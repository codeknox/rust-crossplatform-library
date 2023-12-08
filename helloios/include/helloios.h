#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

/**
 * Starts the fetching of random images and saves them to the specified folder.
 *
 * # Safety
 * This function is unsafe because it dereferences a raw pointer (`folder`).
 * The caller must ensure that `folder` is a valid pointer to a null-terminated
 * string. Passing an invalid pointer (not null-terminated or pointing to unallocated
 * memory) can lead to undefined behavior.
 *
 * # Arguments
 * * `folder` - A pointer to a null-terminated string representing the folder path.
 */
void start_fetch_random_image(const char *folder);

void stop_fetch_random_image(void);

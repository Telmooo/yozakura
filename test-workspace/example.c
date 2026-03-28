/*
 * Yozakura - C example
 * These files are all gibberish, do not attempt to run them
 */

#include <assert.h>
#include <errno.h>
#include <limits.h>
#include <math.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define APP_NAME    "yozakura"
#define VERSION     "1.0.0"
#define MAX_RETRIES 3
#define ARRAY_LEN(arr) (sizeof(arr) / sizeof((arr)[0]))
#define MAX(a, b)   ((a) > (b) ? (a) : (b))
#define MIN(a, b)   ((a) < (b) ? (a) : (b))
#define CLAMP(x, lo, hi) MIN(MAX((x), (lo)), (hi))

#define STRINGIFY(x)  #x
#define TOSTRING(x)   STRINGIFY(x)
#define AT            __FILE__ ":" TOSTRING(__LINE__)

#ifdef NDEBUG
  #define DBG(fmt, ...) ((void)0)
#else
  #define DBG(fmt, ...) \
    fprintf(stderr, "[DEBUG] " fmt "\n", ##__VA_ARGS__)
#endif

typedef uint8_t  u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;
typedef int8_t   i8;
typedef int16_t  i16;
typedef int32_t  i32;
typedef int64_t  i64;
typedef float    f32;
typedef double   f64;

typedef enum {
    STATUS_PENDING  = 0,
    STATUS_ACTIVE   = 1,
    STATUS_INACTIVE = 2,
    STATUS_BANNED   = 255,
} Status;

typedef enum {
    ERR_OK          =  0,
    ERR_NULL_PTR    = -1,
    ERR_OUT_OF_MEM  = -2,
    ERR_INVALID_ARG = -3,
    ERR_NOT_FOUND   = -4,
    ERR_IO          = -5,
} ErrorCode;

typedef struct Node Node;
typedef struct List List;

typedef struct {
    f64 x;
    f64 y;
} Point;

typedef struct {
    char     name[64];
    u32      id;
    Status   status;
    f64      score;
    uint32_t flags;
} User;

struct Node {
    void  *data;
    Node  *next;
    Node  *prev;
};

struct List {
    Node  *head;
    Node  *tail;
    size_t size;
    void (*free_fn)(void *);  /* function pointer */
};

/* Tagged union */
typedef enum { KIND_INT, KIND_FLOAT, KIND_STR } ValueKind;

typedef struct {
    ValueKind kind;
    union {
        i64         as_int;
        f64         as_float;
        const char *as_str;
    };
} Value;

// Bit fields
typedef struct {
    unsigned int read    : 1;
    unsigned int write   : 1;
    unsigned int execute : 1;
    unsigned int _pad    : 5;
} Permission;

/* Function Prototypes */
static Point   point_new(f64 x, f64 y);
static f64     point_distance(Point a, Point b);
static User   *user_create(const char *name, u32 id);
static void    user_free(User *user);
static int     user_compare(const void *a, const void *b);

/* Point */
static Point point_new(f64 x, f64 y) {
    return (Point){ .x = x, .y = y };
}

static f64 point_distance(Point a, Point b) {
    f64 dx = a.x - b.x;
    f64 dy = a.y - b.y;
    return sqrt(dx * dx + dy * dy);
}

static Point point_lerp(Point a, Point b, f64 t) {
    return (Point){
        .x = a.x + (b.x - a.x) * t,
        .y = a.y + (b.y - a.y) * t,
    };
}

/* User */
static User *user_create(const char *name, u32 id) {
    if (!name) return NULL;

    User *u = calloc(1, sizeof(User));
    if (!u) {
        perror("calloc");
        return NULL;
    }

    strncpy(u->name, name, sizeof(u->name) - 1);
    u->id     = id;
    u->status = STATUS_PENDING;
    u->score  = 0.0;

    return u;
}

static void user_free(User *user) {
    if (user) free(user);
}

static int user_compare(const void *a, const void *b) {
    const User *ua = (const User *)a;
    const User *ub = (const User *)b;
    if (ua->score > ub->score) return -1;
    if (ua->score < ub->score) return  1;
    return 0;
}

/* Linked List */
static List *list_create(void (*free_fn)(void *)) {
    List *l = calloc(1, sizeof(List));
    if (!l) return NULL;
    l->free_fn = free_fn;
    return l;
}

static ErrorCode list_push_back(List *l, void *data) {
    if (!l) return ERR_NULL_PTR;

    Node *node = calloc(1, sizeof(Node));
    if (!node) return ERR_OUT_OF_MEM;

    node->data = data;
    node->next = NULL;
    node->prev = l->tail;

    if (l->tail) l->tail->next = node;
    else         l->head       = node;

    l->tail = node;
    l->size++;
    return ERR_OK;
}

static void list_free(List *l) {
    if (!l) return;
    Node *cur = l->head;
    while (cur) {
        Node *next = cur->next;
        if (l->free_fn && cur->data) l->free_fn(cur->data);
        free(cur);
        cur = next;
    }
    free(l);
}

/* Variadic Functions */
static int log_message(const char *level, const char *fmt, ...) {
    va_list args;
    va_start(args, fmt);
    fprintf(stderr, "[%s] ", level);
    int n = vfprintf(stderr, fmt, args);
    fprintf(stderr, "\n");
    va_end(args);
    return n;
}

/* Pointers & Memory */
static void pointer_demos(void) {
    /* Pointer arithmetic */
    int arr[] = {10, 20, 30, 40, 50};
    int *p = arr;
    for (size_t i = 0; i < ARRAY_LEN(arr); i++) {
        printf("arr[%zu] = %d (via ptr: %d)\n", i, arr[i], *(p + i));
    }

    /* Double pointer */
    int   x = 42;
    int  *px  = &x;
    int **ppx = &px;
    printf("x = %d, *px = %d, **ppx = %d\n", x, *px, **ppx);

    /* Void pointer & casting */
    void *generic = malloc(sizeof(double));
    if (generic) {
        *(double *)generic = 3.14159;
        printf("generic double: %.5f\n", *(double *)generic);
        free(generic);
    }

    /* Function pointer */
    double (*fn_ptr)(double) = sqrt;
    printf("sqrt(2.0) = %.6f\n", fn_ptr(2.0));

    /* Array of function pointers */
    double (*math_fns[])(double) = { sqrt, sin, cos, tan, log };
    const char *math_names[]     = { "sqrt", "sin", "cos", "tan", "log" };
    for (size_t i = 0; i < ARRAY_LEN(math_fns); i++) {
        printf("  %s(1.0) = %.4f\n", math_names[i], math_fns[i](1.0));
    }
}

/* String Manipulation */
static char *str_dup(const char *s) {
    if (!s) return NULL;
    size_t len = strlen(s) + 1;
    char  *copy = malloc(len);
    if (copy) memcpy(copy, s, len);
    return copy;
}

static int str_starts_with(const char *str, const char *prefix) {
    return strncmp(str, prefix, strlen(prefix)) == 0;
}

static char *str_join(const char **strs, size_t count, const char *sep) {
    if (!strs || count == 0) return str_dup("");

    size_t sep_len = strlen(sep);
    size_t total   = 0;
    for (size_t i = 0; i < count; i++) {
        total += strlen(strs[i]);
        if (i < count - 1) total += sep_len;
    }

    char *result = malloc(total + 1);
    if (!result) return NULL;

    char *p = result;
    for (size_t i = 0; i < count; i++) {
        size_t len = strlen(strs[i]);
        memcpy(p, strs[i], len);
        p += len;
        if (i < count - 1) {
            memcpy(p, sep, sep_len);
            p += sep_len;
        }
    }
    *p = '\0';
    return result;
}

/* Control Flow */
static void control_flow_demos(void) {
    /* Switch with fall-through */
    Status s = STATUS_ACTIVE;
    switch (s) {
        case STATUS_PENDING:
            printf("pending\n");
            break;
        case STATUS_ACTIVE:
            /* fall through */
        case STATUS_INACTIVE:
            printf("active or inactive\n");
            break;
        case STATUS_BANNED:
            printf("banned\n");
            break;
        default:
            printf("unknown\n");
            break;
    }

    /* goto (error handling pattern) */
    FILE *fp = fopen("/tmp/test.txt", "r");
    if (!fp) goto cleanup;

    char buf[256];
    if (!fgets(buf, sizeof(buf), fp)) goto cleanup;
    printf("Read: %s\n", buf);

cleanup:
    if (fp) fclose(fp);

    /* Ternary & comma operator */
    int n = 7;
    const char *parity = (n % 2 == 0) ? "even" : "odd";
    printf("%d is %s\n", n, parity);
}

/* Value (tagged union) helpers */
static void value_print(const Value *v) {
    if (!v) return;
    switch (v->kind) {
        case KIND_INT:   printf("int:   %lld\n", (long long)v->as_int);   break;
        case KIND_FLOAT: printf("float: %.4f\n",             v->as_float); break;
        case KIND_STR:   printf("str:   %s\n",               v->as_str);  break;
    }
}

/* Main */
int main(int argc, char *argv[]) {
    /* Designated initializers */
    Point origin = { .x = 0.0, .y = 0.0 };
    Point target = { .x = 3.0, .y = 4.0 };

    printf("Distance: %.2f\n", point_distance(origin, target));

    /* Compound literals */
    f64 dist = point_distance((Point){1.0, 2.0}, (Point){4.0, 6.0});
    printf("Compound literal distance: %.2f\n", dist);

    /* Dynamic allocation */
    User *users[4];
    const char *names[] = {"alice", "bob", "charlie", "diana"};
    for (int i = 0; i < 4; i++) {
        users[i] = user_create(names[i], (u32)i + 1);
        if (!users[i]) {
            log_message("ERROR", "Failed to create user %s", names[i]);
            return EXIT_FAILURE;
        }
        users[i]->score  = (f64)(i + 1) * 25.0;
        users[i]->status = STATUS_ACTIVE;
    }

    /* qsort with function pointer */
    qsort(users, 4, sizeof(*users), user_compare);
    for (int i = 0; i < 4; i++) {
        printf("  [%d] %s score=%.1f\n", i, users[i]->name, users[i]->score);
        user_free(users[i]);
    }

    /* Tagged union */
    Value vals[] = {
        { .kind = KIND_INT,   .as_int   = 42      },
        { .kind = KIND_FLOAT, .as_float = 3.14    },
        { .kind = KIND_STR,   .as_str   = "hello" },
    };
    for (size_t i = 0; i < ARRAY_LEN(vals); i++) {
        value_print(&vals[i]);
    }

    /* Bit fields */
    Permission perm = { .read = 1, .write = 1, .execute = 0 };
    printf("perm: r=%u w=%u x=%u\n", perm.read, perm.write, perm.execute);

    pointer_demos();
    control_flow_demos();

    /* String helpers */
    const char *parts[] = {"Hello", "World", "from", "C"};
    char *joined = str_join(parts, ARRAY_LEN(parts), ", ");
    if (joined) {
        printf("Joined: %s\n", joined);
        free(joined);
    }

    DBG("Done. argc=%d", argc);
    (void)argv; /* suppress unused warning */
    return EXIT_SUCCESS;
}

typedef struct { unsigned q, r; } pair;
__attribute__((export_name("divmod"))) pair divmod(unsigned a, unsigned b) { return (pair){ a / b, a % b }; }

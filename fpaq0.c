#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
static int32_t predict(int16_t y) {
  static int16_t cxt = 1;
  static int32_t ct[256][2];
  if (++ct[cxt][y] > 65534)
    ct[cxt][0] >>= 1, ct[cxt][1] >>= 1;
  if ((cxt += cxt + y) >= 256) cxt = 1;
  return 4096 * (ct[cxt][1] + 1) / (ct[cxt][0] + ct[cxt][1] + 2);
}
typedef struct {
  uint32_t x, x1, x2, p;  FILE * stream;
} ac_t;
static void ac_read(ac_t * ac) {
  ac->x = (ac->x << 8) + (getc(ac->stream) & 255);
}
static void ac_init(ac_t * ac, bool encode, FILE * file) {
  ac->x = ac->x1 = 0;
  ac->x2 = 0xffffffff;
  ac->p = 2048;
  ac->stream = file;
  if (!encode) for (int i = 0; i < 4; ++i) ac_read(ac);
}
static void ac_flush(ac_t * ac) {
  putc(ac->x1 >> 24, ac->stream);
}
static void ac_rescale(ac_t * ac) {
  ac->x1 <<= 8;
  ac->x2 = (ac->x2 << 8) + 255;
}
#define AC_SPLIT(src) \
  int y;   \
  uint32_t range = ac->x2 - ac->x1, xmid; \
  xmid = (range >> 12) * ac->p + ((range & 0xfff) * ac->p >> 12); \
  xmid += ac->x1;  y = src;  ac->p = predict(y); \
  y ? (ac->x2 = xmid) : (ac->x1 = xmid + 1);
static void ac_encode_bit(ac_t * ac, int bit) {
  AC_SPLIT(bit);
  while (((ac->x1 ^ ac->x2) & 0xff000000) == 0)
    ac_flush(ac), ac_rescale(ac);
}
static int ac_decode_bit(ac_t * ac) {
  AC_SPLIT(ac->x <= xmid);
  while (((ac->x1 ^ ac->x2) & 0xff000000) == 0)
    ac_rescale(ac), ac_read(ac);
  return y;
}
static void encode(FILE * in, FILE * out) {
  fseek(in, 0, SEEK_END);
  for (int i = 24; i >= 0; i -= 8)
    putc(ftell(in) >> i, out);
  fseek(in, 0, SEEK_SET);
  ac_t ac; ac_init(&ac, true, out);
  for (int c; (c = getc(in)) != EOF; ) {
    for (int i = 7; i >= 0; --i)
      ac_encode_bit(&ac, (c >> i) & 1);
  }
  ac_flush(&ac);
}
static void decode(FILE * in, FILE * out) {
  int size = 0;
  for (int i = 24; i >= 0; i -= 8)
    size = (size << 8) + getc(in);
  ac_t ac; ac_init(&ac, false, in);
  for (int c, n; n < size; n++) {
    for (int i = 7; i >= 0; --i)
      c = (c << 1) + ac_decode_bit(&ac);
    putc(c, out);
  }
}
void usage(char * self) {
  fprintf(stderr, "Usage: %s [e|d] <infile> <outfile>\n", self);
}
int main(int argc, char * argv[]) {
  if (argc != 4) {
    usage(argv[0]);
    return 0;
  }
  int mode = argv[1][0];
  FILE * in, * out;
  if (!(in = fopen(argv[2], "rb"))) {
    fprintf(stderr, "Error: could not open %s\n", argv[1]);
    return 1;
  }
  if (!(out = fopen(argv[3], "wb"))) {
    fprintf(stderr, "Error: could not open %s\n", argv[2]);
    return 1;
  }
  if (mode == 'e')      encode(in, out);
  else if (mode == 'd') decode(in, out);
  else                  usage(argv[0]);
  fclose(in); fclose(out);
}

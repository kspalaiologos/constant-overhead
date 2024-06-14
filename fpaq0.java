import java.io.*;

public class fpaq0 {
  public int x1, x2, p;
  public short cxt = 1;
  public int[][] ct = new int[256][2];
  public short predict(int y) {
    if (++ct[cxt][y] > 65534)
      { ct[cxt][0] >>= 1; ct[cxt][1] >>= 1; }
    if ((cxt += cxt + y) >= 256)  cxt = 1;
    return (short) (4096 * (ct[cxt][1] + 1) / (ct[cxt][0] + ct[cxt][1] + 2));
  }
  public fpaq0_bench() {
    x1 = 0;  x2 = 0xffffffff;  p = 2048;
  }
  public void ac_flush(BufferedOutputStream out) throws IOException {
    out.write(x1 >>> 24);
  }
  public void ac_rescale() {
    x1 <<= 8;  x2 = (x2 << 8) + 255;
  }
  public void ac_encode_bit(int y, BufferedOutputStream out) throws IOException {
    int range = x2 - x1;
    int xmid = x1 + (range >>> 12) * p + (((range & 0xfff) * p) >>> 12);
    p = predict(y);
    if (y == 1) x2 = xmid; else x1 = xmid + 1;
    while (((x1 ^ x2) & 0xff000000) == 0)
      { ac_flush(out); ac_rescale(); }
  }
  public void encode_file(BufferedInputStream in, BufferedOutputStream out, long len) throws IOException {
    out.write((int) ((len >> 24) & 0xff));
    out.write((int) ((len >> 16) & 0xff));
    out.write((int) ((len >> 8) & 0xff));
    out.write((int) (len & 0xff));
    for (;;) {
      int c = in.read();
      if (c == -1) break;
      for (int i = 7; i >= 0; i--)
        ac_encode_bit((c >> i) & 1, out);
    }
    ac_flush(out);
  }
  public static void main(String[] args) throws IOException {
    FileInputStream in = new FileInputStream(args[0]);
    FileOutputStream out = new FileOutputStream(args[1]);
    fpaq0 main = new fpaq0();
    main.encode_file(new BufferedInputStream(in), new BufferedOutputStream(out), in.getChannel().size());
    in.close();
    out.close();
  }
}

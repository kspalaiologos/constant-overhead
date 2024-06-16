import java.io.*;

public final class fpaq0 {
  public static final class State {
    public int x1;
    public int x2;
    public int p;
    public int cxt;
    public int[][] ct;
    public State(int x1, int x2, int p, int cxt, int[][] ct) {
      this.x1 = x1;
      this.x2 = x2;
      this.p = p;
      this.cxt = cxt;
      this.ct = ct;
    }
    public State() {
      this(0, 0xFFFFFFFF, 2048, 1, new int[256][2]);
    }
  }
  public static short predict(State s, int y) {
    if (++s.ct[s.cxt][y] > 65534)
      { s.ct[s.cxt][0] >>= 1; s.ct[s.cxt][1] >>= 1; }
    if ((s.cxt += s.cxt + y) >= 256) s.cxt = 1;
    return (short) (4096 * (s.ct[s.cxt][1] + 1) / (s.ct[s.cxt][0] + s.ct[s.cxt][1] + 2));
  }
  public static void ac_flush(State s, BufferedOutputStream out) throws IOException {
    out.write(s.x1 >>> 24);
  }
  public static void ac_rescale(State s) {
    s.x1 <<= 8;
    s.x2 = (s.x2 << 8) + 255;
  }
  public static void ac_encode_bit(State s, int y, BufferedOutputStream out) throws IOException {
    int range = s.x2 - s.x1;
    int xmid = s.x1 + (range >>> 12) * s.p + (((range & 0xfff) * s.p) >>> 12);
    s.p = predict(s, y);
    if (y == 1) s.x2 = xmid; else s.x1 = xmid + 1;
    while (((s.x1 ^ s.x2) & 0xff000000) == 0)
      { ac_flush(s, out); ac_rescale(s); }
  }
  public static void encode_file(State s, BufferedInputStream in, BufferedOutputStream out, long len) throws IOException {
    out.write((int) ((len >> 24) & 0xff));
    out.write((int) ((len >> 16) & 0xff));
    out.write((int) ((len >> 8) & 0xff));
    out.write((int) (len & 0xff));
    for (;;) {
      int c = in.read();
      if (c == -1) break;
      for (int i = 7; i >= 0; i--)
        ac_encode_bit(s, (c >> i) & 1, out);
    }
    ac_flush(s, out);
  }
  public static void main(String[] args) throws IOException {
    FileInputStream in = new FileInputStream(args[0]);
    FileOutputStream out = new FileOutputStream(args[1]);
    State main = new State();
    encode_file(main, new BufferedInputStream(in), new BufferedOutputStream(out), in.getChannel().size());
    in.close();
    out.close();
  }
}

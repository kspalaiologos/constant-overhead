
const fs = require('fs');

let cxt = 1;  let ct = new Int32Array(256 * 2);
const predict = (y) => {
  if (++ct[cxt * 2 + y] > 65534)
    ct[cxt * 2] >>= 1, ct[cxt * 2 + 1] >>= 1;
  if ((cxt += cxt + y) >= 256) cxt = 1;
  return Math.floor((4096 * (ct[cxt * 2 + 1] + 1)) / (ct[cxt * 2] + ct[cxt * 2 + 1] + 2));
}

const BUFSIZ = 65536;

class InputWrapper {
  constructor(input) {
    this.input = input;
    this.buffer = new Uint8Array(BUFSIZ);
    this.pos = 65536;
  }
  read() {
    if (this.pos >= BUFSIZ) {
      fs.readSync(this.input, this.buffer, 0, BUFSIZ, null);
      this.pos = 0;
    }
    return this.buffer[this.pos++];
  }
}

class OutputWrapper {
  constructor(output) {
    this.output = output;
    this.buffer = new Uint8Array(BUFSIZ);
    this.pos = 0;
  }
  write(x) {
    if (this.pos >= BUFSIZ) {
      fs.writeSync(this.output, this.buffer, 0, this.pos, null);
      this.pos = 0;
    }
    this.buffer[this.pos++] = x;
  }
  flush() {
    fs.writeSync(this.output, this.buffer, 0, this.pos, null);
  }
}

class AC {
  constructor(stream) {
    this.x1 = 0;
    this.x2 = 0xFFFFFFFF;
    this.p = 2048;
    this.stream = stream;
  }
}

function ac_flush(self) {
  self.stream.write(self.x1 >> 24);
}
function ac_rescale(self) {
  self.x1 <<= 8;
  self.x2 = (self.x2 << 8) + 0xFF;
}
function ac_encode_bit(self, y) {
  let range = self.x2 - self.x1;
  let xmid = self.x1 + (range >>> 12) * self.p + ((range & 0xfff) * self.p >>> 12);
  self.p = predict(y);
  if (y) self.x2 = xmid;
  else self.x1 = xmid + 1;
  while (((self.x1 ^ self.x2) & 0xFF000000) === 0)
    { ac_flush(self); ac_rescale(self); }
}

const encode = (input, output, len) => {
  let ac = new AC(output);
  output.write((len >> 24) & 0xFF);
  output.write((len >> 16) & 0xFF);
  output.write((len >> 8) & 0xFF);
  output.write(len & 0xFF);
  for (let i = 0; i < len; i++) {
    let x = input.read();
    for (let j = 7; j >= 0; j--)
      ac_encode_bit(ac, (x >> j) & 1);
  }
  ac_flush(ac);
};

if (process.argv.length !== 4) {
  console.log("Usage: node fpaq0.js input output");
  process.exit(1);
}

const input = new InputWrapper(fs.openSync(process.argv[2], 'r'));
const output = new OutputWrapper(fs.openSync(process.argv[3], 'w'));
encode(input, output, fs.fstatSync(input.input).size);
output.flush();

cxt = 1
ct = [[0, 0] for _ in range(256)]
def predict(y):
    global cxt
    global ct
    ct[cxt][y] += 1
    if ct[cxt][y] > 65534:
        ct[cxt][0] >>= 1
        ct[cxt][1] >>= 1
    cxt += cxt + y
    if cxt >= 256:
        cxt = 1
    return (4096 * (ct[cxt][1] + 1)) // (ct[cxt][0] + ct[cxt][1] + 2)

class AC:
    def __init__(self, stream):
        self.stream = stream
        self.x1 = 0
        self.x2 = 0xFFFFFFFF
        self.p = 2048

def ac_flush(ac):
    ac.stream.write((ac.x1 >> 24).to_bytes(1, 'big'))

def ac_rescale(ac):
    ac.x1 <<= 8
    ac.x1 &= 0xFFFFFF00
    ac.x2 = (ac.x2 << 8) | 0xFF
    ac.x2 &= 0xFFFFFFFF

def ac_encode_bit(ac, bit):
    acrange = ac.x2 - ac.x1
    xmid = ac.x1 + (acrange >> 12) * ac.p + ((acrange & 0xFFF) * ac.p >> 12)
    ac.p = predict(bit)
    if bit: ac.x2 = xmid
    else:   ac.x1 = xmid + 1
    while ((ac.x1 ^ ac.x2) & 0xff000000) == 0:
        ac_flush(ac)
        ac_rescale(ac)

def encode(instream, outstream):
    ac = AC(outstream)
    instream.seek(0, 2)
    length = instream.tell()
    instream.seek(0)
    outstream.write(length.to_bytes(4, 'big'))
    while True:
        byte = instream.read(1)
        if not byte: break
        byte = byte[0]
        for i in range(8):
            ac_encode_bit(ac, (byte >> (7 - i)) & 1)
    ac_flush(ac)

import sys
with open(sys.argv[1], 'rb') as instream:
    with open(sys.argv[2], 'wb') as outstream:
        encode(instream, outstream)

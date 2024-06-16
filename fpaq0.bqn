#!/bin/env BQN

fopen  ← "/usr/lib/libc.so.6" •FFI "*"‿"fopen"‿"*u8"‿"*u8"
fclose ← "/usr/lib/libc.so.6" •FFI "i32"‿"fclose"‿"*"
fgetc  ← "/usr/lib/libc.so.6" •FFI "i32"‿"fgetc"‿"*"
fputc  ← "/usr/lib/libc.so.6" •FFI "i32"‿"fputc"‿"i32"‿"*"
fflush ← "/usr/lib/libc.so.6" •FFI "i32"‿"fflush"‿"*"

ctx ← 1
ct ← 256‿2⥊0

New ← {
    out ← 𝕩
    {
        x ← x1 ← 0
        x2 ← 4294967295
        p ← 2048
        Flush ⇐ {𝕩: 
            Fputc (⌊x1÷16777216)‿out 
            @
        }
        EncodeBit ⇐ {
            xmid ← 4294967296|x1+(p×⌊range÷4096)+⌊(p×4096|range←x2-x1)÷4096
            ct (1⊸+ ⌾ (ctx‿𝕩⊸⊑))↩
            ct ⌊∘÷⟜2 ⌾ (ctx⊸⊏) ⍟ (65534<ctx‿𝕩⊑ct)↩
            ctx 1⍟(256≤ctx +↩ ctx+𝕩) ↩
            p ↩ (4096×1+ctx‿1⊑ct)⌊∘÷2+´ctx⊏ct
            𝕩◶{𝕩:x1 ↩ xmid+1}‿{𝕩:x2 ↩ xmid} @
            {𝕩:
                Fputc (⌊x1÷16777216)‿out 
                x1 ↩ 4294967296|x1×256 
                x2 ↩ 4294967296|255+x2×256 
                @
            } •_while_ {𝕩:
                0≡⌊÷⟜16777216 4294967296|⊑ x1 32•bit._xor○(⥊-⟜(4294967296×≥⟜2147483648)) x2
            } @
        }
    }
}

EncodeFile ← {
in‿out:
    size ← •file.Size in
    in_stream ← Fopen 0∾¨˜ @-˜in‿"r"
    out_stream ← Fopen 0∾¨˜ @-˜out‿"w"
    {Fputc 𝕩‿out_stream}¨ ⌽⥊32‿8•bit._cast ⥊-⟜(4294967296×≥⟜2147483648)size
    ac ← New out_stream
    c ← 0
    {𝕩:ac.EncodeBit¨⌽8‿1•bit._cast⥊-⟜(256×≥⟜128)c} •_while_ {𝕩:¯1≢c↩Fgetc ⥊in_stream} @
    ac.Flush @
    Fclose∘⥊¨ in_stream‿out_stream
}

EncodeFile •args

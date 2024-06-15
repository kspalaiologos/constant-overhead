#!/bin/env BQN

fopen  ← "/usr/lib/libc.so.6" •FFI "u64"‿"fopen"‿"*u8"‿"*u8"
fclose ← "/usr/lib/libc.so.6" •FFI "i32"‿"fclose"‿"u64"
fgetc  ← "/usr/lib/libc.so.6" •FFI "i32"‿"fgetc"‿"u64"
fputc  ← "/usr/lib/libc.so.6" •FFI "i32"‿"fputc"‿"i32"‿"u64"
fflush ← "/usr/lib/libc.so.6" •FFI "i32"‿"fflush"‿"u64"

High  ← ⌊∘÷⟜16777216
Trunc ← 4294967296⊸|
Xor   ← Trunc∘⊑ 32•bit._xor○{⥊𝕩-(𝕩≥2147483648)×4294967296}

ctx ← 1
ct ← 256‿2⥊0
Predict ← {
	ct (1⊸+ ⌾ (ctx‿𝕩⊸⊑))↩
	ct ⌊∘÷⟜2 ⌾ (ctx⊸⊏) ⍟ (65534<ctx‿𝕩⊑ct)↩
	ctx 1⍟(256≤ctx +↩ ctx+𝕩) ↩
	(4096×1+ctx‿1⊑ct)⌊∘÷2+´ctx⊏ct
}

New ← {
	out ← 𝕩
	{
		x ← 0
		x1 ← 0
		x2 ← 4294967295
		p ← 2048
		Flush ⇐ {𝕩: Fputc (High x1)‿out ⋄@}
		Rescale ← {𝕩:x1 ↩ Trunc x1×256 ⋄ x2 ↩ Trunc 255+256×x2 ⋄@}
		EncodeBit ⇐ {
			xmid ← Trunc x1 + (p×range⌊∘÷4096) + (p×4096|range←x2-x1) ⌊∘÷ 4096
			p ↩ Predict 𝕩
			𝕩◶{𝕩:x1 ↩ xmid+1}‿{𝕩:x2 ↩ xmid} @
			Rescale∘Flush •_while_ {𝕩:0≡High x1 Xor x2} @
		}
	}
}

EncodeFile ← {
in‿out:
	size ← •file.Size in
	in_stream ← Fopen 0∾¨˜ @-˜  in‿"r"
	out_stream ← Fopen 0∾¨˜ @-˜ out‿"w"
	{Fputc 𝕩‿out_stream}¨ ⌽⥊32‿8 •bit._cast ⥊size
	ac ← New out_stream
	c ← 0
	{𝕩:ac.EncodeBit¨ ⌽8‿1•bit._cast⥊{𝕩-(𝕩≥128)×256}c} •_while_ {𝕩:¯1≢c↩Fgetc ⥊in_stream} @
	ac.Flush @
	Fclose∘⥊¨ in_stream‿out_stream
}

EncodeFile •args

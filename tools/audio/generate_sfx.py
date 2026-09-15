# tools/audio/generate_sfx.py
"""
NUSAMON — Placeholder Audio Generator (terprogram, deterministik).

Membangkitkan suara placeholder "gamelan-ambient" (strike envelope + overtone,
skala slendro-approksimasi) untuk menutup langkah 5 Fase 5 sampai aset
CC0/produksi asli dipasang (lihat assets/audio/README.md).

Cara pakai:
    python tools/audio/generate_sfx.py --all --out assets/audio

Konvensi:
- Mono 16-bit 22050 Hz (ringan untuk Web export)
- Deterministik: tanpa RNG — hasil identik setiap dijalankan
- Nama file = id di data/audio.json (snake_case, konsisten AudioManager)
"""

import argparse
import math
import os
import struct
import wave

SR = 22050   # sample rate placeholder

# Skala slendro-approksimasi (rasio terhadap nada dasar)
SELENDRO = [1.0, 1.19, 1.33, 1.6, 1.78]


def strike(freq, dur, amp=0.5, decay=6.0, overtone=2.756, attack=0.004):
    """Gamelan-like strike: sine dasar + overtone lonceng, envelope exp decay."""
    n = int(SR * dur)
    hasil = []
    for i in range(n):
        t = i / SR
        env = math.exp(-decay * t) * min(1.0, t / max(attack, 1e-6))
        s = math.sin(2.0 * math.pi * freq * t)
        s += 0.35 * math.sin(2.0 * math.pi * freq * overtone * t)
        s += 0.12 * math.sin(2.0 * math.pi * freq * 4.9 * t)
        hasil.append(amp * env * s / 1.47)
    return hasil


def sweep(freq0, freq1, dur, amp=0.4, decay=3.0):
    """Pitch glide sederhana (hit/miss/pingsan/naik)."""
    n = int(SR * dur)
    hasil = []
    fase = 0.0
    for i in range(n):
        t = i / SR
        freq = freq0 + (freq1 - freq0) * (i / max(1, n - 1))
        fase += 2.0 * math.pi * freq / SR
        env = math.exp(-decay * t) * min(1.0, t / 0.003)
        hasil.append(amp * env * math.sin(fase))
    return hasil


def mix(base, add, at=0.0):
    """Campur `add` ke `base` mulai detik `at` (tanpa clipping — di-normalisasi akhir)."""
    idx = int(at * SR)
    while len(base) < idx + len(add):
        base.append(0.0)
    for i, s in enumerate(add):
        base[idx + i] += s
    return base


def fade_out(samp, dur=0.12):
    """Fade akhir agar loop BGM tidak klik."""
    n = int(SR * dur)
    if n >= len(samp):
        return samp
    for i in range(n):
        samp[-1 - i] *= i / n
    return samp


def tulis_wav(path, samp, gain=0.88):
    """Normalisasi + tulis WAV mono 16-bit."""
    peak = max(1e-9, max(abs(s) for s in samp))
    skala = gain / peak
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(
            struct.pack("<h", int(max(-1.0, min(1.0, s * skala)) * 32767))
            for s in samp))


# ---------------------------------------------------------------- SFX & jingle

def sfx_ui_klik():
    return strike(660.0, 0.09, amp=0.35, decay=42.0)


def sfx_serang_hit():
    samp = mix([], sweep(320.0, 180.0, 0.16, amp=0.5, decay=14.0))
    return mix(samp, strike(440.0, 0.12, amp=0.4, decay=22.0), at=0.0)


def sfx_serang_miss():
    return sweep(500.0, 700.0, 0.14, amp=0.22, decay=16.0)


def sfx_pingsan():
    return sweep(440.0, 100.0, 0.45, amp=0.45, decay=6.0)


def sfx_lempar_amukan():
    return sweep(280.0, 720.0, 0.28, amp=0.4, decay=9.0)


def sfx_tangkap_sukses():
    samp = mix([], strike(523.0, 0.18, amp=0.4, decay=14.0))
    samp = mix(samp, strike(659.0, 0.18, amp=0.4, decay=14.0), at=0.12)
    return mix(samp, strike(784.0, 0.3, amp=0.45, decay=8.0), at=0.24)


def sfx_tangkap_gagal():
    samp = mix([], strike(392.0, 0.16, amp=0.38, decay=16.0))
    return mix(samp, strike(261.0, 0.24, amp=0.38, decay=10.0), at=0.14)


def sfx_naik_level():
    samp = mix([], strike(587.0, 0.16, amp=0.4, decay=14.0))
    return mix(samp, strike(740.0, 0.26, amp=0.44, decay=9.0), at=0.12)


def sfx_evolusi():
    samp = mix([], sweep(220.0, 880.0, 1.1, amp=0.35, decay=1.6))
    return mix(samp, strike(440.0, 0.5, amp=0.4, decay=4.0), at=1.0)


def sfx_pulihkan():
    samp = mix([], strike(523.0, 0.4, amp=0.32, decay=5.0))
    return mix(samp, strike(659.0, 0.5, amp=0.32, decay=4.5), at=0.1)


def sfx_gate_terkunci():
    samp = mix([], strike(165.0, 0.18, amp=0.45, decay=18.0))
    return mix(samp, strike(147.0, 0.26, amp=0.45, decay=12.0), at=0.12)


def jingle_menang():
    nada = [(523.0, 0.0), (659.0, 0.15), (784.0, 0.3), (1046.0, 0.45)]
    samp = []
    for f, at in nada:
        samp = mix(samp, strike(f, 0.35, amp=0.4, decay=9.0), at=at)
    return mix(samp, strike(1046.0, 0.6, amp=0.35, decay=4.0), at=0.7)


def jingle_lencana():
    nada = [(587.0, 0.0), (740.0, 0.16), (880.0, 0.32), (1174.0, 0.5)]
    samp = []
    for f, at in nada:
        samp = mix(samp, strike(f, 0.4, amp=0.42, decay=8.0), at=at)
    return mix(samp, strike(880.0, 0.7, amp=0.3, decay=3.5), at=0.8)


def sting_legendary():
    samp = mix([], strike(110.0, 2.4, amp=0.5, decay=1.8, overtone=3.4))
    samp = mix(samp, sweep(440.0, 1100.0, 1.6, amp=0.2, decay=1.4), at=0.3)
    return mix(samp, strike(220.0, 1.8, amp=0.35, decay=2.2), at=0.6)


# ---------------------------------------------------------------- BGM (loop)

def _arpeggio(pool, pola, beat, amp, decay):
    """Baris melodi: pola = daftar indeks nada (atau -1 = jeda)."""
    samp = []
    for i, idx in enumerate(pola):
        if idx < 0:
            continue
        samp = mix(samp, strike(220.0 * pool[idx % len(pool)],
                                beat * 2.2, amp=amp, decay=decay), at=i * beat)
    return samp


def bgm_jawa():
    """Loop dunia 16 detik — pentatonik tenang, gong dasar tiap blok."""
    beat = 0.5
    pola = [0, 2, 1, 3, 2, 4, 3, 1, 0, 2, 1, 3, 4, 2, 3, 0]
    samp = _arpeggio(SELENDRO, pola, beat, 0.3, 4.0)
    for blok in range(4):
        samp = mix(samp, strike(110.0, 2.5, amp=0.28, decay=1.6), at=blok * 4.0)
    return fade_out(samp, 0.15)


def bgm_battle():
    """Loop battle 8 detik — tempo cepat, bass menekan tiap 1 ketukan."""
    beat = 0.25
    pola = [2, 0, 3, 1, 4, 2, 1, 0, 3, 2, 4, 3, 1, 4, 0, 2,
            2, 0, 3, 1, 4, 2, 1, 0, 4, 3, 2, 4, 1, 0, 3, 2]
    samp = _arpeggio(SELENDRO, pola, beat, 0.26, 7.0)
    for i in range(8):
        samp = mix(samp, strike(146.0, 0.5, amp=0.3, decay=6.0), at=i * 1.0)
    return fade_out(samp, 0.12)


def bgm_liga():
    """Loop liga 12 detik — megah lambat, register rendah + oktaf."""
    beat = 0.75
    pola = [0, 2, 4, 3, 2, 4, 0, 3, 1, 4, 2, 0]
    samp = _arpeggio([1.0, 1.19, 1.33, 1.6, 1.78, 2.0], pola, beat, 0.28, 2.6)
    for i in range(4):
        samp = mix(samp, strike(98.0, 3.0, amp=0.3, decay=1.2), at=i * 3.0)
    return fade_out(samp, 0.2)


# ---------------------------------------------------------------- registry & CLI

BUILDERS = {
    "bgm_jawa": bgm_jawa,
    "bgm_battle": bgm_battle,
    "bgm_liga": bgm_liga,
    "jingle_menang": jingle_menang,
    "jingle_lencana": jingle_lencana,
    "sting_legendary": sting_legendary,
    "sfx_ui_klik": sfx_ui_klik,
    "sfx_serang_hit": sfx_serang_hit,
    "sfx_serang_miss": sfx_serang_miss,
    "sfx_pingsan": sfx_pingsan,
    "sfx_lempar_amukan": sfx_lempar_amukan,
    "sfx_tangkap_sukses": sfx_tangkap_sukses,
    "sfx_tangkap_gagal": sfx_tangkap_gagal,
    "sfx_naik_level": sfx_naik_level,
    "sfx_evolusi": sfx_evolusi,
    "sfx_pulihkan": sfx_pulihkan,
    "sfx_gate_terkunci": sfx_gate_terkunci,
}


def main():
    p = argparse.ArgumentParser(description="NUSAMON placeholder audio generator")
    p.add_argument("--id", default="all", help="id audio dipisah koma, atau 'all'")
    p.add_argument("--out", default="assets/audio", help="folder output .wav")
    args = p.parse_args()
    ids = list(BUILDERS) if args.id.strip().lower() == "all" else [
        s.strip() for s in args.id.split(",") if s.strip()]
    for sid in ids:
        if sid not in BUILDERS:
            print("[NUSAMON] id audio tidak dikenal, dilewati:", sid)
            continue
        out = os.path.join(args.out, sid + ".wav")
        tulis_wav(out, BUILDERS[sid]())
        print("[NUSAMON] OK:", out)


if __name__ == "__main__":
    main()


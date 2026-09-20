#!/usr/bin/env python3
"""Synthesises Baaa/Resources/chappal.wav: a short whoosh, then a rubber slap.

Pure standard library, deterministic. Total 0.42s so that, played 0.18s after a
throw starts, the slap lands at the 0.55s impact used by NotchView's keyframes.
"""
import math, random, struct, wave, pathlib

RATE = 44100
random.seed(11)
n = int(RATE * 0.42)
out = [0.0] * n

# Whoosh: low-passed noise with a rising cutoff and a swell.
lp = 0.0
for i in range(int(RATE * 0.34)):
    t = i / RATE
    env = math.sin(math.pi * min(1.0, t / 0.34)) ** 1.8
    a = 0.015 + 0.20 * (t / 0.34)
    lp += a * (random.uniform(-1, 1) - lp)
    out[i] += lp * env * 0.7

# Slap: a fat, short burst (rubber on skin), low-passed so it thuds rather than
# cracks, with a quick second bounce underneath.
start = int(RATE * 0.335)
lp = 0.0
for i in range(int(RATE * 0.085)):
    t = i / RATE
    lp += 0.45 * (random.uniform(-1, 1) - lp)
    env = math.exp(-t * 70) * (1 if t > 0.001 else t / 0.001)
    thud = math.sin(2 * math.pi * 210 * t) * math.exp(-t * 60) * 0.5
    bounce = math.exp(-max(0.0, t - 0.028) * 140) * (0.35 if t > 0.028 else 0.0) * lp
    out[start + i] += (lp * 1.1 + thud + bounce) * env

tail = int(RATE * 0.02)
for i in range(tail):
    out[n - tail + i] *= 1 - i / tail

peak = max(abs(v) for v in out) or 1.0
frames = b"".join(struct.pack("<h", int(max(-1, min(1, v / peak * 0.92)) * 32767)) for v in out)
dest = pathlib.Path(__file__).resolve().parent.parent / "Baaa" / "Resources" / "chappal.wav"
with wave.open(str(dest), "wb") as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(RATE); w.writeframes(frames)
print("wrote", dest, f"{n / RATE:.2f}s")

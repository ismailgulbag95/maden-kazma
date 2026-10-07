"""Generate the original, seamless 60-second Taşın Altı mine soundtrack."""

from pathlib import Path
import math
import wave

import numpy as np


SAMPLE_RATE = 22_050
BPM = 96
BEAT = 60 / BPM
BAR = BEAT * 4
BARS = 24
DURATION = BAR * BARS
SAMPLES = round(SAMPLE_RATE * DURATION)
OUTPUT = Path(__file__).resolve().parents[1] / "assets" / "audio" / "bgm_loop.wav"

mix = np.zeros((SAMPLES, 2), dtype=np.float64)
rng = np.random.default_rng(314159)


def midi_hz(note: int) -> float:
    return 440 * 2 ** ((note - 69) / 12)


def add_signal(start: float, left: np.ndarray, right: np.ndarray) -> None:
    offset = round(start * SAMPLE_RATE)
    if offset >= SAMPLES:
        return
    count = min(len(left), len(right), SAMPLES - offset)
    if count > 0:
        mix[offset : offset + count, 0] += left[:count]
        mix[offset : offset + count, 1] += right[:count]


def add_note(
    note: int,
    start: float,
    duration: float,
    amplitude: float,
    voice: str,
    pan: float = 0.0,
) -> None:
    count = min(round(duration * SAMPLE_RATE), SAMPLES - round(start * SAMPLE_RATE))
    if count <= 0:
        return
    t = np.arange(count, dtype=np.float64) / SAMPLE_RATE
    frequency = midi_hz(note)
    if voice == "pad":
        attack = np.minimum(1.0, t / 0.34)
        release = np.minimum(1.0, (duration - t) / 0.42)
        envelope = np.minimum(attack, release) * (0.94 + 0.06 * np.sin(2 * np.pi * 0.12 * t))
        left_wave = (
            0.68 * np.sin(2 * np.pi * frequency * 0.998 * t)
            + 0.20 * np.sin(2 * np.pi * frequency * 2.002 * t)
            + 0.07 * np.sin(2 * np.pi * frequency * 3.0 * t)
        )
        right_wave = (
            0.68 * np.sin(2 * np.pi * frequency * 1.002 * t)
            + 0.20 * np.sin(2 * np.pi * frequency * 1.998 * t)
            + 0.07 * np.sin(2 * np.pi * frequency * 3.006 * t)
        )
    elif voice == "bass":
        envelope = np.minimum(1.0, t / 0.025) * np.exp(-t * 2.6)
        left_wave = np.sin(2 * np.pi * frequency * t) + 0.10 * np.sin(4 * np.pi * frequency * t)
        right_wave = np.sin(2 * np.pi * frequency * 1.002 * t) + 0.10 * np.sin(4 * np.pi * frequency * t)
    else:  # soft hammered dulcimer / bell pluck
        envelope = (1 - np.exp(-t * 70)) * np.exp(-t * 3.4)
        left_wave = (
            0.76 * np.sin(2 * np.pi * frequency * t)
            + 0.19 * np.sin(2 * np.pi * frequency * 2.01 * t)
            + 0.07 * np.sin(2 * np.pi * frequency * 3.97 * t)
        )
        right_wave = (
            0.76 * np.sin(2 * np.pi * frequency * 1.001 * t)
            + 0.19 * np.sin(2 * np.pi * frequency * 2.0 * 1.001 * t)
            + 0.07 * np.sin(2 * np.pi * frequency * 4.01 * t)
        )

    left_gain = math.sqrt((1 - pan) * 0.5)
    right_gain = math.sqrt((1 + pan) * 0.5)
    add_signal(
        start,
        left_wave * envelope * amplitude * left_gain,
        right_wave * envelope * amplitude * right_gain,
    )


def add_kick(start: float, amplitude: float) -> None:
    duration = 0.20
    t = np.arange(round(duration * SAMPLE_RATE), dtype=np.float64) / SAMPLE_RATE
    phase = 2 * np.pi * (48 * t + 72 * (1 - np.exp(-t * 28)) / 28)
    wave = np.sin(phase) * np.exp(-t * 17)
    add_signal(start, wave * amplitude * 0.72, wave * amplitude * 0.72)


def add_metal_tick(start: float, amplitude: float, pan: float) -> None:
    duration = 0.11
    t = np.arange(round(duration * SAMPLE_RATE), dtype=np.float64) / SAMPLE_RATE
    noise = rng.normal(0, 1, len(t))
    ring = 0.72 * np.sin(2 * np.pi * 1120 * t) + 0.28 * np.sin(2 * np.pi * 1830 * t)
    sound = (0.32 * noise + ring) * np.exp(-t * 35)
    add_signal(
        start,
        sound * amplitude * math.sqrt((1 - pan) * 0.5),
        sound * amplitude * math.sqrt((1 + pan) * 0.5),
    )


CHORDS = {
    "Gm": (43, 50, 58, 62),
    "Eb": (39, 46, 55, 58),
    "Bb": (46, 53, 58, 62),
    "F": (41, 48, 53, 57),
    "Cm": (36, 43, 51, 55),
    "D": (38, 45, 54, 57),
    "C": (36, 43, 52, 55),
}
PROGRESSION = [
    "Gm", "Eb", "Bb", "F", "Cm", "Eb", "D", "D",
    "Gm", "Bb", "F", "C", "Eb", "Bb", "D", "D",
    "Gm", "Eb", "Bb", "F", "Cm", "D", "Gm", "D",
]
MELODIES = [
    (67, None, 70, 74, None, 77, 74, 70),
    (67, None, 70, None, 74, 77, 74, None),
    (70, 74, None, 77, 74, None, 70, 67),
    (67, None, 70, 74, 77, None, 74, 70),
]


for bar_index, chord_name in enumerate(PROGRESSION):
    bar_start = bar_index * BAR
    chord = CHORDS[chord_name]
    section_gain = (0.76, 0.90, 1.0)[bar_index // 8]

    # Slow, warm chord bed with a fifth and a softly doubled upper voice.
    for voice_index, note in enumerate(chord):
        add_note(
            note,
            bar_start,
            BAR,
            0.052 * section_gain,
            "pad",
            pan=(-0.22, 0.16, -0.08, 0.24)[voice_index],
        )

    # A steady, low lift gives the mine a calm mechanical pulse.
    bass_root = chord[0] - 12
    add_note(bass_root, bar_start, BEAT * 1.8, 0.105 * section_gain, "bass", -0.08)
    add_note(bass_root + 7, bar_start + BEAT * 2, BEAT * 1.7, 0.075 * section_gain, "bass", 0.08)
    add_kick(bar_start, 0.072 * section_gain)
    add_kick(bar_start + BEAT * 2, 0.048 * section_gain)
    add_metal_tick(bar_start + BEAT, 0.023 * section_gain, -0.28)
    add_metal_tick(bar_start + BEAT * 3, 0.026 * section_gain, 0.30)

    # The same small melodic idea changes its ending through each 8-bar phrase.
    melody = MELODIES[(bar_index + bar_index // 8) % len(MELODIES)]
    if bar_index % 8 not in (6, 7):
        for step, note in enumerate(melody):
            if note is None:
                continue
            note = note + (12 if bar_index >= 16 and step in (3, 5) else 0)
            start = bar_start + step * (BEAT / 2)
            pan = -0.24 if step % 2 == 0 else 0.24
            add_note(note, start, 0.88, 0.078 * section_gain, "pluck", pan)
            # A quiet, opposite-side echo widens the little hand-played motif.
            add_note(note, start + 0.24, 0.58, 0.020 * section_gain, "pluck", -pan)

    if bar_index % 2 == 1:
        add_metal_tick(bar_start + BEAT * 0.5, 0.010 * section_gain, 0.45)
        add_metal_tick(bar_start + BEAT * 2.5, 0.011 * section_gain, -0.45)

# Shape the loop seam into a gentle dominant-to-tonic handoff.
fade_samples = round(0.42 * SAMPLE_RATE)
fade = np.linspace(0, 1, fade_samples, endpoint=True)[:, None]
mix[-fade_samples:] = mix[-fade_samples:] * (1 - fade) + mix[:fade_samples] * fade
mix[: round(0.18 * SAMPLE_RATE)] *= np.linspace(0, 1, round(0.18 * SAMPLE_RATE))[:, None]

# Mild saturation keeps the soft layers audible without sharp peaks.
mix = np.tanh(mix * 1.35)
peak = float(np.max(np.abs(mix)))
if peak > 0:
    mix *= 0.88 / peak

pcm = np.round(np.clip(mix, -1, 1) * 32767).astype("<i2")
OUTPUT.parent.mkdir(parents=True, exist_ok=True)
with wave.open(str(OUTPUT), "wb") as wav:
    wav.setnchannels(2)
    wav.setsampwidth(2)
    wav.setframerate(SAMPLE_RATE)
    wav.writeframes(pcm.tobytes())

print(f"Wrote {OUTPUT} ({DURATION:.1f}s, {SAMPLE_RATE} Hz, stereo)")

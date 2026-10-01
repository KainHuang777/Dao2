"""Render original, one-minute Dao2 theme sketches as MIDI and Ogg previews.

Requires numpy and ffmpeg. The Ogg files are synthesized review drafts, not final
instrument recordings. Run from the project root with:
    python tools/compose_theme_prototypes.py
"""

from __future__ import annotations

import shutil
import struct
import subprocess
import tempfile
import wave
from pathlib import Path

import numpy as np


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "audio" / "theme_prototypes" / "v2"
BPM = 64
BEAT = 60.0 / BPM
BAR = 4.0 * BEAT
DURATION = 16.0 * BAR  # Exactly 60 seconds.
SAMPLE_RATE = 24_000
SAMPLES = round(DURATION * SAMPLE_RATE)

PITCH = {
    "C3": 48, "D3": 50, "Eb3": 51, "F3": 53, "G3": 55,
    "Ab3": 56, "Bb3": 58, "C4": 60, "D4": 62, "Eb4": 63,
    "F4": 65, "G4": 67, "Ab4": 68, "Bb4": 70, "C5": 72,
}

# Version 2: more singable, fewer notes and rests. The reference's dominant
# pitch-class region informed the C-minor palette; no reference phrase is copied.
MOTIF = [
    (0, 0.5, "Eb4", 1.5), (0, 2.0, "G4", 1.0), (0, 3.0, "F4", 1.0),
    (1, 0.0, "Eb4", 1.0), (1, 1.0, "C4", 2.0),
    (2, 0.0, "G4", 1.0), (2, 1.0, "Bb4", 1.0), (2, 2.0, "C5", 2.0),
    (3, 0.0, "Bb4", 1.0), (3, 1.0, "G4", 1.0),
    (3, 2.0, "F4", 1.0), (3, 3.0, "D4", 1.0),
]

# The final bar is a shared C/G bridge in all versions. A scene may change
# there without changing tempo, meter, root or the atmospheric bass layer.
CHORDS = [
    ["C3", "G3", "Eb4"],         # Cm
    ["Ab3", "C4", "Eb4", "G4"], # Abmaj7
    ["G3", "Bb3", "C4", "Eb4"], # Eb6/G
    ["G3", "Bb3", "D4", "F4"],  # Gm7
]
BRIDGE = ["C3", "G3", "D4"]

VARIANTS = {
    "00_theme_lead": {"lead": "piano", "pad": "warm", "pluck": False,
                      "lead_gain": 0.32, "pad_gain": 0.0, "drum": 0.0},
    "01_abode": {"lead": "flute", "pad": "warm", "pluck": True,
                 "lead_gain": 0.22, "pad_gain": 0.12, "drum": 0.0},
    "02_meditation": {"lead": "bell", "pad": "air", "pluck": True,
                      "lead_gain": 0.14, "pad_gain": 0.10, "drum": 0.0},
    "03_breakthrough": {"lead": "organ", "pad": "warm", "pluck": True,
                        "lead_gain": 0.19, "pad_gain": 0.15, "drum": 0.030},
    "04_reincarnation": {"lead": "flute", "pad": "air", "pluck": False,
                          "lead_gain": 0.14, "pad_gain": 0.11, "drum": 0.0},
    "05_cosmos": {"lead": "organ", "pad": "air", "pluck": False,
                  "lead_gain": 0.15, "pad_gain": 0.14, "drum": 0.0},
}


def envelope(n: int, attack: float, release: float, decay: float = 0.0) -> np.ndarray:
    t = np.arange(n, dtype=np.float32) / SAMPLE_RATE
    duration = n / SAMPLE_RATE
    a = np.minimum(1.0, t / max(attack, 0.001))
    r = np.minimum(1.0, (duration - t) / max(release, 0.001))
    d = np.exp(-decay * t)
    return np.maximum(0.0, np.minimum(a, r)) * d


def tone(pitch: int, duration: float, kind: str) -> np.ndarray:
    n = max(1, round(duration * SAMPLE_RATE))
    t = np.arange(n, dtype=np.float32) / SAMPLE_RATE
    freq = 440.0 * (2.0 ** ((pitch - 69) / 12.0))
    phase = 2.0 * np.pi * freq * t
    if kind == "flute":
        vibrato = 0.012 * np.sin(2.0 * np.pi * 4.7 * t)
        wave_data = np.sin(phase + vibrato) + 0.11 * np.sin(2 * phase)
        env = envelope(n, 0.20, 0.30)
    elif kind == "bell":
        wave_data = (np.sin(phase) + 0.35 * np.sin(2.01 * phase)
                     + 0.16 * np.sin(3.96 * phase))
        env = envelope(n, 0.005, 0.22, 1.6)
    elif kind == "piano":
        wave_data = (np.sin(phase) + 0.26 * np.sin(2 * phase)
                     + 0.11 * np.sin(3 * phase))
        env = envelope(n, 0.006, 0.16, 0.48)
    elif kind == "organ":
        wave_data = (np.sin(phase) + 0.34 * np.sin(2 * phase)
                     + 0.12 * np.sin(3 * phase))
        env = envelope(n, 0.24, 0.50)
    elif kind == "pluck":
        wave_data = (np.sin(phase) + 0.32 * np.sin(2 * phase)
                     + 0.13 * np.sin(3 * phase))
        env = envelope(n, 0.004, 0.18, 2.8)
    else:  # Continuous warm/air pads.
        wave_data = np.sin(phase) + (0.18 if kind == "warm" else 0.04) * np.sin(2 * phase)
        env = envelope(n, 0.65, 0.85)
    return (wave_data * env).astype(np.float32)


def add_event(bus: np.ndarray, at: float, pitch: int, length: float,
              kind: str, gain: float) -> None:
    sound = tone(pitch, length, kind) * gain
    start = round(at * SAMPLE_RATE)
    for offset in (-SAMPLES, 0, SAMPLES):
        a = start + offset
        left, right = max(a, 0), min(a + len(sound), SAMPLES)
        if right > left:
            bus[left:right] += sound[left - a:right - a]


def pulse(bus: np.ndarray, at: float, gain: float) -> None:
    n = round(0.25 * SAMPLE_RATE)
    t = np.arange(n, dtype=np.float32) / SAMPLE_RATE
    body = np.sin(2.0 * np.pi * (78.0 * t - 80.0 * t * t)) * np.exp(-22.0 * t)
    start = round(at * SAMPLE_RATE)
    for offset in (-SAMPLES, 0, SAMPLES):
        a = start + offset
        left, right = max(a, 0), min(a + n, SAMPLES)
        if right > left:
            bus[left:right] += body[left - a:right - a] * gain


def events_for(name: str) -> tuple[list[tuple[float, int, float, str, float]], list[tuple[float, float]]]:
    cfg = VARIANTS[name]
    events: list[tuple[float, int, float, str, float]] = []
    pulses: list[tuple[float, float]] = []
    for bar in range(16):
        chord = BRIDGE if bar == 15 else CHORDS[bar % 4]
        if cfg["pad_gain"] > 0:
            for index, note in enumerate(chord):
                pitch = PITCH[note]
                events.append((bar * BAR, pitch, BAR + 0.8, cfg["pad"],
                               cfg["pad_gain"] / (2.2 + index * 0.5)))
        if cfg["pluck"] and bar != 15:
            for beat_index in (0.0, 1.5, 2.5):
                pitch = PITCH[chord[int(beat_index * 2) % len(chord)]]
                events.append((bar * BAR + beat_index * BEAT, pitch + 12,
                               1.1, "pluck", 0.036 if name != "03_breakthrough" else 0.05))
        if cfg["drum"] and bar < 15:
            pulses.append((bar * BAR, cfg["drum"]))
            pulses.append((bar * BAR + 2 * BEAT, cfg["drum"] * 0.55))

    for cycle in range(4):
        for motif_bar, beat, note, length in MOTIF:
            bar = cycle * 4 + motif_bar
            if bar == 15:
                continue  # Shared bridge is sparse and has no lead melody.
            if name == "02_meditation" and cycle in (0, 2):
                continue
            if name == "04_reincarnation" and cycle in (0, 2) and beat not in (0.0, 0.5, 2.0):
                continue
            pitch = PITCH[note]
            if name == "05_cosmos":
                pitch -= 12
            if name == "03_breakthrough" and cycle == 2:
                pitch += 12
            gain = cfg["lead_gain"] * (0.75 if cycle == 0 else 1.0)
            events.append((bar * BAR + beat * BEAT, pitch,
                           length * BEAT * (0.88 if name != "05_cosmos" else 1.1),
                           cfg["lead"], gain))

    # A shared quiet fifth survives the final bar and the next first beat.
    if name == "00_theme_lead":
        events.append((15 * BAR, PITCH["C4"], BAR + 1.0, "piano", 0.11))
    else:
        events.append((15 * BAR, PITCH["C3"], BAR + 1.4, "warm", 0.048))
        events.append((15 * BAR, PITCH["G3"], BAR + 1.4, "warm", 0.031))
    return events, pulses


def varlen(value: int) -> bytes:
    result = [value & 0x7F]
    value >>= 7
    while value:
        result.insert(0, 0x80 | (value & 0x7F))
        value >>= 7
    return bytes(result)


def write_midi(path: Path, events: list[tuple[float, int, float, str, float]]) -> None:
    # Type 1 MIDI with separate editable instrument tracks, 480 ticks/beat.
    assignments = {"flute": (0, 73), "bell": (1, 9), "organ": (2, 19),
                   "pluck": (3, 24), "warm": (4, 48), "air": (5, 89)}
    assignments["piano"] = (6, 0)
    grouped: dict[str, list[tuple[int, int, bytes]]] = {}
    for at, pitch, length, kind, gain in events:
        onset = round(at / BEAT * 480)
        end = min(16 * 4 * 480, round((at + length) / BEAT * 480))
        velocity = min(105, max(38, round(64 + gain * 95)))
        if end > onset:
            channel = assignments[kind][0]
            grouped.setdefault(kind, []).append((onset, 2, bytes((0x90 | channel, pitch, velocity))))
            grouped[kind].append((end, 1, bytes((0x80 | channel, pitch, 0))))

    def track(messages: list[tuple[int, int, bytes]]) -> bytes:
        messages.sort(key=lambda item: (item[0], item[1]))
        data = bytearray()
        previous = 0
        for tick, _, message in messages:
            data.extend(varlen(tick - previous))
            data.extend(message)
            previous = tick
        data.extend(varlen(16 * 4 * 480 - previous))
        data.extend(b"\xff\x2f\x00")
        return b"MTrk" + struct.pack(">I", len(data)) + data

    tracks = [track([(0, 0, b"\xff\x51\x03" + (937500).to_bytes(3, "big")),
                     (0, 0, b"\xff\x58\x04\x04\x02\x18\x08")])]
    for kind in sorted(grouped):
        channel, program = assignments[kind]
        tracks.append(track([(0, 0, bytes((0xC0 | channel, program)))] + grouped[kind]))
    path.write_bytes(b"MThd" + struct.pack(">IHHH", 6, 1, len(tracks), 480)
                     + b"".join(tracks))


def render(name: str) -> None:
    events, pulses = events_for(name)
    bus = np.zeros(SAMPLES, dtype=np.float32)
    for at, pitch, length, kind, gain in events:
        add_event(bus, at, pitch, length, kind, gain)
    for at, gain in pulses:
        pulse(bus, at, gain)
    # Very short repeating delay gives air while preserving the exact loop length.
    bus += np.roll(bus, round(0.23 * SAMPLE_RATE)) * 0.075
    # Bring the two edge samples together over 10 ms to avoid a loop click.
    edge = 0.5 * (bus[0] + bus[-1])
    seam = round(0.01 * SAMPLE_RATE)
    bus[:seam] += (edge - bus[0]) * np.linspace(1.0, 0.0, seam)
    bus[-seam:] += (edge - bus[-1]) * np.linspace(0.0, 1.0, seam)
    peak = float(np.max(np.abs(bus)))
    if peak > 0:
        bus *= min(0.82 / peak, 1.0)
    pcm = np.clip(bus * 32767.0, -32768, 32767).astype("<i2")
    with tempfile.TemporaryDirectory() as temp:
        wav_path = Path(temp) / "preview.wav"
        with wave.open(str(wav_path), "wb") as wav:
            wav.setnchannels(1)
            wav.setsampwidth(2)
            wav.setframerate(SAMPLE_RATE)
            wav.writeframes(pcm.tobytes())
        result = subprocess.run(
            ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i",
             str(wav_path), "-c:a", "libvorbis", "-qscale:a", "5",
             str(OUT / f"{name}.ogg")], capture_output=True, text=True)
        if result.returncode:
            raise RuntimeError(result.stderr)
    write_midi(OUT / f"{name}.mid", events)
    print(f"{name}: {DURATION:.1f}s, {len(events)} notes, peak {peak:.3f}")


def main() -> None:
    if not shutil.which("ffmpeg"):
        raise SystemExit("ffmpeg is required to encode Ogg previews")
    OUT.mkdir(parents=True, exist_ok=True)
    for name in VARIANTS:
        render(name)


if __name__ == "__main__":
    main()

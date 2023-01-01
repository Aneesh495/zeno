#!/usr/bin/env python3
"""
Zeno Replay Inspector & Binary Stream Visualizer.
Decodes .znr binary replay streams, validates header integrity,
and visualizes player input streams and periodic state checkpoints.
"""

import sys
import struct
from typing import List, Dict, Optional, Tuple

class ReplayVisualizer:
    def __init__(self):
        self.magic = ""
        self.version = 0
        self.initial_seed = 0
        self.player_count = 0
        self.tick_rate_hz = 0
        self.total_frames = 0
        self.frames: List[Dict] = []

    def decode_stream(self, data: bytes) -> bool:
        """Parses the packed binary replay format."""
        offset = 0
        if len(data) < 20:
            return False

        # Read magic string (int16 length prefix + utf-8 bytes)
        str_len = struct.unpack_from("<h", data, offset)[0]
        offset += 2
        self.magic = data[offset:offset + str_len].decode("utf-8", errors="ignore")
        offset += str_len

        if self.magic != "ZENO_REPLAY":
            print(f"Error: Invalid replay magic '{self.magic}' (expected 'ZENO_REPLAY')")
            return False

        # Read header fields (version, seed, players, tick_rate, total_frames)
        self.version, self.initial_seed, self.player_count, self.tick_rate_hz, self.total_frames = struct.unpack_from("<iiiii", data, offset)
        offset += 20

        # Read frames count
        frame_count = struct.unpack_from("<i", data, offset)[0]
        offset += 4

        self.frames = []
        for _ in range(frame_count):
            frame_idx, chk_hash, num_players = struct.unpack_from("<iiB", data, offset)
            offset += 9

            player_inputs = []
            for _ in range(num_players):
                inp = struct.unpack_from("<i", data, offset)[0]
                offset += 4
                player_inputs.append(inp)

            self.frames.append({
                "frame": frame_idx,
                "checkpoint_hash": chk_hash,
                "inputs": player_inputs
            })

        return True

    def print_timeline(self, limit: int = 20) -> None:
        """Prints a visual timeline table of recorded player actions."""
        print("\n" + "=" * 80)
        print("  ZENO REPLAY INSPECTOR: STREAM TIMELINE")
        print("=" * 80)
        print(f"  Format Version : {self.version}")
        print(f"  PRNG Seed      : {self.initial_seed}")
        print(f"  Player Count   : {self.player_count}")
        print(f"  Tick Rate      : {self.tick_rate_hz} Hz")
        print(f"  Total Frames   : {len(self.frames)}")
        print("-" * 80)
        print(f" {'Frame':^8} | {'Player 0 Input':^16} | {'Player 1 Input':^16} | {'Checkpoint Hash':^16}")
        print("-" * 80)

        for f in self.frames[:limit]:
            p0 = f"0x{f['inputs'][0]:04X}" if len(f['inputs']) > 0 else "---"
            p1 = f"0x{f['inputs'][1]:04X}" if len(f['inputs']) > 1 else "---"
            chk = f"0x{f['checkpoint_hash'] & 0xFFFFFFFF:08X}" if f['checkpoint_hash'] != 0 else "(speculative)"
            print(f" {f['frame']:^8} | {p0:^16} | {p1:^16} | {chk:^16}")

        if len(self.frames) > limit:
            print(f"  ... [ {len(self.frames) - limit} additional frames truncated ] ...")
        print("=" * 80 + "\n")

def run_synthetic_test():
    # Build synthetic binary replay buffer matching Zeno's serialization
    data = bytearray()
    magic_str = b"ZENO_REPLAY"
    data.extend(struct.pack("<h", len(magic_str)))
    data.extend(magic_str)
    # version=1, seed=1337, players=2, tick_rate=60, total_frames=10
    data.extend(struct.pack("<iiiii", 1, 1337, 2, 60, 10))

    # Frames count = 10
    data.extend(struct.pack("<i", 10))
    for frame in range(10):
        chk = 0x57CF3364 if frame % 5 == 0 else 0
        data.extend(struct.pack("<iiB", frame, chk, 2))
        data.extend(struct.pack("<i", 1 << (frame % 4)))      # Player 0
        data.extend(struct.pack("<i", (1 << (frame % 4)) * 3)) # Player 1

    viz = ReplayVisualizer()
    if viz.decode_stream(bytes(data)):
        viz.print_timeline()
        print("✓ Replay decoding and timeline extraction verified.")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        with open(sys.argv[1], "rb") as fp:
            raw = fp.read()
            viz = ReplayVisualizer()
            if viz.decode_stream(raw):
                viz.print_timeline()
    else:
        run_synthetic_test()

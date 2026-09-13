# tools/blender/starter.py
"""Membangun 3 starter tahap dasar MVP (Anak Rimau, Orangkici, Penyuci).

Jalankan (headless):
    blender --background --python tools/blender/starter.py
Output: assets/models/<id>.glb
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import nusamon_build as nb  # noqa: E402

if __name__ == "__main__":
    for sid in ("anak_rimau", "orangkici", "penyuci"):
        nb.BUILDERS[sid]()
        out = os.path.join(nb.OUTPUT_DIR, sid + ".glb")
        nb.export_model(out)
        print("[NUSAMON starter] OK:", out)

#!/usr/bin/env python3
"""CSV -> CMX3600 EDL.
CSV columns: reel,source_in,source_out,record_in   (timecodes HH:MM:SS:FF; record_in optional, auto-packed)
Usage: edl.py cuts.csv out.edl [fps=24] [title=TIMELINE]
"""
import csv, sys

def tc2f(tc, fps):
    h, m, s, f = (int(x) for x in tc.replace(";", ":").split(":"))
    return ((h * 3600 + m * 60 + s) * fps) + f

def f2tc(n, fps):
    f = n % fps; s = n // fps
    return f"{s // 3600:02d}:{s % 3600 // 60:02d}:{s % 60:02d}:{f:02d}"

def main():
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    src, dst = sys.argv[1], sys.argv[2]
    fps = int(sys.argv[3]) if len(sys.argv) > 3 else 24
    title = sys.argv[4] if len(sys.argv) > 4 else "TIMELINE"
    out = [f"TITLE: {title}", "FCM: NON-DROP FRAME", ""]
    pos = tc2f("01:00:00:00", fps)
    with open(src, newline="") as fh:
        for i, row in enumerate(csv.DictReader(fh), 1):
            a, b = tc2f(row["source_in"], fps), tc2f(row["source_out"], fps)
            if b <= a:
                sys.exit(f"row {i}: source_out must be after source_in")
            ri = tc2f(row["record_in"], fps) if row.get("record_in") else pos
            ro = ri + (b - a); pos = ro
            reel = row["reel"][:8].upper().ljust(8)
            out.append(f"{i:03d}  {reel} V     C        {f2tc(a,fps)} {f2tc(b,fps)} {f2tc(ri,fps)} {f2tc(ro,fps)}")
            out.append(f"*FROM CLIP NAME: {row['reel']}")
            out.append("")
    open(dst, "w").write("\n".join(out))
    print(f"wrote {dst} ({i} events @ {fps} fps)")

main()

"""Download chosen members of the Brno DAS zip (parallel HTTP range requests, resumable), inflate them and check the CRC32.

    python -I ai/fetch_members.py <out_dir> <member> [<member> ...]
Members are deflated inside the zip, so each one is downloaded as its compressed byte range (in 64 MB parts, 8 in parallel), joined,
inflated with zlib (raw deflate) and verified against the zip's CRC32. Part files live in <out_dir>/_parts and are removed when done.
"""
import os, sys, zlib, zipfile, concurrent.futures as cf
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from zip_remote import RangeFile

PART = 64 * 1024 * 1024
WORKERS = 8


def fetch_part(args):
    member_tag, off, n, path = args
    if os.path.isfile(path) and os.path.getsize(path) == n:
        return n
    import time
    data = b""
    for attempt in range(12):                  # signed URLs expire / the server throttles: new URL and back-off, never give up quickly
        try:
            rf = RangeFile()
            while len(data) < n:               # a response may be shorter than asked: keep going
                data += rf._fetch(off + len(data), min(n - len(data), 16 * 1024 * 1024))
            break
        except Exception as e:
            time.sleep(5 * (attempt + 1))
    assert len(data) == n, "part incomplete"

    tmp = path + ".tmp"
    with open(tmp, "wb") as f:
        f.write(data)
    os.replace(tmp, path)
    return n


def fetch_member(z, rf, name, out_dir):
    info = z.getinfo(name)
    dst = os.path.join(out_dir, name.replace("/", os.sep))
    if os.path.isfile(dst) and os.path.getsize(dst) == info.file_size:
        print("already there:", dst); return
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    rf.seek(info.header_offset); hdr = rf.read(30)
    off = info.header_offset + 30 + int.from_bytes(hdr[26:28], "little") + int.from_bytes(hdr[28:30], "little")
    csize = info.compress_size
    parts_dir = os.path.join(out_dir, "_parts", os.path.basename(name)); os.makedirs(parts_dir, exist_ok=True)
    jobs = []
    for i, start in enumerate(range(0, csize, PART)):
        n = min(PART, csize - start)
        jobs.append((name, off + start, n, os.path.join(parts_dir, f"{i:05d}.part")))
    done = 0
    with cf.ThreadPoolExecutor(WORKERS) as ex:
        for n in ex.map(fetch_part, jobs):
            done += n
            print(f"{os.path.basename(name)}: {100 * done / csize:5.1f} %", flush=True)
    d = zlib.decompressobj(-15); crc = 0; tmp = dst + ".tmp"
    with open(tmp, "wb") as out:
        for j in jobs:
            with open(j[3], "rb") as f:
                while True:
                    b = f.read(8 * 1024 * 1024)
                    if not b: break
                    x = d.decompress(b); crc = zlib.crc32(x, crc); out.write(x)
        x = d.flush(); crc = zlib.crc32(x, crc); out.write(x)
    assert crc & 0xFFFFFFFF == info.CRC, f"CRC mismatch for {name}"
    os.replace(tmp, dst)
    for j in jobs: os.remove(j[3])
    print("OK", dst, os.path.getsize(dst), "bytes, CRC ok", flush=True)


if __name__ == "__main__":
    out_dir = sys.argv[1]
    rf = RangeFile(); z = zipfile.ZipFile(rf)
    for name in sys.argv[2:]:
        fetch_member(z, rf, name, out_dir)

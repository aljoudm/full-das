"""Read a remote zip over HTTP range requests (list entries, extract chosen members) without downloading the whole archive.

Used for the Brno DAS dataset (figshare 10.6084/m9.figshare.27004732, DAS-dataset.zip, 47,120,418,495 bytes, md5 77e990a08907c2a4b16997e95f31b55e).
    python -I ai/zip_remote.py list
    python -I ai/zip_remote.py get <member> <out_dir>
"""
import io, sys, os, zipfile, urllib.request

URL = "https://ndownloader.figshare.com/files/52736258"
UA = {"User-Agent": "full-das-research-client/1.0"}


class RangeFile(io.RawIOBase):
    """Minimal seekable file over HTTP Range requests, with a small read-ahead cache."""

    def __init__(self, url=URL):
        self.url = url
        req = urllib.request.Request(url, headers={**UA, "Range": "bytes=0-0"})
        with urllib.request.urlopen(req) as r:
            self.size = int(r.headers["Content-Range"].split("/")[1])
            self.url = r.geturl()          # resolved (signed) URL
        self.pos = 0
        self._cache = (0, b"")

    def readable(self): return True
    def seekable(self): return True
    def tell(self): return self.pos

    def seek(self, off, whence=0):
        self.pos = off if whence == 0 else self.pos + off if whence == 1 else self.size + off
        return self.pos

    def _fetch(self, start, n):
        end = min(start + n, self.size) - 1
        req = urllib.request.Request(self.url, headers={**UA, "Range": f"bytes={start}-{end}"})
        with urllib.request.urlopen(req, timeout=120) as r:
            return r.read()

    def read(self, n=-1):
        if n < 0: n = self.size - self.pos
        n = min(n, self.size - self.pos)
        if n <= 0: return b""
        cs, cb = self._cache
        if cs <= self.pos and self.pos + n <= cs + len(cb):
            out = cb[self.pos - cs:self.pos - cs + n]
        else:
            blk = self._fetch(self.pos, max(n, 4 * 1024 * 1024))
            self._cache = (self.pos, blk)
            out = blk[:n]
        self.pos += len(out)
        return out

    def readinto(self, b):
        d = self.read(len(b)); b[:len(d)] = d; return len(d)


if __name__ == "__main__":
    z = zipfile.ZipFile(RangeFile())
    if sys.argv[1] == "list":
        for i in z.infolist():
            print(f"{i.file_size}\t{i.compress_size}\t{i.filename}")
    elif sys.argv[1] == "get":
        z.extract(sys.argv[2], sys.argv[3])

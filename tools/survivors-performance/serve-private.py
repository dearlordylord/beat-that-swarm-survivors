#!/usr/bin/env python3
"""Serve a private static preview behind Tailscale's HTTP/2 proxy."""

import argparse
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


class PreviewServer(ThreadingHTTPServer):
    request_queue_size = 128


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('directory', type=Path)
    parser.add_argument('--port', type=int, default=18813)
    args = parser.parse_args()
    if not (args.directory / 'index.html').is_file():
        parser.error('The preview directory must contain index.html')
    handler = partial(SimpleHTTPRequestHandler, directory=str(args.directory.resolve()))
    with PreviewServer(('127.0.0.1', args.port), handler) as server:
        print(f'Private preview backend: http://127.0.0.1:{args.port}', flush=True)
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            pass


if __name__ == '__main__':
    main()

#!/usr/bin/env python3

import argparse
import re
from pathlib import Path

DEFINE = re.compile(
    rb"^[ \t]*#define[ \t]+([A-Za-z_][A-Za-z_0-9]*)[ \t]+([0-9]+)[ \t]*$"
)
SYMBOL = re.compile(rb'^([ \t]*)([A-Za-z_][A-Za-z_0-9]*)\+([0-9]+)[ \t]+(".*)$')
NUMBER = re.compile(rb'^([ \t]*)([0-9]+)[ \t]+(".*)$')


def convert(source):
    definitions = {}
    output = []
    for line in source.replace(b"\r\n", b"\n").split(b"\n"):
        match = DEFINE.match(line)
        if match:
            definitions[match.group(1)] = int(match.group(2))
            continue

        if line.strip().lower() in (b"stringtable", b"begin", b"end"):
            line = line.upper()
        else:
            match = SYMBOL.match(line)
            if match:
                name = match.group(2)
                if name not in definitions:
                    raise ValueError(
                        "undefined resource prefix: " + name.decode("ascii")
                    )
                value = definitions[name] + int(match.group(3))
                line = (
                    match.group(1) + str(value).encode("ascii") + b", " + match.group(4)
                )
            else:
                match = NUMBER.match(line)
                if match:
                    line = match.group(1) + match.group(2) + b", " + match.group(3)
        output.append(line)

    return b"\n".join(output)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    args = parser.parse_args()
    args.destination.write_bytes(convert(args.source.read_bytes()))


if __name__ == "__main__":
    main()

#!/usr/bin/env python3

import argparse
import subprocess
import os
import re
from pathlib import Path
from collections import defaultdict



class DisassemblerArguments:
    elf: str
    txt: str


parser = argparse.ArgumentParser(description="Disassemble ELF files")
parser.add_argument("elf", type=str, help="Path to the input ELF")
parser.add_argument("txt", type=str, help="Path to the output txt")



def get_elf_paths(elf_root: Path) -> list[Path]:
    return [f for f in elf_root.rglob("*.elf")]


def main():
    args = parser.parse_args(namespace=DisassemblerArguments())
    RISCV = os.environ.get("RISCV")
    if RISCV is None:
        raise EnvironmentError("RISCV environment variable not set")

    memory_cells: dict[int, int] = {}
    output_lines: list[str] = []

    elf_path: Path = Path(args.elf)
    txt_path: Path = Path(args.txt)


    disassemble_command = [
        f"{RISCV}/bin/riscv64-unknown-elf-objdump",
        "-d",
        elf_path
    ]

    objdump_output = subprocess.check_output(disassemble_command, text=True)


    for line in objdump_output.splitlines():
        if m := re.search(r"^\s*([0-9a-fA-F]+):\s+([0-9a-fA-F]+)", line):
            address = m.group(1)
            instruction = m.group(2)
            memory_cells[int(address, 16)] = int(instruction, 16)

    for address in sorted(memory_cells.keys()):
        output_lines.append(f"{address:08x}: {memory_cells[address]:08x}\n")

    with open(txt_path, "w") as f:
        f.writelines(output_lines)

    return 0



if __name__ == "__main__":
    exit(main())

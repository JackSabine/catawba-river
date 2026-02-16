#!/usr/bin/env python3

import argparse
import subprocess
import os
import re
from pathlib import Path



class DisassemblerArguments:
    elf: str
    txt: str


parser = argparse.ArgumentParser(description="Disassemble ELF files")
parser.add_argument("elf", type=str, help="Path to the input ELF")
parser.add_argument("txt", type=str, help="Path to the output txt")



def convert_little_endian(hex_string: str) -> int:
    hex_string = hex_string.strip()

    bytes_list = [hex_string[i:i+2] for i in range(0, len(hex_string), 2)]
    bytes_list.reverse()

    word = ''.join(bytes_list)
    return int(word, 16)


def main():
    args = parser.parse_args(namespace=DisassemblerArguments())
    RISCV = os.environ.get("RISCV")
    if RISCV is None:
        raise EnvironmentError("RISCV environment variable not set")

    memory_cells: dict[int, tuple[int, str]] = {}
    output_lines: list[str] = []

    elf_path: Path = Path(args.elf)
    txt_path: Path = Path(args.txt)

    for section in [".text", ".rodata", ".bss", ".data"]:
        disassemble_command = [
            f"{RISCV}/bin/riscv64-unknown-elf-objdump",
            "-s",
            "-j",
            section,
            elf_path
        ]

        try:
            objdump_output = subprocess.check_output(disassemble_command, text=True, stderr=subprocess.STDOUT)
        except subprocess.CalledProcessError as e:
            if e.returncode == 1 and "not found" in e.output:
                # print(f"Warning: Section {section} not found in {elf_path}, skipping.")
                continue
            continue

        for line in objdump_output.splitlines():
            if m := re.search(r"^\s*(?P<base_address>[0-9a-fA-F]{8})(?P<word0>\s[0-9a-fA-F]{8})?(?P<word1>\s[0-9a-fA-F]{8})?(?P<word2>\s[0-9a-fA-F]{8})?(?P<word3>\s[0-9a-fA-F]{8})?.*$", line):
                base_address = m.group("base_address")
                for i in range(4):
                    word = m.group(f"word{i}")
                    if word is None:
                        break
                    address = int(base_address, 16) + (i * 4)
                    if address in memory_cells:
                        # Duplicate element
                        _, old_section = memory_cells[address]
                        raise ValueError(f"Duplicate address {address:08x} being added in section {section}, already provided by section {old_section}")
                    data = convert_little_endian(word)
                    memory_cells[address] = (data, section)

    for address in sorted(memory_cells.keys()):
        data, _ = memory_cells[address]
        output_lines.append(f"{address:08x}: {data:08x}\n")

    with open(txt_path, "w") as f:
        f.writelines(output_lines)

    return 0



if __name__ == "__main__":
    exit(main())

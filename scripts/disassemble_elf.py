#!/usr/bin/env python3

import argparse
import subprocess
import os
import re
from pathlib import Path
from collections import defaultdict



class DisassemblerArguments:
    elf_path: str
    output_file: str


parser = argparse.ArgumentParser(description="Disassemble ELF files")
parser.add_argument("elf_path", type=str, help="Path to the dir containing ELF files")
parser.add_argument("output_file", type=str, help="Path to the output file")



def get_elf_paths(elf_root: Path) -> list[Path]:
    return [f for f in elf_root.rglob("*.elf")]


def main():
    args = parser.parse_args(namespace=DisassemblerArguments())
    RISCV = os.environ.get("RISCV")
    if RISCV is None:
        raise EnvironmentError("RISCV environment variable not set")

    memory_cells: dict[str, dict[int, int]] = defaultdict(dict)
    output_lines: list[str] = []

    for elf_path in get_elf_paths(Path(args.elf_path)):
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
                memory_cells[elf_path.stem][int(address, 16)] = int(instruction, 16)

        if not memory_cells:
            raise RuntimeError("No instructions found in ELF file " + str(elf_path))

    output_lines.append("// Auto-generated memory map from ELF files - disassemble_elf.py\n\n")
    output_lines.append("memory_t asm_files [string];\n\n")
    for elf_name, cells in memory_cells.items():
        output_lines.append(f"asm_files[\"{elf_name}\"] = '{{\n")
        for i, address in enumerate(sorted(cells.keys())):
            output_lines.append(f"  {', ' if i != 0 else '  '}32'h{address:08x}: 32'h{cells[address]:08x}\n")
        output_lines.append("};\n\n")

    with open(args.output_file, "w") as f:
        f.writelines(output_lines)

    return 0



if __name__ == "__main__":
    exit(main())

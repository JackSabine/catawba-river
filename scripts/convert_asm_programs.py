#!/usr/bin/env python3

import os
from pathlib import Path
import riscv_assembler
import riscv_assembler.convert



def convert_and_write(asm_path: Path, asm_converter: riscv_assembler.convert.AssemblyConverter, output_path: Path) -> None:
    with open(asm_path, "r") as f:
        asm_converter.convert(f.read(), str(output_path))


def get_asm_test_paths(asm_root: Path) -> list[Path]:
    return [f for f in asm_root.rglob("*.S")]


def main() -> None:
    asm_converter = riscv_assembler.convert.AssemblyConverter(output_mode="f")
    asm_root = Path(os.environ["WORKAREA"]) / "dv" / "asm"
    asm_paths = get_asm_test_paths(asm_root)
    output_root = Path(os.environ["WORKDIR"])
    for asm_path in asm_paths:
        convert_and_write(asm_path, asm_converter, (output_root / asm_path.name).with_suffix(".txt"))

    return


if __name__ == "__main__":
    main()
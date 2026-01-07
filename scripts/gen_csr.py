#!/usr/bin/env python3

import os
from pathlib import Path
import csv
from dataclasses import dataclass
import re


@dataclass
class CSR:
    name: str
    address: int
    width: int
    reset: int
    export: bool
    volatile: bool


def is_read_only(csr: CSR) -> bool:
    return ((csr.address >> 10) & 0b11) == 0b11


def convert_port_list_to_inst_list(port_list: list[str]) -> list[str]:
    port_names: list[str] = []
    for port in port_list:
        if m := re.search(r'^.*?(\w+)$', port):
            port_names.append(f"    .{m.group(1)}")

    return port_names



def main() -> None:
    csr_csv = Path(os.environ["WORKAREA"]) / "rtl" / "csr.csv"
    rtl_path = Path(os.environ["WORKDIR"]) / "csr_core.sv"
    csr_wrapper_path = Path(os.environ["WORKAREA"]) / "rtl" / "csr_wrapper.sv"

    csrs: list[CSR] = []

    port_list: list[str] = [
        "    input logic clk",
        "    input logic rst",
        "    input logic [11:0] req_csr_address",
        "    input logic req_valid_read",
        "    input logic req_valid_write",
        "    input logic [XLEN-1:0] value_to_write",
        "    input logic req_trigger_read_side_effects",
        "    output logic [XLEN-1:0] csr_read_value",
        "    output logic invalid_csr_index",
    ]
    internal_declares: list[str] = []
    always_ff_statements: list[str] = []
    always_ff_reset_statements: list[str] = []
    assign_statements: list[str] = []
    reading_statements: list[str] = []
    inst_lines: list[str] = []
    csr_wrapper_input_lines: list[str]
    csr_wrapper_output_lines: list[str] = []

    internal_declares.append("logic [31:0] csr_read_value_precheck;")


    with open(csr_csv, newline='') as f:
        csvreader = csv.reader(f, delimiter=',', quotechar='"')
        next(csvreader, None)  # Skip header
        for row in csvreader:
            name, addr, width, reset, export, volatile = row
            csrs.append(CSR(
                name=name,
                address=int(addr, 16),
                width=int(width, 10),
                reset=int(reset, 16),
                export=(export == 'Y'),
                volatile=(volatile == 'Y')
            ))

    for csr in csrs:
        if csr.export:
            port_list.append(
                f"    output logic [{csr.width - 1}:0] csr_{csr.name}"
            )
        else:
            internal_declares.append(
                f"logic [{csr.width - 1}:0] csr_{csr.name};"
            )

        if not is_read_only(csr):
            if csr.volatile:
                assert not is_read_only(csr), f"CSR {csr.name} cannot be both volatile and read-only"
                port_list.append(f"    input logic [{csr.width - 1}:0] csr_{csr.name}_hw_ovrd")
                port_list.append(f"    input logic csr_{csr.name}_hw_ovrd_en")
                always_ff_statements.append(f"        csr_{csr.name:20s} <= csr_{csr.name}_hw_ovrd_en ? csr_{csr.name}_hw_ovrd : (req_valid_write && (req_csr_address == 12'h{csr.address:03X}) ? value_to_write : csr_{csr.name});")
            else:
                always_ff_statements.append(f"        csr_{csr.name:20s} <= (req_valid_write && (req_csr_address == 12'h{csr.address:03X}) ? value_to_write : csr_{csr.name});")

            if csr.reset == 0:
                always_ff_reset_statements.append(f"        csr_{csr.name} <= '0;")
            else:
                always_ff_reset_statements.append(f"        csr_{csr.name} <= {csr.width}'h{csr.reset:0{(csr.width + 3) // 4}X};")
        else:
            if csr.reset == 0:
                assign_statements.append(f"assign csr_{csr.name:20s} = '0;")
            else:
                assign_statements.append(f"assign csr_{csr.name:20s} = {csr.width}'h{csr.reset:0{(csr.width + 3) // 4}X};")

        reading_statements.append(f"        12'h{csr.address:03X}: csr_read_value_precheck = {{ {{(XLEN - {csr.width}){{1'b0}}}}, csr_{csr.name} }};")

    reading_statements.append("        default: begin")
    reading_statements.append("            csr_read_value_precheck = '0;")
    reading_statements.append("            invalid_csr_index = 1'b1;")
    reading_statements.append("        end")

    assign_statements.append("assign csr_read_value = req_valid_read ? csr_read_value_precheck : '0;")

    with open(rtl_path, 'w') as f:
        f.write("// This file is auto-generated. Do not edit directly.\n\n")
        f.write("module csr_core #(\n")
        f.write("    parameter XLEN = 32\n")
        f.write(") (\n")
        f.write(",\n".join(port_list))
        f.write("\n);\n\n")
        f.write("\n".join(internal_declares))
        f.write("\n\nalways_ff @(posedge clk) begin\n")
        f.write("    if (rst) begin\n")
        f.write("\n".join(always_ff_reset_statements))
        f.write("\n    end else begin\n")
        f.write("\n".join(always_ff_statements))
        f.write("\n    end\nend\n\n")
        f.write("\n".join(assign_statements))
        f.write("\n\nalways_comb begin\n")
        f.write("    invalid_csr_index = 1'b0;\n")
        f.write("    unique casez (req_csr_address)\n")
        f.write("\n".join(reading_statements))
        f.write("\n    endcase\n")
        f.write("end\n\n")
        f.write("\n\nendmodule\n")

    inst_lines.append("csr_core #(\n")
    inst_lines.append("    .XLEN(XLEN)\n")
    inst_lines.append(") csr_core_inst (\n")
    inst_lines.append(",\n".join(convert_port_list_to_inst_list(port_list)))
    inst_lines.append("\n);\n")

    with open(csr_wrapper_path, 'r') as f:
        csr_wrapper_input_lines = f.readlines()

    skipping_lines = False

    for l in csr_wrapper_input_lines:
        if skipping_lines:
            if re.search(r'^\s*//\s*gen_csr\.py end\s*$', l):
                skipping_lines = False
                csr_wrapper_output_lines.append(l)
            continue

        csr_wrapper_output_lines.append(l)
        if re.search(r'^\s*//\s*gen_csr\.py begin\s*$', l):
            csr_wrapper_output_lines.extend(inst_lines)
            skipping_lines = True

    with open(csr_wrapper_path, 'w') as f:
        f.writelines(csr_wrapper_output_lines)

    return



if __name__ == "__main__":
    main()
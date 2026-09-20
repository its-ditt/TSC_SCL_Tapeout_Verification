#!/usr/bin/env python3
import re
import sys
from pathlib import Path

R_FUNCT3 = {
    'add': 0b000, 'sub': 0b000, 'sll': 0b001, 'slt': 0b010,
    'sltu': 0b011, 'xor': 0b100, 'srl': 0b101, 'sra': 0b101,
    'or': 0b110, 'and': 0b111,
}
I_FUNCT3 = {
    'addi': 0b000, 'slli': 0b001, 'slti': 0b010, 'sltiu': 0b011,
    'xori': 0b100, 'srli': 0b101, 'srai': 0b101, 'ori': 0b110,
    'andi': 0b111,
}
LOAD_FUNCT3 = {'lb':0b000, 'lh':0b001, 'lw':0b010, 'lbu':0b100, 'lhu':0b101}
STORE_FUNCT3 = {'sb':0b000, 'sh':0b001, 'sw':0b010}
BR_FUNCT3 = {'beq':0b000, 'bne':0b001, 'blt':0b100, 'bge':0b101, 'bltu':0b110, 'bgeu':0b111}


def reg(tok: str) -> int:
    tok = tok.strip()
    m = re.fullmatch(r'x([0-9]|[12][0-9]|3[01])', tok)
    if not m:
        raise ValueError(f'bad register: {tok}')
    return int(m.group(1))


def num(tok: str) -> int:
    tok = tok.strip()
    sign = -1 if tok.startswith('-') else 1
    t = tok[1:] if tok[:1] in '+-' else tok
    if t.lower().startswith('0x'):
        return sign * int(t, 16)
    return sign * int(t, 10)


def parse_mem(tok: str):
    m = re.fullmatch(r'(.+)\((x(?:[0-9]|[12][0-9]|3[01]))\)', tok.strip())
    if not m:
        raise ValueError(f'bad memory operand: {tok}')
    imm = num(m.group(1))
    rs1 = reg(m.group(2))
    return imm, rs1


def s12(x: int) -> int:
    if not -2048 <= x <= 2047:
        raise ValueError(f'I/S immediate out of range: {x}')
    return x & 0xfff


def s13(x: int) -> int:
    if x % 2 or not -(1 << 12) <= x < (1 << 12):
        raise ValueError(f'branch immediate invalid: {x}')
    return x & 0x1fff


def s21(x: int) -> int:
    if x % 2 or not -(1 << 20) <= x < (1 << 20):
        raise ValueError(f'JAL immediate invalid: {x}')
    return x & 0x1fffff


def enc_r(mn, rd, rs1, rs2):
    funct7 = 0x20 if mn in ('sub', 'sra') else 0x00
    funct3 = R_FUNCT3[mn]
    return (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | 0x33


def enc_i(mn, rd, rs1, imm):
    funct3 = I_FUNCT3[mn]
    if mn in ('slli', 'srli', 'srai'):
        if not 0 <= imm <= 31:
            raise ValueError(f'shift amount out of range: {imm}')
        imm12 = imm
        if mn == 'srai':
            imm12 |= 0x20 << 5
    else:
        imm12 = s12(imm)
    return (imm12 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | 0x13


def enc_load(mn, rd, rs1, imm):
    return (s12(imm) << 20) | (rs1 << 15) | (LOAD_FUNCT3[mn] << 12) | (rd << 7) | 0x03


def enc_store(mn, rs2, rs1, imm):
    u = s12(imm)
    return (((u >> 5) & 0x7f) << 25) | (rs2 << 20) | (rs1 << 15) | (STORE_FUNCT3[mn] << 12) | ((u & 0x1f) << 7) | 0x23


def enc_branch(mn, rs1, rs2, off):
    u = s13(off)
    b12 = (u >> 12) & 1
    b11 = (u >> 11) & 1
    b10_5 = (u >> 5) & 0x3f
    b4_1 = (u >> 1) & 0xf
    return (b12 << 31) | (b10_5 << 25) | (rs2 << 20) | (rs1 << 15) | (BR_FUNCT3[mn] << 12) | (b4_1 << 8) | (b11 << 7) | 0x63


def enc_u(mn, rd, imm20):
    if not 0 <= imm20 <= 0xfffff:
        raise ValueError(f'U immediate out of range: {imm20}')
    opcode = 0x37 if mn == 'lui' else 0x17
    return (imm20 << 12) | (rd << 7) | opcode


def enc_jal(rd, off):
    u = s21(off)
    b20 = (u >> 20) & 1
    b10_1 = (u >> 1) & 0x3ff
    b11 = (u >> 11) & 1
    b19_12 = (u >> 12) & 0xff
    return (b20 << 31) | (b19_12 << 12) | (b11 << 20) | (b10_1 << 21) | (rd << 7) | 0x6f


def enc_jalr(rd, rs1, imm):
    return (s12(imm) << 20) | (rs1 << 15) | (0 << 12) | (rd << 7) | 0x67


def tokenize(line):
    line = line.split('#',1)[0].split(';',1)[0].strip()
    if not line:
        return []
    # commas are optional in a few common assembly styles; normalize them.
    return [x for x in re.split(r'[\s,]+', line) if x]


def strip_label(line, labels, pc):
    line = line.strip()
    while True:
        m = re.match(r'^([A-Za-z_][A-Za-z0-9_]*):\s*(.*)$', line)
        if not m:
            return line
        labels[m.group(1)] = pc
        line = m.group(2).strip()
        if not line:
            return ''


def expand_count(tokens):
    if not tokens:
        return 0
    mn = tokens[0].lower()
    if mn in ('.text', '.globl'):
        return 0
    if mn == 'la':
        return 2
    return 1


def parse_source(path: Path):
    raw = path.read_text().splitlines()
    labels = {}
    pc = 0
    cleaned = []
    for line_no, raw_line in enumerate(raw, 1):
        no_comment = raw_line.split('#',1)[0].split(';',1)[0].strip()
        if not no_comment:
            continue
        no_comment = strip_label(no_comment, labels, pc)
        if not no_comment:
            continue
        toks = tokenize(no_comment)
        if not toks or toks[0].lower() in ('.text', '.globl'):
            continue
        cleaned.append((pc, line_no, toks))
        pc += 4 * expand_count(toks)
    return labels, cleaned


def encode_line(pc, toks, labels):
    mn = toks[0].lower()
    a = toks[1:]
    if mn in ('.text', '.globl'):
        return []
    if mn == 'nop':
        return [0x00000013]
    if mn == 'la':
        rd = reg(a[0]); label = a[1]
        if label not in labels:
            raise ValueError(f'unknown label: {label}')
        delta = labels[label] - pc
        hi = (delta + 0x800) >> 12
        lo = delta - (hi << 12)
        return [enc_u('auipc', rd, hi & 0xfffff), enc_i('addi', rd, rd, lo)]
    if mn in R_FUNCT3:
        return [enc_r(mn, reg(a[0]), reg(a[1]), reg(a[2]))]
    if mn in I_FUNCT3:
        return [enc_i(mn, reg(a[0]), reg(a[1]), num(a[2]))]
    if mn in LOAD_FUNCT3:
        imm, rs1 = parse_mem(a[1]); return [enc_load(mn, reg(a[0]), rs1, imm)]
    if mn in STORE_FUNCT3:
        imm, rs1 = parse_mem(a[1]); return [enc_store(mn, reg(a[0]), rs1, imm)]
    if mn in BR_FUNCT3:
        target = labels[a[2]]; return [enc_branch(mn, reg(a[0]), reg(a[1]), target-pc)]
    if mn == 'jal':
        target = labels[a[1]]; return [enc_jal(reg(a[0]), target-pc)]
    if mn == 'jalr':
        imm, rs1 = parse_mem(a[1]); return [enc_jalr(reg(a[0]), rs1, imm)]
    if mn in ('lui','auipc'):
        return [enc_u(mn, reg(a[0]), num(a[1]) & 0xfffff)]
    raise ValueError(f'unknown instruction {mn} at PC {pc:#x}')


def main():
    if len(sys.argv) != 3:
        print('usage: assemble_rv32i.py input.S output.hex', file=sys.stderr)
        return 2
    src, out = map(Path, sys.argv[1:])
    labels, cleaned = parse_source(src)
    words = []
    listing = []
    pc = 0
    for src_pc, line_no, toks in cleaned:
        if src_pc != pc:
            raise RuntimeError('internal PC tracking error')
        encs = encode_line(pc, toks, labels)
        for idx, w in enumerate(encs):
            words.append(w & 0xffffffff)
            listing.append(f'{pc:08x}  {w & 0xffffffff:08x}  {" ".join(toks)}')
            pc += 4
    out.write_text('\n'.join(f'{w:08x}' for w in words) + '\n')
    listing_path = out.with_suffix('.lst')
    listing_path.write_text('\n'.join(listing) + '\n')
    image_path = out.with_name('program_image.svh')
    image_lines = ['// Generated instruction image. Do not edit manually.', 'initial begin']
    for i, w in enumerate(words):
        image_lines.append(f"    program_words[{i}] = 32'h{w:08x};")
    image_lines += ['end', '']
    image_path.write_text('\n'.join(image_lines))
    print(f'assembled {len(words)} words ({len(words)*4} bytes)')
    print(f'output: {out}')
    print(f'listing: {listing_path}')
    print('labels:')
    for k,v in sorted(labels.items(), key=lambda kv: kv[1]):
        print(f'  {k:20s} = 0x{v:08x}')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())

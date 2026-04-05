from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path
import re
import sys
from typing import Dict, List


REQUIRED_HEADERS = {"language", "module", "version", "owner"}
SUPPORTED_BLOCKS = {"role", "authority", "constraint", "policy"}
BLOCK_OPEN_RE = re.compile(r"^(role|authority|constraint|policy)\s+([A-Za-z0-9_\-]+)\s*\{\s*$")


@dataclass
class Block:
    block_type: str
    block_id: str
    lines: List[str]


@dataclass
class PTNDocument:
    headers: Dict[str, str]
    blocks: List[Block]


class PTNError(Exception):
    pass


def parse_ptn(text: str) -> PTNDocument:
    headers: Dict[str, str] = {}
    blocks: List[Block] = []
    current: Block | None = None

    for idx, raw_line in enumerate(text.splitlines(), start=1):
        line = raw_line.strip()
        if not line:
            continue

        if current is None and ":" in line and "{" not in line:
            k, v = line.split(":", 1)
            headers[k.strip()] = v.strip()
            continue

        if current is None:
            m = BLOCK_OPEN_RE.match(line)
            if m:
                current = Block(block_type=m.group(1), block_id=m.group(2), lines=[])
                continue
            raise PTNError(f"Line {idx}: invalid block start or header: {line}")

        if line == "}":
            blocks.append(current)
            current = None
            continue

        current.lines.append(line)

    if current is not None:
        raise PTNError(f"Unclosed block: {current.block_type} {current.block_id}")

    return PTNDocument(headers=headers, blocks=blocks)


def validate_ptn(doc: PTNDocument) -> List[str]:
    issues: List[str] = []

    missing_headers = sorted(REQUIRED_HEADERS - set(doc.headers))
    if missing_headers:
        issues.append(f"missing required headers: {', '.join(missing_headers)}")

    if not doc.blocks:
        issues.append("contains no blocks")
        return issues

    roles = {b.block_id for b in doc.blocks if b.block_type == "role"}
    authorities = [b for b in doc.blocks if b.block_type == "authority"]
    constraints = [b for b in doc.blocks if b.block_type == "constraint"]
    policies = [b for b in doc.blocks if b.block_type == "policy"]

    if not roles:
        issues.append("no role definitions")

    if not authorities:
        issues.append("missing authority block")

    for b in doc.blocks:
        if b.block_type not in SUPPORTED_BLOCKS:
            issues.append(f"unsupported block type: {b.block_type}")

    for auth in authorities:
        if auth.block_id not in roles:
            issues.append(f"authority '{auth.block_id}' has no matching role")

    if not constraints and not policies:
        issues.append("must define at least one constraint or policy")

    return issues


def cmd_validate(file_path: Path) -> int:
    source = file_path.read_text(encoding="utf-8")
    doc = parse_ptn(source)
    issues = validate_ptn(doc)

    if issues:
        print(f"[ERROR] {file_path} is invalid")
        for issue in issues:
            print(f" - {issue}")
        return 1

    print(f"[OK] {file_path} is valid")
    print(f"Headers: {len(doc.headers)} | Blocks: {len(doc.blocks)}")
    return 0


def build_cli() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="PTN parser and validator")
    sub = parser.add_subparsers(dest="command", required=True)

    validate = sub.add_parser("validate", help="Validate a .ptn file")
    validate.add_argument("file", type=Path, help="Path to .ptn file")
    return parser


def main(argv: List[str]) -> int:
    parser = build_cli()
    args = parser.parse_args(argv)

    if args.command == "validate":
        try:
            return cmd_validate(args.file)
        except PTNError as exc:
            print(f"[ERROR] Parse failed: {exc}")
            return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

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
REQUIRE_RE = re.compile(r"^require\s+([A-Za-z0-9_:-]+)(?:\[([^\]]+)\])?\s+for\s+([A-Za-z0-9_:-]+)$")
REQ_NAME_RE = re.compile(r"^[a-z][a-z0-9_:-]*$")
REQ_METADATA_ALLOWED = {"risk", "mode", "evidence", "owner"}
REQ_RISK_ALLOWED = {"low", "medium", "high", "critical"}
REQ_MODE_ALLOWED = {"strict", "advisory"}


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


def parse_requirement_statement(line: str) -> tuple[str, str, Dict[str, str]] | None:
    match = REQUIRE_RE.match(line.strip())
    if not match:
        return None

    requirement = match.group(1).strip()
    metadata_raw = (match.group(2) or "").strip()
    action = match.group(3).strip()
    metadata: Dict[str, str] = {}
    if metadata_raw:
        for pair in metadata_raw.split(","):
            item = pair.strip()
            if not item:
                continue
            if "=" not in item:
                raise PTNError(f"invalid require metadata item '{item}'")
            key, value = item.split("=", 1)
            metadata[key.strip()] = value.strip()
    return requirement, action, metadata


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

    for block in doc.blocks:
        if block.block_type not in {"authority", "constraint"}:
            continue
        for line in block.lines:
            try:
                parsed = parse_requirement_statement(line)
            except PTNError as exc:
                issues.append(f"{block.block_type} '{block.block_id}': {exc}")
                continue
            if parsed is None:
                continue
            requirement, _action, metadata = parsed
            if not REQ_NAME_RE.match(requirement):
                issues.append(
                    f"{block.block_type} '{block.block_id}': invalid requirement identifier '{requirement}'",
                )
            for key, value in metadata.items():
                if key not in REQ_METADATA_ALLOWED:
                    issues.append(
                        f"{block.block_type} '{block.block_id}': unsupported require metadata key '{key}'",
                    )
                    continue
                if key == "risk" and value not in REQ_RISK_ALLOWED:
                    issues.append(
                        f"{block.block_type} '{block.block_id}': unsupported risk value '{value}'",
                    )
                if key == "mode" and value not in REQ_MODE_ALLOWED:
                    issues.append(
                        f"{block.block_type} '{block.block_id}': unsupported mode value '{value}'",
                    )

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

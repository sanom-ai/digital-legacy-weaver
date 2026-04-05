from pathlib import Path

from ptn_parser import parse_ptn, validate_ptn


def _validate(path: Path) -> tuple[int, int, list[str]]:
    source = path.read_text(encoding="utf-8")
    doc = parse_ptn(source)
    issues = validate_ptn(doc)
    return len(doc.headers), len(doc.blocks), issues


def main() -> int:
    files = [
        Path("examples/default-policy.ptn"),
        Path("examples/pdpa-policy-pack.ptn"),
    ]
    for file_path in files:
        headers, blocks, issues = _validate(file_path)
        if issues:
            print(f"[FAIL] PTN smoke test found issues in {file_path}:")
            for issue in issues:
                print(f" - {issue}")
            return 1
        print(f"[PASS] PTN smoke test | file={file_path} headers={headers} blocks={blocks}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

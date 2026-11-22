from __future__ import annotations

import re
import subprocess
import sys
import tempfile
from pathlib import Path

COMPAT_PATCHES = {
    "0017-FotaAgent-finish-the-update-job-without-a-DM-report-.patch": (
        "smali/com/idm/fotaagent/enabler/fumo/executor/IDMFumoExecutorUpdateFailedNodata.smali",
        ".method public idmFumoStart()V",
    ),
    "0018-FotaAgent-check-the-ROM-update-manifest-instead-of-S.patch": (
        "smali/com/idm/fotaagent/restapi/restclient/polling/state/PollingStartState.smali",
        ".method public onExecute()V",
    ),
}


def split_patch(text: str) -> tuple[str, list[str]]:
    lines = text.splitlines(keepends=True)
    starts = [i for i, line in enumerate(lines) if line.startswith("diff --git ")]
    if not starts:
        raise ValueError("patch contains no diff sections")
    preamble = "".join(lines[: starts[0]])
    sections = []
    for index, start in enumerate(starts):
        end = starts[index + 1] if index + 1 < len(starts) else len(lines)
        sections.append("".join(lines[start:end]))
    return preamble, sections


def section_path(section: str) -> str:
    first = section.splitlines()[0]
    match = re.fullmatch(r"diff --git a/(.+) b/(.+)", first)
    if not match or match.group(1) != match.group(2):
        raise ValueError(f"cannot identify patch path: {first}")
    return match.group(2)


def replacement_method(section: str, signature: str) -> list[str]:
    new_side: list[str] = []
    in_hunk = False
    for line in section.splitlines():
        if line.startswith("@@"):
            in_hunk = True
            continue
        if not in_hunk:
            continue
        if line.startswith(" "):
            new_side.append(line[1:])
        elif line.startswith("+"):
            new_side.append(line[1:])
        elif line.startswith("-") or line.startswith("\\"):
            continue
        else:
            raise ValueError(f"unexpected line in patch hunk: {line!r}")

    starts = [i for i, line in enumerate(new_side) if line.strip() == signature]
    if len(starts) != 1:
        raise ValueError(f"expected one {signature!r} in patch hunk, found {len(starts)}")
    start = starts[0]
    ends = [i for i in range(start + 1, len(new_side)) if new_side[i].strip() == ".end method"]
    if not ends:
        raise ValueError(f"could not find end of {signature!r} in patch hunk")
    return new_side[start : ends[0] + 1]


def replace_method(path: Path, signature: str, method: list[str]) -> None:
    if not path.is_file():
        raise FileNotFoundError(f"decoded Smali file missing: {path}")
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    starts = [i for i, line in enumerate(lines) if line.strip() == signature]
    if len(starts) != 1:
        raise ValueError(f"expected one {signature!r} in {path}, found {len(starts)}")
    start = starts[0]
    ends = [i for i in range(start + 1, len(lines)) if lines[i].strip() == ".end method"]
    if not ends:
        raise ValueError(f"could not find end of {signature!r} in {path}")
    end = ends[0]
    if lines[start : end + 1] == method:
        print(f"Already applied {signature} in {path.name}")
        return
    updated = lines[:start] + method + lines[end + 1 :]
    path.write_text("\n".join(updated) + "\n", encoding="utf-8")
    print(f"Rebased {signature} in {path.name} using the patch's complete method body")


def apply_remaining_patch(preamble: str, sections: list[str], target_section: str, patch_path: Path, target_dir: Path) -> None:
    remaining = [section for section in sections if section is not target_section]
    if not remaining:
        return
    patch_text = preamble + "".join(remaining)
    with tempfile.TemporaryDirectory(prefix="mintos-fota-patch-") as temporary:
        temporary_dir = Path(temporary)
        rejects = temporary_dir / "rejects"
        command = [
            "patch",
            "--batch",
            "--forward",
            "--fuzz=2",
            f"--reject-file={rejects}",
            "-p1",
            "-d",
            str(target_dir),
        ]
        check = subprocess.run(
            command + ["--dry-run"],
            input=patch_text,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )
        if check.returncode != 0:
            print(check.stdout, file=sys.stderr, end="")
            raise RuntimeError(f"remaining hunks from {patch_path.name} do not apply")
        applied = subprocess.run(
            command,
            input=patch_text,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )
        print(applied.stdout, end="")
        if applied.returncode != 0:
            raise RuntimeError(f"could not apply remaining hunks from {patch_path.name}")


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: apply_smali_compat_patch.py <patch> <decoded-apk-dir>", file=sys.stderr)
        return 2
    patch_path = Path(sys.argv[1])
    target_dir = Path(sys.argv[2])
    config = COMPAT_PATCHES.get(patch_path.name)
    if config is None:
        print(f"unsupported compatibility patch: {patch_path.name}", file=sys.stderr)
        return 2

    relative_path, signature = config
    preamble, sections = split_patch(patch_path.read_text(encoding="utf-8-sig"))
    target_sections = [section for section in sections if section_path(section) == relative_path]
    if len(target_sections) != 1:
        raise ValueError(f"expected one patch section for {relative_path}, found {len(target_sections)}")
    target_section = target_sections[0]
    method = replacement_method(target_section, signature)

    apply_remaining_patch(preamble, sections, target_section, patch_path, target_dir)
    replace_method(target_dir / relative_path, signature, method)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as error:
        print(f"FotaAgent compatibility patch failed: {error}", file=sys.stderr)
        raise SystemExit(1)

#!/usr/bin/env python3
"""
Fix test_documents filenames by reverting to simpler original names.

The previous migration added ugly prefixes like:
  simple_small_extractiontest.docx  ->  extraction_test.docx
  bold_small_bold.odt               ->  bold.odt
  rst_reader_tiny_rstreader.rst     ->  rst-reader.rst

This script:
1. Reads migration_map.json to get original filenames
2. Renames files back to their original (base)names
3. Handles conflicts by keeping the first file and warning about duplicates
4. Updates all code references
"""

import json
import os
import re
import shutil
from pathlib import Path
from collections import defaultdict

PROJECT_ROOT = Path(__file__).parent.parent
TEST_DOCS = PROJECT_ROOT / "test_documents"
MIGRATION_MAP = PROJECT_ROOT / "migration_map.json"


def load_migration_map():
    """Load the migration map to get original filenames."""
    with open(MIGRATION_MAP) as f:
        data = json.load(f)
    return data.get("migrations", [])


def get_original_basename(old_path: str) -> str:
    """Extract the original basename from old_path."""
    return Path(old_path).name


def build_rename_map(migrations):
    """
    Build a map of current_path -> desired_path.

    Desired path keeps the new directory but uses the original filename.
    """
    rename_map = {}
    target_names = defaultdict(list)  # Track conflicts

    for m in migrations:
        old_path = m["old_path"]
        new_path = m["new_path"]

        # Get the original filename
        original_name = get_original_basename(old_path)

        # Get the new directory
        new_dir = Path(new_path).parent

        # Desired path: new_dir / original_name
        desired_path = str(new_dir / original_name)

        current_full = TEST_DOCS / new_path
        desired_full = TEST_DOCS / desired_path

        if current_full.exists():
            # Track for conflict detection
            target_names[desired_path].append((new_path, original_name))
            rename_map[new_path] = desired_path

    # Handle conflicts - keep first, warn about others
    conflicts = {k: v for k, v in target_names.items() if len(v) > 1}
    if conflicts:
        print(f"\n⚠️  Found {len(conflicts)} naming conflicts:")
        for target, sources in conflicts.items():
            print(f"  {target}:")
            for src, orig in sources:
                print(f"    - {src} (from {orig})")
        print("\n  Will keep only the first file for each conflict.\n")

    return rename_map, conflicts


def rename_files(rename_map, conflicts, dry_run=True):
    """Rename files back to original names."""

    # Track which targets we've already used
    used_targets = set()
    renames_done = []
    skipped = []

    for current, desired in sorted(rename_map.items()):
        current_full = TEST_DOCS / current
        desired_full = TEST_DOCS / desired

        if not current_full.exists():
            continue

        # Skip if target already used (conflict)
        if desired in used_targets:
            skipped.append((current, desired, "conflict"))
            continue

        # Skip if already at desired name
        if current == desired:
            continue

        # Check if target exists (shouldn't if we handle conflicts)
        if desired_full.exists() and current_full != desired_full:
            skipped.append((current, desired, "exists"))
            continue

        if dry_run:
            print(f"  {current} -> {desired}")
        else:
            # Create parent directory if needed
            desired_full.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(str(current_full), str(desired_full))

        used_targets.add(desired)
        renames_done.append((current, desired))

    return renames_done, skipped


def update_references(renames_done, dry_run=True):
    """Update all code references to use new paths."""

    # Build old->new path map for test_documents references
    path_updates = {}
    for old_rel, new_rel in renames_done:
        # Various path patterns used in code
        path_updates[f"test_documents/{old_rel}"] = f"test_documents/{new_rel}"

    if not path_updates:
        print("No path updates needed.")
        return []

    # File patterns to search
    patterns = [
        "**/*.rs",
        "**/*.py",
        "**/*.json",
        "**/*.ts",
        "**/*.js",
        "**/*.rb",
        "**/*.php",
        "**/*.java",
        "**/*.go",
    ]

    files_updated = []

    for pattern in patterns:
        for filepath in PROJECT_ROOT.glob(pattern):
            # Skip node_modules, target, etc.
            if any(skip in str(filepath) for skip in [
                "node_modules", "target", ".git", "__pycache__",
                "dist", "build", ".venv", "venv"
            ]):
                continue

            try:
                content = filepath.read_text()
                original = content

                for old_path, new_path in path_updates.items():
                    content = content.replace(old_path, new_path)

                if content != original:
                    if dry_run:
                        print(f"  Would update: {filepath.relative_to(PROJECT_ROOT)}")
                    else:
                        filepath.write_text(content)
                    files_updated.append(filepath)

            except (UnicodeDecodeError, PermissionError):
                continue

    return files_updated


def generate_new_migration_map(renames_done):
    """Generate updated migration map with final paths."""

    migrations = load_migration_map()

    # Build lookup from new_path to desired_path
    rename_lookup = dict(renames_done)

    updated_migrations = []
    for m in migrations:
        new_path = m["new_path"]
        if new_path in rename_lookup:
            m["final_path"] = rename_lookup[new_path]
        else:
            m["final_path"] = new_path
        updated_migrations.append(m)

    return {
        "version": "2.0",
        "description": "Fixed migration with original filenames preserved",
        "migrations": updated_migrations
    }


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Fix test_documents filenames")
    parser.add_argument("--dry-run", action="store_true", default=True,
                       help="Show what would be done without making changes")
    parser.add_argument("--execute", action="store_true",
                       help="Actually perform the renames")
    args = parser.parse_args()

    dry_run = not args.execute

    print("=" * 70)
    print("TEST DOCUMENTS FILENAME FIX")
    print("=" * 70)

    if dry_run:
        print("\n🔍 DRY RUN MODE - No changes will be made\n")
    else:
        print("\n⚡ EXECUTE MODE - Files will be renamed\n")

    # Load migration map
    print("Loading migration map...")
    migrations = load_migration_map()
    print(f"  Found {len(migrations)} migrations\n")

    # Build rename map
    print("Building rename map...")
    rename_map, conflicts = build_rename_map(migrations)
    print(f"  {len(rename_map)} files to rename\n")

    # Perform renames
    print("Renaming files...")
    renames_done, skipped = rename_files(rename_map, conflicts, dry_run)
    print(f"\n  Renamed: {len(renames_done)}")
    print(f"  Skipped: {len(skipped)}")

    if skipped and not dry_run:
        print("\n  Skipped files:")
        for src, dst, reason in skipped[:10]:
            print(f"    {src} -> {dst} ({reason})")

    # Update references
    print("\nUpdating code references...")
    files_updated = update_references(renames_done, dry_run)
    print(f"  Files to update: {len(files_updated)}")

    if not dry_run:
        # Save updated migration map
        new_map = generate_new_migration_map(renames_done)
        with open(PROJECT_ROOT / "migration_map_v2.json", "w") as f:
            json.dump(new_map, f, indent=2)
        print(f"\n  Saved updated migration map to migration_map_v2.json")

    print("\n" + "=" * 70)
    print("SUMMARY")
    print("=" * 70)
    print(f"  Files renamed: {len(renames_done)}")
    print(f"  Files skipped: {len(skipped)}")
    print(f"  Code files updated: {len(files_updated)}")

    if dry_run:
        print("\n  Run with --execute to apply changes")


if __name__ == "__main__":
    main()

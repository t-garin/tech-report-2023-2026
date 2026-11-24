"""Convert the SEICHE MkDocs documentation into Typst appendices.

Builds a fresh MkDocs site from the SEICHE repository, converts the user guide,
configuration reference and API reference to Typst, copies the images, and
writes one ``.typ`` file per appendix under ``typs/``.

Usage:
    uv run --isolated --with beautifulsoup4 --with pypandoc-binary --with pyyaml \
        python seiche_docs_to_typst.py
"""

from __future__ import annotations

import argparse
import datetime
import re
import shutil
import subprocess
import tempfile
from pathlib import Path

import pypandoc
import yaml
from bs4 import BeautifulSoup

HERE = Path(__file__).resolve().parent
REPORT = HERE.parent
DEFAULT_SEICHE = Path.home() / "seiche"
DOC_TITLE = "SEICHE Documentation"
CONFIG_TITLE = "Configuration"
# The introductory example and test cases are described in the report itself.
EXCLUDED_PAGES = {
    "example.md",
    "index.md",
    "getting_started.md",
    "contributing.md",
    "tests.md",
}
API_GROUPS = (
    ("src", "reference/src/seiche", "`src` API reference"),
    ("tools", "reference/tools", "`tools` API reference"),
)
# Summary lists repeat the entries documented in full below.
SUMMARY_SECTIONS = {"Modules:", "Classes:", "Functions:", "Methods:", "Attributes:"}


def build_site(seiche: Path, site: Path) -> None:
    """Build a fresh MkDocs site, so the appendix matches the current code."""
    subprocess.run(
        [
            "uv",
            "run",
            "--project",
            str(seiche),
            "--group",
            "docs",
            "mkdocs",
            "build",
            "--site-dir",
            str(site),
        ],
        cwd=seiche,
        check=True,
    )


def nav_pages(mkdocs_yml: Path) -> list[tuple[str, str]]:
    """Flatten the MkDocs nav into ordered (label, markdown page) pairs."""
    nav = yaml.safe_load(mkdocs_yml.read_text())["nav"]
    pages: list[tuple[str, str]] = []

    def add(label: str, page: object) -> None:
        if (
            isinstance(page, str)
            and page.endswith(".md")
            and not page.startswith("reference/")
        ):
            pages.append((label, page))

    def walk(item: object) -> None:
        if isinstance(item, str):
            add("", item)
        elif isinstance(item, dict):
            for label, value in item.items():
                if isinstance(value, str):
                    add(label, value)
                else:
                    walk(value)
        elif isinstance(item, list):
            for value in item:
                walk(value)

    walk(nav)
    return pages


def postprocess(text: str) -> str:
    """Fix constructs pandoc emits that the report's Typst does not use."""
    text = text.replace("#horizontalrule", "#line(length: 100%)")
    text = re.sub(
        r'image\("([^"]+)"\)',
        lambda m: f'image("../imgs/seiche-docs/{Path(m.group(1)).name}", width: 100%)',
        text,
    )
    # An image directly followed by its italic caption must stay a block.
    text = re.sub(
        r'(#box\(image\("[^"]+", width: 100%\)\)) #emph\[', r"\1\n\n#emph[", text
    )
    # Namespace the generated labels, so they cannot clash with the report or
    # its bibliography (e.g. the "Filosofi" heading vs the `filosofi` key).
    text = re.sub(r"^<(?!sdocs-)([^>\n]+)>$", r"<sdocs-\1>", text, flags=re.MULTILINE)
    text = re.sub(r"#link\(<(?!sdocs-)([^>\n]+)>\)", r"#link(<sdocs-\1>)", text)
    return re.sub(r'#label\("(?!sdocs-)([^"\n]+)"\)', r'#label("sdocs-\1")', text)


def guess_language(block: list[str]) -> str:
    """Guess the language of an unlabelled API code block."""
    first = block[0].strip() if block else ""
    if first.startswith(
        ("uv run ", "$ ", "just ", "git ", "docker ", "podman ", "pip ", "conda ")
    ):
        return "sh"
    # A few docstrings contain ASCII diagrams, not code.
    if first.startswith(("^", "|")):
        return ""
    if all(set(line.strip()) <= set("^|0123456789 ") for line in block if line.strip()):
        return ""
    return "py"


def label_fences(text: str, default: str | None = None) -> str:
    """Give unlabelled fenced blocks a language, so Typst highlights them."""
    lines = text.splitlines()
    out = []
    index = 0
    while index < len(lines):
        line = lines[index]
        if line.startswith("```"):
            lang = line[3:].strip()
            end = index + 1
            while end < len(lines) and not lines[end].startswith("```"):
                end += 1
            block = lines[index + 1 : end]
            if not lang:
                lang = default or guess_language(block)
            lang = {"python": "py", "yaml": "yml"}.get(lang, lang)
            out.append(f"```{lang}" if lang else "```")
            out.extend(block)
            if end < len(lines):
                out.append("```")
                index = end + 1
            else:
                index = end
        else:
            out.append(line)
            index += 1
    return "\n".join(out)


def page_label(stem: str) -> str:
    """Stable label for the title of a standalone page appendix."""
    return "sdocs-page-" + stem.replace("_", "-")


def read_pages(seiche: Path) -> dict[str, str]:
    """Read the guide pages in nav order, with a title for pages missing one."""
    docs = seiche / "docs"
    pages = {}
    for label, page in nav_pages(seiche / "mkdocs.yml"):
        text = (docs / page).read_text()
        first = re.search(r"^(#+)\s", text, re.MULTILINE)
        if first is None or len(first.group(1)) > 1:
            text = f"# {label or Path(page).stem}\n\n{text}"
        pages[page] = text
    return pages


def convert_page(page: str, text: str) -> tuple[str, str]:
    """Convert one guide page to a standalone Typst appendix body."""
    first = re.search(r"^# (.+)$", text, re.MULTILINE)
    if first is None:
        raise SystemExit(f"no H1 title in {page}")
    title = first.group(1).strip()
    text = text[: first.start()] + text[first.end() :]
    # index.md has several H1 sections; they become H2 under the page title.
    text = re.sub(r"^# ", "## ", text, flags=re.MULTILINE)
    # Links to the generated API markdown keep only the anchor.
    text = re.sub(r"\]\((?:\.\./)*reference/[^)#]+\.md#([^)]+)\)", r"](#\1)", text)
    # Cross-page links become Typst labels.
    text = re.sub(r"\]\(([^)/#]+)\.md#([^)]+)\)", r"](#\2)", text)
    text = re.sub(
        r"\]\(([^)/#]+)\.md\)",
        lambda m: f"](#{page_label(m.group(1))})",
        text,
    )
    out = pypandoc.convert_text(text, "typst", format="gfm")
    return title, label_fences(postprocess(out))


def convert_config(seiche: Path) -> str:
    """Convert the configuration reference to Typst, with real headings."""
    text = (seiche / "docs" / "config.md").read_text()
    text = re.sub(r"^# Configuration\s*$", "", text, count=1, flags=re.MULTILINE)

    def section(match: re.Match) -> str:
        number, title = match.group(1), match.group(2)
        if re.fullmatch(r"\d+\.|\d+-[A-Z]\.", number):
            level = 2
        else:
            level = 3
        return f"{'#' * level} {number} {title}"

    # The config page uses numbered setext headings; make them real headings.
    text = re.sub(
        r"^([0-9][\w-]*\.)[ \t]+(.+)\n-{3,}[ \t]*$",
        section,
        text,
        flags=re.MULTILINE,
    )
    out = pypandoc.convert_text(text, "typst", format="gfm")
    out = postprocess(out).replace("#line(length: 100%)\n", "")
    return label_fences(out, default="yml")


def convert_api(site: Path) -> dict[str, str]:
    """Convert each mkdocstrings API group to its own Typst body."""
    groups = {}
    for name, group, _ in API_GROUPS:
        root = site / group
        if not root.is_dir():
            raise SystemExit(f"missing API group: {root}")
        pages = sorted(
            root.glob("*.html"), key=lambda p: (p.name != "index.html", p.name)
        )
        parts = []
        for page in pages:
            soup = BeautifulSoup(page.read_text(), "html.parser")
            art = soup.select_one("article.md-content__inner")
            if art is None:
                continue
            if page.name == "index.html":
                # The package docstring is a placeholder; keep only the title.
                contents = art.select_one("div.doc-contents")
                for para in contents.find_all("p", recursive=False) if contents else []:
                    if not para.find("span", class_="doc-section-title"):
                        para.decompose()
            for node in art.select(
                "details.mkdocstrings-source, a.headerlink, code.doc-symbol"
            ):
                node.decompose()
            for title in art.find_all("span", class_="doc-section-title"):
                if title.get_text(strip=True) in SUMMARY_SECTIONS:
                    para = title.find_parent("p")
                    listing = para.find_next_sibling("ul") if para else None
                    if listing is not None:
                        listing.decompose()
                    if para is not None:
                        para.decompose()
            # A page left with nothing but its title (package index, script with
            # no documented object) has no section to show.
            contents = art.select_one("div.doc-contents")
            if contents is not None and not contents.get_text(strip=True):
                continue
            # Parameter headings are structural noise in Typst; make them inline.
            for heading in art.select(
                "h3.doc-heading-parameter, h4.doc-heading-parameter, h5.doc-heading-parameter"
            ):
                heading.unwrap()
            for link in art.find_all("a", href=True):
                href = link["href"]
                if not href.startswith(("http://", "https://")) and ".html#" in href:
                    link["href"] = "#" + href.split("#", 1)[1]
            for div in art.find_all("div"):
                classes = div.get("class", [])
                if (
                    any(c.startswith("doc") for c in classes)
                    and "highlight" not in classes
                ):
                    div.unwrap()
            # Keep the parameter and return descriptions, but on one line.
            for title in art.find_all("span", class_="doc-section-title"):
                if title.get_text(strip=True) not in {"Parameters:", "Returns:"}:
                    continue
                para = title.find_parent("p")
                listing = para.find_next_sibling("ul") if para else None
                for item in listing.find_all("li", recursive=False) if listing else []:
                    for desc in item.find_all("p", recursive=False):
                        desc.unwrap()
            out = pypandoc.convert_text(
                art.decode_contents(),
                "typst",
                format="html",
                extra_args=["--shift-heading-level-by=1"],
            )
            parts.append(label_fences(postprocess(out)))
        # Every documented file starts on a new page.
        groups[name] = "\n\n#pagebreak()\n\n".join(parts)
    return groups


def referenced_images(typst: str) -> set[str]:
    """Image filenames referenced by a generated Typst body."""
    return set(re.findall(r'image\("\.\./imgs/seiche-docs/([^"]+)"', typst))


def copy_images(seiche: Path, dest: Path, names: set[str]) -> None:
    """Copy only the images referenced by the appendix, flattening the tree."""
    if dest.exists():
        shutil.rmtree(dest)
    dest.mkdir(parents=True)
    sources = {
        path.name: path
        for path in (seiche / "docs" / "imgs").iterdir()
        if path.is_file()
    }
    for pattern in ("*.png", "*.svg", "*.ico"):
        for path in (seiche / "docs").glob(pattern):
            sources[path.name] = path
    missing = sorted(names - sources.keys())
    if missing:
        raise SystemExit(f"missing source images: {missing}")
    for name in sorted(names):
        shutil.copy2(sources[name], dest / name)


def check_images(typst: str, dest: Path) -> None:
    """Fail loudly if the generated file references a missing image."""
    missing = sorted(
        name for name in referenced_images(typst) if not (dest / name).is_file()
    )
    if missing:
        raise SystemExit(f"missing images in {dest}: {missing}")


def render_appendix(title: str, body: str, *, label: str = "") -> str:
    """Wrap one appendix body, unnumbered and outside the table of contents."""
    heading = f"= {DOC_TITLE} - {title}" + (f" <{label}>" if label else "")
    return (
        "#[\n"
        "  #show heading.where(level: 2): set heading(numbering: none, outlined: false)\n"
        "  #show heading.where(level: 3): set heading(numbering: none, outlined: false)\n"
        "  #show heading.where(level: 4): set heading(numbering: none, outlined: false)\n"
        "  #show heading.where(level: 5): set heading(numbering: none, outlined: false)\n\n"
        f"  {heading}\n\n  {body}\n]\n"
    )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--seiche-root", type=Path, default=DEFAULT_SEICHE)
    parser.add_argument("--out-dir", type=Path, default=REPORT / "typs")
    parser.add_argument("--imgs", type=Path, default=REPORT / "imgs" / "seiche-docs")
    args = parser.parse_args()

    seiche = args.seiche_root.expanduser().resolve()
    with tempfile.TemporaryDirectory(prefix="seiche-docs-") as tmp:
        site = Path(tmp) / "site"
        build_site(seiche, site)
        pages = read_pages(seiche)
        config = convert_config(seiche)
        api = convert_api(site)

    today = datetime.datetime.now().astimezone().date()
    header = (
        f"// Generated by scripts/seiche_docs_to_typst.py from {seiche} on {today}.\n"
        "// Do not edit by hand; run `just seiche-docs` in scripts/ to refresh.\n\n"
    )
    titles = {name: title for name, _, title in API_GROUPS}
    files = []
    for page, text in pages.items():
        if page in EXCLUDED_PAGES:
            continue
        slug = Path(page).stem.replace("_", "-")
        if page == "config.md":
            title, body = CONFIG_TITLE, config
        else:
            title, body = convert_page(page, text)
        files.append(
            (
                f"appendix-seiche-docs-{slug}.typ",
                render_appendix(title, body, label=page_label(slug)),
            )
        )
    files.append(
        (
            "appendix-seiche-docs-api-src.typ",
            render_appendix(titles["src"], api["src"]),
        )
    )
    files.append(
        (
            "appendix-seiche-docs-api-tools.typ",
            render_appendix(titles["tools"], api["tools"]),
        )
    )
    images = set()
    for _, body in files:
        images |= referenced_images(body)
    copy_images(seiche, args.imgs, images)
    args.out_dir.mkdir(parents=True, exist_ok=True)
    for filename, body in files:
        check_images(body, args.imgs)
        (args.out_dir / filename).write_text(header + body)
    print(f"wrote {len(files)} files to {args.out_dir}")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
PDF to Typst converter using a global grid approach.

Strategy:
1. Extract all spans with positions and styling
2. Find all unique x-positions → columns
3. Find all unique y-positions → rows
4. Create a grid cell for each (row, column) combination
5. Place each span in its appropriate cell
6. Generate Typst with one grid per row
"""

import fitz
import os
import sys
from pathlib import Path
from dataclasses import dataclass
from typing import List, Dict, Tuple
from collections import defaultdict


@dataclass
class Span:
    """A text span with position and styling."""
    text: str
    x: float
    y: float
    width: float
    height: float
    is_bold: bool
    is_italic: bool
    is_underlined: bool = False


def escape_typst(text):
    """Escape special Typst characters."""
    if not text:
        return ""
    text = text.replace('\\', '\\\\')
    text = text.replace('#', '\\#')
    text = text.replace('*', '\\*')
    text = text.replace('_', '\\_')
    text = text.replace('[', '\\[')
    text = text.replace(']', '\\]')
    text = text.replace('<', '\\<')
    text = text.replace('>', '\\>')
    text = text.replace('`', '\\`')
    text = text.replace('$', '\\$')
    text = text.replace('@', '\\@')
    return text


def extract_all_spans(page):
    """Extract all text spans with positions and styling."""
    blocks_dict = page.get_text("dict")
    spans = []

    for block in blocks_dict['blocks']:
        if block['type'] != 0:
            continue

        for line in block['lines']:
            for span_data in line['spans']:
                text = span_data['text']
                if not text or text.isspace():
                    continue

                bbox = span_data['bbox']
                span = Span(
                    text=text,
                    x=bbox[0],
                    y=bbox[1],
                    width=bbox[2] - bbox[0],
                    height=bbox[3] - bbox[1],
                    is_bold=(span_data['flags'] & 2**4) > 0,
                    is_italic=(span_data['flags'] & 2**1) > 0
                )
                spans.append(span)

    return spans


def extract_underlines(page):
    """Extract underline positions."""
    underlines = []
    drawings = page.get_drawings()

    for drawing in drawings:
        if drawing['type'] == 'f':
            rect = drawing['rect']
            if rect.height < 5:
                underlines.append({
                    'y': (rect.y0 + rect.y1) / 2,
                    'x0': rect.x0,
                    'x1': rect.x1
                })

    return underlines


def mark_underlines(spans, underlines):
    """Mark which spans have underlines."""
    for span in spans:
        y_bottom = span.y + span.height

        for ul in underlines:
            # Check if underline is near this span (y-wise and x-wise)
            if abs(ul['y'] - y_bottom) <= 5:
                # Check x-overlap
                span_x_end = span.x + span.width
                if not (ul['x1'] < span.x or ul['x0'] > span_x_end):
                    span.is_underlined = True
                    break


def cluster_positions(positions, tolerance=5):
    """Cluster close positions together."""
    if not positions:
        return []

    sorted_pos = sorted(set(positions))
    clusters = [[sorted_pos[0]]]

    for pos in sorted_pos[1:]:
        if pos - clusters[-1][-1] <= tolerance:
            clusters[-1].append(pos)
        else:
            clusters.append([pos])

    # Return average of each cluster
    return [sum(cluster) / len(cluster) for cluster in clusters]


def assign_to_cluster(value, clusters, tolerance=5):
    """Find which cluster a value belongs to."""
    for i, cluster_center in enumerate(clusters):
        if abs(value - cluster_center) <= tolerance:
            return i
    # Shouldn't happen, but fallback
    return 0


def format_span(span):
    """Format a single span with its styling."""
    text = escape_typst(span.text)

    if span.is_bold and span.is_underlined:
        return f"#underline[#strong[{text}]]"
    elif span.is_bold:
        return f"#strong[{text}]"
    elif span.is_italic:
        return f"#emph[{text}]"
    elif span.is_underlined:
        return f"#underline[{text}]"
    else:
        return text


def generate_typst_from_pdf(pdf_path, output_path=None):
    """Generate Typst using global grid approach."""
    doc = fitz.open(pdf_path)
    typst_lines = []

    # Header
    typst_lines.append("// Generated from PDF using global grid approach")
    typst_lines.append("")
    typst_lines.append("#set page(paper: \"a4\", margin: (x: 2cm, y: 2cm))")
    font = os.environ.get("TYPST_FONT", "Calibri")
    typst_lines.append(f"#set text(font: \"{font}\", size: 11pt)")
    typst_lines.append("#set par(leading: 0.65em)")
    typst_lines.append("")

    for page_idx, page in enumerate(doc):
        if page_idx > 0:
            typst_lines.append("#pagebreak()")
            typst_lines.append("")

        # Extract all content
        spans = extract_all_spans(page)
        underlines = extract_underlines(page)
        mark_underlines(spans, underlines)

        if not spans:
            continue

        # Collect all x and y positions
        x_positions = [span.x for span in spans]
        y_positions = [span.y for span in spans]

        # Cluster into columns and rows
        x_clusters = cluster_positions(x_positions, tolerance=5)
        y_clusters = cluster_positions(y_positions, tolerance=3)

        print(f"Page {page_idx + 1}:")
        print(f"  Found {len(x_clusters)} columns at x={[f'{x:.0f}' for x in x_clusters]}")
        print(f"  Found {len(y_clusters)} rows")

        # Create grid: grid[row_idx][col_idx] = [list of spans]
        grid = [[[] for _ in x_clusters] for _ in y_clusters]

        # Assign each span to a cell
        for span in spans:
            row_idx = assign_to_cluster(span.y, y_clusters, tolerance=3)
            col_idx = assign_to_cluster(span.x, x_clusters, tolerance=5)
            grid[row_idx][col_idx].append(span)

        # Sort spans within each cell by x position
        for row in grid:
            for cell in row:
                cell.sort(key=lambda s: s.x)

        # Generate Typst for each row
        for row_idx, row in enumerate(grid):
            # Check if row has any content
            filled_cols = sum(1 for cell in row if cell)

            if filled_cols == 0:
                continue

            # ALWAYS use grid - even for single column
            typst_lines.append("#grid(")
            typst_lines.append(f"  columns: {len(x_clusters)},")
            typst_lines.append("  gutter: 1em,")

            for col_idx, cell in enumerate(row):
                if cell:
                    # Check if starts with bullet
                    text = ''.join(s.text for s in cell)
                    if text.strip().startswith('•'):
                        # Remove bullet symbol
                        formatted_spans = []
                        for i, span in enumerate(cell):
                            if i == 0 and span.text.strip() in ['•', '●', '◦']:
                                continue
                            formatted_spans.append(format_span(span))
                        content = f"- {''.join(formatted_spans)}"
                    else:
                        content = ''.join(format_span(s) for s in cell)
                    typst_lines.append(f"  [{content}],")
                else:
                    typst_lines.append("  [],")

            typst_lines.append(")")

        typst_lines.append("")

    doc.close()

    # Write output
    typst_content = '\n'.join(typst_lines)

    if output_path:
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(typst_content)

    return typst_content


def main():
    if len(sys.argv) < 2:
        print("Usage: python pdf_to_typst_global_grid.py <pdf_file> [output.typ]")
        sys.exit(1)

    pdf_path = sys.argv[1]

    if not Path(pdf_path).exists():
        print(f"Error: File not found: {pdf_path}")
        sys.exit(1)

    if len(sys.argv) >= 3:
        output_path = sys.argv[2]
    else:
        output_path = Path(pdf_path).stem + "_global_grid.typ"

    print(f"Converting {pdf_path} to Typst...")

    try:
        generate_typst_from_pdf(pdf_path, output_path)
        print(f"✓ Successfully generated: {output_path}")
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()

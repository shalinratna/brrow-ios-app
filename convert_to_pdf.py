#!/usr/bin/env python3
"""
Brrow Documentation Markdown to PDF Converter
Professional PDF generation with Brrow brand colors and styling
"""

import markdown2
import re
from pathlib import Path
from datetime import datetime
from weasyprint import HTML, CSS

def extract_toc(markdown_content):
    """Extract table of contents from markdown headers"""
    lines = markdown_content.split('\n')
    toc_items = []

    for line in lines:
        # Match headers (h1-h3 for TOC)
        match = re.match(r'^(#{1,3})\s+(.+)$', line)
        if match:
            level = len(match.group(1))
            title = match.group(2)
            # Create anchor-friendly ID
            anchor_id = re.sub(r'[^\w\s-]', '', title.lower())
            anchor_id = re.sub(r'[-\s]+', '-', anchor_id)
            toc_items.append({
                'level': level,
                'title': title,
                'anchor': anchor_id
            })

    return toc_items

def add_anchors_to_headers(html_content):
    """Add ID anchors to headers for TOC linking"""
    def replace_header(match):
        tag = match.group(1)
        content = match.group(2)
        # Create anchor-friendly ID from content
        anchor_id = re.sub(r'[^\w\s-]', '', content.lower())
        anchor_id = re.sub(r'[-\s]+', '-', anchor_id)
        anchor_id = re.sub(r'<[^>]+>', '', anchor_id)  # Remove HTML tags
        return f'<{tag} id="{anchor_id}">{content}</{tag}>'

    # Replace h1, h2, h3 tags
    html_content = re.sub(r'<(h[1-3])>(.*?)</\1>', replace_header, html_content)
    return html_content

def generate_toc_html(toc_items):
    """Generate HTML table of contents"""
    toc_html = '''
    <div class="toc">
        <h1>Table of Contents</h1>
        <ul>
    '''

    current_level = 0
    for item in toc_items:
        level = item['level']

        # Only include h1 and h2 in TOC for cleaner look
        if level > 2:
            continue

        indent = '&nbsp;' * (level - 1) * 4
        toc_html += f'''
            <li>{indent}<a href="#{item['anchor']}">{item['title']}</a></li>
        '''

    toc_html += '''
        </ul>
    </div>
    '''
    return toc_html

def create_cover_page():
    """Generate cover page HTML"""
    current_date = datetime.now().strftime("%B %d, %Y")
    return f'''
    <div class="cover-page">
        <h1>Brrow</h1>
        <div class="subtitle">Complete System Documentation</div>
        <div class="date">Generated on {current_date}</div>
    </div>
    '''

def convert_markdown_to_pdf(markdown_file, output_file, css_file):
    """
    Convert Markdown to PDF with professional styling

    Args:
        markdown_file: Path to input markdown file
        output_file: Path to output PDF file
        css_file: Path to CSS stylesheet
    """
    print(f"Reading markdown file: {markdown_file}")

    # Read markdown content
    with open(markdown_file, 'r', encoding='utf-8') as f:
        markdown_content = f.read()

    print("Converting markdown to HTML...")

    # Configure markdown2 with extras
    extras = [
        'fenced-code-blocks',
        'tables',
        'code-friendly',
        'cuddled-lists',
        'header-ids',
        'task_list',
        'strike',
        'target-blank-links',
        'numbering',
    ]

    # Convert markdown to HTML
    html_content = markdown2.markdown(markdown_content, extras=extras)

    print("Generating table of contents...")

    # Extract TOC from original markdown
    toc_items = extract_toc(markdown_content)

    # Add anchors to headers
    html_content = add_anchors_to_headers(html_content)

    # Generate cover page
    cover_html = create_cover_page()

    # Generate TOC HTML
    toc_html = generate_toc_html(toc_items)

    # Combine into full HTML document
    full_html = f'''
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Brrow Complete System Documentation</title>
    </head>
    <body>
        {cover_html}
        {toc_html}
        <div class="content">
            {html_content}
        </div>
    </body>
    </html>
    '''

    print("Generating PDF...")

    # Create PDF with WeasyPrint
    html_obj = HTML(string=full_html)
    css_obj = CSS(filename=css_file)

    html_obj.write_pdf(
        output_file,
        stylesheets=[css_obj],
        optimize_size=('fonts', 'images')
    )

    print(f"PDF generated successfully: {output_file}")

    # Get file size
    file_size = Path(output_file).stat().st_size
    file_size_mb = file_size / (1024 * 1024)

    print(f"File size: {file_size_mb:.2f} MB")

    return output_file

if __name__ == "__main__":
    # File paths
    base_dir = Path("/Users/shalin/Documents/Projects/Xcode/Brrow")
    markdown_file = base_dir / "BRROW_COMPLETE_SYSTEM_DOCUMENTATION.md"
    output_file = base_dir / "BRROW_COMPLETE_SYSTEM_DOCUMENTATION.pdf"
    css_file = base_dir / "pdf_styles.css"

    # Convert
    convert_markdown_to_pdf(markdown_file, output_file, css_file)

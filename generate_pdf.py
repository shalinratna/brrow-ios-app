#!/usr/bin/env python3
"""
Brrow Documentation Markdown to PDF Converter
Using markdown2 + HTML + print to PDF approach
"""

import markdown2
import re
import subprocess
import os
from pathlib import Path
from datetime import datetime

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

def read_css(css_file):
    """Read CSS file content"""
    with open(css_file, 'r', encoding='utf-8') as f:
        return f.read()

def convert_markdown_to_html(markdown_file, output_html, css_file):
    """
    Convert Markdown to HTML with professional styling

    Args:
        markdown_file: Path to input markdown file
        output_html: Path to output HTML file
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

    # Read CSS
    css_content = read_css(css_file)

    # Combine into full HTML document
    full_html = f'''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Brrow Complete System Documentation</title>
    <style>
    {css_content}
    </style>
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

    print("Writing HTML file...")

    # Write HTML file
    with open(output_html, 'w', encoding='utf-8') as f:
        f.write(full_html)

    print(f"HTML generated successfully: {output_html}")

    # Get file size
    file_size = Path(output_html).stat().st_size
    file_size_kb = file_size / 1024

    print(f"File size: {file_size_kb:.2f} KB")

    return output_html

def convert_html_to_pdf_chrome(html_file, pdf_file):
    """Convert HTML to PDF using Chrome headless"""
    print("\nConverting HTML to PDF using Chrome...")

    chrome_paths = [
        '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
        '/Applications/Chromium.app/Contents/MacOS/Chromium',
        '/Applications/Google Chrome Canary.app/Contents/MacOS/Google Chrome Canary',
    ]

    chrome_path = None
    for path in chrome_paths:
        if os.path.exists(path):
            chrome_path = path
            break

    if not chrome_path:
        print("Chrome not found. Trying Safari/WebKit...")
        return convert_html_to_pdf_webkit(html_file, pdf_file)

    # Convert using Chrome headless
    cmd = [
        chrome_path,
        '--headless',
        '--disable-gpu',
        '--no-pdf-header-footer',
        '--print-to-pdf=' + str(pdf_file),
        'file://' + str(html_file)
    ]

    try:
        subprocess.run(cmd, check=True, capture_output=True, timeout=60)
        print(f"PDF generated successfully: {pdf_file}")
        return pdf_file
    except Exception as e:
        print(f"Error using Chrome: {e}")
        return convert_html_to_pdf_webkit(html_file, pdf_file)

def convert_html_to_pdf_webkit(html_file, pdf_file):
    """Convert HTML to PDF using WebKit (Safari) via AppleScript"""
    print("\nConverting HTML to PDF using Safari/WebKit...")

    applescript = f'''
tell application "Safari"
    activate
    open POSIX file "{html_file}"
    delay 3
    tell application "System Events"
        keystroke "p" using command down
        delay 2
        keystroke return
        delay 1
    end tell
    quit
end tell
'''

    try:
        # This is a fallback - we'll use cupsfilter instead
        print("Using cupsfilter as alternative...")
        cmd = ['cupsfilter', str(html_file)]
        with open(pdf_file, 'wb') as f:
            subprocess.run(cmd, check=True, stdout=f, timeout=60)
        print(f"PDF generated successfully: {pdf_file}")
        return pdf_file
    except Exception as e:
        print(f"Error: {e}")
        print("\nManual conversion required:")
        print(f"1. Open: {html_file}")
        print(f"2. Print to PDF: {pdf_file}")
        return None

if __name__ == "__main__":
    # File paths
    base_dir = Path("/Users/shalin/Documents/Projects/Xcode/Brrow")
    markdown_file = base_dir / "BRROW_COMPLETE_SYSTEM_DOCUMENTATION.md"
    output_html = base_dir / "BRROW_COMPLETE_SYSTEM_DOCUMENTATION.html"
    output_pdf = base_dir / "BRROW_COMPLETE_SYSTEM_DOCUMENTATION.pdf"
    css_file = base_dir / "pdf_styles.css"

    # Convert markdown to HTML
    html_path = convert_markdown_to_html(markdown_file, output_html, css_file)

    # Convert HTML to PDF
    pdf_path = convert_html_to_pdf_chrome(html_path, output_pdf)

    if pdf_path:
        # Get PDF file size
        file_size = Path(pdf_path).stat().st_size
        file_size_mb = file_size / (1024 * 1024)
        print(f"\n✅ Conversion complete!")
        print(f"📄 PDF file: {pdf_path}")
        print(f"📊 File size: {file_size_mb:.2f} MB")

        # Try to get page count
        try:
            result = subprocess.run(['mdls', '-name', 'kMDItemNumberOfPages', str(pdf_path)],
                                  capture_output=True, text=True)
            if result.returncode == 0:
                pages = result.stdout.strip().split('=')[1].strip()
                print(f"📖 Page count: {pages}")
        except:
            pass
    else:
        print(f"\n📄 HTML file generated: {html_path}")
        print("\nTo create PDF:")
        print(f"  1. Open {html_path} in Chrome/Safari")
        print(f"  2. Print to PDF")
        print(f"  3. Save as {output_pdf}")

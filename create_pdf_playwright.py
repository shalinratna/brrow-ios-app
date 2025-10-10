#!/usr/bin/env python3
"""
Create PDF from HTML using Playwright (most reliable method)
"""

import os
import sys
import subprocess
from pathlib import Path

def install_playwright():
    """Install playwright if not already installed"""
    try:
        import playwright
        print("✓ Playwright is already installed")
        return True
    except ImportError:
        print("Installing Playwright...")
        try:
            subprocess.run(
                [sys.executable, '-m', 'pip', 'install', 'playwright', '--user'],
                check=True,
                capture_output=True,
                timeout=120
            )
            print("✓ Playwright installed")

            print("Installing Chromium browser...")
            subprocess.run(
                [sys.executable, '-m', 'playwright', 'install', 'chromium'],
                check=True,
                timeout=300
            )
            print("✓ Chromium installed")
            return True
        except Exception as e:
            print(f"✗ Failed to install Playwright: {e}")
            return False

def create_pdf_playwright(html_file, pdf_file):
    """Create PDF using Playwright"""
    try:
        from playwright.sync_api import sync_playwright

        print(f"\nConverting HTML to PDF...")
        print(f"Input:  {html_file}")
        print(f"Output: {pdf_file}\n")

        with sync_playwright() as p:
            # Launch browser
            print("⏳ Launching Chromium...")
            browser = p.chromium.launch(headless=True)
            page = browser.new_page()

            # Load HTML file
            print("⏳ Loading HTML...")
            page.goto(f'file://{os.path.abspath(html_file)}')

            # Wait for page to be fully loaded
            page.wait_for_load_state('networkidle')

            # Extra wait for rendering
            page.wait_for_timeout(2000)

            print("⏳ Generating PDF...")

            # Generate PDF
            page.pdf(
                path=pdf_file,
                format='A4',
                print_background=True,
                margin={
                    'top': '2.5cm',
                    'right': '2cm',
                    'bottom': '2.5cm',
                    'left': '2cm'
                },
                prefer_css_page_size=False,
                display_header_footer=False,
            )

            browser.close()

            print("✅ PDF created successfully!")
            return True

    except Exception as e:
        print(f"✗ Error: {e}")
        import traceback
        traceback.print_exc()
        return False

def get_pdf_info(pdf_file):
    """Get PDF file information"""
    if not os.path.exists(pdf_file):
        return None

    file_size = os.path.getsize(pdf_file) / (1024 * 1024)

    info = {
        'path': pdf_file,
        'size_mb': file_size,
        'pages': None
    }

    # Try to get page count on macOS
    try:
        result = subprocess.run(
            ['mdls', '-name', 'kMDItemNumberOfPages', pdf_file],
            capture_output=True,
            text=True,
            timeout=5
        )
        if '=' in result.stdout:
            pages_str = result.stdout.split('=')[1].strip()
            if pages_str and pages_str != '(null)':
                info['pages'] = int(pages_str)
    except:
        pass

    return info

def main():
    """Main function"""
    base_dir = Path("/Users/shalin/Documents/Projects/Xcode/Brrow")
    html_file = base_dir / "BRROW_COMPLETE_SYSTEM_DOCUMENTATION.html"
    pdf_file = base_dir / "BRROW_COMPLETE_SYSTEM_DOCUMENTATION.pdf"

    print("="*70)
    print(" BRROW DOCUMENTATION - PDF GENERATION WITH PLAYWRIGHT")
    print("="*70)

    # Check if HTML exists
    if not html_file.exists():
        print(f"\n✗ Error: HTML file not found")
        print(f"  Expected: {html_file}")
        print(f"\nPlease run generate_pdf.py first to create the HTML file.")
        sys.exit(1)

    # Install Playwright if needed
    if not install_playwright():
        print("\n✗ Failed to install Playwright")
        print("\nPlease install manually:")
        print("  pip3 install playwright --user")
        print("  playwright install chromium")
        sys.exit(1)

    # Create PDF
    success = create_pdf_playwright(str(html_file), str(pdf_file))

    if success:
        info = get_pdf_info(str(pdf_file))
        if info:
            print("\n" + "="*70)
            print(" PDF GENERATION COMPLETE!")
            print("="*70)
            print(f"\n📄 File: {info['path']}")
            print(f"📊 Size: {info['size_mb']:.2f} MB")
            if info['pages']:
                print(f"📖 Pages: {info['pages']}")
            print("\n✅ Your professional Brrow documentation PDF is ready!")
            print("="*70)
        else:
            print("\n⚠ PDF was created but file info could not be retrieved")
    else:
        print("\n✗ PDF generation failed")
        print("\nPlease try manual conversion:")
        print(f"  1. Open: {html_file}")
        print("  2. File → Print → Save as PDF")
        print(f"  3. Save to: {pdf_file}")
        sys.exit(1)

if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
Convert HTML to PDF using macOS native tools
"""

import subprocess
import os
from pathlib import Path

def html_to_pdf_osascript(html_file, pdf_file):
    """
    Convert HTML to PDF using Safari and AppleScript automation
    """
    print(f"Converting {html_file} to PDF...")

    # Create absolute paths
    html_path = os.path.abspath(html_file)
    pdf_path = os.path.abspath(pdf_file)

    # AppleScript to open in Safari and export as PDF
    applescript = f'''
    set htmlFile to POSIX file "{html_path}"
    set pdfFile to POSIX file "{pdf_path}"

    tell application "Safari"
        activate
        open htmlFile
        delay 5

        -- Wait for page to load
        repeat while (do JavaScript "document.readyState" in document 1) is not "complete"
            delay 0.5
        end repeat

        delay 2
    end tell

    -- Use print dialog
    tell application "System Events"
        tell process "Safari"
            keystroke "p" using command down
            delay 2

            -- Click PDF menu
            click menu button "PDF" of sheet 1 of window 1
            delay 1

            -- Click "Save as PDF"
            click menu item "Save as PDF" of menu 1 of menu button "PDF" of sheet 1 of window 1
            delay 1

            -- Enter filename
            keystroke "g" using {{command down, shift down}}
            delay 0.5
            keystroke "{pdf_path}"
            delay 0.5
            keystroke return
            delay 0.5

            -- Click Save
            click button "Save" of sheet 1 of window 1
            delay 2
        end tell
    end tell

    tell application "Safari"
        close window 1
    end tell
    '''

    try:
        # Execute AppleScript
        result = subprocess.run(
            ['osascript', '-e', applescript],
            capture_output=True,
            text=True,
            timeout=60
        )

        if result.returncode == 0:
            print(f"✅ PDF created successfully: {pdf_file}")
            return True
        else:
            print(f"Error: {result.stderr}")
            return False
    except Exception as e:
        print(f"Error: {e}")
        return False

def html_to_pdf_textutil(html_file, pdf_file):
    """
    Try using textutil (macOS built-in) - limited HTML support
    """
    print("Trying textutil conversion...")
    try:
        subprocess.run(
            ['textutil', '-convert', 'html', '-output', pdf_file, html_file],
            check=True,
            timeout=30
        )
        print(f"✅ PDF created: {pdf_file}")
        return True
    except:
        return False

def html_to_pdf_webkit2png(html_file, pdf_file):
    """
    Generate PDF using headless webkit2png if available
    """
    try:
        # First try to install webkit2png
        subprocess.run(['pip3', 'install', 'webkit2png', '--user'],
                      capture_output=True, timeout=60)

        result = subprocess.run(
            ['webkit2png', '-F', '-o', pdf_file.replace('.pdf', ''), html_file],
            capture_output=True,
            timeout=60
        )
        return result.returncode == 0
    except:
        return False

if __name__ == "__main__":
    base_dir = Path("/Users/shalin/Documents/Projects/Xcode/Brrow")
    html_file = base_dir / "BRROW_COMPLETE_SYSTEM_DOCUMENTATION.html"
    pdf_file = base_dir / "BRROW_COMPLETE_SYSTEM_DOCUMENTATION.pdf"

    print("Attempting HTML to PDF conversion using Safari...")
    print("This will open Safari briefly to export the PDF.")
    print("")

    if html_to_pdf_osascript(str(html_file), str(pdf_file)):
        # Check if PDF was created
        if os.path.exists(pdf_file):
            file_size = Path(pdf_file).stat().st_size / (1024 * 1024)
            print(f"\n📄 PDF: {pdf_file}")
            print(f"📊 Size: {file_size:.2f} MB")

            # Get page count
            try:
                result = subprocess.run(
                    ['mdls', '-name', 'kMDItemNumberOfPages', str(pdf_file)],
                    capture_output=True,
                    text=True
                )
                if '=' in result.stdout:
                    pages = result.stdout.split('=')[1].strip()
                    print(f"📖 Pages: {pages}")
            except:
                pass
        else:
            print("\n❌ PDF file was not created")
            print("\nPlease create PDF manually:")
            print(f"1. Open: {html_file}")
            print(f"2. File → Print → Save as PDF")
            print(f"3. Save to: {pdf_file}")
    else:
        print("\n❌ Automated conversion failed")
        print("\nPlease create PDF manually:")
        print(f"1. Open: {html_file}")
        print(f"2. File → Print → Save as PDF")
        print(f"3. Save to: {pdf_file}")

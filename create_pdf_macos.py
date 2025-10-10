#!/usr/bin/env python3
"""
Create PDF from HTML using macOS native Quartz APIs
"""

import os
import sys
from pathlib import Path

def create_pdf_with_quartz(html_file, pdf_file):
    """
    Use macOS Quartz to convert HTML to PDF
    This uses PyObjC which should be available on macOS
    """
    try:
        # Import macOS frameworks
        import Quartz
        import Cocoa
        from Foundation import NSURL

        print(f"Converting {html_file} to PDF using Quartz...")

        # Create NSURL for HTML file
        html_url = NSURL.fileURLWithPath_(os.path.abspath(html_file))

        # Create WebView
        web_view = Cocoa.WebView.alloc().initWithFrame_(Cocoa.NSMakeRect(0, 0, 800, 1000))

        # Load HTML
        web_view.mainFrame().loadRequest_(Cocoa.NSURLRequest.requestWithURL_(html_url))

        # Wait for loading to complete
        while web_view.isLoading():
            Cocoa.NSRunLoop.currentRunLoop().runUntilDate_(
                Cocoa.NSDate.dateWithTimeIntervalSinceNow_(0.1)
            )

        # Additional delay to ensure rendering is complete
        import time
        time.sleep(2)

        # Get print operation
        print_info = Cocoa.NSPrintInfo.sharedPrintInfo()
        print_info.setHorizontalPagination_(Cocoa.NSAutoPagination)
        print_info.setVerticalPagination_(Cocoa.NSAutoPagination)
        print_info.setVerticallyCentered_(False)

        # Set margins
        print_info.setLeftMargin_(50)
        print_info.setRightMargin_(50)
        print_info.setTopMargin_(50)
        print_info.setBottomMargin_(50)

        # Get document view
        doc_view = web_view.mainFrame().frameView().documentView()

        # Create print operation
        print_op = Cocoa.NSPrintOperation.printOperationWithView_printInfo_(
            doc_view,
            print_info
        )

        # Set to save to file
        print_op.setShowsPrintPanel_(False)
        print_op.setShowsProgressPanel_(False)

        # Set PDF output path
        pdf_path = os.path.abspath(pdf_file)
        print_info.dictionary()[Cocoa.NSPrintJobSavingURL] = NSURL.fileURLWithPath_(pdf_path)
        print_info.dictionary()[Cocoa.NSPrintJobDisposition] = Cocoa.NSPrintSaveJob

        # Run print operation
        success = print_op.runOperation()

        if success:
            print(f"✅ PDF created successfully: {pdf_file}")
            return True
        else:
            print("❌ Failed to create PDF")
            return False

    except ImportError as e:
        print(f"PyObjC not available: {e}")
        print("Trying alternative method...")
        return False
    except Exception as e:
        print(f"Error: {e}")
        return False

def create_pdf_with_subprocess(html_file, pdf_file):
    """
    Use command-line tools to convert HTML to PDF
    """
    import subprocess

    # Try using sips or qlmanage (macOS built-in tools)
    try:
        # Create a temporary PostScript file first
        temp_ps = pdf_file.replace('.pdf', '.ps')

        # Try using enscript (if available)
        subprocess.run(
            ['enscript', '-p', temp_ps, '--language=html', html_file],
            check=True,
            capture_output=True,
            timeout=30
        )

        # Convert PS to PDF
        subprocess.run(
            ['ps2pdf', temp_ps, pdf_file],
            check=True,
            capture_output=True,
            timeout=30
        )

        # Clean up
        if os.path.exists(temp_ps):
            os.remove(temp_ps)

        print(f"✅ PDF created: {pdf_file}")
        return True
    except:
        pass

    # Try using pandoc if available
    try:
        subprocess.run(
            ['pandoc', html_file, '-o', pdf_file, '--pdf-engine=context'],
            check=True,
            capture_output=True,
            timeout=60
        )
        print(f"✅ PDF created: {pdf_file}")
        return True
    except:
        pass

    return False

def show_manual_instructions(html_file, pdf_file):
    """
    Show instructions for manual PDF creation
    """
    print("\n" + "="*60)
    print("MANUAL PDF CREATION REQUIRED")
    print("="*60)
    print("\nThe HTML file has been generated successfully.")
    print("Please follow these steps to create the PDF:\n")
    print("1. Open Safari or Chrome")
    print(f"2. Open file: {html_file}")
    print("3. Press Cmd+P (or File → Print)")
    print("4. Click 'Show Details' if needed")
    print("5. In the PDF dropdown (bottom left), select 'Save as PDF'")
    print(f"6. Save to: {pdf_file}")
    print("\nThe HTML file has professional styling with:")
    print("  • Brrow brand colors (Blue, Green, White)")
    print("  • Table of contents with clickable links")
    print("  • Syntax highlighted code blocks")
    print("  • Professional typography and spacing")
    print("  • Page numbers and headers")
    print("="*60)

if __name__ == "__main__":
    base_dir = Path("/Users/shalin/Documents/Projects/Xcode/Brrow")
    html_file = base_dir / "BRROW_COMPLETE_SYSTEM_DOCUMENTATION.html"
    pdf_file = base_dir / "BRROW_COMPLETE_SYSTEM_DOCUMENTATION.pdf"

    # Verify HTML exists
    if not html_file.exists():
        print(f"❌ HTML file not found: {html_file}")
        sys.exit(1)

    print("Attempting to create PDF from HTML...")
    print(f"Input:  {html_file}")
    print(f"Output: {pdf_file}")
    print("")

    # Try Quartz method first
    success = create_pdf_with_quartz(str(html_file), str(pdf_file))

    # Try subprocess methods
    if not success:
        success = create_pdf_with_subprocess(str(html_file), str(pdf_file))

    # If all methods fail, show manual instructions
    if not success:
        show_manual_instructions(html_file, pdf_file)
    else:
        # Show file info
        if pdf_file.exists():
            file_size = pdf_file.stat().st_size / (1024 * 1024)
            print(f"\n📄 PDF file: {pdf_file}")
            print(f"📊 File size: {file_size:.2f} MB")

            # Try to get page count
            try:
                import subprocess
                result = subprocess.run(
                    ['mdls', '-name', 'kMDItemNumberOfPages', str(pdf_file)],
                    capture_output=True,
                    text=True
                )
                if '=' in result.stdout:
                    pages = result.stdout.split('=')[1].strip()
                    print(f"📖 Page count: {pages}")
            except:
                pass

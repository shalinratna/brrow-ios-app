#!/usr/bin/env python3
"""
Create PDF from HTML using macOS WebKit with proper rendering wait
"""

import os
import sys
import time
from pathlib import Path

def create_pdf_webkit(html_file, pdf_file):
    """
    Use WebKit to convert HTML to PDF with proper loading wait
    """
    try:
        import objc
        from Foundation import NSObject, NSURL, NSRunLoop, NSDate, NSDefaultRunLoopMode
        from WebKit import WebView
        from AppKit import NSPrintInfo, NSPrintOperation, NSPrintSaveJob, NSAutoPagination, NSRect, NSPrintJobSavingURL, NSPrintJobDisposition

        print(f"Converting {html_file} to PDF using WebKit...")

        # Create WebView delegate to track loading
        class WebViewDelegate(NSObject):
            def init(self):
                self = objc.super(WebViewDelegate, self).init()
                if self is None:
                    return None
                self.is_loaded = False
                return self

            def webView_didFinishLoadForFrame_(self, webview, frame):
                if frame == webview.mainFrame():
                    self.is_loaded = True
                    print("✓ HTML loaded")

        # Create WebView with a reasonable size (A4 proportions)
        frame = NSRect()
        frame.origin.x = 0
        frame.origin.y = 0
        frame.size.width = 595  # A4 width in points
        frame.size.height = 842  # A4 height in points

        web_view = WebView.alloc().initWithFrame_(frame)

        # Set delegate
        delegate = WebViewDelegate.alloc().init()
        web_view.setFrameLoadDelegate_(delegate)

        # Load HTML file
        html_url = NSURL.fileURLWithPath_(os.path.abspath(html_file))
        web_view.mainFrame().loadRequest_(objc.lookUpClass('NSURLRequest').requestWithURL_(html_url))

        # Wait for loading to complete (with timeout)
        timeout = 30  # seconds
        start_time = time.time()
        while not delegate.is_loaded:
            NSRunLoop.currentRunLoop().runMode_beforeDate_(
                NSDefaultRunLoopMode,
                NSDate.dateWithTimeIntervalSinceNow_(0.1)
            )
            if time.time() - start_time > timeout:
                print("⚠ Timeout waiting for HTML to load")
                break
            time.sleep(0.1)

        # Extra delay for rendering
        print("⏳ Waiting for rendering...")
        time.sleep(3)

        # Configure print settings
        print_info = NSPrintInfo.sharedPrintInfo().copy()
        print_info.setHorizontalPagination_(NSAutoPagination)
        print_info.setVerticalPagination_(NSAutoPagination)
        print_info.setVerticallyCentered_(False)

        # Set margins (in points, 72 points = 1 inch)
        print_info.setLeftMargin_(72)
        print_info.setRightMargin_(72)
        print_info.setTopMargin_(72)
        print_info.setBottomMargin_(72)

        # Get the document view
        doc_view = web_view.mainFrame().frameView().documentView()

        # Create print operation
        print_op = NSPrintOperation.printOperationWithView_printInfo_(doc_view, print_info)
        print_op.setShowsPrintPanel_(False)
        print_op.setShowsProgressPanel_(False)

        # Configure for PDF output
        pdf_path = os.path.abspath(pdf_file)
        pdf_url = NSURL.fileURLWithPath_(pdf_path)
        print_info.dictionary()[NSPrintJobSavingURL] = pdf_url
        print_info.dictionary()[NSPrintJobDisposition] = NSPrintSaveJob

        # Run the print operation
        print("📄 Generating PDF...")
        success = print_op.runOperation()

        if success and os.path.exists(pdf_file):
            file_size = os.path.getsize(pdf_file)
            if file_size > 1000:  # At least 1KB
                print(f"✅ PDF created successfully!")
                return True
            else:
                print(f"⚠ PDF file is too small ({file_size} bytes), might be empty")
                os.remove(pdf_file)
                return False
        else:
            print("❌ Failed to create PDF")
            return False

    except ImportError as e:
        print(f"❌ Required frameworks not available: {e}")
        return False
    except Exception as e:
        print(f"❌ Error during conversion: {e}")
        import traceback
        traceback.print_exc()
        return False

def show_manual_instructions(html_file, pdf_file):
    """Show manual PDF creation instructions"""
    print("\n" + "="*70)
    print(" PLEASE CREATE PDF MANUALLY")
    print("="*70)
    print("\nThe HTML documentation has been successfully generated with:")
    print("  ✓ Professional styling with Brrow brand colors (Blue, Green, White)")
    print("  ✓ Clickable table of contents")
    print("  ✓ Syntax-highlighted code blocks")
    print("  ✓ Professional typography and spacing")
    print("  ✓ Headers and page numbers (will appear in PDF)")
    print("\n" + "-"*70)
    print("TO CREATE THE PDF:")
    print("-"*70)
    print("\n1. Open Safari, Chrome, or any web browser")
    print(f"\n2. Open this file:")
    print(f"   {html_file}")
    print("\n3. Print to PDF:")
    print("   • Press Cmd+P (or File → Print)")
    print("   • Click 'Show Details' if available")
    print("   • In the PDF dropdown (bottom left), select 'Save as PDF'")
    print(f"   • Save to: {pdf_file}")
    print("\n4. Verify the PDF:")
    print("   • Check that all formatting is preserved")
    print("   • Verify code blocks are readable")
    print("   • Ensure table of contents links work")
    print("\n" + "="*70)

if __name__ == "__main__":
    base_dir = Path("/Users/shalin/Documents/Projects/Xcode/Brrow")
    html_file = base_dir / "BRROW_COMPLETE_SYSTEM_DOCUMENTATION.html"
    pdf_file = base_dir / "BRROW_COMPLETE_SYSTEM_DOCUMENTATION.pdf"

    # Verify HTML exists
    if not html_file.exists():
        print(f"❌ HTML file not found: {html_file}")
        print("\nPlease run generate_pdf.py first to create the HTML file.")
        sys.exit(1)

    print("\n" + "="*70)
    print(" BRROW DOCUMENTATION - PDF GENERATION")
    print("="*70)
    print(f"\nInput:  {html_file}")
    print(f"Output: {pdf_file}\n")

    # Try to create PDF automatically
    success = create_pdf_webkit(str(html_file), str(pdf_file))

    if success and pdf_file.exists():
        # Show file statistics
        file_size = pdf_file.stat().st_size / (1024 * 1024)
        print(f"\n📄 PDF File: {pdf_file}")
        print(f"📊 Size: {file_size:.2f} MB")

        # Try to get page count
        try:
            import subprocess
            result = subprocess.run(
                ['mdls', '-name', 'kMDItemNumberOfPages', str(pdf_file)],
                capture_output=True,
                text=True,
                timeout=5
            )
            if '=' in result.stdout:
                pages = result.stdout.split('=')[1].strip()
                if pages and pages != '(null)':
                    print(f"📖 Pages: {pages}")
        except:
            pass

        print("\n✅ PDF GENERATION COMPLETE!")
        print("\n" + "="*70)
    else:
        # Show manual instructions
        show_manual_instructions(html_file, pdf_file)

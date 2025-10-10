-- AppleScript to export Safari page as PDF
-- This automates the Print to PDF process

set pdfPath to "/Users/shalin/Documents/Projects/Xcode/Brrow/BRROW_COMPLETE_SYSTEM_DOCUMENTATION.pdf"

tell application "Safari"
    activate
    delay 2
end tell

tell application "System Events"
    tell process "Safari"
        -- Open Print dialog
        keystroke "p" using command down
        delay 3

        -- Click PDF menu button
        try
            click menu button "PDF" of sheet 1 of window 1
            delay 1

            -- Click "Save as PDF"
            click menu item "Save as PDF" of menu 1 of menu button "PDF" of sheet 1 of window 1
            delay 2

            -- Go to specific folder
            keystroke "g" using {command down, shift down}
            delay 1

            -- Type the folder path
            keystroke "/Users/shalin/Documents/Projects/Xcode/Brrow/"
            delay 0.5
            keystroke return
            delay 1

            -- Type the filename
            keystroke "a" using command down
            delay 0.3
            keystroke "BRROW_COMPLETE_SYSTEM_DOCUMENTATION.pdf"
            delay 0.5

            -- Click Save
            click button "Save" of sheet 1 of sheet 1 of window 1
            delay 2

            -- Handle replace dialog if file exists
            try
                click button "Replace" of sheet 1 of sheet 1 of sheet 1 of window 1
                delay 1
            end try

            display notification "PDF export complete!" with title "Brrow Documentation"
        on error errMsg
            display dialog "Error during PDF export: " & errMsg
        end try
    end tell
end tell

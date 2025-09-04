-- Fix uploaded_files table schema
-- Add missing user_api_id column if it doesn't exist

-- First, check if the column exists and add it if not
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'uploaded_files' 
        AND column_name = 'user_api_id'
    ) THEN
        ALTER TABLE uploaded_files 
        ADD COLUMN user_api_id VARCHAR(255);
    END IF;
END $$;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_uploaded_files_user_api_id 
ON uploaded_files(user_api_id);

-- Show current table structure
\d uploaded_files
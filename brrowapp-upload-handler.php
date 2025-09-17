<?php
/**
 * Image Upload Handler for brrowapp.com
 * This handles image uploads from the Railway backend
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, X-API-Key');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// Configuration
$API_KEY = 'brrow-upload-key-2024-secure';
$UPLOAD_DIR = __DIR__ . '/uploads/';
$MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB
$ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];

// Verify API key
$providedKey = $_SERVER['HTTP_X_API_KEY'] ?? $_POST['api_key'] ?? '';
if ($providedKey !== $API_KEY) {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Invalid API key']);
    exit;
}

// Create upload directory if it doesn't exist
if (!file_exists($UPLOAD_DIR)) {
    mkdir($UPLOAD_DIR, 0755, true);
}

// Handle DELETE request
if ($_SERVER['REQUEST_METHOD'] === 'DELETE') {
    $path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
    $filename = basename($path);

    if ($filename && file_exists($UPLOAD_DIR . $filename)) {
        unlink($UPLOAD_DIR . $filename);
        echo json_encode(['success' => true, 'message' => 'Image deleted']);
    } else {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'Image not found']);
    }
    exit;
}

// Handle POST request (upload)
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

// Check if file was uploaded
if (!isset($_FILES['image'])) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'No image uploaded']);
    exit;
}

$uploadedFile = $_FILES['image'];

// Check for upload errors
if ($uploadedFile['error'] !== UPLOAD_ERR_OK) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Upload failed: ' . $uploadedFile['error']]);
    exit;
}

// Validate file size
if ($uploadedFile['size'] > $MAX_FILE_SIZE) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'File too large (max 10MB)']);
    exit;
}

// Validate file type
$finfo = finfo_open(FILEINFO_MIME_TYPE);
$mimeType = finfo_file($finfo, $uploadedFile['tmp_name']);
finfo_close($finfo);

if (!in_array($mimeType, $ALLOWED_TYPES)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Invalid file type']);
    exit;
}

// Generate unique filename
$extension = pathinfo($uploadedFile['name'], PATHINFO_EXTENSION);
$filename = time() . '-' . bin2hex(random_bytes(8)) . '.' . $extension;
$targetPath = $UPLOAD_DIR . $filename;

// Move uploaded file
if (!move_uploaded_file($uploadedFile['tmp_name'], $targetPath)) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Failed to save file']);
    exit;
}

// Generate thumbnail (optional - requires GD library)
$thumbnailUrl = null;
if (extension_loaded('gd')) {
    try {
        $thumbnailPath = $UPLOAD_DIR . 'thumb_' . $filename;

        switch ($mimeType) {
            case 'image/jpeg':
                $source = imagecreatefromjpeg($targetPath);
                break;
            case 'image/png':
                $source = imagecreatefrompng($targetPath);
                break;
            case 'image/gif':
                $source = imagecreatefromgif($targetPath);
                break;
            case 'image/webp':
                $source = imagecreatefromwebp($targetPath);
                break;
            default:
                $source = null;
        }

        if ($source) {
            $width = imagesx($source);
            $height = imagesy($source);

            // Calculate thumbnail dimensions (max 200px)
            $maxDim = 200;
            if ($width > $height) {
                $newWidth = $maxDim;
                $newHeight = ($height / $width) * $maxDim;
            } else {
                $newHeight = $maxDim;
                $newWidth = ($width / $height) * $maxDim;
            }

            $thumb = imagecreatetruecolor($newWidth, $newHeight);

            // Preserve transparency for PNG/WebP
            if ($mimeType === 'image/png' || $mimeType === 'image/webp') {
                imagealphablending($thumb, false);
                imagesavealpha($thumb, true);
                $transparent = imagecolorallocatealpha($thumb, 255, 255, 255, 127);
                imagefilledrectangle($thumb, 0, 0, $newWidth, $newHeight, $transparent);
            }

            imagecopyresampled($thumb, $source, 0, 0, 0, 0,
                             $newWidth, $newHeight, $width, $height);

            // Save thumbnail
            switch ($mimeType) {
                case 'image/jpeg':
                    imagejpeg($thumb, $thumbnailPath, 85);
                    break;
                case 'image/png':
                    imagepng($thumb, $thumbnailPath, 8);
                    break;
                case 'image/gif':
                    imagegif($thumb, $thumbnailPath);
                    break;
                case 'image/webp':
                    imagewebp($thumb, $thumbnailPath, 85);
                    break;
            }

            imagedestroy($source);
            imagedestroy($thumb);

            $thumbnailUrl = '/uploads/thumb_' . $filename;
        }
    } catch (Exception $e) {
        // Thumbnail generation failed, but main upload succeeded
        error_log('Thumbnail generation failed: ' . $e->getMessage());
    }
}

// Return success response
echo json_encode([
    'success' => true,
    'url' => '/uploads/' . $filename,
    'thumbnailUrl' => $thumbnailUrl ?? '/uploads/' . $filename,
    'filename' => $filename,
    'size' => $uploadedFile['size'],
    'type' => $mimeType
]);
?>
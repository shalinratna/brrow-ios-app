<?php
// get_profile.php - Fetch user profile data

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Authorization, Content-Type');

require_once 'config.php';
require_once 'auth_middleware.php';

// Get user ID from request
$userId = isset($_GET['user_id']) ? intval($_GET['user_id']) : null;

// If no user ID provided, get current user's profile
if (!$userId) {
    $authUser = authenticate();
    if (!$authUser) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Unauthorized']);
        exit;
    }
    $userId = $authUser['id'];
}

try {
    // Get user profile
    $stmt = $pdo->prepare("
        SELECT 
            u.id,
            u.api_id,
            u.username,
            u.email,
            u.profile_picture,
            u.bio,
            u.location,
            u.website,
            u.created_at,
            u.lister_rating,
            u.rentee_rating,
            u.verified,
            u.stripe_linked,
            COUNT(DISTINCT l.id) as total_listings,
            COUNT(DISTINCT t.id) as total_transactions,
            COUNT(DISTINCT r.id) as total_reviews
        FROM users u
        LEFT JOIN listings l ON u.id = l.user_id AND l.is_active = 1
        LEFT JOIN transactions t ON u.id = t.borrower_id OR u.id = t.lender_id
        LEFT JOIN reviews r ON u.id = r.reviewed_user_id
        WHERE u.id = ?
        GROUP BY u.id
    ");
    
    $stmt->execute([$userId]);
    $profile = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$profile) {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'User not found']);
        exit;
    }
    
    // Get user stats
    $stats = [];
    
    // Total items lent
    $stmt = $pdo->prepare("
        SELECT COUNT(*) as count 
        FROM transactions 
        WHERE lender_id = ? AND status = 'completed'
    ");
    $stmt->execute([$userId]);
    $stats['items_lent'] = $stmt->fetchColumn();
    
    // Total items borrowed
    $stmt = $pdo->prepare("
        SELECT COUNT(*) as count 
        FROM transactions 
        WHERE borrower_id = ? AND status = 'completed'
    ");
    $stmt->execute([$userId]);
    $stats['items_borrowed'] = $stmt->fetchColumn();
    
    // Total earnings
    $stmt = $pdo->prepare("
        SELECT COALESCE(SUM(total_cost), 0) as total 
        FROM transactions 
        WHERE lender_id = ? AND payment_status = 'completed'
    ");
    $stmt->execute([$userId]);
    $stats['total_earnings'] = floatval($stmt->fetchColumn());
    
    // Format response
    $response = [
        'success' => true,
        'profile' => [
            'id' => intval($profile['id']),
            'api_id' => $profile['api_id'],
            'username' => $profile['username'],
            'email' => $profile['email'],
            'profile_picture' => $profile['profile_picture'],
            'bio' => $profile['bio'] ?: "Hi! I'm new to Brrow.",
            'location' => $profile['location'] ?: "Not specified",
            'website' => $profile['website'],
            'created_at' => $profile['created_at'],
            'lister_rating' => floatval($profile['lister_rating']),
            'rentee_rating' => floatval($profile['rentee_rating']),
            'verified' => (bool)$profile['verified'],
            'stripe_linked' => (bool)$profile['stripe_linked']
        ],
        'stats' => [
            'total_listings' => intval($profile['total_listings']),
            'total_transactions' => intval($profile['total_transactions']),
            'total_reviews' => intval($profile['total_reviews']),
            'items_lent' => intval($stats['items_lent']),
            'items_borrowed' => intval($stats['items_borrowed']),
            'total_earnings' => $stats['total_earnings']
        ]
    ];
    
    echo json_encode($response);
    
} catch (Exception $e) {
    error_log("Profile fetch error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'success' => false, 
        'message' => 'Failed to fetch profile'
    ]);
}
?>
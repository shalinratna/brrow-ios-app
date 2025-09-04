<?php
// get_user_activities.php - Fetch user activity feed

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Authorization, Content-Type');

require_once 'config.php';
require_once 'auth_middleware.php';

$userId = isset($_GET['user_id']) ? intval($_GET['user_id']) : null;
$limit = isset($_GET['limit']) ? intval($_GET['limit']) : 20;
$offset = isset($_GET['offset']) ? intval($_GET['offset']) : 0;

// If no user ID provided, get current user's activities
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
    $activities = [];
    
    // Get recent transactions
    $stmt = $pdo->prepare("
        SELECT 
            t.id,
            t.created_at,
            t.total_cost,
            t.status,
            l.title as listing_title,
            CASE 
                WHEN t.borrower_id = ? THEN 'borrowed'
                ELSE 'lent'
            END as activity_type,
            CASE 
                WHEN t.borrower_id = ? THEN u2.username
                ELSE u1.username
            END as other_user
        FROM transactions t
        JOIN listings l ON t.listing_id = l.id
        JOIN users u1 ON t.borrower_id = u1.id
        JOIN users u2 ON t.lender_id = u2.id
        WHERE t.borrower_id = ? OR t.lender_id = ?
        ORDER BY t.created_at DESC
        LIMIT ? OFFSET ?
    ");
    
    $stmt->execute([$userId, $userId, $userId, $userId, $limit, $offset]);
    $transactions = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    foreach ($transactions as $trans) {
        $activities[] = [
            'id' => 'trans_' . $trans['id'],
            'type' => $trans['activity_type'],
            'title' => $trans['activity_type'] === 'borrowed' ? 'Item Borrowed' : 'Item Lent',
            'description' => $trans['activity_type'] === 'borrowed' 
                ? "Borrowed {$trans['listing_title']} from @{$trans['other_user']}"
                : "Lent {$trans['listing_title']} to @{$trans['other_user']}",
            'amount' => $trans['total_cost'] ? '$' . number_format($trans['total_cost'], 2) : null,
            'created_at' => $trans['created_at'],
            'time_ago' => getTimeAgo($trans['created_at'])
        ];
    }
    
    // Get recent reviews
    $stmt = $pdo->prepare("
        SELECT 
            r.id,
            r.created_at,
            r.rating,
            r.comment,
            u.username as reviewer_name
        FROM reviews r
        JOIN users u ON r.reviewer_id = u.id
        WHERE r.reviewed_user_id = ?
        ORDER BY r.created_at DESC
        LIMIT 5
    ");
    
    $stmt->execute([$userId]);
    $reviews = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    foreach ($reviews as $review) {
        $activities[] = [
            'id' => 'review_' . $review['id'],
            'type' => 'reviewed',
            'title' => 'New Review',
            'description' => "@{$review['reviewer_name']} left a {$review['rating']}-star review",
            'amount' => null,
            'created_at' => $review['created_at'],
            'time_ago' => getTimeAgo($review['created_at'])
        ];
    }
    
    // Sort activities by date
    usort($activities, function($a, $b) {
        return strtotime($b['created_at']) - strtotime($a['created_at']);
    });
    
    echo json_encode([
        'success' => true,
        'activities' => array_slice($activities, 0, $limit)
    ]);
    
} catch (Exception $e) {
    error_log("Activities fetch error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'success' => false, 
        'message' => 'Failed to fetch activities'
    ]);
}

function getTimeAgo($timestamp) {
    $time = strtotime($timestamp);
    $now = time();
    $diff = $now - $time;
    
    if ($diff < 60) {
        return "Just now";
    } elseif ($diff < 3600) {
        $mins = floor($diff / 60);
        return $mins . " minute" . ($mins > 1 ? "s" : "") . " ago";
    } elseif ($diff < 86400) {
        $hours = floor($diff / 3600);
        return $hours . " hour" . ($hours > 1 ? "s" : "") . " ago";
    } elseif ($diff < 604800) {
        $days = floor($diff / 86400);
        return $days . " day" . ($days > 1 ? "s" : "") . " ago";
    } else {
        return date("M j, Y", $time);
    }
}
?>
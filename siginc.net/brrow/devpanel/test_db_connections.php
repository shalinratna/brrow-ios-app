<?php
/**
 * Comprehensive Database Connection Test for siginc.net DevPanel
 * Tests both main database and BrrowSum settings database connections
 */

// Load credentials
require_once '../creds/secrets.php';
require_once 'settings_secrets.php';

// Set error reporting
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Output as JSON if requested
$outputFormat = $_GET['format'] ?? 'html';
$results = [
    'timestamp' => date('Y-m-d H:i:s T'),
    'tests' => [],
    'overall_status' => 'unknown'
];

function addTest($name, $success, $details = []) {
    global $results;
    $results['tests'][] = [
        'name' => $name,
        'success' => $success,
        'details' => $details
    ];
}

// Test 1: Main Database Connection
try {
    $dsn = "pgsql:host=" . DB_HOST . ";port=" . DB_PORT . ";dbname=" . DB_NAME;
    $pdo = new PDO($dsn, DB_USER, DB_PASS, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_TIMEOUT => 10
    ]);
    
    $stmt = $pdo->query("SELECT version() as pg_version, current_database() as db_name");
    $info = $stmt->fetch();
    
    addTest('Main Database Connection', true, [
        'host' => DB_HOST,
        'database' => $info['db_name'],
        'postgresql_version' => $info['pg_version'],
        'status' => 'Connected successfully'
    ]);
} catch (Exception $e) {
    addTest('Main Database Connection', false, [
        'host' => DB_HOST,
        'error' => $e->getMessage(),
        'status' => 'Connection failed'
    ]);
}

// Test 2: BrrowSum Settings Database Connection
try {
    $dsn = "pgsql:host=" . BRROWSUM_DB_HOST . ";port=" . BRROWSUM_DB_PORT . ";dbname=" . BRROWSUM_DB_NAME;
    $brrowsumPdo = new PDO($dsn, BRROWSUM_DB_USER, BRROWSUM_DB_PASS, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_TIMEOUT => 10
    ]);
    
    $stmt = $brrowsumPdo->query("SELECT version() as pg_version, current_database() as db_name");
    $info = $stmt->fetch();
    
    addTest('BrrowSum Settings Database', true, [
        'host' => BRROWSUM_DB_HOST,
        'database' => $info['db_name'],
        'postgresql_version' => $info['pg_version'],
        'status' => 'Connected successfully'
    ]);
} catch (Exception $e) {
    addTest('BrrowSum Settings Database', false, [
        'host' => BRROWSUM_DB_HOST,
        'error' => $e->getMessage(),
        'status' => 'Connection failed'
    ]);
}

// Test 3: Main Database Schema Check
try {
    if (isset($pdo)) {
        $schemas = $pdo->query("SELECT schema_name FROM information_schema.schemata WHERE schema_name IN ('public', 'brrow')")->fetchAll(PDO::FETCH_COLUMN);
        
        addTest('Main Database Schema', true, [
            'available_schemas' => $schemas,
            'has_brrow_schema' => in_array('brrow', $schemas),
            'has_public_schema' => in_array('public', $schemas)
        ]);
    } else {
        addTest('Main Database Schema', false, ['error' => 'No database connection available']);
    }
} catch (Exception $e) {
    addTest('Main Database Schema', false, ['error' => $e->getMessage()]);
}

// Test 4: App Settings Table
try {
    if (isset($pdo)) {
        // Check if brrow.app_settings exists
        $stmt = $pdo->prepare("
            SELECT EXISTS (
                SELECT FROM information_schema.tables 
                WHERE table_schema = 'brrow' 
                AND table_name = 'app_settings'
            )
        ");
        $stmt->execute();
        $tableExists = $stmt->fetchColumn();
        
        if ($tableExists) {
            $stmt = $pdo->query("SELECT COUNT(*) FROM brrow.app_settings");
            $settingsCount = $stmt->fetchColumn();
            
            addTest('App Settings Table', true, [
                'table_exists' => true,
                'settings_count' => $settingsCount,
                'status' => 'Table accessible'
            ]);
        } else {
            addTest('App Settings Table', false, [
                'table_exists' => false,
                'status' => 'Table does not exist'
            ]);
        }
    } else {
        addTest('App Settings Table', false, ['error' => 'No database connection available']);
    }
} catch (Exception $e) {
    addTest('App Settings Table', false, ['error' => $e->getMessage()]);
}

// Test 5: Essential Constants Check
$constants = [
    'DB_HOST', 'DB_PORT', 'DB_NAME', 'DB_USER', 'DB_PASS',
    'BRROWSUM_DB_HOST', 'BRROWSUM_DB_PORT', 'BRROWSUM_DB_NAME', 'BRROWSUM_DB_USER', 'BRROWSUM_DB_PASS',
    'ONESIGNAL_APP_ID', 'UPLOAD_MAX_MB'
];

$definedConstants = [];
$missingConstants = [];

foreach ($constants as $constant) {
    if (defined($constant)) {
        $definedConstants[] = $constant;
    } else {
        $missingConstants[] = $constant;
    }
}

addTest('Essential Constants', empty($missingConstants), [
    'defined_constants' => $definedConstants,
    'missing_constants' => $missingConstants,
    'total_required' => count($constants),
    'total_defined' => count($definedConstants)
]);

// Test 6: PHP Extensions
$requiredExtensions = ['pdo', 'pdo_pgsql', 'curl', 'json', 'openssl'];
$loadedExtensions = [];
$missingExtensions = [];

foreach ($requiredExtensions as $ext) {
    if (extension_loaded($ext)) {
        $loadedExtensions[] = $ext;
    } else {
        $missingExtensions[] = $ext;
    }
}

addTest('PHP Extensions', empty($missingExtensions), [
    'loaded_extensions' => $loadedExtensions,
    'missing_extensions' => $missingExtensions,
    'php_version' => phpversion()
]);

// Test 7: File Permissions
$criticalFiles = [
    '../creds/secrets.php',
    'settings_secrets.php',
    'settings/index.php',
    'index.php'
];

$filePermissions = [];
$permissionIssues = [];

foreach ($criticalFiles as $file) {
    if (file_exists($file)) {
        $readable = is_readable($file);
        $filePermissions[$file] = [
            'exists' => true,
            'readable' => $readable,
            'permissions' => substr(sprintf('%o', fileperms($file)), -4)
        ];
        
        if (!$readable) {
            $permissionIssues[] = $file;
        }
    } else {
        $filePermissions[$file] = ['exists' => false];
        $permissionIssues[] = $file . ' (missing)';
    }
}

addTest('File Permissions', empty($permissionIssues), [
    'files_checked' => $filePermissions,
    'permission_issues' => $permissionIssues
]);

// Determine overall status
$successCount = array_reduce($results['tests'], function($carry, $test) {
    return $carry + ($test['success'] ? 1 : 0);
}, 0);
$totalTests = count($results['tests']);

if ($successCount === $totalTests) {
    $results['overall_status'] = 'excellent';
} elseif ($successCount >= $totalTests * 0.8) {
    $results['overall_status'] = 'good';
} elseif ($successCount >= $totalTests * 0.6) {
    $results['overall_status'] = 'fair';
} else {
    $results['overall_status'] = 'poor';
}

$results['summary'] = [
    'total_tests' => $totalTests,
    'successful_tests' => $successCount,
    'failed_tests' => $totalTests - $successCount,
    'success_rate' => round(($successCount / $totalTests) * 100, 2)
];

// Output results
if ($outputFormat === 'json') {
    header('Content-Type: application/json');
    echo json_encode($results, JSON_PRETTY_PRINT);
} else {
    // HTML output
    ?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DevPanel Database Connection Test</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1000px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { text-align: center; margin-bottom: 30px; }
        .status-excellent { color: #22c55e; }
        .status-good { color: #3b82f6; }
        .status-fair { color: #f59e0b; }
        .status-poor { color: #ef4444; }
        .test-item { margin: 15px 0; padding: 15px; border: 1px solid #e5e7eb; border-radius: 6px; }
        .test-success { border-left: 4px solid #22c55e; background: #f0fdf4; }
        .test-failure { border-left: 4px solid #ef4444; background: #fef2f2; }
        .test-details { margin-top: 10px; font-size: 14px; color: #6b7280; }
        .summary { background: #f8fafc; padding: 20px; border-radius: 6px; margin: 20px 0; }
        .json-link { margin-top: 20px; text-align: center; }
        .json-link a { color: #3b82f6; text-decoration: none; }
        .json-link a:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔧 DevPanel Database Connection Test</h1>
            <p>siginc.net Brrow DevPanel System Check</p>
            <p><strong>Tested at:</strong> <?= $results['timestamp'] ?></p>
        </div>
        
        <div class="summary">
            <h3>📊 Summary</h3>
            <p><strong>Overall Status:</strong> <span class="status-<?= $results['overall_status'] ?>"><?= strtoupper($results['overall_status']) ?></span></p>
            <p><strong>Tests Passed:</strong> <?= $results['summary']['successful_tests'] ?>/<?= $results['summary']['total_tests'] ?> (<?= $results['summary']['success_rate'] ?>%)</p>
        </div>
        
        <h3>🧪 Test Results</h3>
        <?php foreach ($results['tests'] as $test): ?>
        <div class="test-item <?= $test['success'] ? 'test-success' : 'test-failure' ?>">
            <strong><?= $test['success'] ? '✅' : '❌' ?> <?= htmlspecialchars($test['name']) ?></strong>
            <?php if (!empty($test['details'])): ?>
            <div class="test-details">
                <?php foreach ($test['details'] as $key => $value): ?>
                    <div><strong><?= htmlspecialchars(ucwords(str_replace('_', ' ', $key))) ?>:</strong> 
                    <?php if (is_array($value)): ?>
                        <?= htmlspecialchars(implode(', ', $value)) ?>
                    <?php else: ?>
                        <?= htmlspecialchars($value) ?>
                    <?php endif; ?>
                    </div>
                <?php endforeach; ?>
            </div>
            <?php endif; ?>
        </div>
        <?php endforeach; ?>
        
        <div class="json-link">
            <a href="?format=json">View Raw JSON Results</a>
        </div>
    </div>
</body>
</html>
<?php
}
?>

<?php
session_start();
require_once '../../../brrow/includes/db_functions.php';

// Check if user is admin
if (!isset($_SESSION['admin_logged_in'])) {
    header('Location: login.php');
    exit();
}

// Documentation sections
$sections = [
    'ios' => 'iOS/Swift Documentation',
    'php' => 'PHP/Backend Documentation', 
    'api' => 'API Documentation',
    'database' => 'Database Schema',
    'architecture' => 'System Architecture'
];

$currentSection = $_GET['section'] ?? 'ios';
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Brrow Code Documentation</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/themes/prism-tomorrow.min.css">
    <style>
        body {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding-top: 20px;
        }
        .doc-container {
            background: white;
            border-radius: 15px;
            padding: 30px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.1);
            margin-bottom: 30px;
        }
        .nav-tabs .nav-link {
            color: #667eea;
            font-weight: 500;
        }
        .nav-tabs .nav-link.active {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
        }
        .code-block {
            background: #2d2d2d;
            border-radius: 8px;
            padding: 15px;
            margin: 15px 0;
            overflow-x: auto;
        }
        .section-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            font-weight: bold;
            margin: 20px 0;
        }
        .function-card {
            border: 1px solid #e0e0e0;
            border-radius: 8px;
            padding: 15px;
            margin: 10px 0;
            transition: all 0.3s;
        }
        .function-card:hover {
            box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
            transform: translateY(-2px);
        }
        .param-badge {
            background: #667eea;
            color: white;
            padding: 3px 8px;
            border-radius: 4px;
            font-size: 12px;
            margin: 2px;
            display: inline-block;
        }
        .return-type {
            background: #764ba2;
            color: white;
            padding: 3px 8px;
            border-radius: 4px;
            font-size: 12px;
        }
        .search-box {
            background: #f5f5f5;
            border: none;
            border-radius: 25px;
            padding: 10px 20px;
            width: 100%;
            margin-bottom: 20px;
        }
        .toc-sidebar {
            position: sticky;
            top: 20px;
            max-height: calc(100vh - 100px);
            overflow-y: auto;
        }
        .toc-link {
            display: block;
            padding: 5px 10px;
            color: #666;
            text-decoration: none;
            border-left: 3px solid transparent;
            margin: 2px 0;
        }
        .toc-link:hover, .toc-link.active {
            color: #667eea;
            border-left-color: #667eea;
            background: rgba(102, 126, 234, 0.1);
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="doc-container">
            <div class="d-flex justify-content-between align-items-center mb-4">
                <h1>🚀 Brrow Code Documentation</h1>
                <a href="index.php" class="btn btn-outline-primary">Back to Admin</a>
            </div>
            
            <input type="text" class="search-box" id="searchBox" placeholder="Search documentation...">
            
            <ul class="nav nav-tabs mb-4">
                <?php foreach($sections as $key => $title): ?>
                    <li class="nav-item">
                        <a class="nav-link <?php echo $currentSection === $key ? 'active' : ''; ?>" 
                           href="?section=<?php echo $key; ?>"><?php echo $title; ?></a>
                    </li>
                <?php endforeach; ?>
            </ul>
            
            <div class="row">
                <!-- Table of Contents -->
                <div class="col-md-3">
                    <div class="toc-sidebar" id="tableOfContents">
                        <!-- Dynamic TOC will be inserted here -->
                    </div>
                </div>
                
                <!-- Main Content -->
                <div class="col-md-9">
                    <?php
                    // Include appropriate documentation section
                    $docFile = "docs/{$currentSection}_documentation.php";
                    if (file_exists($docFile)) {
                        include $docFile;
                    } else {
                        // Generate documentation dynamically
                        include 'docs/generate_docs.php';
                        generateDocumentation($currentSection);
                    }
                    ?>
                </div>
            </div>
        </div>
    </div>
    
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/prism.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-swift.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-php.min.js"></script>
    <script>
        // Search functionality
        document.getElementById('searchBox').addEventListener('keyup', function(e) {
            const searchTerm = e.target.value.toLowerCase();
            const cards = document.querySelectorAll('.function-card');
            
            cards.forEach(card => {
                const text = card.textContent.toLowerCase();
                if (text.includes(searchTerm)) {
                    card.style.display = 'block';
                } else {
                    card.style.display = 'none';
                }
            });
        });
        
        // Generate table of contents
        function generateTOC() {
            const headers = document.querySelectorAll('.section-header');
            const toc = document.getElementById('tableOfContents');
            toc.innerHTML = '<h5>Contents</h5>';
            
            headers.forEach((header, index) => {
                const id = 'section-' + index;
                header.id = id;
                
                const link = document.createElement('a');
                link.href = '#' + id;
                link.className = 'toc-link';
                link.textContent = header.textContent;
                link.onclick = function(e) {
                    e.preventDefault();
                    document.getElementById(id).scrollIntoView({ behavior: 'smooth' });
                    
                    // Update active state
                    document.querySelectorAll('.toc-link').forEach(l => l.classList.remove('active'));
                    this.classList.add('active');
                };
                
                toc.appendChild(link);
            });
        }
        
        // Initialize on load
        document.addEventListener('DOMContentLoaded', function() {
            generateTOC();
            Prism.highlightAll();
        });
    </script>
</body>
</html>
from flask import Flask, send_from_directory, render_template_string, abort, request
from flask_cors import CORS
import os
import argparse
from pathlib import Path
import mimetypes
from datetime import datetime
import socket
import json
from datetime import datetime

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Configuration
IMAGE_EXTENSIONS = {'.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.svg'}
VIDEO_EXTENSIONS = {'.mp4', '.avi', '.mov', '.wmv', '.flv', '.mkv'}
ITEMS_PER_PAGE = 1000  # Set high to show all images

# HTML template for directory listing
HTML_TEMPLATE = '''
<!DOCTYPE html>
<html>
<head>
    <title>Image Gallery Server - {{ directory }}</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            background-color: #f5f5f5;
        }
        h1 {
            color: #333;
            border-bottom: 2px solid #4CAF50;
            padding-bottom: 10px;
        }
        .info {
            background-color: #e7f3fe;
            border-left: 4px solid #2196F3;
            padding: 10px;
            margin: 20px 0;
        }
        .stats {
            background-color: #fff;
            padding: 15px;
            border-radius: 5px;
            margin: 20px 0;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        ul {
            list-style-type: none;
            padding: 0;
        }
        li {
            margin: 10px 0;
            padding: 10px;
            background-color: white;
            border-radius: 5px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
            transition: transform 0.2s;
        }
        li:hover {
            transform: translateX(5px);
            box-shadow: 0 2px 5px rgba(0,0,0,0.2);
        }
        a {
            text-decoration: none;
            color: #2196F3;
            font-weight: 500;
        }
        a:hover {
            color: #1976D2;
        }
        .file-info {
            color: #666;
            font-size: 0.9em;
            margin-top: 5px;
        }
        .thumbnail-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
            gap: 15px;
            margin-top: 20px;
        }
        .thumbnail-item {
            background: white;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            transition: transform 0.2s;
        }
        .thumbnail-item:hover {
            transform: scale(1.05);
        }
        .thumbnail-item img {
            width: 100%;
            height: 200px;
            object-fit: cover;
        }
        .thumbnail-item .filename {
            padding: 10px;
            font-size: 0.9em;
            word-break: break-all;
        }
        .view-toggle {
            margin: 20px 0;
        }
        .btn {
            background-color: #4CAF50;
            color: white;
            padding: 10px 20px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            margin-right: 10px;
        }
        .btn:hover {
            background-color: #45a049;
        }
        .btn.active {
            background-color: #2196F3;
        }
    </style>
    <script>
        function toggleView(view) {
            const listView = document.getElementById('list-view');
            const gridView = document.getElementById('grid-view');
            const listBtn = document.getElementById('list-btn');
            const gridBtn = document.getElementById('grid-btn');
            
            if (view === 'list') {
                listView.style.display = 'block';
                gridView.style.display = 'none';
                listBtn.classList.add('active');
                gridBtn.classList.remove('active');
            } else {
                listView.style.display = 'none';
                gridView.style.display = 'block';
                gridBtn.classList.add('active');
                listBtn.classList.remove('active');
            }
        }
    </script>
</head>
<body>
    <h1>📁 Image Gallery Server</h1>
    
    <div class="info">
        <strong>Directory:</strong> {{ directory }}<br>
        <strong>Server IP:</strong> {{ server_ip }}:{{ server_port }}<br>
        <strong>Access URL:</strong> http://{{ server_ip }}:{{ server_port }}
    </div>
    
    <div class="stats">
        <strong>Statistics:</strong><br>
        Total Images: {{ image_count }}<br>
        Total Videos: {{ video_count }}<br>
        Total Files: {{ total_count }}
    </div>
    
    {% if images %}
    <div class="view-toggle">
        <button id="list-btn" class="btn active" onclick="toggleView('list')">📝 List View</button>
        <button id="grid-btn" class="btn" onclick="toggleView('grid')">🖼️ Grid View</button>
    </div>
    
    <!-- List View -->
    <div id="list-view">
        <h2>📷 Images ({{ image_count }})</h2>
        <ul>
        {% for image in images %}
            <li>
                <a href="{{ image.url }}">{{ image.name }}</a>
                <div class="file-info">
                    Size: {{ image.size }} | Modified: {{ image.modified }}
                </div>
            </li>
        {% endfor %}
        </ul>
    </div>
    
    <!-- Grid View -->
    <div id="grid-view" style="display: none;">
        <h2>📷 Image Gallery</h2>
        <div class="thumbnail-grid">
        {% for image in images %}
            <div class="thumbnail-item">
                <a href="{{ image.url }}">
                    <img src="{{ image.url }}" alt="{{ image.name }}" loading="lazy">
                    <div class="filename">{{ image.name }}</div>
                </a>
            </div>
        {% endfor %}
        </div>
    </div>
    {% else %}
    <p>No images found in this directory.</p>
    {% endif %}
    
    {% if videos %}
    <h2>🎥 Videos ({{ video_count }})</h2>
    <ul>
    {% for video in videos %}
        <li>
            <a href="{{ video.url }}">{{ video.name }}</a>
            <div class="file-info">
                Size: {{ video.size }} | Modified: {{ video.modified }}
            </div>
        </li>
    {% endfor %}
    </ul>
    {% endif %}
</body>
</html>
'''

def get_local_ip():
    """Get the local IP address of the machine"""
    try:
        # Create a socket to get the local IP
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        local_ip = s.getsockname()[0]
        s.close()
        return local_ip
    except:
        return "127.0.0.1"

def format_file_size(size_bytes):
    """Format file size in human readable format"""
    for unit in ['B', 'KB', 'MB', 'GB']:
        if size_bytes < 1024.0:
            return f"{size_bytes:.1f} {unit}"
        size_bytes /= 1024.0
    return f"{size_bytes:.1f} TB"

def get_file_info(filepath):
    """Get file information"""
    try:
        stat = os.stat(filepath)
        return {
            'size': format_file_size(stat.st_size),
            'modified': datetime.fromtimestamp(stat.st_mtime).strftime('%Y-%m-%d %H:%M:%S')
        }
    except:
        return {'size': 'Unknown', 'modified': 'Unknown'}

@app.route('/')
@app.route('/<path:subpath>')
def list_files(subpath=''):
    """List all files in the directory"""
    try:
        # Get the actual directory path
        target_dir = os.path.join(app.config['SERVE_DIRECTORY'], subpath)
        
        if not os.path.exists(target_dir):
            abort(404)
        
        if not os.path.isdir(target_dir):
            # If it's a file, serve it
            return send_from_directory(
                os.path.dirname(target_dir),
                os.path.basename(target_dir),
                as_attachment=False
            )
        
        # Get all files in the directory
        files = []
        for filename in os.listdir(target_dir):
            filepath = os.path.join(target_dir, filename)
            if os.path.isfile(filepath):
                files.append(filename)
        
        # Separate images and videos
        images = []
        videos = []
        
        for filename in sorted(files):
            file_ext = Path(filename).suffix.lower()
            filepath = os.path.join(target_dir, filename)
            file_info = get_file_info(filepath)
            
            file_data = {
                'name': filename,
                'url': f"/{os.path.join(subpath, filename)}",
                'size': file_info['size'],
                'modified': file_info['modified']
            }
            
            if file_ext in IMAGE_EXTENSIONS:
                images.append(file_data)
            elif file_ext in VIDEO_EXTENSIONS:
                videos.append(file_data)
        
        # Render the HTML template
        return render_template_string(
            HTML_TEMPLATE,
            directory=target_dir,
            images=images,
            videos=videos,
            image_count=len(images),
            video_count=len(videos),
            total_count=len(files),
            server_ip=get_local_ip(),
            server_port=app.config['SERVER_PORT']
        )
    
    except Exception as e:
        return f"Error: {str(e)}", 500

@app.route('/api/images')
def api_images():
    """API endpoint to get image list with metadata as JSON"""
    try:
        target_dir = app.config['SERVE_DIRECTORY']
        images = []
        
        for root, dirs, files in os.walk(target_dir):
            for filename in files:
                file_ext = Path(filename).suffix.lower()
                if file_ext in IMAGE_EXTENSIONS:
                    filepath = os.path.join(root, filename)
                    relative_path = os.path.relpath(filepath, target_dir)
                    
                    # Get file modification time
                    try:
                        mod_time = os.path.getmtime(filepath)
                        mod_datetime = datetime.fromtimestamp(mod_time)
                    except:
                        mod_datetime = datetime.now()
                    
                    images.append({
                        'name': filename,
                        'url': f"/{relative_path.replace(os.sep, '/')}",
                        'path': relative_path,
                        'modified': mod_datetime.isoformat(),
                        'size': os.path.getsize(filepath)
                    })
        
        # Sort by modification date (newest first)
        images.sort(key=lambda x: x['modified'], reverse=True)
        
        return json.dumps({'images': images, 'count': len(images)}), 200, {'Content-Type': 'application/json'}
    
    except Exception as e:
        return json.dumps({'error': str(e)}), 500, {'Content-Type': 'application/json'}

@app.errorhandler(404)
def not_found(e):
    return "File not found", 404

def main():
    parser = argparse.ArgumentParser(description='Flask Image Gallery Server')
    parser.add_argument(
        '--directory', '-d',
        type=str,
        default='.',
        help='Directory to serve (default: current directory)'
    )
    parser.add_argument(
        '--port', '-p',
        type=int,
        default=8000,
        help='Port to run the server on (default: 8000)'
    )
    parser.add_argument(
        '--host',
        type=str,
        default='0.0.0.0',
        help='Host to bind to (default: 0.0.0.0 - accessible from network)'
    )
    parser.add_argument(
        '--debug',
        action='store_true',
        help='Run in debug mode'
    )
    
    args = parser.parse_args()
    
    # Convert to absolute path
    serve_directory = os.path.abspath(args.directory)
    
    if not os.path.exists(serve_directory):
        print(f"Error: Directory '{serve_directory}' does not exist!")
        return
    
    if not os.path.isdir(serve_directory):
        print(f"Error: '{serve_directory}' is not a directory!")
        return
    
    # Configure the app
    app.config['SERVE_DIRECTORY'] = serve_directory
    app.config['SERVER_PORT'] = args.port
    
    # Set mime types
    mimetypes.add_type('image/webp', '.webp')
    
    # Print server information
    local_ip = get_local_ip()
    print("\n" + "="*50)
    print("🚀 Flask Image Gallery Server")
    print("="*50)
    print(f"📁 Serving directory: {serve_directory}")
    print(f"🌐 Local access: http://localhost:{args.port}")
    print(f"📱 Network access: http://{local_ip}:{args.port}")
    print(f"💻 All interfaces: http://0.0.0.0:{args.port}")
    print("\n📝 Available endpoints:")
    print(f"  • http://{local_ip}:{args.port}/ - HTML gallery view")
    print(f"  • http://{local_ip}:{args.port}/api/images - JSON API")
    print("\nPress Ctrl+C to stop the server")
    print("="*50 + "\n")
    
    # Count files
    image_count = sum(1 for root, dirs, files in os.walk(serve_directory) 
                     for f in files if Path(f).suffix.lower() in IMAGE_EXTENSIONS)
    print(f"Found {image_count} images in the directory\n")
    
    # Run the server
    app.run(
        host=args.host,
        port=args.port,
        debug=args.debug
    )

if __name__ == '__main__':
    main()
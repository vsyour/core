import http.server, socketserver, base64, os, urllib.parse, shutil, html, json, mimetypes, sys

# 配置
USERNAME = 'user'
PASSWORD = 'pass'
PORT = 7860
ROOT_DIR = '/tmp'

# 确保根目录存在
if not os.path.exists(ROOT_DIR):
    os.makedirs(ROOT_DIR)

class FileManagerHandler(http.server.BaseHTTPRequestHandler):
    
    def check_auth(self):
        auth = self.headers.get('Authorization')
        expected = 'Basic ' + base64.b64encode(f'{USERNAME}:{PASSWORD}'.encode()).decode()
        return auth == expected

    def send_auth_request(self):
        self.send_response(401)
        self.send_header('WWW-Authenticate', 'Basic realm="Protected"')
        self.end_headers()
        self.wfile.write(b'Authentication required.')

    def get_safe_path(self, path_str):
        """解析URL路径并确保它在ROOT_DIR内，防止目录遍历"""
        # 解码 URL
        path_str = urllib.parse.unquote(path_str)
        # 去掉开头的 /
        path_str = path_str.lstrip('/')
        # 组合绝对路径
        full_path = os.path.abspath(os.path.join(ROOT_DIR, path_str))
        # 检查是否跑出了 ROOT_DIR
        if not full_path.startswith(os.path.abspath(ROOT_DIR)):
            return None
        return full_path

    def build_breadcrumb(self, dir_path):
        rel_path = os.path.relpath(dir_path, ROOT_DIR)
        parts = rel_path.split(os.sep) if rel_path != '.' else []
        html_nav = f'<a href="/">ROOT</a>'
        accumulated = ''
        for part in parts:
            accumulated = os.path.join(accumulated, part)
            html_nav += f' / <a href="/{urllib.parse.quote(accumulated)}/">{html.escape(part)}</a>'
        return html_nav

    def list_dir_html(self, dir_path):
        html_nav = '<h3>Current Path: ' + self.build_breadcrumb(dir_path) + '</h3>'
        try:
            files = sorted(os.listdir(dir_path), key=lambda s: s.lower())
        except Exception as e:
            return f"Error listing directory: {e}".encode()

        html_list = "<ul style='line-height:1.8;'>"
        # 返回上级
        if dir_path != ROOT_DIR:
             parent_path = os.path.dirname(dir_path)
             rel_parent = os.path.relpath(parent_path, ROOT_DIR)
             if rel_parent == '.': rel_parent = ''
             html_list += f'<li><strong><a href="/{urllib.parse.quote(rel_parent)}">.. (Parent)</a></strong></li>'

        for f in files:
            f_path = os.path.join(dir_path, f)
            display_path = os.path.relpath(f_path, ROOT_DIR)
            quoted_path = urllib.parse.quote(display_path)
            
            # 操作按钮
            btn_style = "margin-left:10px; font-size:0.9em; text-decoration:none; color:#007bff;"
            del_link = f'<a href="#" style="{btn_style};color:red" onclick="deleteItem(\'{quoted_path}\')">[Del]</a>'
            ren_link = f'<a href="#" style="{btn_style}" onclick="renameItem(\'{quoted_path}\')">[Ren]</a>'
            
            if os.path.isdir(f_path):
                html_list += f'<li>📁 <a href="/{quoted_path}/"><strong>{html.escape(f)}</strong></a> {del_link} {ren_link}</li>'
            else:
                down_link = f'<a href="/{quoted_path}" style="{btn_style}">[Down]</a>'
                edit_link = f'<a href="#" style="{btn_style}" onclick="editItem(\'{quoted_path}\')">[Edit]</a>'
                html_list += f'<li>📄 {html.escape(f)} {down_link} {edit_link} {del_link} {ren_link}</li>'
        html_list += "</ul>"

        # 前端 CSS/JS
        page_content = f'''
        <html><head><title>File Manager Pro</title>
        <style>
            body {{ font-family: sans-serif; padding: 20px; max-width: 900px; margin: 0 auto; }}
            a {{ text-decoration: none; }} a:hover {{ text-decoration: underline; }}
            .modal {{ display:none; position:fixed; z-index:1; left:0; top:0; width:100%; height:100%; overflow:auto; background-color:rgba(0,0,0,0.4); }}
            .modal-content {{ background-color:#fefefe; margin:5% auto; padding:20px; border:1px solid #888; width:80%; }}
            textarea {{ width:100%; height:400px; font-family: monospace; margin-bottom: 10px; }}
            button {{ cursor:pointer; padding: 5px 10px; }}
        </style>
        </head><body>
        <h2>File Manager Pro</h2>
        {html_nav}
        <hr>
        {html_list}
        <hr>
        
        <div style="display:flex; gap:20px;">
            <div>
                <h3>Create Folder</h3>
                <input type="text" id="newFolder" placeholder="Folder name">
                <button onclick="createFolder()">Create</button>
            </div>
            <div>
                <h3>Upload File</h3>
                <input type="file" id="fileInput">
                <button onclick="uploadFile()">Upload</button>
            </div>
        </div>

        <div id="editModal" class="modal">
          <div class="modal-content">
            <h3>Editing: <span id="editingFilename"></span></h3>
            <textarea id="fileContent"></textarea><br>
            <button onclick="saveFile()">Save Changes</button>
            <button onclick="closeModal()">Cancel</button>
          </div>
        </div>

        <script>
        const authHeader = 'Basic ' + btoa('{USERNAME}:{PASSWORD}');

        function request(method, url, body=null, isJson=false) {{
            let headers = {{'Authorization': authHeader}};
            if (isJson) headers['Content-Type'] = 'application/json';
            else if (method === 'POST' && !body.toString().startsWith('filename')) headers['Content-Type'] = 'application/x-www-form-urlencoded';

            return fetch(url, {{ method: method, headers: headers, body: body }});
        }}

        function createFolder(){{
            let name = document.getElementById('newFolder').value;
            if(!name) return;
            request('POST', '/', 'folder='+encodeURIComponent(name)).then(()=>location.reload());
        }}

        function uploadFile(){{
            let fileInput = document.getElementById('fileInput');
            if(fileInput.files.length === 0) return;
            let file = fileInput.files[0];
            let reader = new FileReader();
            reader.onload = function(){{
                let b64 = reader.result.split(",")[1];
                let body = 'filename='+encodeURIComponent(file.name)+'&content='+encodeURIComponent(b64);
                request('POST', '/', body).then(()=>location.reload());
            }}
            reader.readAsDataURL(file);
        }}

        function deleteItem(name){{
            if(confirm('Delete '+name+'?'))
                request('DELETE', '/', 'filename='+encodeURIComponent(name)).then(()=>location.reload());
        }}

        function renameItem(name){{
            let newName = prompt('Enter new name:', name);
            if(newName && newName !== name){{
                request('PUT', '/', JSON.stringify({{old:name, newName:newName}}), true).then(()=>location.reload());
            }}
        }}

        // --- Edit Logic ---
        function editItem(path){{
            // 获取文件内容
            fetch('/' + path + '?raw=true', {{headers: {{'Authorization': authHeader}}}})
                .then(r => r.text())
                .then(text => {{
                    document.getElementById('editingFilename').innerText = path;
                    document.getElementById('fileContent').value = text;
                    document.getElementById('editModal').style.display = "block";
                }});
        }}
        
        function saveFile(){{
            let path = document.getElementById('editingFilename').innerText;
            let content = document.getElementById('fileContent').value;
            // 使用 POST 保存，添加 save=true 标记
            request('POST', '/', 'save_file='+encodeURIComponent(path)+'&content='+encodeURIComponent(content))
                .then(() => {{ closeModal(); alert('Saved!'); }});
        }}

        function closeModal(){{
            document.getElementById('editModal').style.display = "none";
        }}
        </script>
        </body></html>
        '''
        return page_content.encode('utf-8')

    def do_GET(self):
        if not self.check_auth():
            self.send_auth_request()
            return
        
        # 解析路径
        path = self.path.split('?')[0]
        query = urllib.parse.urlparse(self.path).query
        query_params = urllib.parse.parse_qs(query)

        full_path = self.get_safe_path(path)
        if full_path is None:
            self.send_error(403, "Access Denied")
            return

        if os.path.isdir(full_path):
            # 如果是目录但没有以 / 结尾，重定向加 /
            if not self.path.endswith('/'):
                self.send_response(301)
                self.send_header("Location", self.path + "/")
                self.end_headers()
                return
            
            self.send_response(200)
            self.send_header('Content-type', 'text/html; charset=utf-8')
            self.end_headers()
            self.wfile.write(self.list_dir_html(full_path))
        
        elif os.path.isfile(full_path):
            # 如果是为了编辑获取原始内容
            if 'raw' in query_params:
                try:
                    with open(full_path, 'rb') as f:
                        content = f.read()
                    self.send_response(200)
                    self.send_header('Content-type', 'text/plain; charset=utf-8')
                    self.end_headers()
                    self.wfile.write(content)
                except Exception as e:
                    self.send_error(500, str(e))
                return

            # 下载文件
            try:
                with open(full_path, 'rb') as f:
                    self.send_response(200)
                    mime_type, _ = mimetypes.guess_type(full_path)
                    self.send_header('Content-type', mime_type or 'application/octet-stream')
                    self.send_header('Content-Disposition', f'attachment; filename="{os.path.basename(full_path)}"')
                    fs = os.fstat(f.fileno())
                    self.send_header('Content-Length', str(fs.st_size))
                    self.end_headers()
                    shutil.copyfileobj(f, self.wfile)
            except Exception as e:
                self.send_error(500, f"File read error: {e}")
        else:
            self.send_error(404, "File not found")

    def do_POST(self):
        if not self.check_auth():
            self.send_auth_request()
            return
            
        length = int(self.headers.get('Content-Length', 0))
        data = self.rfile.read(length)
        
        try:
            # 简单的解析 body
            txt_data = data.decode('utf-8')
            parsed = urllib.parse.parse_qs(txt_data)
        except:
            self.send_error(400, "Bad Request Data")
            return

        # Case 1: Upload File (Base64 encoded from JS)
        if 'filename' in parsed and 'content' in parsed and 'save_file' not in parsed:
            filename = parsed['filename'][0]
            b64_content = parsed['content'][0]
            save_path = self.get_safe_path(filename) # 这里 filename 可能是相对路径
            if save_path:
                try:
                    # 必须解码 Base64
                    file_data = base64.b64decode(b64_content)
                    with open(save_path, 'wb') as f:
                        f.write(file_data)
                except Exception as e:
                    print(f"Upload error: {e}")
        
        # Case 2: Save Edited File (Text content)
        elif 'save_file' in parsed and 'content' in parsed:
            rel_path = parsed['save_file'][0]
            content = parsed['content'][0]
            save_path = self.get_safe_path(rel_path)
            if save_path:
                with open(save_path, 'w', encoding='utf-8') as f:
                    f.write(content)

        # Case 3: Create Folder
        elif 'folder' in parsed:
            folder = parsed['folder'][0]
            new_dir = self.get_safe_path(folder)
            if new_dir:
                os.makedirs(new_dir, exist_ok=True)

        self.send_response(200)
        self.end_headers()

    def do_DELETE(self):
        if not self.check_auth():
            self.send_auth_request()
            return
        length = int(self.headers.get('Content-Length', 0))
        data = self.rfile.read(length)
        parsed = urllib.parse.parse_qs(data.decode())
        
        if 'filename' in parsed:
            path = self.get_safe_path(parsed['filename'][0])
            if path and os.path.exists(path):
                if os.path.isdir(path):
                    shutil.rmtree(path)
                else:
                    os.remove(path)
        self.send_response(200)
        self.end_headers()

    def do_PUT(self):
        if not self.check_auth():
            self.send_auth_request()
            return
        length = int(self.headers.get('Content-Length', 0))
        data = self.rfile.read(length)
        try:
            parsed = json.loads(data.decode())
            old = self.get_safe_path(parsed['old'])
            new = self.get_safe_path(parsed['newName'])
            if old and new and os.path.exists(old):
                os.rename(old, new)
        except:
            pass
        self.send_response(200)
        self.end_headers()

# 允许地址复用，防止重启时报错 Address already in use
socketserver.TCPServer.allow_reuse_address = True
with socketserver.ThreadingTCPServer(('0.0.0.0', PORT), FileManagerHandler) as httpd:
    print(f"Serving at http://0.0.0.0:{PORT}")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass

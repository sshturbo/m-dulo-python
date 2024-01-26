#!/usr/bin/env python3

from flask import Flask, request, render_template
from werkzeug.utils import secure_filename
import os
import subprocess
import threading
import time
import atexit

app = Flask(__name__)

BASE_SCRIPTS_FOLDER = os.path.join(os.path.dirname(os.path.abspath(__file__)), "scripts")
os.makedirs(BASE_SCRIPTS_FOLDER, exist_ok=True)

def execute_queue(route_name):
    folder_path = os.path.join(BASE_SCRIPTS_FOLDER, route_name)
    os.makedirs(folder_path, exist_ok=True)

    def _execute_loop():
        while True:
            files = os.listdir(folder_path)

            if files:
                next_file = files[0]

                if next_file.endswith(".sh"):
                    file_path = os.path.join(folder_path, next_file)
                    print(f"Arquivo {file_path} existe: {os.path.exists(file_path)}")

                    if os.path.exists(file_path):
                        subprocess.Popen(f"chmod +x {file_path} && /bin/bash {file_path}", shell=True).wait()
                        if os.path.exists(file_path):  # Verificar novamente antes de remover o arquivo
                            os.remove(file_path)  # Remover o arquivo após a execução

            time.sleep(1)

    thread = threading.Thread(target=_execute_loop)
    thread.start()

queues = {
    'editar': execute_queue('editar'),
    'deletar': execute_queue('deletar'),
    'criar': execute_queue('criar'),
    'online': execute_queue('online')  # Adicionando a rota 'online'
}

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/editar', methods=['POST'])
def editar():
    return handle_script(request, 'editar')

@app.route('/deletar', methods=['POST'])
def deletar():
    return handle_script(request, 'deletar')

@app.route('/criar', methods=['POST'])
def criar():
    return handle_script(request, 'criar')

@app.route('/online', methods=['POST'])
def online():
    return handle_script(request, 'online')

def handle_script(request, route_name):
    file = request.files['file']

    if file is None:
        return "Nenhum arquivo enviado", 400

    if file.filename == '':
        return "Nenhum arquivo selecionado", 400

    folder_path = os.path.join(BASE_SCRIPTS_FOLDER, route_name)
    os.makedirs(folder_path, exist_ok=True)

    file_path = os.path.abspath(os.path.join(folder_path, secure_filename(file.filename)))
    file.save(file_path)

    return "A sincronização foi iniciada com sucesso!", 200

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8040, debug=True)

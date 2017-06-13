from flask import Flask
from flask import request
from flask import jsonify
import subprocess

import ujson as json

app = Flask(__name__)
config = None

@app.route("/", methods=['POST'])
def hook_listen():
    s = request.data
    data = json.loads(s)
    print('data=%s' % data)
    return jsonify(success=True), 200

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=9999)
~

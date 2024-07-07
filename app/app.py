from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/', methods=['GET'])
def welcome():
    return jsonify(message="Test simple app")

if __name__ == '__main__':
    app.run(debug=True)
"""Minimal web service used to demonstrate a secure software supply chain."""
import os

from flask import Flask, jsonify

app = Flask(__name__)


@app.get("/")
def index():
    return jsonify(service="devsecops-demo", version=os.environ.get("APP_VERSION", "dev"))


@app.get("/healthz")
def healthz():
    return jsonify(status="ok")

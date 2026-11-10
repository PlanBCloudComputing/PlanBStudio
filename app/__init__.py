"""Plan B Studio Flask app factory (hello-world skeleton, task P0-A4).

Purpose: prove the container builds and runs on Cloud Run before real features land.
Important logic:
  * INSTANCE_ID is a random id made once when this process starts. Each Cloud Run
    instance therefore has its own id, so the scaling demo can show requests being
    spread across instances.
  * Every response carries an X-Served-By header with that id (API_SPEC.md).
  * The app is stateless: nothing is written to disk or kept between requests.
"""
import os
import uuid

from flask import Flask, jsonify

# Generated once per process, never changes while the instance lives.
INSTANCE_ID = uuid.uuid4().hex[:8]


def create_app():
    app = Flask(__name__)

    @app.after_request
    def add_instance_header(response):
        response.headers["X-Served-By"] = INSTANCE_ID
        return response

    @app.get("/api/v1/healthz")
    def healthz():
        # No database call: checks the process is alive. Under /api/v1 because
        # Cloud Run's frontend reserves the bare /healthz path (it never reaches us).
        return jsonify(status="ok")

    @app.get("/api/v1/whoami")
    def whoami():
        # K_REVISION is set by Cloud Run; "local" when running on a laptop.
        return jsonify(instance_id=INSTANCE_ID, revision=os.environ.get("K_REVISION", "local"))

    return app

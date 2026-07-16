#!/bin/bash
set -e

########################################
# ð§± STEP 1: SYSTEM UPDATE & DEPENDENCIES
########################################
echo "=== Updating system and installing Python tools ==="
sudo apt update
sudo apt install -y python3 python3-venv python3-pip

########################################
# ð§° STEP 2: CREATE PROJECT DIRECTORY
########################################
echo "=== Creating project directory ==="
mkdir -p ~/tracing-demo
cd ~/tracing-demo

########################################
# ð§ª STEP 3: CREATE & ACTIVATE VIRTUAL ENVIRONMENT
########################################
echo "=== Setting up Python virtual environment ==="
python3 -m venv venv
#source venv/bin/activate    # manual apply
. venv/bin/activate   # through bin/bash
########################################
# ð¦ STEP 4: UPGRADE PIP
########################################
echo "=== Upgrading pip ==="
pip install --upgrade pip

########################################
# âï¸ STEP 5: INSTALL FLASK + OPENTELEMETRY PACKAGES
########################################
echo "=== Installing Flask and OpenTelemetry dependencies ==="
pip install flask \
    opentelemetry-api \
    opentelemetry-sdk \
    opentelemetry-exporter-otlp \
    opentelemetry-instrumentation \
    opentelemetry-instrumentation-flask

########################################
# ð§© STEP 6: CREATE FLASK APP (app.py)
########################################
echo "=== Creating Flask application with OpenTelemetry tracing ==="

cat <<'EOF' > app.py
from flask import Flask
import time
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import SimpleSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.flask import FlaskInstrumentor

# ------------------------
# 1. Setup OpenTelemetry
# ------------------------
trace.set_tracer_provider(TracerProvider())
tracer = trace.get_tracer(__name__)

exporter = OTLPSpanExporter(
    endpoint="http://127.0.0.1:4318/v1/traces"  # OTLP endpoint of collector (Tempo or OTel Collector)
)
span_processor = SimpleSpanProcessor(exporter)
trace.get_tracer_provider().add_span_processor(span_processor)

# ------------------------
# 2. Flask App
# ------------------------
app = Flask(__name__)
FlaskInstrumentor().instrument_app(app)  # auto-instrument Flask

@app.route("/")
def home():
    with tracer.start_as_current_span("home-span"):
        return "Hello from EC2 + Python + OpenTelemetry + Grafana!"

@app.route("/users")
def users():
    with tracer.start_as_current_span("users-span"):
        time.sleep(0.05)  # simulate DB query
        return "Users data"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
EOF

########################################
# ð STEP 7: RUN THE APPLICATION
########################################
echo "=== Starting Flask + OpenTelemetry app ==="
echo ">>> To run manually later, activate venv and use: python app.py"
echo "=============================================================="
echo "Access the app at: http://<your-EC2-IP>:5000"
echo "Traces will be sent to: http://127.0.0.1:4318/v1/traces"
echo "=============================================================="

python app.py

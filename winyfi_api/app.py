from flask import Flask
from flask_cors import CORS
from controllers.auth import auth_bp
from controllers.routers import routers_bp
from controllers.reports import reports_bp

app = Flask(__name__)
CORS(app)

# Register blueprints (modular routes)
app.register_blueprint(auth_bp)
app.register_blueprint(routers_bp)
app.register_blueprint(reports_bp)

if __name__ == '__main__':
    app.run(debug=True)

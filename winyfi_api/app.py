from flask import Flask, send_from_directory
from flask_cors import CORS
from controllers.auth import auth_bp
from controllers.routers import routers_bp
from controllers.reports import reports_bp


app = Flask(__name__)
CORS(app)

# <-- point this at your desktop‐app image folder
IMAGES_FOLDER = r'C:\Users\63967\Desktop\network monitoring\routerLocImg'

@app.route('/router_image/<path:filename>')
def router_image(filename):
    """
    Serve router location images from the desktop‐app folder.
    """
    return send_from_directory(IMAGES_FOLDER, filename, as_attachment=False)

# Register blueprints (modular routes)
app.register_blueprint(auth_bp)
app.register_blueprint(routers_bp)
app.register_blueprint(reports_bp, url_prefix='/reports')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)

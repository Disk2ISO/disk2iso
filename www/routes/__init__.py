"""
disk2iso - Modulare Route Blueprints
Jedes optionale Modul kann eigene Routen registrieren
"""

from flask import Blueprint

# DEPRECATED: Core Config Blueprint removed (was: from .settings import config_bp)
# Config is now managed via widget-specific endpoints in routes/widgets/

# MQTT Blueprint wird in routes_mqtt.py definiert
from .routes_mqtt import mqtt_bp

__all__ = ['mqtt_bp']

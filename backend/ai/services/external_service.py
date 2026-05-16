"""
Service pour les données externes (API ou scraping)
⚠️ NE PAS utiliser en temps réel dans le chatbot
Prévoir un système séparé pour collecter et stocker les données
"""
import requests
from django.conf import settings


def fetch_weather_data(location: str = "Dakar") -> dict:
    """
    Récupère les données météo via OpenWeather API
    
    Args:
        location: Nom de la ville (défaut: Dakar)
    
    Returns:
        dict: Données météo ou None en cas d'erreur
    """
    try:
        api_key = settings.OPENWEATHER_API_KEY or os.environ.get('OPENWEATHER_API_KEY')
        if not api_key:
            return None
        
        url = f"http://api.openweathermap.org/data/2.5/weather?q={location}&appid={api_key}&units=metric&lang=fr"
        response = requests.get(url, timeout=5)
        
        if response.status_code == 200:
            data = response.json()
            return {
                'temperature': data['main']['temp'],
                'humidity': data['main']['humidity'],
                'description': data['weather'][0]['description'],
                'location': data['name']
            }
        
        return None
        
    except Exception as e:
        print(f"Erreur météo: {e}")
        return None


def fetch_market_news(category: str = "agriculture") -> list:
    """
    Récupère des nouvelles agricoles (placeholder pour API réelle)
    
    Args:
        category: Catégorie de nouvelles
    
    Returns:
        list: Liste de nouvelles ou liste vide
    """
    # Placeholder - à remplacer avec une vraie API
    # Exemples: NewsAPI, Google News API, scraping de sites agricoles
    return []


def fetch_commodity_prices(commodity: str) -> dict:
    """
    Récupère les prix des matières premières (placeholder)
    
    Args:
        commodity: Nom de la matière première
    
    Returns:
        dict: Prix ou None
    """
    # Placeholder - à remplacer avec une vraie API
    # Exemples: FAO, World Bank, Bloomberg
    return None


def fetch_agricultural_advice(topic: str) -> str:
    """
    Récupère des conseils agricoles depuis une source externe (placeholder)
    
    Args:
        topic: Sujet du conseil
    
    Returns:
        str: Conseil ou None
    """
    # Placeholder - à remplacer avec une vraie API ou scraping
    return None


# ⚠️ IMPORTANT: Ces fonctions ne doivent PAS être appelées directement dans le chatbot
# Elles servent à collecter des données qui seront ensuite stockées dans la base de données
# Le chatbot doit toujours passer par db_service pour accéder aux données

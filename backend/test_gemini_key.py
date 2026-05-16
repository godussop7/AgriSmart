import os
import sys

# Configurer Django
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'agriprice.settings')

import django
django.setup()

from django.conf import settings

print("=" * 50)
print("TEST DE LA CLÉ API GEMINI")
print("=" * 50)

print(f"\nClé API configurée: {settings.GEMINI_API_KEY[:20]}..." if settings.GEMINI_API_KEY else "❌ NON CONFIGURÉE")

if not settings.GEMINI_API_KEY:
    print("\n❌ ERREUR: La clé API Gemini n'est pas configurée.")
    print("Configurez GEMINI_API_KEY dans settings.py ou .env")
    sys.exit(1)

try:
    import google.generativeai as genai
    
    print("\n🔧 Configuration de l'API...")
    genai.configure(api_key=settings.GEMINI_API_KEY)
    
    print("🤖 Création du modèle...")
    model = genai.GenerativeModel('gemini-1.5-flash')
    
    print("💬 Test de génération...")
    response = model.generate_content("Dis 'Bonjour' en une phrase.")
    
    print(f"\n✅ SUCCÈS: L'API Gemini fonctionne !")
    print(f"Réponse: {response.text}")
    
except ImportError:
    print("\n❌ ERREUR: La bibliothèque google-generativeai n'est pas installée.")
    print("Installez-la avec: pip install google-generativeai")
    sys.exit(1)
    
except Exception as e:
    print(f"\n❌ ERREUR: L'API Gemini a échoué.")
    print(f"Détail: {e}")
    print("\n🔑 La clé API est probablement invalide ou expirée.")
    print("Obtenez une nouvelle clé sur: https://makersuite.google.com/app/apikey")
    sys.exit(1)

print("\n" + "=" * 50)

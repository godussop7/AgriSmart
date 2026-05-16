import os
import sys
import django

# Configurer Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'agriprice.settings')
django.setup()

from django.conf import settings

print(f"Clé API: {settings.GEMINI_API_KEY[:20]}...")

try:
    import google.generativeai as genai
    genai.configure(api_key=settings.GEMINI_API_KEY)
    model = genai.GenerativeModel('gemini-1.5-flash')
    
    print("Test avec question simple...")
    response = model.generate_content("Bonjour, qui es-tu ?")
    print(f"Réponse: {response.text}")
    
except Exception as e:
    print(f"ERREUR: {e}")

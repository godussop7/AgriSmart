# Module Chatbot Intelligent AgriPrice

Chatbot intelligent avec architecture à 3 couches pour l'application AgriPrice.

## 🏗️ Architecture

Le système fonctionne en 3 étapes prioritaires :

1. **Données locales (Base de données)** - PRIORITÉ ABSOLUE
2. **Enrichissement avec Gemini** - Génération de réponses pertinentes
3. **Données externes (API/Scraping)** - Dernier recours (optionnel)

## 📁 Structure

```
/ai/
├── __init__.py
├── chatbot.py                 # Orchestration principale
├── services/
│   ├── __init__.py
│   ├── db_service.py          # Accès aux données locales
│   ├── gemini_service.py      # Intégration Gemini
│   └── external_service.py    # Données externes (optionnel)
└── README.md                  # Documentation
```

## 🚀 Installation

### Dépendances

```bash
pip install google-generativeai requests
```

### Configuration des variables d'environnement

Ajoutez dans votre fichier `.env` ou `settings.py` :

```python
GEMINI_API_KEY=votre_clé_api_gemini
OPENWEATHER_API_KEY=votre_clé_api_openweather  # Optionnel
```

## 📖 Utilisation

### Exemple dans une API Django

```python
from ai.chatbot import chatbot

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def chatbot_endpoint(request):
    user_message = request.data.get('message', '')
    
    result = chatbot(
        question=user_message,
        user=request.user
    )
    
    return Response({
        'response': result['response'],
        'source': result['source'],
        'has_local_data': result['has_local_data'],
        'local_data_summary': result['local_data_summary']
    })
```

### Exemple dans un script Python

```python
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'agriprice.settings')
django.setup()

from ai.chatbot import chatbot
from django.contrib.auth.models import User

# Récupérer un utilisateur
user = User.objects.get(username='demo')

# Poser une question
result = chatbot(
    question="Qu'est-ce que j'ai en stock ?",
    user=user
)

print(f"Réponse: {result['response']}")
print(f"Source: {result['source']}")
print(f"Données locales: {result['has_local_data']}")
```

## 🔧 Services

### 1. db_service.py

Récupère les données depuis la base de données Django.

**Fonctions principales :**
- `get_local_data(question: str, user=None) -> dict` : Récupère les données pertinentes
- `format_local_data_for_prompt(context: dict) -> str` : Formate pour le prompt Gemini

**Données recherchées :**
- Produits et catégories
- Prix récents
- Marchés
- Stocks utilisateur
- Ventes utilisateur
- Guides de culture

### 2. gemini_service.py

Génère des réponses via l'API Google Gemini.

**Fonctions principales :**
- `generate_response(prompt: str, model: str) -> str` : Appel basique à l'API
- `generate_response_with_context(question, local_data, user_context) -> str` : Avec contexte local
- `generate_simple_response(question: str) -> str` : Sans contexte (fallback)

### 3. external_service.py

Récupère des données externes (API, scraping).

**⚠️ IMPORTANT :** Ne pas utiliser en temps réel dans le chatbot. Ces fonctions servent à collecter des données qui seront ensuite stockées dans la base de données.

**Fonctions disponibles :**
- `fetch_weather_data(location: str) -> dict` : Météo via OpenWeather
- `fetch_market_news(category: str) -> list` : Nouvelles agricoles (placeholder)
- `fetch_commodity_prices(commodity: str) -> dict` : Prix matières premières (placeholder)

### 4. chatbot.py

Orchestration principale du système.

**Fonction principale :**
```python
chatbot(question: str, user=None) -> dict
```

**Retour :**
```python
{
    'response': str,              # La réponse générée
    'source': str,                # Source: 'gemini_with_local', 'gemini_simple', 'local_only', 'fallback'
    'has_local_data': bool,       # Si des données locales ont été trouvées
    'local_data_summary': str     # Résumé des données utilisées
}
```

## 🔄 Flux de fonctionnement

```
Question utilisateur
    ↓
1. get_local_data() → Recherche dans la base
    ↓
Données trouvées ?
    ↓ OUI → 2. generate_response_with_context()
            ↓
        Gemini avec contexte local
            ↓
        Réponse enrichie
    ↓ NON → 3. generate_simple_response()
            ↓
        Gemini sans contexte
            ↓
        Réponse simple
    ↓
Échec Gemini ?
    ↓ OUI → 4. _generate_local_only_response()
            ↓
        Réponse basée uniquement sur les données locales
    ↓ NON → 5. _generate_fallback_response()
            ↓
        Réponse générique
```

## 🎯 Sources de réponse

| Source | Description | Quand utilisé |
|--------|-------------|---------------|
| `gemini_with_local` | Gemini avec données locales | Données locales trouvées + Gemini fonctionne |
| `gemini_simple` | Gemini sans contexte | Pas de données locales mais Gemini fonctionne |
| `local_only` | Données locales uniquement | Données locales trouvées mais Gemini échoue |
| `fallback` | Réponse générique | Aucune donnée locale et Gemini échoue |
| `error` | Erreur système | Exception lors du traitement |

## 🔐 Sécurité

- **Jamais d'invention de données** : L'IA n'invente pas de données qui ne sont pas dans les informations fournies
- **Priorité aux données locales** : Les données de la base sont toujours utilisées en premier
- **Authentification requise** : L'utilisateur doit être connecté pour accéder à ses données personnelles
- **Clés API sécurisées** : Utilisation de variables d'environnement

## 📈 Extension

### Ajouter une nouvelle source de données

1. Créer une nouvelle fonction dans `db_service.py` :
```python
def get_custom_data(question: str) -> dict:
    # Votre logique ici
    return context
```

2. Appeler cette fonction dans `get_local_data()` :
```python
custom_data = get_custom_data(question)
if custom_data['has_data']:
    context['custom'] = custom_data
```

3. Mettre à jour `format_local_data_for_prompt()` pour inclure ces données.

### Ajouter un nouveau provider IA

1. Créer un nouveau service dans `services/` (ex: `openai_service.py`)
2. Ajouter la logique de fallback dans `chatbot.py`
3. Mettre à jour la documentation

## 🐛 Débogage

Activer les logs pour voir le flux :

```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

Les logs affichent :
- Données locales trouvées
- Source de la réponse
- Erreurs éventuelles

## 📝 Exemples de questions

| Question | Données utilisées | Source typique |
|----------|-------------------|----------------|
| "Qu'est-ce que j'ai en stock ?" | Stocks utilisateur | `gemini_with_local` |
| "Combien j'ai gagné ce mois ?" | Ventes utilisateur | `gemini_with_local` |
| "Quels sont les prix du mil ?" | Prix produits | `gemini_with_local` |
| "Comment cultiver le riz ?" | Guides de culture | `gemini_with_local` |
| "Bonjour" | Aucune | `gemini_simple` |
| "Météo à Dakar" | Aucune (nécessite external) | `gemini_simple` |

## 🤝 Contribution

Pour contribuer :
1. Respecter l'architecture à 3 couches
2. Priorité absolue aux données locales
3. Ajouter des tests unitaires
4. Mettre à jour la documentation

## 📄 Licence

Propriétaire - AgriPrice Sénégal

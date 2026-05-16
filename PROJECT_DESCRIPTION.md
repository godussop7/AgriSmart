# PROJET : AgriSmart (Application Agricole pour le Sénégal)

## 🎯 1. Objectif du Projet

AgriSmart est une plateforme (Mobile + API Backend) destinée aux agriculteurs, commerçants et consommateurs au Sénégal. Elle permet de suivre les prix des produits agricoles sur différents marchés locaux en temps réel, de gérer les stocks/ventes des agriculteurs, et d'utiliser l'Intelligence Artificielle (Gemini) pour faire des prédictions de prix et fournir un assistant virtuel contextualisé (Chatbot).

## 🛠 2. Stack Technologique

### Backend
- **Python** : 3.10+
- **Django** : 4.2+
- **Django REST Framework (DRF)** : Pour l'API REST
- **Base de données** : PostgreSQL (production) ou SQLite (développement)
- **Authentification** : JWT via djangorestframework-simplejwt
- **Intelligence Artificielle** : Google Generative AI (API Gemini 1.5 Flash)
- **Scraping / Météo** : requests, xml.etree.ElementTree (RSS), API OpenWeatherMap
- **CORS** : django-cors-headers

### Frontend Web
- **React** : 18+
- **TypeScript** : Langage principal
- **Gestion d'état** : Context API ou Redux Toolkit
- **HTTP** : axios ou fetch pour les requêtes
- **Sécurité** : localStorage ou sessionStorage pour la persistance des tokens
- **Graphiques** : recharts ou chart.js pour les visualisations de prix
- **Navigation** : React Router v6
- **UI Components** : Material-UI (MUI) ou TailwindCSS + shadcn/ui

## 📁 3. Structure du Projet

```
agris_full/
├── backend/
│   ├── agrismart/              # Configuration Django
│   │   ├── settings.py         # Paramètres (clés API, DB, CORS)
│   │   ├── urls.py             # Routes URL principales
│   │   └── wsgi.py             # Configuration WSGI
│   ├── api/                    # API REST
│   │   ├── models.py           # Modèles de données
│   │   ├── serializers.py      # Sérialiseurs DRF
│   │   ├── views.py            # Vues API
│   │   ├── urls.py             # Routes API
│   │   └── permissions.py      # Permissions personnalisées
│   ├── ai/                     # Module Intelligence Artificielle
│   │   ├── chatbot.py          # Chatbot principal
│   │   ├── services/
│   │   │   ├── db_service.py   # Accès données locales
│   │   │   ├── gemini_service.py # Service Gemini
│   │   │   └── external_service.py # Données externes
│   │   └── README.md           # Documentation IA
│   ├── manage.py               # Script Django
│   ├── requirements.txt        # Dépendances Python
│   └── .env                    # Variables d'environnement
├── react_app/
│   ├── src/
│   │   ├── main.tsx            # Point d'entrée
│   │   ├── services/
│   │   │   └── apiService.ts   # Service API centralisé
│   │   ├── types/              # Types TypeScript
│   │   ├── pages/              # Pages de l'application
│   │   ├── components/         # Composants React
│   │   ├── utils/              # Utilitaires (constants, helpers)
│   │   └── context/            # Context API
│   ├── public/                 # Fichiers statiques
│   ├── package.json            # Dépendances React
│   └── tsconfig.json           # Configuration TypeScript
└── README.md                   # Documentation générale
```

## 🗄 4. Architecture de la Base de Données (Modèles Django)

### Region
- `name` : CharField (Nom de la région)
- `code` : CharField (Code unique)
- `latitude` : DecimalField (Coordonnées)
- `longitude` : DecimalField (Coordonnées)
- `population` : PositiveIntegerField
- `created_at` : DateTimeField (auto_now_add=True)

### Market
- `name` : CharField (Nom du marché)
- `region` : ForeignKey (Region)
- `address` : CharField (Adresse)
- `latitude` : DecimalField
- `longitude` : DecimalField
- `rating` : DecimalField (Note 0-5)
- `price_level` : CharField (choices: low, medium, high)
- `market_days` : CharField (Jours de marché)
- `status` : CharField (choices: active, inactive, maintenance)

### Category
- `name` : CharField (Nom de la catégorie)
- `icon` : CharField (Emoji)
- `color` : CharField (Code hex couleur)

### Product
- `name` : CharField (Nom du produit)
- `local_name` : CharField (Nom en Wolof)
- `category` : ForeignKey (Category)
- `unit` : CharField (kg, tonne, unité...)
- `availability` : CharField (choices: available, limited, out_of_stock)
- `trend` : CharField (choices: rising, stable, falling)
- `min_price` : DecimalField
- `max_price` : DecimalField
- `avg_price` : DecimalField
- `is_featured` : BooleanField

### Price
- `product` : ForeignKey (Product)
- `market` : ForeignKey (Market)
- `price` : DecimalField
- `date` : DateField
- `source` : CharField (admin, user, scraping)
- `added_by` : ForeignKey (User)

### UserProfile
- `user` : OneToOneField (User)
- `role` : CharField (choices: farmer, trader, consumer)
- `phone` : CharField
- `region` : ForeignKey (Region)
- `preferred_market` : ForeignKey (Market)
- `favorite_products` : ManyToManyField (Product)

### FarmerStock
- `user` : ForeignKey (User)
- `product` : ForeignKey (Product)
- `quantity` : DecimalField
- `unit` : CharField
- `storage_location` : CharField
- `stored_date` : DateField
- `expiry_date` : DateField
- `status` : CharField (choices: available, sold, expired)

### FarmerSale
- `user` : ForeignKey (User)
- `product` : ForeignKey (Product)
- `market` : ForeignKey (Market)
- `quantity` : DecimalField
- `unit` : CharField
- `unit_price` : DecimalField
- `total_price` : DecimalField
- `sale_date` : DateField
- `buyer_name` : CharField
- `payment_method` : CharField

### Alert
- `user` : ForeignKey (User)
- `product` : ForeignKey (Product)
- `alert_type` : CharField (choices: above, below, change)
- `threshold_price` : DecimalField
- `change_percent` : DecimalField
- `status` : CharField (choices: active, triggered)
- `created_at` : DateTimeField

### Prediction
- `product` : ForeignKey (Product)
- `market` : ForeignKey (Market)
- `horizon` : CharField (7d, 30d)
- `predicted_price` : DecimalField
- `trend` : CharField (rising, stable, falling)
- `confidence` : DecimalField (0-1)
- `advice` : TextField
- `created_at` : DateTimeField

### CultureGuide
- `title` : CharField
- `crop` : CharField (Culture)
- `region` : ForeignKey (Region)
- `planting_season` : CharField
- `harvest_season` : CharField
- `soil_type` : CharField
- `water_needs` : CharField
- `tips` : TextField

## ⚙️ 5. Fonctionnalités Clés du Backend (API REST)

### Authentification & Profils
- `POST /auth/register/` : Inscription avec rôle
- `POST /auth/login/` : Login avec retour JWT (access + refresh)
- `POST /auth/refresh/` : Rafraîchissement du token
- `GET /auth/profile/` : Profil utilisateur
- `PUT /auth/profile/` : Modification du profil
- `POST /auth/logout/` : Déconnexion

### Catalogue & Prix
- `GET /categories/` : Liste des catégories
- `GET /products/` : Liste des produits (filtres: category, search, trend, availability)
- `GET /products/{id}/` : Détails d'un produit
- `POST /products/` : Ajouter un produit (admin)
- `GET /markets/` : Liste des marchés (filtres: region, price_level)
- `POST /prices/` : Ajouter un prix à un produit sur un marché
- `GET /products/{id}/price_history/` : Historique des prix (param: days)
- `GET /products/{id}/compare/` : Comparaison prix sur plusieurs marchés

### Prédictions IA (Gemini)
- `GET /predictions/` : Liste des prédictions (filtres: product, horizon)
- `POST /predictions/` : Générer une prédiction IA
  - Paramètres: product_id, market_id (optionnel), horizon (7d ou 30d)
  - Récupère l'historique des prix des 14/30 derniers jours
  - Génère un prompt strict pour Gemini
  - Retourne: prix prédit, tendance, confiance, conseil

### Assistant Intelligent (Chatbot)
- `POST /chatbot/` : Endpoint du chatbot
  - Paramètres: message (texte)
  - Contexte envoyé à Gemini:
    - Profil utilisateur (rôle, région, marché préféré)
    - Stocks actuels de l'utilisateur
    - Ventes récentes (30 derniers jours)
    - Prix actuels des produits de l'utilisateur
    - Actualités agricoles (Google News RSS)
  - Directive Gemini: réponse concise, structurée par tirets, sans Markdown
  - Fallback: réponses basées sur mots-clés si Gemini échoue

### Météo
- `GET /weather/{region}/` : Météo pour une région
  - Utilise OpenWeatherMap API
  - Retourne: température, humidité, description
  - Conseils adaptés (ex: pas d'arrosage s'il pleut)

### Ventes & Stocks
- `GET /stock/` : Liste des stocks de l'utilisateur
- `POST /stock/` : Ajouter un stock
- `PUT /stock/{id}/` : Modifier un stock
- `DELETE /stock/{id}/` : Supprimer un stock
- `GET /stock/low_stock/` : Stocks en dessous du seuil
- `GET /stock/expiring_soon/` : Stocks qui périment bientôt
- `GET /sales/` : Liste des ventes de l'utilisateur
- `POST /sales/` : Enregistrer une vente
- `DELETE /sales/{id}/` : Supprimer une vente
- `GET /sales/statistics/` : Statistiques de ventes (param: period)

### Alertes
- `GET /alerts/` : Liste des alertes de l'utilisateur
- `POST /alerts/` : Créer une alerte
- `POST /alerts/{id}/toggle/` : Activer/désactiver une alerte
- `DELETE /alerts/{id}/` : Supprimer une alerte

### Dashboard & Stats
- `GET /dashboard/` : Statistiques pour le dashboard
- `GET /stats/` : Statistiques globales (admin)

## 📱 6. Application Web (Frontend React)

### Architecture & Services
- **apiService.ts** : Service centralisé pour tous les appels HTTP
  - Méthodes: `get()`, `post()`, `put()`, `delete()`
  - Gestion automatique des headers avec JWT
  - Interceptor axios pour rafraîchissement automatique du token (401)
  - Gestion des erreurs avec messages utilisateur
- **localStorage/sessionStorage** : Persistance des tokens JWT
- **axios** : Requêtes HTTP vers l'API backend
- **React Context API** : Gestion de l'état global (auth, user, theme)

### Pages Principales

#### DashboardPage
- Statistiques générales (nombre de produits, marchés, utilisateurs)
- Produits vedettes (is_featured=True)
- Variations de prix récentes
- Accès rapide aux fonctionnalités principales

#### ProductsPage
- Liste des produits avec filtrage (catégorie, recherche, tendance)
- Vue détaillée d'un produit avec:
  - Graphique d'historique des prix (recharts)
  - Comparaison entre marchés
  - Informations détaillées (nom local, unité, disponibilité)

#### PredictionsPage
- Interface affichant les analyses IA
- Visualisation des tendances (haussière/baissière)
- Conseils de vente/stockage
- Filtres par produit et horizon

#### ChatbotPage
- Interface de messagerie textuelle
- Bulles de messages (utilisateur / bot)
- Indicateur de chargement (Spinner)
- Affichage de la réponse texte brute (sans Markdown)
- Support des emojis

#### AlertsPage
- Liste des alertes actives
- Interface pour ajouter/modifier des seuils
- Notifications d'alertes déclenchées

#### ProfilePage
- Gestion des infos personnelles
- Vue du stock de l'agriculteur
- Historique des ventes
- Modification du profil

## 🔐 7. Configuration & Sécurité

### Variables d'Environnement (.env)
```
DJANGO_SECRET_KEY=votre_secret_key
DEBUG=True/False
DATABASE_URL=postgresql://user:password@localhost/dbname
GEMINI_API_KEY=votre_clé_gemini
GOOGLE_MAPS_API_KEY=votre_clé_google_maps
OPENWEATHER_API_KEY=votre_clé_openweather
```

### CORS Configuration
- `CORS_ALLOW_ALL_ORIGINS=True` (dev) ou whitelist (prod)
- `CORS_ALLOW_CREDENTIALS=True`
- Origines autorisées: localhost:3000, 127.0.0.1:8000, 10.0.2.2:8000

### Sécurité JWT
- Access token expiration: 30 minutes
- Refresh token expiration: 7 jours
- Rotation des refresh tokens activée

## 🚀 8. Règles Métiers & Prompting

### Focus Agriculteur
- Toutes les prédictions IA orientées "producteur"
- Exemples de conseils: "Les prix montent, c'est le moment de vendre"
- Recommandations basées sur le contexte local

### Fallback Local
- Si Gemini ou OpenWeather hors-ligne → fonctions de secours
- `_fallback_prediction()` : Données fictives cohérentes
- `_generate_demo_response()` : Réponses basées sur mots-clés
- Mots-clés: salutations, culture, vente, stockage, météo, engrais, aide

### Mise à jour Automatique des Stats
- À chaque nouveau prix enregistré:
  - Recalcul automatique de min/max/avg du produit
  - Vérification des alertes utilisateur déclenchées
  - Notification si alerte activée

## 📦 9. Dépendances

### Backend (requirements.txt)
```
Django==4.2.7
djangorestframework==3.14.0
djangorestframework-simplejwt==5.3.0
django-cors-headers==4.3.1
psycopg2-binary==2.9.9
google-generativeai==0.3.2
requests==2.31.0
python-decouple==3.8
```

### Frontend (package.json)
```json
{
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.20.0",
    "axios": "^1.6.0",
    "recharts": "^2.10.0",
    "@mui/material": "^5.14.0",
    "@mui/icons-material": "^5.14.0",
    "@emotion/react": "^11.11.0",
    "@emotion/styled": "^11.11.0"
  },
  "devDependencies": {
    "@types/react": "^18.2.0",
    "@types/react-dom": "^18.2.0",
    "typescript": "^5.3.0",
    "vite": "^5.0.0"
  }
}
```

## 🏗️ 10. Instructions de Build

### Backend
```bash
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver 0.0.0.0:8000
```

### Frontend
```bash
cd react_app
npm install
npm run dev
```

### Build Production
```bash
cd react_app
npm run build
```

### Preview Production Build
```bash
cd react_app
npm run preview
```

## 🧪 11. Tests

### Backend Tests
```bash
cd backend
python manage.py test
```

### Frontend Tests
```bash
cd react_app
npm test
```

## 📝 12. Notes Importantes

- L'application doit fonctionner en mode offline partiel (cache des données)
- Le chatbot doit prioriser les données locales avant Gemini
- Les prédictions IA doivent être basées sur l'historique réel des prix
- L'interface doit être en français avec support du Wolof pour les noms de produits
- L'application doit être optimisée pour les connexions internet limitées

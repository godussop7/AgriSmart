"""
Commande de gestion pour peupler la base de données avec des données de test
Usage: python manage.py seed_data
"""

import random
from datetime import date, timedelta
from decimal import Decimal

from django.core.management.base import BaseCommand
from django.contrib.auth.models import User

from api.models import Region, Market, Category, Product, Price, UserProfile


REGIONS_DATA = [
    {"name": "Dakar", "code": "DKR", "latitude": 14.7167, "longitude": -17.4677, "population": 3732284},
    {"name": "Thiès", "code": "THS", "latitude": 14.7886, "longitude": -16.9260, "population": 1874671},
    {"name": "Kaolack", "code": "KLC", "latitude": 14.1513, "longitude": -16.0766, "population": 1073893},
    {"name": "Ziguinchor", "code": "ZGC", "latitude": 12.5681, "longitude": -16.2719, "population": 549151},
    {"name": "Saint-Louis", "code": "SLO", "latitude": 16.0179, "longitude": -16.4896, "population": 981418},
    {"name": "Diourbel", "code": "DRB", "latitude": 14.6544, "longitude": -16.2309, "population": 1561243},
    {"name": "Louga", "code": "LGA", "latitude": 15.6131, "longitude": -16.2246, "population": 974015},
    {"name": "Fatick", "code": "FTK", "latitude": 14.3395, "longitude": -16.4111, "population": 735679},
    {"name": "Kolda", "code": "KLD", "latitude": 12.8918, "longitude": -14.9407, "population": 661083},
    {"name": "Tambacounda", "code": "TBC", "latitude": 13.7707, "longitude": -13.6673, "population": 783970},
    {"name": "Matam", "code": "MTM", "latitude": 15.6560, "longitude": -13.2555, "population": 614547},
    {"name": "Kaffrine", "code": "KFF", "latitude": 14.1059, "longitude": -15.5504, "population": 555504},
    {"name": "Kédougou", "code": "KDG", "latitude": 12.5556, "longitude": -12.1773, "population": 180071},
    {"name": "Sédhiou", "code": "SDH", "latitude": 12.7081, "longitude": -15.5576, "population": 452876},
]

MARKETS_DATA = [
    {"name": "Marché Sandaga", "region": "Dakar", "lat": 14.6941, "lng": -17.4374, "rating": 4.2, "level": "medium"},
    {"name": "Marché HLM", "region": "Dakar", "lat": 14.7139, "lng": -17.4621, "rating": 3.8, "level": "low"},
    {"name": "Marché Thiaroye", "region": "Dakar", "lat": 14.7369, "lng": -17.3672, "rating": 3.5, "level": "low"},
    {"name": "Marché Rufisque", "region": "Dakar", "lat": 14.7156, "lng": -17.2706, "rating": 3.9, "level": "low"},
    {"name": "Marché Central Thiès", "region": "Thiès", "lat": 14.7833, "lng": -16.9333, "rating": 4.0, "level": "medium"},
    {"name": "Marché Mbour", "region": "Thiès", "lat": 14.3675, "lng": -16.9748, "rating": 3.7, "level": "low"},
    {"name": "Marché Kaolack", "region": "Kaolack", "lat": 14.1513, "lng": -16.0766, "rating": 4.1, "level": "medium"},
    {"name": "Marché Ndoffane", "region": "Kaolack", "lat": 14.0127, "lng": -16.3022, "rating": 3.3, "level": "low"},
    {"name": "Marché Saint-Louis", "region": "Saint-Louis", "lat": 16.0200, "lng": -16.4900, "rating": 4.3, "level": "medium"},
    {"name": "Marché Ziguinchor", "region": "Ziguinchor", "lat": 12.5620, "lng": -16.2720, "rating": 3.9, "level": "low"},
    {"name": "Marché Diourbel", "region": "Diourbel", "lat": 14.6544, "lng": -16.2309, "rating": 3.6, "level": "low"},
    {"name": "Marché Tambacounda", "region": "Tambacounda", "lat": 13.7707, "lng": -13.6673, "rating": 3.4, "level": "low"},
]

CATEGORIES_DATA = [
    {"name": "Céréales", "icon": "🌾", "color": "#F59E0B", "sort_order": 1},
    {"name": "Légumes", "icon": "🥬", "color": "#10B981", "sort_order": 2},
    {"name": "Fruits", "icon": "🍊", "color": "#F97316", "sort_order": 3},
    {"name": "Légumineuses", "icon": "🫘", "color": "#8B5CF6", "sort_order": 4},
    {"name": "Tubercules", "icon": "🥔", "color": "#92400E", "sort_order": 5},
    {"name": "Élevage", "icon": "🐄", "color": "#EF4444", "sort_order": 6},
    {"name": "Poisson", "icon": "🐟", "color": "#3B82F6", "sort_order": 7},
    {"name": "Huiles & Graisses", "icon": "🫙", "color": "#F59E0B", "sort_order": 8},
    {"name": "Épices", "icon": "🌶️", "color": "#DC2626", "sort_order": 9},
]

PRODUCTS_DATA = [
    # Céréales
    {"name": "Mil", "local": "Gros mil / Souna", "cat": "Céréales", "unit": "kg", "min": 200, "max": 450, "featured": True},
    {"name": "Sorgho", "local": "Gawri", "cat": "Céréales", "unit": "kg", "min": 180, "max": 380, "featured": False},
    {"name": "Maïs", "local": "Maïs", "cat": "Céréales", "unit": "kg", "min": 200, "max": 350, "featured": True},
    {"name": "Riz local", "local": "Riz Casamance", "cat": "Céréales", "unit": "kg", "min": 350, "max": 600, "featured": True},
    {"name": "Riz importé", "local": "Riz ordinaire", "cat": "Céréales", "unit": "kg", "min": 300, "max": 500, "featured": False},
    {"name": "Fonio", "local": "Findi", "cat": "Céréales", "unit": "kg", "min": 400, "max": 750, "featured": False},
    # Légumes
    {"name": "Oignons", "local": "Suuf", "cat": "Légumes", "unit": "kg", "min": 200, "max": 600, "featured": True},
    {"name": "Tomates", "local": "Tamaate", "cat": "Légumes", "unit": "kg", "min": 300, "max": 800, "featured": True},
    {"name": "Choux", "local": "Chou", "cat": "Légumes", "unit": "unite", "min": 200, "max": 500, "featured": False},
    {"name": "Aubergines", "local": "Jaxatu", "cat": "Légumes", "unit": "kg", "min": 150, "max": 400, "featured": False},
    {"name": "Gombo", "local": "Kanja", "cat": "Légumes", "unit": "botte", "min": 100, "max": 300, "featured": False},
    {"name": "Piment", "local": "Kaani", "cat": "Légumes", "unit": "kg", "min": 500, "max": 1500, "featured": False},
    # Fruits
    {"name": "Mangues", "local": "Maango", "cat": "Fruits", "unit": "kg", "min": 200, "max": 600, "featured": True},
    {"name": "Papayes", "local": "Papay", "cat": "Fruits", "unit": "unite", "min": 300, "max": 800, "featured": False},
    {"name": "Pastèques", "local": "Xarba", "cat": "Fruits", "unit": "unite", "min": 500, "max": 2000, "featured": False},
    {"name": "Oranges", "local": "Sëttan", "cat": "Fruits", "unit": "kg", "min": 300, "max": 700, "featured": False},
    # Légumineuses
    {"name": "Niébé", "local": "Niébé", "cat": "Légumineuses", "unit": "kg", "min": 400, "max": 800, "featured": True},
    {"name": "Arachides", "local": "Gerte", "cat": "Légumineuses", "unit": "kg", "min": 350, "max": 650, "featured": True},
    {"name": "Lentilles", "local": "Lentilles", "cat": "Légumineuses", "unit": "kg", "min": 600, "max": 1200, "featured": False},
    # Tubercules
    {"name": "Manioc", "local": "Manioc", "cat": "Tubercules", "unit": "kg", "min": 100, "max": 300, "featured": False},
    {"name": "Patate douce", "local": "Ñami", "cat": "Tubercules", "unit": "kg", "min": 150, "max": 350, "featured": False},
    # Élevage
    {"name": "Bœuf (viande)", "local": "Yapp yéwéné", "cat": "Élevage", "unit": "kg", "min": 2500, "max": 4500, "featured": True},
    {"name": "Poulet de chair", "local": "Gerte caval", "cat": "Élevage", "unit": "unite", "min": 2000, "max": 4000, "featured": False},
    {"name": "Mouton (viande)", "local": "Yapp xar", "cat": "Élevage", "unit": "kg", "min": 3000, "max": 5000, "featured": False},
    # Poisson
    {"name": "Thiof (mérou)", "local": "Thiof", "cat": "Poisson", "unit": "kg", "min": 3000, "max": 6000, "featured": True},
    {"name": "Yeet (cymbium)", "local": "Yeet", "cat": "Poisson", "unit": "kg", "min": 800, "max": 2000, "featured": False},
    {"name": "Sardines", "local": "Yabé", "cat": "Poisson", "unit": "kg", "min": 300, "max": 700, "featured": False},
    # Huiles
    {"name": "Huile d'arachide", "local": "Dëkk u gerte", "cat": "Huiles & Graisses", "unit": "litre", "min": 1200, "max": 2000, "featured": False},
    {"name": "Huile de palme", "local": "Dëkk u tëlëk", "cat": "Huiles & Graisses", "unit": "litre", "min": 800, "max": 1500, "featured": False},
]


class Command(BaseCommand):
    help = 'Peuple la base de données avec des données de test pour AgriPrice AI'

    def handle(self, *args, **options):
        self.stdout.write('🌱 Démarrage du peuplement de la base de données...\n')

        # Régions
        self.stdout.write('📍 Création des régions...')
        regions = {}
        for r in REGIONS_DATA:
            region, _ = Region.objects.get_or_create(
                code=r['code'],
                defaults={
                    'name': r['name'],
                    'latitude': r['latitude'],
                    'longitude': r['longitude'],
                    'population': r['population'],
                }
            )
            regions[r['name']] = region
        self.stdout.write(self.style.SUCCESS(f'  ✅ {len(regions)} régions créées'))

        # Marchés
        self.stdout.write('🏪 Création des marchés...')
        markets = {}
        for m in MARKETS_DATA:
            market, _ = Market.objects.get_or_create(
                name=m['name'],
                defaults={
                    'region': regions[m['region']],
                    'latitude': m['lat'],
                    'longitude': m['lng'],
                    'rating': m['rating'],
                    'price_level': m['level'],
                    'status': 'active',
                    'description': f"Marché agricole de {m['name']}, {m['region']}",
                    'market_days': random.choice(['Lundi, Jeudi', 'Mardi, Vendredi', 'Mercredi, Samedi', 'Quotidien']),
                }
            )
            markets[m['name']] = market
        self.stdout.write(self.style.SUCCESS(f'  ✅ {len(markets)} marchés créés'))

        # Catégories
        self.stdout.write('📂 Création des catégories...')
        categories = {}
        for c in CATEGORIES_DATA:
            cat, _ = Category.objects.get_or_create(
                name=c['name'],
                defaults={'icon': c['icon'], 'color': c['color'], 'sort_order': c['sort_order']}
            )
            categories[c['name']] = cat
        self.stdout.write(self.style.SUCCESS(f'  ✅ {len(categories)} catégories créées'))

        # Produits
        self.stdout.write('🌾 Création des produits...')
        products = []
        for p in PRODUCTS_DATA:
            avg = (p['min'] + p['max']) / 2
            trend = random.choice(['up', 'down', 'stable'])
            change = random.uniform(-15, 20) if trend != 'stable' else random.uniform(-3, 3)
            product, _ = Product.objects.get_or_create(
                name=p['name'],
                defaults={
                    'local_name': p['local'],
                    'category': categories[p['cat']],
                    'unit': p['unit'],
                    'min_price': p['min'],
                    'max_price': p['max'],
                    'avg_price': avg,
                    'price_change_percent': round(change, 2),
                    'trend': trend,
                    'availability': random.choice(['abundant', 'normal', 'normal', 'scarce']),
                    'is_featured': p['featured'],
                    'description': f"{p['name']} - Produit agricole sénégalais",
                }
            )
            products.append(product)
        self.stdout.write(self.style.SUCCESS(f'  ✅ {len(products)} produits créés'))

        # Historique des prix (60 jours)
        self.stdout.write('💰 Génération de l\'historique des prix (60 jours)...')
        market_list = list(markets.values())
        price_count = 0
        today = date.today()

        for product in products:
            base_price = float(product.avg_price)
            for market in random.sample(market_list, min(4, len(market_list))):
                price = base_price * random.uniform(0.85, 1.15)
                for days_ago in range(60, 0, -1):
                    d = today - timedelta(days=days_ago)
                    delta = random.uniform(-4, 4)
                    price = max(50, price * (1 + delta / 100))
                    try:
                        Price.objects.get_or_create(
                            product=product,
                            market=market,
                            date=d,
                            defaults={
                                'price': round(price, 0),
                                'source': random.choice(['enquêteur', 'agent', 'commerçant']),
                                'is_verified': random.random() > 0.3,
                            }
                        )
                        price_count += 1
                    except Exception:
                        pass

        self.stdout.write(self.style.SUCCESS(f'  ✅ {price_count} entrées de prix créées'))

        # Utilisateur admin
        self.stdout.write('👤 Création de l\'utilisateur admin...')
        if not User.objects.filter(username='admin').exists():
            admin_user = User.objects.create_superuser(
                username='admin',
                email='admin@agriprice.sn',
                password='admin123',
                first_name='Admin',
                last_name='AgriPrice',
            )
            UserProfile.objects.create(user=admin_user, role='admin')

        # Utilisateur de démonstration
        if not User.objects.filter(username='demo').exists():
            demo_user = User.objects.create_user(
                username='demo',
                email='demo@agriprice.sn',
                password='demo123',
                first_name='Mamadou',
                last_name='Diallo',
            )
            UserProfile.objects.create(
                user=demo_user,
                role='farmer',
                phone='+221 77 123 45 67',
                region=regions.get('Thiès'),
            )

        self.stdout.write(self.style.SUCCESS(
            '\n🎉 Base de données peuplée avec succès!\n'
            '   👤 Admin: admin / admin123\n'
            '   👤 Demo:  demo / demo123\n'
            f'   📊 {len(products)} produits, {len(markets)} marchés, {price_count} prix\n'
        ))

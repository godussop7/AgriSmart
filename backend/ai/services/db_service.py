"""
Service de récupération des données locales depuis la base de données
Priorité absolue aux données locales avant toute source externe
"""
from datetime import datetime, timedelta
from django.db.models import Avg, Max, Min, Sum, Count, Q
from api.models import Product, Price, Market, Region, Category, FarmerStock, FarmerSale, CultureGuide


def get_local_data(question: str, user=None) -> dict:
    """
    Récupère les données pertinentes depuis la base de données
    
    Args:
        question: La question de l'utilisateur
        user: L'utilisateur connecté (optionnel, pour données personnelles)
    
    Returns:
        dict: Dictionnaire contenant les données locales trouvées
    """
    question_lower = question.lower()
    context = {
        'has_data': False,
        'products': [],
        'prices': [],
        'markets': [],
        'user_stocks': [],
        'user_sales': [],
        'culture_guides': [],
        'summary': ''
    }
    
    # 1. Recherche de produits par nom ou catégorie
    product_keywords = []
    for category in Category.objects.all():
        if category.name.lower() in question_lower:
            product_keywords.append(category.name)
    
    # Chercher les produits correspondants
    if product_keywords:
        products = Product.objects.filter(
            category__name__in=product_keywords
        )[:5]
    else:
        # Chercher par mot-clé dans le nom
        products = Product.objects.filter(
            name__icontains=question_lower
        )[:5]
    
    if products.exists():
        context['has_data'] = True
        for p in products:
            context['products'].append({
                'name': p.name,
                'category': p.category.name,
                'unit': p.unit,
                'avg_price': float(p.avg_price) if p.avg_price else 0,
                'trend': p.get_trend_display(),
                'availability': p.get_availability_display()
            })
    
    # 2. Recherche de prix récents pour les produits trouvés
    if context['products']:
        product_ids = [p['name'] for p in context['products']]
        recent_prices = Price.objects.filter(
            product__name__in=product_ids,
            date__gte=datetime.now().date() - timedelta(days=7)
        ).order_by('-date')[:10]
        
        for price in recent_prices:
            context['prices'].append({
                'product': price.product.name,
                'market': price.market.name,
                'price': float(price.price),
                'date': price.date.strftime('%d/%m/%Y')
            })
    
    # 3. Recherche de marchés mentionnés
    markets = Market.objects.filter(
        Q(name__icontains=question_lower) |
        Q(region__name__icontains=question_lower)
    )[:5]
    
    if markets.exists():
        context['has_data'] = True
        for m in markets:
            context['markets'].append({
                'name': m.name,
                'region': m.region.name if m.region else 'Non spécifié',
                'price_level': m.price_level
            })
    
    # 4. Données personnelles de l'utilisateur (si connecté)
    if user and user.is_authenticated:
        # Stocks de l'utilisateur
        user_stocks = FarmerStock.objects.filter(
            user=user,
            status='available'
        )[:10]
        
        if user_stocks.exists():
            context['has_data'] = True
            for stock in user_stocks:
                context['user_stocks'].append({
                    'product': stock.product.name,
                    'quantity': float(stock.quantity),
                    'unit': stock.unit,
                    'location': stock.storage_location or 'Non spécifié',
                    'stored_date': stock.stored_date.strftime('%d/%m/%Y') if stock.stored_date else 'Inconnue'
                })
        
        # Ventes récentes de l'utilisateur
        recent_sales = FarmerSale.objects.filter(
            user=user,
            sale_date__gte=datetime.now().date() - timedelta(days=30)
        ).order_by('-sale_date')[:10]
        
        if recent_sales.exists():
            context['has_data'] = True
            for sale in recent_sales:
                context['user_sales'].append({
                    'product': sale.product.name,
                    'quantity': float(sale.quantity),
                    'unit': sale.unit,
                    'unit_price': float(sale.unit_price),
                    'total': float(sale.total_price),
                    'date': sale.sale_date.strftime('%d/%m/%Y')
                })
    
    # 5. Guides de culture pertinents
    if any(word in question_lower for word in ['cultiver', 'planter', 'semis', 'récolte', 'culture', 'plantation']):
        culture_guides = CultureGuide.objects.all()[:5]
        
        if culture_guides.exists():
            context['has_data'] = True
            for guide in culture_guides:
                context['culture_guides'].append({
                    'title': guide.title,
                    'crop': guide.crop,
                    'region': guide.region.name if guide.region else 'Général',
                    'planting_season': guide.planting_season,
                    'harvest_season': guide.harvest_season,
                    'tips': guide.tips[:200] if guide.tips else ''
                })
    
    # 6. Générer un résumé des données trouvées
    if context['has_data']:
        summary_parts = []
        
        if context['products']:
            summary_parts.append(f"Produits trouvés: {len(context['products'])}")
        
        if context['prices']:
            summary_parts.append(f"Prix récents: {len(context['prices'])}")
        
        if context['user_stocks']:
            summary_parts.append(f"Stocks utilisateur: {len(context['user_stocks'])}")
        
        if context['user_sales']:
            summary_parts.append(f"Ventes récentes: {len(context['user_sales'])}")
        
        if context['culture_guides']:
            summary_parts.append(f"Guides de culture: {len(context['culture_guides'])}")
        
        context['summary'] = ', '.join(summary_parts)
    
    return context


def format_local_data_for_prompt(context: dict) -> str:
    """
    Formate les données locales pour inclusion dans le prompt Gemini
    
    Args:
        context: Dictionnaire des données locales
    
    Returns:
        str: Texte formaté pour le prompt
    """
    if not context['has_data']:
        return "Aucune donnée locale disponible pour cette question."
    
    formatted_parts = []
    
    # Produits
    if context['products']:
        formatted_parts.append("PRODUITS:")
        for p in context['products']:
            formatted_parts.append(
                f"- {p['name']} ({p['category']}): Prix moyen {p['avg_price']:.0f} FCFA/{p['unit']}, "
                f"Tendance: {p['trend']}, Disponibilité: {p['availability']}"
            )
    
    # Prix récents
    if context['prices']:
        formatted_parts.append("\nPRIX RÉCENTS:")
        for p in context['prices']:
            formatted_parts.append(
                f"- {p['product']}: {p['price']:.0f} FCFA à {p['market']} ({p['date']})"
            )
    
    # Marchés
    if context['markets']:
        formatted_parts.append("\nMARCHÉS:")
        for m in context['markets']:
            formatted_parts.append(
                f"- {m['name']} ({m['region']}): Niveau de prix {m['price_level']}"
            )
    
    # Stocks utilisateur
    if context['user_stocks']:
        formatted_parts.append("\nVOTRE STOCK:")
        for s in context['user_stocks']:
            formatted_parts.append(
                f"- {s['product']}: {s['quantity']} {s['unit']} (stocké le {s['stored_date']}, "
                f"lieu: {s['location']})"
            )
    
    # Ventes utilisateur
    if context['user_sales']:
        total_revenue = sum(s['total'] for s in context['user_sales'])
        formatted_parts.append("\nVOS VENTES RÉCENTES:")
        for s in context['user_sales']:
            formatted_parts.append(
                f"- {s['date']}: {s['product']} - {s['quantity']} {s['unit']} à "
                f"{s['unit_price']:.0f} FCFA/unité = {s['total']:.0f} FCFA"
            )
        formatted_parts.append(f"Total des ventes: {total_revenue:.0f} FCFA")
    
    # Guides de culture
    if context['culture_guides']:
        formatted_parts.append("\nGUIDES DE CULTURE:")
        for g in context['culture_guides']:
            formatted_parts.append(
                f"- {g['title']} ({g['crop']}): Saison de plantation {g['planting_season']}, "
                f"Saison de récolte {g['harvest_season']}"
            )
            if g['tips']:
                formatted_parts.append(f"  Conseil: {g['tips']}")
    
    return '\n'.join(formatted_parts)

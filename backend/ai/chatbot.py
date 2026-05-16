"""
Chatbot intelligent avec architecture à 3 couches
1. Données locales (base de données) - PRIORITÉ ABSOLUE
2. Enrichissement avec Gemini
3. Données externes (API/scraping) - dernier recours
"""
from .services.gemini_service import generate_response


def chatbot(question: str, user=None) -> dict:
    """
    Fonction principale du chatbot
    
    Args:
        question: La question de l'utilisateur
        user: L'utilisateur connecté (optionnel)
    
    Returns:
        dict: {
            'response': str - La réponse générée,
            'source': str - Source de la réponse
        }
    """
    # Prompt pour Gemini
    prompt = f"""Tu es un conseiller agricole sénégalais expert et utile.
Réponds à cette question de manière claire, professionnelle et en français.
Donne des conseils pratiques et actionnables adaptés au contexte agricole sénégalais.

QUESTION: {question}

Ta réponse:"""
    
    try:
        response = generate_response(prompt)
        return {
            'response': response,
            'source': 'gemini'
        }
    except Exception as e:
        print(f"Erreur chatbot: {e}")
        return {
            'response': "Désolé, je ne peux pas répondre pour le moment. Veuillez réessayer plus tard.",
            'source': 'error'
        }


def _generate_local_only_response(local_context: dict, question: str) -> str:
    """
    Génère une réponse basée uniquement sur les données locales (sans Gemini)
    
    Args:
        local_context: Contexte des données locales
        question: Question de l'utilisateur
    
    Returns:
        str: Réponse basée sur les données locales
    """
    question_lower = question.lower()
    
    # Réponse basée sur les stocks utilisateur
    if local_context['user_stocks']:
        if any(word in question_lower for word in ['stock', 'inventaire', 'disponible', 'combien']):
            stock_list = '\n'.join([
                f"- {s['product']}: {s['quantity']} {s['unit']} (stocké le {s['stored_date']}, lieu: {s['location']})"
                for s in local_context['user_stocks']
            ])
            return f"📦 **Votre stock actuel :**\n{stock_list}\n\n💡 **Conseil :** Surveillez régulièrement vos stocks pour éviter les pertes."
    
    # Réponse basée sur les ventes utilisateur
    if local_context['user_sales']:
        if any(word in question_lower for word in ['vente', 'revenu', 'gagné', 'chiffre']):
            total_revenue = sum(s['total'] for s in local_context['user_sales'])
            sales_list = '\n'.join([
                f"- {s['date']}: {s['product']} - {s['quantity']} {s['unit']} à {s['unit_price']:.0f} FCFA = {s['total']:.0f} FCFA"
                for s in local_context['user_sales'][:5]
            ])
            return f"💰 **Vos ventes récentes :**\n{sales_list}\n\n📊 **Total :** {total_revenue:.0f} FCFA"
    
    # Réponse basée sur les produits
    if local_context['products']:
        if any(word in question_lower for word in ['prix', 'produit', 'marché']):
            product_list = '\n'.join([
                f"- {p['name']} ({p['category']}): Prix moyen {p['avg_price']:.0f} FCFA/{p['unit']}, Tendance: {p['trend']}"
                for p in local_context['products']
            ])
            return f"📊 **Produits trouvés :**\n{product_list}\n\n💡 Ces données proviennent de votre base de données locale."
    
    # Réponse basée sur les guides de culture
    if local_context['culture_guides']:
        if any(word in question_lower for word in ['cultiver', 'planter', 'semis', 'récolte']):
            guide_list = '\n'.join([
                f"- {g['title']} ({g['crop']}): Plantation {g['planting_season']}, Récolte {g['harvest_season']}"
                for g in local_context['culture_guides']
            ])
            return f"🌱 **Guides de culture :**\n{guide_list}\n\n💡 Ces conseils proviennent de votre base de données locale."
    
    # Réponse par défaut avec données disponibles
    available_data = []
    if local_context['products']:
        available_data.append(f"{len(local_context['products'])} produits")
    if local_context['prices']:
        available_data.append(f"{len(local_context['prices'])} prix récents")
    if local_context['user_stocks']:
        available_data.append(f"{len(local_context['user_stocks'])} stocks")
    if local_context['user_sales']:
        available_data.append(f"{len(local_context['user_sales'])} ventes")
    
    if available_data:
        return f"J'ai trouvé ces données dans votre base : {', '.join(available_data)}. Posez une question plus spécifique pour que je puisse vous aider (ex: 'montre-moi mon stock', 'quels sont les prix ?')."
    
    return "Je n'ai pas trouvé de données pertinentes dans votre base pour cette question. Essayez de poser une question sur vos stocks, vos ventes, ou les prix des produits."


def _generate_fallback_response(question: str) -> str:
    """
    Génère une réponse de fallback quand tout échoue
    
    Args:
        question: Question de l'utilisateur
    
    Returns:
        str: Réponse de fallback
    """
    question_lower = question.lower()
    
    # Salutations
    if any(word in question_lower for word in ['salut', 'bonjour', 'bonsoir', 'hello', 'hi']):
        return "Bonjour ! Je suis AgriSmart Bot, votre assistant agricole. Je peux vous aider avec vos stocks, vos ventes, et les prix du marché. Posez-moi une question !"
    
    # Culture
    if any(word in question_lower for word in ['cultiver', 'planter', 'semis', 'récolte']):
        return "Pour la culture au Sénégal, je vous conseille de tenir compte de la saison des pluies (juin-octobre). Choisissez des variétés adaptées à votre région."
    
    # Vente
    if any(word in question_lower for word in ['vendre', 'prix', 'marché']):
        return "Pour optimiser vos ventes, surveillez les prix sur différents marchés. Les prix sont généralement plus élevés en début de saison."
    
    # Stockage
    if any(word in question_lower for word in ['stocker', 'stockage']):
        return "Pour un bon stockage, assurez une ventilation adéquate et protégez des insectes et des rongeurs."
    
    # Aide
    if any(word in question_lower for word in ['aide', 'conseil', 'que faire']):
        return "Je peux vous aider avec : vos stocks, vos ventes, les prix du marché, et des conseils agricoles. Posez-moi une question spécifique !"
    
    return "Désolé, je ne peux pas répondre pour le moment. Veuillez réessayer plus tard ou contacter le support technique."

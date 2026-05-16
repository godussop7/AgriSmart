"""
Service Gemini pour la génération de réponses IA
Utilise l'API Google Gemini avec gestion d'erreurs et fallback
"""
import os
from django.conf import settings


def generate_response(prompt: str, model: str = "gemini-1.5-flash") -> str:
    """
    Génère une réponse via l'API Google Gemini
    
    Args:
        prompt: Le prompt à envoyer à l'IA
        model: Le modèle Gemini à utiliser (défaut: gemini-1.5-flash)
    
    Returns:
        str: La réponse générée par l'IA
    
    Raises:
        ValueError: Si la clé API n'est pas configurée
        Exception: Si l'appel API échoue
    """
    try:
        import google.generativeai as genai
        
        # Récupérer la clé API
        api_key = settings.GEMINI_API_KEY or os.environ.get('GEMINI_API_KEY')
        if not api_key:
            raise ValueError("Clé API Gemini non configurée. Configurez GEMINI_API_KEY dans les variables d'environnement.")
        
        # Configurer l'API
        genai.configure(api_key=api_key)
        
        # Créer le modèle
        gemini_model = genai.GenerativeModel(model)
        
        # Générer la réponse
        response = gemini_model.generate_content(prompt)
        
        # Nettoyer la réponse
        response_text = response.text.strip()
        
        return response_text
        
    except ImportError:
        raise ImportError("La bibliothèque google-generativeai n'est pas installée. Installez-la avec: pip install google-generativeai")
    
    except Exception as e:
        # Logger l'erreur pour débogage
        print(f"Erreur Gemini API: {e}")
        raise Exception(f"Erreur lors de l'appel à l'API Gemini: {str(e)}")


def generate_response_with_context(question: str, local_data: str, user_context: dict = None) -> str:
    """
    Génère une réponse Gemini enrichie avec les données locales
    
    Args:
        question: La question de l'utilisateur
        local_data: Les données locales formatées
        user_context: Contexte additionnel de l'utilisateur (optionnel)
    
    Returns:
        str: La réponse générée par l'IA
    """
    # Construire le prompt avec le format spécifié
    prompt = f"""Tu es un conseiller agricole sénégalais expert.
Tu dois te baser PRIORITAIREMENT sur les données fournies ci-dessous.
Si tu ne trouves pas la réponse dans les données, dis-le clairement.
N'invente JAMAIS de données qui ne sont pas dans les informations fournies.

DONNÉES LOCALES:
{local_data}

CONTEXTE UTILISATEUR:
{format_user_context(user_context) if user_context else 'Non connecté'}

QUESTION DE L'UTILISATEUR:
{question}

INSTRUCTIONS:
- Réponds en français de manière claire et professionnelle
- Utilise les données locales pour étayer ta réponse
- Si les données sont insuffisantes, indique-le honnêtement
- Donne des conseils pratiques et actionnables
- Sois concis (max 3-4 paragraphes)
- Utilise un ton encourageant et motivant

Ta réponse:"""
    
    return generate_response(prompt)


def format_user_context(user_context: dict) -> str:
    """
    Formate le contexte utilisateur pour le prompt
    
    Args:
        user_context: Dictionnaire du contexte utilisateur
    
    Returns:
        str: Texte formaté
    """
    if not user_context:
        return "Non disponible"
    
    parts = []
    
    if 'username' in user_context:
        parts.append(f"Nom: {user_context['username']}")
    
    if 'role' in user_context:
        parts.append(f"Rôle: {user_context['role']}")
    
    if 'region' in user_context:
        parts.append(f"Région: {user_context['region']}")
    
    if 'preferred_market' in user_context:
        parts.append(f"Marché préféré: {user_context['preferred_market']}")
    
    return ', '.join(parts) if parts else "Non disponible"


def generate_simple_response(question: str) -> str:
    """
    Génère une réponse simple sans contexte local (fallback)
    
    Args:
        question: La question de l'utilisateur
    
    Returns:
        str: La réponse générée
    """
    prompt = f"""Tu es un conseiller agricole sénégalais expert.
Réponds à cette question de manière claire et professionnelle en français.

QUESTION:
{question}

INSTRUCTIONS:
- Donne des conseils pratiques adaptés au contexte sénégalais
- Sois concis (max 2-3 paragraphes)
- Si tu ne connais pas la réponse, indique-le honnêtement
- N'invente pas de données spécifiques (prix, quantités, etc.)

Ta réponse:"""
    
    return generate_response(prompt)

"""
Module IA pour AgriSmart Sénégal
Architecture à 3 couches : Données locales → Gemini → Externe
"""
from .chatbot import chatbot

__all__ = ['chatbot']

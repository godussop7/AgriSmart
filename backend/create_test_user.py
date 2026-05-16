import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'agriprice.settings')
django.setup()

from django.contrib.auth.models import User
from api.models import UserProfile

# Créer un utilisateur de test
username = "test"
password = "test123"
email = "test@example.com"

try:
    user = User.objects.create_user(
        username=username,
        email=email,
        password=password,
        first_name="Test",
        last_name="User"
    )
    
    # Créer le profil
    profile = UserProfile.objects.create(
        user=user,
        role='FARMER',
        phone='221770000000'
    )
    
    print(f"✅ Utilisateur de test créé avec succès!")
    print(f"   Username: {username}")
    print(f"   Password: {password}")
    print(f"   Email: {email}")
    
except Exception as e:
    print(f"❌ Erreur lors de la création de l'utilisateur: {e}")
    print("L'utilisateur existe peut-être déjà.")

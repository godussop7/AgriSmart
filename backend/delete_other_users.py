import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'agriprice.settings')
django.setup()

from django.contrib.auth.models import User

# Garder uniquement l'utilisateur 'test'
users_to_delete = User.objects.exclude(username='test')
count = users_to_delete.count()

if count > 0:
    users_to_delete.delete()
    print(f"✅ {count} utilisateur(s) supprimé(s) avec succès!")
else:
    print("ℹ️ Aucun autre utilisateur à supprimer.")

# Afficher les utilisateurs restants
remaining = User.objects.all()
print(f"\n👥 Utilisateurs restants ({remaining.count()}):")
for user in remaining:
    print(f"   - {user.username} ({user.email})")

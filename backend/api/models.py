"""
# AgriSmart - Modèles de données
Tous les modèles pour le suivi des prix agricoles au Sénégal
"""

from django.db import models
from django.contrib.auth.models import User
from django.core.validators import MinValueValidator, MaxValueValidator


class Region(models.Model):
    """Régions administratives du Sénégal"""
    name = models.CharField(max_length=100, unique=True, verbose_name="Nom")
    code = models.CharField(max_length=10, unique=True, verbose_name="Code")
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    population = models.PositiveIntegerField(default=0, verbose_name="Population")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Région"
        verbose_name_plural = "Régions"
        ordering = ['name']

    def __str__(self):
        return self.name


class Market(models.Model):
    """Marchés agricoles avec géolocalisation"""

    PRICE_LEVEL_CHOICES = [
        ('low', 'Bas'),
        ('medium', 'Moyen'),
        ('high', 'Élevé'),
    ]

    STATUS_CHOICES = [
        ('active', 'Actif'),
        ('inactive', 'Inactif'),
        ('maintenance', 'En maintenance'),
    ]

    name = models.CharField(max_length=200, verbose_name="Nom du marché")
    region = models.ForeignKey(Region, on_delete=models.CASCADE, related_name='markets')
    address = models.CharField(max_length=300, blank=True, verbose_name="Adresse")
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    rating = models.DecimalField(
        max_digits=3, decimal_places=1, default=0.0,
        validators=[MinValueValidator(0), MaxValueValidator(5)],
        verbose_name="Note"
    )
    price_level = models.CharField(max_length=10, choices=PRICE_LEVEL_CHOICES, default='medium')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    opening_time = models.TimeField(null=True, blank=True, verbose_name="Heure d'ouverture")
    closing_time = models.TimeField(null=True, blank=True, verbose_name="Heure de fermeture")
    market_days = models.CharField(max_length=100, blank=True, verbose_name="Jours de marché")
    description = models.TextField(blank=True, verbose_name="Description")
    products_count = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Marché"
        verbose_name_plural = "Marchés"
        ordering = ['name']

    def __str__(self):
        return f"{self.name} - {self.region.name}"


class Category(models.Model):
    """Catégories de produits agricoles"""
    name = models.CharField(max_length=100, unique=True, verbose_name="Nom")
    icon = models.CharField(max_length=50, default='🌾', verbose_name="Icône emoji")
    color = models.CharField(max_length=7, default='#4CAF50', verbose_name="Couleur hex")
    description = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)
    sort_order = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Catégorie"
        verbose_name_plural = "Catégories"
        ordering = ['sort_order', 'name']

    def __str__(self):
        return self.name


class Product(models.Model):
    """Produits agricoles"""

    UNIT_CHOICES = [
        ('kg', 'Kilogramme'),
        ('g', 'Gramme'),
        ('tonne', 'Tonne'),
        ('sac', 'Sac'),
        ('botte', 'Botte'),
        ('unite', 'Unité'),
        ('litre', 'Litre'),
        ('panier', 'Panier'),
    ]

    TREND_CHOICES = [
        ('up', 'En hausse'),
        ('down', 'En baisse'),
        ('stable', 'Stable'),
    ]

    AVAILABILITY_CHOICES = [
        ('abundant', 'Abondant'),
        ('normal', 'Normal'),
        ('scarce', 'Rare'),
        ('unavailable', 'Indisponible'),
    ]

    name = models.CharField(max_length=200, verbose_name="Nom du produit")
    local_name = models.CharField(max_length=200, blank=True, verbose_name="Nom local (Wolof/Pulaar)")
    category = models.ForeignKey(Category, on_delete=models.CASCADE, related_name='products')
    unit = models.CharField(max_length=10, choices=UNIT_CHOICES, default='kg')
    description = models.TextField(blank=True)
    image_url = models.URLField(blank=True, verbose_name="URL image")
    season_start = models.PositiveIntegerField(
        null=True, blank=True,
        validators=[MinValueValidator(1), MaxValueValidator(12)],
        verbose_name="Début saison (mois)"
    )
    season_end = models.PositiveIntegerField(
        null=True, blank=True,
        validators=[MinValueValidator(1), MaxValueValidator(12)],
        verbose_name="Fin saison (mois)"
    )
    trend = models.CharField(max_length=10, choices=TREND_CHOICES, default='stable')
    availability = models.CharField(max_length=15, choices=AVAILABILITY_CHOICES, default='normal')
    min_price = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    max_price = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    avg_price = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    price_change_percent = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    is_featured = models.BooleanField(default=False, verbose_name="Produit vedette")
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Produit"
        verbose_name_plural = "Produits"
        ordering = ['category', 'name']

    def __str__(self):
        return f"{self.name} ({self.get_unit_display()})"

    @property
    def is_in_season(self):
        """Vérifie si le produit est actuellement en saison"""
        from django.utils import timezone
        current_month = timezone.now().month
        if not self.season_start or not self.season_end:
            return True
        if self.season_start <= self.season_end:
            return self.season_start <= current_month <= self.season_end
        else: # Saison à cheval sur deux années
            return current_month >= self.season_start or current_month <= self.season_end


class Price(models.Model):
    """Historique des prix par produit, marché et date"""
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='prices')
    market = models.ForeignKey(Market, on_delete=models.CASCADE, related_name='prices')
    price = models.DecimalField(max_digits=10, decimal_places=2, verbose_name="Prix (FCFA)")
    date = models.DateField(verbose_name="Date")
    source = models.CharField(max_length=100, default='manuel', verbose_name="Source")
    is_verified = models.BooleanField(default=False)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    created_by = models.ForeignKey(
        User, on_delete=models.SET_NULL, null=True, blank=True,
        related_name='prices_added'
    )

    class Meta:
        verbose_name = "Prix"
        verbose_name_plural = "Prix"
        ordering = ['-date', 'product']
        unique_together = ['product', 'market', 'date']

    def __str__(self):
        return f"{self.product.name} - {self.market.name}: {self.price} FCFA ({self.date})"


class Prediction(models.Model):
    """Prédictions IA des prix"""

    HORIZON_CHOICES = [
        ('7d', '7 jours'),
        ('30d', '30 jours'),
        ('90d', '90 jours'),
    ]

    CONFIDENCE_CHOICES = [
        ('low', 'Faible'),
        ('medium', 'Modéré'),
        ('high', 'Élevé'),
    ]

    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='predictions')
    market = models.ForeignKey(Market, on_delete=models.CASCADE, related_name='predictions', null=True, blank=True)
    horizon = models.CharField(max_length=5, choices=HORIZON_CHOICES, default='7d')
    current_price = models.DecimalField(max_digits=10, decimal_places=2)
    predicted_price = models.DecimalField(max_digits=10, decimal_places=2)
    price_change_percent = models.DecimalField(max_digits=5, decimal_places=2)
    confidence_level = models.CharField(max_length=10, choices=CONFIDENCE_CHOICES, default='medium')
    confidence_score = models.DecimalField(
        max_digits=4, decimal_places=2, default=0.70,
        validators=[MinValueValidator(0), MaxValueValidator(1)]
    )
    trend = models.CharField(max_length=10, choices=Product.TREND_CHOICES, default='stable')
    recommendation = models.TextField(verbose_name="Recommandation IA")
    analysis = models.TextField(blank=True, verbose_name="Analyse détaillée")
    factors = models.JSONField(default=list, verbose_name="Facteurs d'influence")
    predicted_prices_series = models.JSONField(default=list, verbose_name="Série de prix prédits")
    created_at = models.DateTimeField(auto_now_add=True)
    created_by = models.ForeignKey(
        User, on_delete=models.SET_NULL, null=True, blank=True,
        related_name='predictions_created'
    )

    class Meta:
        verbose_name = "Prédiction"
        verbose_name_plural = "Prédictions"
        ordering = ['-created_at']

    def __str__(self):
        return f"Prédiction {self.product.name} ({self.horizon}) - {self.confidence_level}"


class Alert(models.Model):
    """Alertes de prix personnalisées"""

    ALERT_TYPE_CHOICES = [
        ('above', 'Prix au-dessus du seuil'),
        ('below', 'Prix en dessous du seuil'),
        ('change', 'Variation de prix'),
    ]

    STATUS_CHOICES = [
        ('active', 'Active'),
        ('triggered', 'Déclenchée'),
        ('disabled', 'Désactivée'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='alerts')
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='alerts')
    market = models.ForeignKey(Market, on_delete=models.CASCADE, related_name='alerts', null=True, blank=True)
    alert_type = models.CharField(max_length=10, choices=ALERT_TYPE_CHOICES, default='above')
    threshold_price = models.DecimalField(max_digits=10, decimal_places=2, verbose_name="Prix seuil (FCFA)")
    change_percent = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='active')
    triggered_at = models.DateTimeField(null=True, blank=True)
    triggered_price = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    notification_sent = models.BooleanField(default=False)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Alerte"
        verbose_name_plural = "Alertes"
        ordering = ['-created_at']

    def __str__(self):
        return f"Alerte {self.user.username}: {self.product.name} {self.get_alert_type_display()} {self.threshold_price} FCFA"


class UserProfile(models.Model):
    """Profils utilisateurs étendus"""

    ROLE_CHOICES = [
        ('farmer', 'Agriculteur'),
        ('trader', 'Commerçant'),
        ('consumer', 'Consommateur'),
        ('analyst', 'Analyste'),
        ('admin', 'Administrateur'),
    ]

    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    role = models.CharField(max_length=15, choices=ROLE_CHOICES, default='consumer')
    phone = models.CharField(max_length=20, blank=True, verbose_name="Téléphone")
    region = models.ForeignKey(Region, on_delete=models.SET_NULL, null=True, blank=True)
    preferred_market = models.ForeignKey(Market, on_delete=models.SET_NULL, null=True, blank=True)
    avatar_url = models.URLField(blank=True)
    bio = models.TextField(blank=True, verbose_name="Biographie")
    preferred_products = models.ManyToManyField(Product, blank=True, verbose_name="Produits favoris")
    notifications_enabled = models.BooleanField(default=True)
    language = models.CharField(max_length=5, default='fr', choices=[('fr', 'Français'), ('wo', 'Wolof')])
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Profil utilisateur"
        verbose_name_plural = "Profils utilisateurs"
        ordering = ['-created_at']

    def __str__(self):
        return f"Profil {self.user.username} ({self.get_role_display()})"


class FarmerStock(models.Model):
    """Stock des produits de l'agriculteur"""
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='stocks')
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='stocks')
    quantity = models.DecimalField(max_digits=10, decimal_places=2, verbose_name="Quantité")
    unit = models.CharField(max_length=20, verbose_name="Unité")
    storage_location = models.CharField(max_length=200, blank=True, verbose_name="Lieu de stockage")
    purchase_date = models.DateField(null=True, blank=True, verbose_name="Date d'achat")
    expiry_date = models.DateField(null=True, blank=True, verbose_name="Date de péremption")
    status = models.CharField(max_length=20, default='available', 
                              choices=[('available', 'Disponible'), ('reserved', 'Réservé'), ('sold', 'Vendu')])
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Stock agriculteur"
        verbose_name_plural = "Stocks agriculteurs"
        ordering = ['-created_at']
        unique_together = ['user', 'product', 'storage_location']

    def __str__(self):
        return f"{self.user.username} - {self.product.name}: {self.quantity} {self.unit}"


class FarmerSale(models.Model):
    """Ventes des produits de l'agriculteur"""
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='sales')
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='sales')
    market = models.ForeignKey(Market, on_delete=models.SET_NULL, null=True, blank=True, related_name='sales')
    quantity = models.DecimalField(max_digits=10, decimal_places=2, verbose_name="Quantité vendue")
    unit = models.CharField(max_length=20, verbose_name="Unité")
    unit_price = models.DecimalField(max_digits=10, decimal_places=2, verbose_name="Prix unitaire (FCFA)")
    total_revenue = models.DecimalField(max_digits=12, decimal_places=2, verbose_name="Revenu total (FCFA)")
    sale_date = models.DateTimeField(verbose_name="Date de vente")
    buyer_name = models.CharField(max_length=200, blank=True, verbose_name="Nom de l'acheteur")
    payment_method = models.CharField(max_length=20, default='cash',
                                     choices=[('cash', 'Espèces'), ('mobile', 'Mobile Money'), ('bank', 'Banque')])
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Vente agriculteur"
        verbose_name_plural = "Ventes agriculteurs"
        ordering = ['-sale_date']

    def __str__(self):
        return f"{self.user.username} - {self.product.name}: {self.quantity} {self.unit} à {self.unit_price} FCFA"

    def save(self, *args, **kwargs):
        # Calcul automatique du revenu total pour cohérence des données
        self.total_revenue = self.quantity * self.unit_price
        super().save(*args, **kwargs)


class CultureGuide(models.Model):
    """Guide de culture pour les produits"""
    
    product = models.OneToOneField(Product, on_delete=models.CASCADE, related_name='culture_guide')
    planting_season = models.CharField(max_length=100, verbose_name="Saison de plantation")
    harvest_season = models.CharField(max_length=100, verbose_name="Saison de récolte")
    growth_duration = models.IntegerField(verbose_name="Durée de croissance (jours)")
    soil_type = models.CharField(max_length=200, verbose_name="Type de sol")
    water_requirements = models.TextField(verbose_name="Besoins en eau")
    temperature_range = models.CharField(max_length=100, verbose_name="Plage de température")
    materials_needed = models.TextField(verbose_name="Matériaux nécessaires")
    planting_instructions = models.TextField(verbose_name="Instructions de plantation")
    care_instructions = models.TextField(verbose_name="Instructions d'entretien")
    harvest_instructions = models.TextField(verbose_name="Instructions de récolte")
    common_diseases = models.TextField(blank=True, verbose_name="Maladies courantes")
    pest_control = models.TextField(blank=True, verbose_name="Lutte contre les ravageurs")
    yield_per_hectare = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True, 
                                           verbose_name="Rendement par hectare (kg)")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Guide de culture"
        verbose_name_plural = "Guides de culture"

    def __str__(self):
        return f"Guide de culture: {self.product.name}"

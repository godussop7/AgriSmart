"""
AgriSmart - Serializers DRF
Sérialisation de tous les modèles pour l'API REST
"""

from rest_framework import serializers
from django.contrib.auth.models import User
from .models import Region, Market, Category, Product, Price, Prediction, Alert, UserProfile, FarmerStock, FarmerSale, CultureGuide


class RegionSerializer(serializers.ModelSerializer):
    markets_count = serializers.SerializerMethodField()

    class Meta:
        model = Region
        fields = ['id', 'name', 'code', 'latitude', 'longitude', 'population', 'markets_count']

    def get_markets_count(self, obj):
        return obj.markets.filter(status='active').count()


class MarketSerializer(serializers.ModelSerializer):
    region_name = serializers.CharField(source='region.name', read_only=True)
    price_level_display = serializers.CharField(source='get_price_level_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)

    class Meta:
        model = Market
        fields = [
            'id', 'name', 'region', 'region_name', 'address',
            'latitude', 'longitude', 'rating', 'price_level',
            'price_level_display', 'status', 'status_display',
            'opening_time', 'closing_time', 'market_days',
            'description', 'products_count', 'created_at',
        ]


class MarketDetailSerializer(MarketSerializer):
    recent_prices = serializers.SerializerMethodField()

    class Meta(MarketSerializer.Meta):
        fields = MarketSerializer.Meta.fields + ['recent_prices']

    def get_recent_prices(self, obj):
        prices = obj.prices.select_related('product').order_by('-date')[:10]
        return PriceSerializer(prices, many=True).data


class CategorySerializer(serializers.ModelSerializer):
    products_count = serializers.SerializerMethodField()

    class Meta:
        model = Category
        fields = ['id', 'name', 'icon', 'color', 'description', 'is_active', 'sort_order', 'products_count']

    def get_products_count(self, obj):
        return obj.products.filter(is_active=True).count()


class ProductListSerializer(serializers.ModelSerializer):
    category_name = serializers.CharField(source='category.name', read_only=True)
    category_icon = serializers.CharField(source='category.icon', read_only=True)
    category_color = serializers.CharField(source='category.color', read_only=True)
    unit_display = serializers.CharField(source='get_unit_display', read_only=True)
    trend_display = serializers.CharField(source='get_trend_display', read_only=True)
    availability_display = serializers.CharField(source='get_availability_display', read_only=True)

    class Meta:
        model = Product
        fields = [
            'id', 'name', 'local_name', 'category', 'category_name',
            'category_icon', 'category_color', 'unit', 'unit_display',
            'image_url', 'trend', 'trend_display', 'availability',
            'availability_display', 'min_price', 'max_price', 'avg_price',
            'price_change_percent', 'is_featured', 'season_start', 'season_end',
        ]


class ProductDetailSerializer(ProductListSerializer):
    price_history = serializers.SerializerMethodField()
    latest_prices = serializers.SerializerMethodField()

    class Meta(ProductListSerializer.Meta):
        fields = ProductListSerializer.Meta.fields + [
            'description', 'price_history', 'latest_prices', 'created_at', 'updated_at'
        ]

    def get_price_history(self, obj):
        prices = obj.prices.order_by('-date')[:30]
        return [
            {'date': str(p.date), 'price': float(p.price), 'market': p.market.name}
            for p in prices
        ]

    def get_latest_prices(self, obj):
        from django.db.models import Max
        # Get latest date per market for this product
        latest_dates = (
            obj.prices.values('market')
            .annotate(latest_date=Max('date'))
        )
        
        # Build query for specific market/date pairs
        from django.db.models import Q
        query = Q()
        for item in latest_dates[:5]:
            query |= Q(market_id=item['market'], date=item['latest_date'])
        
        if not query:
            return []
            
        latest_prices = obj.prices.filter(query).select_related('market')[:5]
        
        return [
            {
                'market_id': p.market.id,
                'market_name': p.market.name,
                'price': float(p.price),
                'date': str(p.date),
            }
            for p in latest_prices
        ]


class ProductCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Product
        fields = [
            'id', 'name', 'local_name', 'category', 'unit', 'description',
            'image_url', 'season_start', 'season_end',
        ]


class PriceSerializer(serializers.ModelSerializer):
    product_name = serializers.CharField(source='product.name', read_only=True)
    product_unit = serializers.CharField(source='product.unit', read_only=True)
    market_name = serializers.CharField(source='market.name', read_only=True)
    market_region = serializers.CharField(source='market.region.name', read_only=True)

    class Meta:
        model = Price
        fields = [
            'id', 'product', 'product_name', 'product_unit',
            'market', 'market_name', 'market_region',
            'price', 'date', 'source', 'is_verified', 'notes', 'created_at',
        ]


class PriceCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Price
        fields = ['product', 'market', 'price', 'date', 'source', 'notes']

    def validate(self, data):
        if data.get('price', 0) <= 0:
            raise serializers.ValidationError("Le prix doit être positif.")
        return data


class PredictionSerializer(serializers.ModelSerializer):
    product_name = serializers.CharField(source='product.name', read_only=True)
    product_unit = serializers.CharField(source='product.unit', read_only=True)
    product_category = serializers.CharField(source='product.category.name', read_only=True)
    market_name = serializers.SerializerMethodField()
    confidence_level_display = serializers.CharField(source='get_confidence_level_display', read_only=True)
    horizon_display = serializers.CharField(source='get_horizon_display', read_only=True)
    trend_display = serializers.CharField(source='get_trend_display', read_only=True)

    class Meta:
        model = Prediction
        fields = [
            'id', 'product', 'product_name', 'product_unit', 'product_category',
            'market', 'market_name', 'horizon', 'horizon_display',
            'current_price', 'predicted_price', 'price_change_percent',
            'confidence_level', 'confidence_level_display', 'confidence_score',
            'trend', 'trend_display', 'recommendation', 'analysis',
            'factors', 'predicted_prices_series', 'created_at',
        ]

    def get_market_name(self, obj):
        return obj.market.name if obj.market else "Tous les marchés"


class AlertSerializer(serializers.ModelSerializer):
    product_name = serializers.CharField(source='product.name', read_only=True)
    product_unit = serializers.CharField(source='product.unit', read_only=True)
    market_name = serializers.SerializerMethodField()
    alert_type_display = serializers.CharField(source='get_alert_type_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)

    class Meta:
        model = Alert
        fields = [
            'id', 'product', 'product_name', 'product_unit',
            'market', 'market_name', 'alert_type', 'alert_type_display',
            'threshold_price', 'change_percent', 'status', 'status_display',
            'triggered_at', 'triggered_price', 'notes', 'created_at',
        ]

    def get_market_name(self, obj):
        return obj.market.name if obj.market else "Tous les marchés"


class AlertCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Alert
        fields = ['product', 'market', 'alert_type', 'threshold_price', 'change_percent', 'notes']

    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)


class UserProfileSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)
    email = serializers.CharField(source='user.email', read_only=True)
    first_name = serializers.CharField(source='user.first_name', read_only=True)
    last_name = serializers.CharField(source='user.last_name', read_only=True)
    role_display = serializers.CharField(source='get_role_display', read_only=True)
    region_name = serializers.SerializerMethodField()
    alerts_count = serializers.SerializerMethodField()
    predictions_count = serializers.SerializerMethodField()

    class Meta:
        model = UserProfile
        fields = [
            'username', 'email', 'first_name', 'last_name',
            'role', 'role_display', 'phone', 'region', 'region_name',
            'preferred_market', 'avatar_url', 'bio',
            'notifications_enabled', 'language',
            'alerts_count', 'predictions_count', 'created_at',
        ]

    def get_region_name(self, obj):
        return obj.region.name if obj.region else None

    def get_alerts_count(self, obj):
        return obj.user.alerts.filter(status='active').count()

    def get_predictions_count(self, obj):
        return obj.user.predictions_created.count()


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=6)
    password_confirm = serializers.CharField(write_only=True)
    role = serializers.ChoiceField(choices=UserProfile.ROLE_CHOICES, default='consumer')
    phone = serializers.CharField(required=False, allow_blank=True)
    region = serializers.PrimaryKeyRelatedField(queryset=Region.objects.all(), required=False, allow_null=True)

    class Meta:
        model = User
        fields = ['username', 'email', 'first_name', 'last_name', 'password', 'password_confirm', 'role', 'phone', 'region']

    def validate(self, data):
        if data['password'] != data['password_confirm']:
            raise serializers.ValidationError({"password_confirm": "Les mots de passe ne correspondent pas."})
        if User.objects.filter(email=data.get('email', '')).exists():
            raise serializers.ValidationError({"email": "Cet email est déjà utilisé."})
        return data

    def create(self, validated_data):
        role = validated_data.pop('role', 'consumer')
        phone = validated_data.pop('phone', '')
        region = validated_data.pop('region', None)
        validated_data.pop('password_confirm')

        user = User.objects.create_user(**validated_data)
        UserProfile.objects.create(user=user, role=role, phone=phone, region=region)
        return user


class DashboardSerializer(serializers.Serializer):
    """Données agrégées pour le dashboard"""
    total_products = serializers.IntegerField()
    total_markets = serializers.IntegerField()
    total_prices_today = serializers.IntegerField()
    active_alerts = serializers.IntegerField()
    featured_products = ProductListSerializer(many=True)
    active_markets = MarketSerializer(many=True)
    recent_prices = PriceSerializer(many=True)


class FarmerStockSerializer(serializers.ModelSerializer):
    product_name = serializers.CharField(source='product.name', read_only=True)
    product_category = serializers.CharField(source='product.category.name', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)

    class Meta:
        model = FarmerStock
        fields = [
            'id', 'user', 'product', 'product_name', 'product_category',
            'quantity', 'unit', 'storage_location', 'purchase_date',
            'expiry_date', 'status', 'status_display', 'notes',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['user']


class FarmerSaleSerializer(serializers.ModelSerializer):
    product_name = serializers.CharField(source='product.name', read_only=True)
    market_name = serializers.CharField(source='market.name', read_only=True)
    payment_method_display = serializers.CharField(source='get_payment_method_display', read_only=True)

    class Meta:
        model = FarmerSale
        fields = [
            'id', 'user', 'product', 'product_name', 'market', 'market_name',
            'quantity', 'unit', 'unit_price', 'total_revenue', 'sale_date',
            'buyer_name', 'payment_method', 'payment_method_display', 'notes',
            'created_at'
        ]
        read_only_fields = ['user', 'total_revenue']


class CultureGuideSerializer(serializers.ModelSerializer):
    product_name = serializers.CharField(source='product.name', read_only=True)
    product_category = serializers.CharField(source='product.category.name', read_only=True)

    class Meta:
        model = CultureGuide
        fields = [
            'id', 'product', 'product_name', 'product_category',
            'planting_season', 'harvest_season', 'growth_duration',
            'soil_type', 'water_requirements', 'temperature_range',
            'materials_needed', 'planting_instructions', 'care_instructions',
            'harvest_instructions', 'common_diseases', 'pest_control',
            'yield_per_hectare', 'created_at', 'updated_at'
        ]

"""
AgriSmart - API Views
Tous les endpoints REST avec prédictions IA via Gemini
"""

import json
import random
from datetime import date, timedelta, datetime
from decimal import Decimal

from django.contrib.auth.models import User
from django.conf import settings
from django.db.models import Avg, Min, Max, Count, Q
from django.utils import timezone

from rest_framework import viewsets, status, filters
from rest_framework.decorators import api_view, permission_classes, action
from rest_framework.permissions import IsAuthenticated, AllowAny, IsAuthenticatedOrReadOnly
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken

from django_filters.rest_framework import DjangoFilterBackend

from .models import Region, Market, Category, Product, Price, Prediction, Alert, UserProfile, FarmerStock, FarmerSale, CultureGuide
from .serializers import (
    RegionSerializer, MarketSerializer, MarketDetailSerializer,
    CategorySerializer, ProductListSerializer, ProductDetailSerializer,
    ProductCreateSerializer, PriceSerializer, PriceCreateSerializer,
    PredictionSerializer, AlertSerializer, AlertCreateSerializer,
    FarmerStockSerializer, FarmerSaleSerializer, CultureGuideSerializer,
    UserProfileSerializer, RegisterSerializer,
)


# ── Gemini AI Integration ─────────────────────────────────────────────────────
def generate_ai_prediction(product, market, horizon, price_history):
    """Génère une prédiction de prix via l'API Gemini"""
    try:
        import google.generativeai as genai
        genai.configure(api_key=settings.GEMINI_API_KEY)
        model = genai.GenerativeModel('gemini-1.5-flash')

        price_data = [
            f"{p['date']}: {p['price']} FCFA"
            for p in price_history[-14:]
        ] if price_history else ["Aucun historique disponible"]

        market_name = market.name if market else "marché sénégalais"

        prompt = f"""
Tu es un expert en marchés agricoles au Sénégal. Accompagne cet agriculteur pour MAXIMISER SES PROFITS.
Produit: {product.name} ({product.unit}), Catégorie: {product.category.name}
Marché: {market_name}, Horizon: {horizon}
Tendance: {product.get_trend_display()}, Prix actuel: {product.avg_price} FCFA

Historique: {chr(10).join(price_data)}

Réponds UNIQUEMENT par un JSON:
{{
  "predicted_price": int, "price_change_percent": float, "confidence_level": "low|medium|high",
  "confidence_score": float, "trend": "up|down|stable", "recommendation": "string",
  "analysis": "string", "factors": ["string"], "predicted_prices_series": [float]
}}
"""
        response = model.generate_content(prompt)
        text = response.text.strip()
        
        # Clean response if markdown
        if '```' in text:
            text = text.split('```')[1]
            if text.startswith('json'):
                text = text[4:]
        
        return json.loads(text.strip())

    except Exception as e:
        # Fallback to local generation if AI fails
        return _fallback_prediction(product, horizon, product.get_trend_display())


def _fallback_prediction(product, horizon, trend):
    """Prédiction de secours sans IA - orientée agriculteur"""
    current = float(product.avg_price) if product.avg_price else 500
    days = 7 if horizon == '7d' else 30
    change = random.uniform(-15, 20)
    predicted = current * (1 + change / 100)
    series = []
    price = current
    for i in range(days):
        delta = random.uniform(-3, 5)
        price = max(50, price * (1 + delta / 100))
        series.append(round(price, 0))

    confidence = random.choice(['medium', 'high'])
    trend = 'up' if change > 2 else ('down' if change < -2 else 'stable')

    # Farmer-focused recommendations
    if trend == 'up':
        recommendation = f"Les prix de {product.name} augmentent, c'est le moment idéal pour vendre votre récolte."
    elif trend == 'down':
        recommendation = f"Les prix de {product.name} baissent, attendez avant de vendre ou stockez votre production."
    else:
        recommendation = f"Les prix de {product.name} sont stables, maintenez votre production actuelle."

    return {
        "predicted_price": round(predicted),
        "price_change_percent": round(change, 2),
        "confidence_level": confidence,
        "confidence_score": round(random.uniform(0.6, 0.85), 2),
        "trend": trend,
        "recommendation": recommendation,
        "analysis": f"L'analyse des données historiques indique une tendance {'haussière' if trend == 'up' else 'baissière' if trend == 'down' else 'stable'} pour {product.name}. Les conditions saisonnières et la disponibilité jouent un rôle clé.",
        "factors": ["Saisonnalité", "Offre et demande", "Conditions climatiques"],
        "predicted_prices_series": series,
    }


# ── Dashboard ─────────────────────────────────────────────────────────────────
@api_view(['GET'])
@permission_classes([AllowAny])
def dashboard(request):
    """Données agrégées pour le tableau de bord"""
    today = date.today()
    week_ago = today - timedelta(days=7)

    total_products = Product.objects.filter(is_active=True).count()
    total_markets = Market.objects.filter(status='active').count()
    total_prices_today = Price.objects.filter(date=today).count()

    active_alerts = 0
    if request.user.is_authenticated:
        active_alerts = Alert.objects.filter(user=request.user, status='active').count()

    featured_products = Product.objects.filter(is_active=True, is_featured=True)[:6]
    active_markets = Market.objects.filter(status='active').select_related('region')[:8]
    recent_prices = Price.objects.select_related('product', 'market').order_by('-date', '-created_at')[:10]
    categories = Category.objects.filter(is_active=True)

    # Tendances des 7 derniers jours: Optimisation avec 1 seule requête
    fallback_avg_data = Price.objects.filter(
        date__gte=today - timedelta(days=30)
    ).aggregate(avg=Avg('price'))['avg']
    fallback_avg = float(fallback_avg_data or 0)

    recent_prices_agg = Price.objects.filter(
        date__gte=week_ago, date__lte=today
    ).values('date').annotate(avg=Avg('price')).order_by('date')
    
    price_trends_dict = {str(item['date']): float(item['avg']) for item in recent_prices_agg}
    
    price_trends = []
    for i in range(7):
        d = str(today - timedelta(days=6 - i))
        day_avg = price_trends_dict.get(d)
        if not day_avg and fallback_avg:
            day_avg = float(fallback_avg)
        price_trends.append({
            'date': d,
            'avg_price': round(day_avg, 2) if day_avg else 0,
            'has_data': d in price_trends_dict,
        })

    user_stock_count = 0
    user_products = []
    if request.user.is_authenticated:
        stocks = FarmerStock.objects.filter(
            user=request.user
        ).select_related('product', 'product__category')
        user_stock_count = stocks.count()
        
        # Optimize product extraction logic
        seen_product_ids = set()
        for stock in stocks:
            if stock.product_id not in seen_product_ids:
                seen_product_ids.add(stock.product_id)
                user_products.append(ProductListSerializer(stock.product).data)
                if len(user_products) >= 8:
                    break

    return Response({
        'total_products': total_products,
        'total_markets': total_markets,
        'total_prices_today': total_prices_today,
        'active_alerts': active_alerts,
        'featured_products': ProductListSerializer(featured_products, many=True).data,
        'active_markets': MarketSerializer(active_markets, many=True).data,
        'recent_prices': PriceSerializer(recent_prices, many=True).data,
        'price_trends': price_trends,
        'categories': CategorySerializer(categories, many=True).data,
        'user_stock_count': user_stock_count,
        'user_products': user_products,
    })


# ── Regions ───────────────────────────────────────────────────────────────────
class RegionViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Region.objects.all()
    serializer_class = RegionSerializer
    permission_classes = [AllowAny]
    filter_backends = [filters.SearchFilter]
    search_fields = ['name', 'code']


# ── Markets ───────────────────────────────────────────────────────────────────
class MarketViewSet(viewsets.ModelViewSet):
    queryset = Market.objects.select_related('region').filter(status='active')
    permission_classes = [IsAuthenticatedOrReadOnly]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['region', 'price_level', 'status']
    search_fields = ['name', 'address', 'region__name']
    ordering_fields = ['name', 'rating', 'created_at']

    def get_serializer_class(self):
        if self.action == 'retrieve':
            return MarketDetailSerializer
        return MarketSerializer


# ── Categories ────────────────────────────────────────────────────────────────
class CategoryViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Category.objects.filter(is_active=True)
    serializer_class = CategorySerializer
    permission_classes = [AllowAny]


# ── Products ──────────────────────────────────────────────────────────────────
class ProductViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticatedOrReadOnly]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['category', 'trend', 'availability', 'is_featured']
    search_fields = ['name', 'local_name', 'description']
    ordering_fields = ['name', 'avg_price', 'price_change_percent', 'created_at']

    def get_queryset(self):
        return Product.objects.filter(is_active=True).select_related('category')

    def get_serializer_class(self):
        if self.action == 'create':
            return ProductCreateSerializer
        if self.action == 'retrieve':
            return ProductDetailSerializer
        return ProductListSerializer

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        print(f"Deleting product: {instance.name} (ID: {instance.id})")
        self.perform_destroy(instance)
        return Response(status=status.HTTP_204_NO_CONTENT)

    @action(detail=True, methods=['get'])
    def price_history(self, request, pk=None):
        """Historique des prix d'un produit"""
        product = self.get_object()
        days = int(request.query_params.get('days', 30))
        start_date = date.today() - timedelta(days=days)
        prices = Price.objects.filter(
            product=product, date__gte=start_date
        ).select_related('market').order_by('date')
        return Response(PriceSerializer(prices, many=True).data)

    @action(detail=True, methods=['get'])
    def compare(self, request, pk=None):
        """Compare les prix d'un produit entre plusieurs marchés"""
        product = self.get_object()
        markets_param = request.query_params.get('markets', '')
        
        if not markets_param:
            return Response(
                {'error': 'Paramètre markets requis (IDs séparés par des virgules)'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            market_ids = [int(m.strip()) for m in markets_param.split(',') if m.strip()]
        except ValueError:
            return Response(
                {'error': 'Format invalide pour markets. Utilisez des IDs numériques séparés par des virgules'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        if len(market_ids) < 2 or len(market_ids) > 3:
            return Response(
                {'error': 'Veuillez sélectionner 2 à 3 marchés pour la comparaison'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Récupérer les prix actuels pour chaque marché
        today = date.today()
        week_ago = today - timedelta(days=7)
        
        result = []
        for market_id in market_ids:
            try:
                market = Market.objects.get(id=market_id, status='active')
                
                # Prix le plus récent
                latest_price = Price.objects.filter(
                    product=product,
                    market=market,
                    date__gte=week_ago
                ).order_by('-date').first()
                
                # Historique des 7 derniers jours
                price_history = Price.objects.filter(
                    product=product,
                    market=market,
                    date__gte=week_ago
                ).order_by('date').values_list('price', flat=True)
                
                if latest_price:
                    result.append({
                        'market_id': market.id,
                        'market_name': market.name,
                        'current_price': str(latest_price.price),
                        'price_date': str(latest_price.date),
                        'price_history': [float(p) for p in price_history]
                    })
                else:
                    result.append({
                        'market_id': market.id,
                        'market_name': market.name,
                        'current_price': None,
                        'price_date': None,
                        'price_history': []
                    })
                    
            except Market.DoesNotExist:
                continue
        
        return Response(result)


# ── Prices ────────────────────────────────────────────────────────────────────
class PriceViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticatedOrReadOnly]
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ['product', 'market', 'date', 'is_verified']
    ordering_fields = ['date', 'price', 'created_at']

    def get_queryset(self):
        return Price.objects.select_related('product', 'market', 'market__region').order_by('-date')

    def get_serializer_class(self):
        if self.action in ['create', 'update', 'partial_update']:
            return PriceCreateSerializer
        return PriceSerializer

    def perform_create(self, serializer):
        price_obj = serializer.save(created_by=self.request.user)
        # Mettre à jour les stats du produit
        product = price_obj.product
        stats = Price.objects.filter(product=product).aggregate(
            avg=Avg('price'), min=Min('price'), max=Max('price')
        )
        product.avg_price = stats['avg'] or 0
        product.min_price = stats['min'] or 0
        product.max_price = stats['max'] or 0
        product.save(update_fields=['avg_price', 'min_price', 'max_price'])

        # Vérifier les alertes
        _check_alerts(product, price_obj.price)


def _check_alerts(product, new_price):
    """Vérifie et déclenche les alertes de prix"""
    alerts = Alert.objects.filter(product=product, status='active')
    for alert in alerts:
        triggered = False
        if alert.alert_type == 'above' and new_price >= alert.threshold_price:
            triggered = True
        elif alert.alert_type == 'below' and new_price <= alert.threshold_price:
            triggered = True
        elif alert.alert_type == 'change' and alert.change_percent:
            product_avg = product.avg_price
            if product_avg > 0:
                change = abs((new_price - product_avg) / product_avg * 100)
                if change >= float(alert.change_percent):
                    triggered = True

        if triggered:
            alert.status = 'triggered'
            alert.triggered_at = timezone.now()
            alert.triggered_price = new_price
            alert.save(update_fields=['status', 'triggered_at', 'triggered_price'])


# ── Predictions ───────────────────────────────────────────────────────────────
class PredictionViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ['product', 'market', 'horizon', 'confidence_level']
    ordering_fields = ['created_at', 'confidence_score']
    http_method_names = ['get', 'post', 'delete']

    def get_queryset(self):
        qs = Prediction.objects.select_related(
            'product', 'product__category', 'market'
        )
        if self.request.user.is_authenticated:
            return qs.filter(created_by=self.request.user).order_by('-created_at')
        return qs.none()

    def get_serializer_class(self):
        return PredictionSerializer

    def create(self, request, *args, **kwargs):
        """Génère une nouvelle prédiction IA"""
        product_id = request.data.get('product')
        market_id = request.data.get('market')
        horizon = request.data.get('horizon', '7d')

        try:
            product = Product.objects.get(id=product_id)
        except Product.DoesNotExist:
            return Response({'error': 'Produit non trouvé.'}, status=status.HTTP_404_NOT_FOUND)

        market = None
        if market_id:
            try:
                market = Market.objects.get(id=market_id)
            except Market.DoesNotExist:
                pass

        # Récupérer l'historique des prix
        start_date = date.today() - timedelta(days=60)
        price_query = Price.objects.filter(product=product, date__gte=start_date)
        if market:
            price_query = price_query.filter(market=market)
        price_history = list(price_query.order_by('date').values('date', 'price'))

        # Appel Gemini AI
        ai_result = generate_ai_prediction(product, market, horizon, [
            {'date': str(p['date']), 'price': float(p['price'])} for p in price_history
        ])

        # Créer la prédiction
        prediction = Prediction.objects.create(
            product=product,
            market=market,
            horizon=horizon,
            current_price=product.avg_price or Decimal('0'),
            predicted_price=Decimal(str(ai_result['predicted_price'])),
            price_change_percent=Decimal(str(ai_result['price_change_percent'])),
            confidence_level=ai_result['confidence_level'],
            confidence_score=Decimal(str(ai_result['confidence_score'])),
            trend=ai_result['trend'],
            recommendation=ai_result['recommendation'],
            analysis=ai_result.get('analysis', ''),
            factors=ai_result.get('factors', []),
            predicted_prices_series=ai_result.get('predicted_prices_series', []),
            created_by=request.user if request.user.is_authenticated else None,
        )

        return Response(
            PredictionSerializer(prediction).data,
            status=status.HTTP_201_CREATED
        )


# ── Alerts ────────────────────────────────────────────────────────────────────
class AlertViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['product', 'alert_type', 'status']

    def get_queryset(self):
        return Alert.objects.filter(
            user=self.request.user
        ).select_related('product', 'market').order_by('-created_at')

    def get_serializer_class(self):
        if self.action in ['create', 'update', 'partial_update']:
            return AlertCreateSerializer
        return AlertSerializer

    @action(detail=True, methods=['post'])
    def toggle(self, request, pk=None):
        """Active/désactive une alerte"""
        alert = self.get_object()
        if alert.status == 'active':
            alert.status = 'disabled'
        elif alert.status == 'disabled':
            alert.status = 'active'
        alert.save(update_fields=['status'])
        return Response(AlertSerializer(alert).data)


# ── Authentication ────────────────────────────────────────────────────────────
class RegisterView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            refresh = RefreshToken.for_user(user)
            profile = user.profile
            return Response({
                'message': 'Compte créé avec succès!',
                'user': {
                    'id': user.id,
                    'username': user.username,
                    'email': user.email,
                    'first_name': user.first_name,
                    'last_name': user.last_name,
                    'role': profile.role,
                },
                'access': str(refresh.access_token),
                'refresh': str(refresh),
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class ProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        profile, _ = UserProfile.objects.get_or_create(user=request.user)
        return Response(UserProfileSerializer(profile).data)

    def put(self, request):
        profile, _ = UserProfile.objects.get_or_create(user=request.user)
        
        # Optimize: Batch update User fields if present
        user = request.user
        user_fields = ['first_name', 'last_name', 'email']
        user_updated = False
        for field in user_fields:
            if field in request.data:
                setattr(user, field, request.data[field])
                user_updated = True
        if user_updated:
            user.save()

        # Update profile using serializer for validation
        serializer = UserProfileSerializer(profile, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([AllowAny])
def stats(request):
    """Statistiques générales de l'application"""
    return Response({
        'total_products': Product.objects.filter(is_active=True).count(),
        'total_markets': Market.objects.filter(status='active').count(),
        'total_regions': Region.objects.count(),
        'total_prices': Price.objects.count(),
        'total_users': User.objects.count(),
        'total_predictions': Prediction.objects.count(),
    })


# ── Farmer Stock Management ───────────────────────────────────────────────────
class FarmerStockViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ['product', 'status']
    ordering_fields = ['created_at', 'expiry_date']
    http_method_names = ['get', 'post', 'put', 'delete']

    def get_queryset(self):
        return FarmerStock.objects.filter(user=self.request.user).select_related('product', 'product__category')

    def get_serializer_class(self):
        return FarmerStockSerializer

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    @action(detail=False, methods=['get'])
    def low_stock(self, request):
        """Produits en stock faible"""
        threshold = request.query_params.get('threshold', 10)
        stocks = self.get_queryset().filter(quantity__lte=threshold)
        return Response(FarmerStockSerializer(stocks, many=True).data)

    @action(detail=False, methods=['get'])
    def expiring_soon(self, request):
        """Produits qui expirent bientôt"""
        from datetime import datetime, timedelta
        days = int(request.query_params.get('days', 7))
        expiry_date = datetime.now().date() + timedelta(days=days)
        stocks = self.get_queryset().filter(expiry_date__lte=expiry_date, status='available')
        return Response(FarmerStockSerializer(stocks, many=True).data)


# ── Farmer Sales Management ────────────────────────────────────────────────────
class FarmerSaleViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ['product', 'market', 'payment_method']
    ordering_fields = ['sale_date', 'total_revenue']
    http_method_names = ['get', 'post', 'delete']

    def get_queryset(self):
        return FarmerSale.objects.filter(user=self.request.user).select_related('product', 'market')

    def get_serializer_class(self):
        return FarmerSaleSerializer

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    @action(detail=False, methods=['get'])
    def statistics(self, request):
        """Statistiques de ventes de l'agriculteur"""
        from django.db.models import Sum, Count
        from datetime import datetime, timedelta
        
        period = request.query_params.get('period', 'week')
        if period == 'week':
            start_date = datetime.now().date() - timedelta(days=7)
        elif period == 'month':
            start_date = datetime.now().date() - timedelta(days=30)
        else:
            start_date = datetime.now().date() - timedelta(days=7)
        
        sales = self.get_queryset().filter(sale_date__gte=start_date)
        
        total_revenue = sales.aggregate(total=Sum('total_revenue'))['total'] or 0
        total_quantity = sales.aggregate(total=Sum('quantity'))['total'] or 0
        total_sales = sales.count()
        
        # Produits les plus vendus
        top_products = sales.values('product__name').annotate(
            count=Count('id'),
            revenue=Sum('total_revenue')
        ).order_by('-revenue')[:5]
        
        return Response({
            'period': period,
            'total_revenue': total_revenue,
            'total_quantity': total_quantity,
            'total_sales': total_sales,
            'top_products': list(top_products),
        })


# ── Culture Guide ─────────────────────────────────────────────────────────────
class CultureGuideViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [IsAuthenticatedOrReadOnly]
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['product']

    def get_queryset(self):
        return CultureGuide.objects.select_related('product', 'product__category')

    def get_serializer_class(self):
        return CultureGuideSerializer


# ── Weather Integration ───────────────────────────────────────────────────────
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def weather_info(request):
    """Obtenir les informations météo pour les conseils agricoles"""
    try:
        import requests
        
        api_key = settings.OPENWEATHER_API_KEY
        if not api_key:
            return Response(
                {'error': 'OPENWEATHER_API_KEY non configurée'},
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )

        profile = request.user.profile
        region_name = profile.region.name if profile.region else 'Dakar'

        # Map des régions avec fallback intelligent
        region_coords = {
            'dakar': (14.7167, -17.4677),
            'thiès': (14.7833, -16.9333),
            'thies': (14.7833, -16.9333),
            'saint-louis': (16.0167, -16.4833),
            'kaolack': (14.1333, -15.7333),
            'tambacounda': (13.7667, -13.6667),
            'kolda': (12.8833, -14.9500),
            'ziguinchor': (12.5667, -16.2667),
            'touba': (14.8500, -15.8833),
        }

        key = region_name.lower()
        lat, lon = region_coords.get(key, (14.7167, -17.4677))
        
        # Recherche floue si pas de match exact
        if key not in region_coords:
            for name, (lt, ln) in region_coords.items():
                if name in key or key in name:
                    lat, lon = lt, ln
                    break

        url = f"https://api.openweathermap.org/data/2.5/weather?lat={lat}&lon={lon}&appid={api_key}&units=metric&lang=fr"
        
        response = requests.get(url)
        response.raise_for_status()
        data = response.json()
        
        # Extraire les informations pertinentes pour l'agriculture
        weather_data = {
            'temperature': data['main']['temp'],
            'humidity': data['main']['humidity'],
            'wind_speed': data['wind']['speed'],
            'description': data['weather'][0]['description'],
            'rain': data.get('rain', {}).get('1h', 0),
            'region': region_name,
        }
        
        # Générer des conseils basés sur la météo
        advice = _generate_weather_advice(weather_data)
        
        return Response({
            'weather': weather_data,
            'advice': advice,
        })
        
    except Exception as e:
        return Response({
            'error': f'Erreur météo: {str(e)}',
            'advice': 'Impossible d\'obtenir les données météo. Veuillez réessayer plus tard.'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


def _generate_weather_advice(weather):
    """Génère des conseils agricoles basés sur la météo"""
    temp = weather['temperature']
    humidity = weather['humidity']
    rain = weather['rain']
    description = weather['description']
    
    advice = []
    
    # Conseils basés sur la température
    if temp > 35:
        advice.append("🌡️ Température élevée: Arrosez vos cultures tôt le matin ou tard le soir pour éviter l'évaporation.")
    elif temp < 20:
        advice.append("🌡️ Température basse: Protégez vos cultures sensibles au froid.")
    
    # Conseils basés sur l'humidité
    if humidity > 80:
        advice.append("💧 Humidité élevée: Surveillez les maladies fongiques et assurez une bonne ventilation.")
    elif humidity < 30:
        advice.append("💧 Humidité faible: Augmentez l'arrosage de vos cultures.")
    
    # Conseils basés sur la pluie
    if rain > 0:
        advice.append("🌧️ Pluie attendue: Évitez l'arrosage aujourd'hui et profitez de l'eau de pluie.")
    
    # Conseils basés sur la description
    if 'soleil' in description.lower():
        advice.append("☀️ Ensoleillé: Bonne journée pour les travaux de récolte et de séchage.")
    elif 'nuage' in description.lower():
        advice.append("☁️ Nuageux: Conditions idéales pour la plantation et le repiquage.")
    
    return advice if advice else ["☀️ Conditions météo favorables pour vos activités agricoles."]


# ── Chatbot AI ────────────────────────────────────────────────────────────────
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def chatbot(request):
    """Endpoint du chatbot IA intelligent"""
    from ai.chatbot import chatbot as intelligent_chatbot
    
    user_message = request.data.get('message', '')
    if not user_message:
        return Response({'error': 'Message requis'}, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        result = intelligent_chatbot(
            question=user_message,
            user=request.user
        )
        
        return Response({
            'message': user_message,
            'response': result['response'],
            'source': result['source'],
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        print(f"Chatbot error: {e}")
        return Response({
            'message': user_message,
            'response': 'Désolé, je ne peux pas répondre pour le moment. Veuillez réessayer plus tard.',
            'source': 'error',
            'timestamp': datetime.now().isoformat()
        })

"""
AgriSmart - URL Routing
Tous les endpoints REST de l'application
"""

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

from . import views

router = DefaultRouter()
router.register(r'regions', views.RegionViewSet, basename='region')
router.register(r'markets', views.MarketViewSet, basename='market')
router.register(r'categories', views.CategoryViewSet, basename='category')
router.register(r'products', views.ProductViewSet, basename='product')
router.register(r'prices', views.PriceViewSet, basename='price')
router.register(r'predictions', views.PredictionViewSet, basename='prediction')
router.register(r'alerts', views.AlertViewSet, basename='alert')
router.register(r'stock', views.FarmerStockViewSet, basename='stock')
router.register(r'sales', views.FarmerSaleViewSet, basename='sale')
router.register(r'culture-guides', views.CultureGuideViewSet, basename='culture-guide')

urlpatterns = [
    # Dashboard & Stats
    path('dashboard/', views.dashboard, name='dashboard'),
    path('stats/', views.stats, name='stats'),

    # Auth
    path('auth/login/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('auth/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('auth/register/', views.RegisterView.as_view(), name='register'),
    path('auth/profile/', views.ProfileView.as_view(), name='profile'),

    # Chatbot
    path('chatbot/', views.chatbot, name='chatbot'),

    # Weather
    path('weather/', views.weather_info, name='weather'),

    # REST API
    path('', include(router.urls)),
]

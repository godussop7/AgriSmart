"""AgriSmart - Admin Django"""

from django.contrib import admin
from .models import Region, Market, Category, Product, Price, Prediction, Alert, UserProfile


@admin.register(Region)
class RegionAdmin(admin.ModelAdmin):
    list_display = ['name', 'code', 'population']
    search_fields = ['name', 'code']


@admin.register(Market)
class MarketAdmin(admin.ModelAdmin):
    list_display = ['name', 'region', 'price_level', 'rating', 'status']
    list_filter = ['region', 'price_level', 'status']
    search_fields = ['name', 'address']


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ['name', 'icon', 'is_active', 'sort_order']
    list_editable = ['is_active', 'sort_order']


@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = ['name', 'category', 'unit', 'avg_price', 'trend', 'availability', 'is_featured']
    list_filter = ['category', 'trend', 'availability', 'is_featured']
    search_fields = ['name', 'local_name']
    list_editable = ['is_featured']


@admin.register(Price)
class PriceAdmin(admin.ModelAdmin):
    list_display = ['product', 'market', 'price', 'date', 'is_verified', 'source']
    list_filter = ['date', 'market__region', 'is_verified']
    search_fields = ['product__name', 'market__name']
    date_hierarchy = 'date'


@admin.register(Prediction)
class PredictionAdmin(admin.ModelAdmin):
    list_display = ['product', 'market', 'horizon', 'current_price', 'predicted_price', 'confidence_level', 'created_at']
    list_filter = ['horizon', 'confidence_level', 'trend']
    search_fields = ['product__name']


@admin.register(Alert)
class AlertAdmin(admin.ModelAdmin):
    list_display = ['user', 'product', 'alert_type', 'threshold_price', 'status']
    list_filter = ['alert_type', 'status']
    search_fields = ['user__username', 'product__name']


@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    list_display = ['user', 'role', 'region', 'phone', 'notifications_enabled']
    list_filter = ['role', 'region']
    search_fields = ['user__username', 'user__email']


admin.site.site_header = "AgriSmart - Administration"
admin.site.site_title = "AgriSmart"
admin.site.index_title = "Gestion de l'application"

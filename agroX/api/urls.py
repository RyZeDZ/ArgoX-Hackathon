from django.contrib import admin
from django.urls import path,include
from .views import predict_hybrid,predict_single,ranks,search_plants
urlpatterns = [
  path('predict/',predict_hybrid,name='predict_hybrid'),
  path('predict-single/',predict_single,name='predict_single'),
  path('ranks/',ranks,name = "ranks"),
  path('search-plants/', search_plants, name='search_plants'),
]
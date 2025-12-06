from rest_framework.decorators import api_view
from rest_framework.response import Response
import os,sys
sys.path.append("F:\ArgoX-Hackathon\model")
from backend import AgroX_Intelligence
from .services import search_plants_service


@api_view(['POST'])
def predict_hybrid(request):
    # 1. Get data from React
    plant_a = request.data.get('plant_a')
    plant_b = request.data.get('plant_b')
    model = AgroX_Intelligence()
    result = model.analyze_pair(plant_a, plant_b)
    return Response(result)
@api_view(['POST'])
def predict_single(request):
    # 1. Get data from React
    plant = request.data.get('plant')
    model = AgroX_Intelligence()
    result = model.find_best_match(plant)
    return Response(result)
@api_view(['GET'])
def ranks(request):
    model =AgroX_Intelligence()
    result = model.get_top_hybrids()
    return Response(result)
@api_view(['POST'])
def search_plants(request):
    """
    Receives JSON: { "query": "mallow" }
    Returns JSON: [ 
        { 
          "display_name": "shrubby Indian mallow (Abutilon)", 
          "common_name": "shrubby Indian mallow", 
          "genus": "Abutilon" 
        }, ... 
    ]
    """
    query = request.data.get('query', '')
    
    # 1. Use your service to find matches
    results = search_plants_service(query)
    
    # 2. Return list (DRF automatically serializes lists/dicts to JSON)
    return Response(results)
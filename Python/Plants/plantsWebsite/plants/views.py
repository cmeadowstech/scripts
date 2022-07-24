from django.shortcuts import render
from django.http import HttpResponse

def index(request):
    name = request.GET.get('name') or 'world'
    return HttpResponse("Hello, {}!",name)

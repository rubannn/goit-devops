from django.db import DatabaseError, connection
from django.http import JsonResponse


def home(request):
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            cursor.fetchone()
    except DatabaseError:
        return JsonResponse({"status": "error", "database": "unavailable"}, status=503)

    return JsonResponse({"status": "ok", "app": "Django", "database": "PostgreSQL"})

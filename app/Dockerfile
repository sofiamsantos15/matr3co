FROM python:3.9

WORKDIR /app

COPY requirements.txt requirements.txt

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

#CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:8000", "wsgi:app"]
# Variáveis de ambiente para Flask
ENV FLASK_APP=wsgi.py
ENV FLASK_ENV=development

# Executar por padrão o servidor Flask
CMD ["flask", "run", "--host=0.0.0.0", "--port=8000"]
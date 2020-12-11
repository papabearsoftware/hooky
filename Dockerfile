FROM python:3.9

ENV PIP_DISABLE_PIP_VERSION_CHECK=on

RUN pip install poetry

WORKDIR /app
COPY ./app /app/app
COPY .env pyproject.toml poetry.lock main.py /app/

RUN poetry config virtualenvs.create false
RUN poetry install --no-interaction

EXPOSE 5000

CMD ["gunicorn", \
    "--workers=2", \
    "--worker-class=gevent", \
    "--threads=4", \
    "--bind=0.0.0.0:5000", \
    "--timeout=15", \
    "--forwarded-allow-ips=*", \
    "main:app"]

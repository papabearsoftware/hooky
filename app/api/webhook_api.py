from uuid import UUID

from flask import Blueprint, request
from injector import inject
from pydantic import ValidationError

from app.schemas.webhook_schema import WebhookCreate
from app.services.webhook_service import WebhookService
from app.util.config import settings
from app.util.exception import BadRequestException

webhook_api = Blueprint('webhook_api', 'webhook_api', url_prefix=f'{settings.API_V1_STR}/webhook')


@webhook_api.route('/', methods=['POST'])
@inject
def add_webhook(webhook_service: WebhookService):
	try:
		webhook_create = WebhookCreate(**request.json)
	except ValidationError as e:
		raise BadRequestException(e.errors())
	return webhook_service.create_webhook_job(webhook_create).json(), 201


@webhook_api.route('/<id>', methods=['GET'])
@inject
def get_webhook(webhook_service: WebhookService, id: UUID):
	webhook_get = webhook_service.get_webhook(id)
	return webhook_get.json()

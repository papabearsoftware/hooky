from flask import Blueprint
from app.util.config import settings

healthcheck_api = Blueprint('healthcheck_api', 'healthcheck_api', url_prefix=f'{settings.API_V1_STR}/healthcheck')

@healthcheck_api.route('', methods=['GET'])
def healthcheck():
	return {"API": "Alive"}, 200

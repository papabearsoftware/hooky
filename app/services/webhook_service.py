import logging
import random
import traceback
from datetime import datetime
from uuid import UUID

import requests
from sqlalchemy.orm.exc import NoResultFound

from app.model.webhook_model import Webhook, StatusEnum
from app.schemas.webhook_schema import WebhookCreate, HttpMethodEnum, WebhookGet, Header, WebhookCreateResponse
from app.util.config import settings
from app.util.exception import ResourceNotFoundException, ApiException
from app.util.session import SessionLocal

logging.basicConfig(encoding='utf-8', level=logging.DEBUG)


class WebhookService:

	def create_webhook_job(self, webhook_create: WebhookCreate):
		session = SessionLocal()
		try:
			flattened_headers = [f"{header.key}:{header.value}" for header in webhook_create.headers]
			flattened_query_params = [f"{header.key}:{header.value}" for header in webhook_create.queryParams]
			joined_headers = ";".join(flattened_headers)
			joined_query_params = ";".join(flattened_query_params)

			webhook = Webhook(status=StatusEnum.READY,
							  url=webhook_create.url,
							  http_method=HttpMethodEnum[webhook_create.httpMethod],
							  headers=joined_headers,
							  query_params=joined_query_params,
							  body=webhook_create.body)

			session.add(webhook)
			session.commit()

			return WebhookCreateResponse(id=webhook.id, status=webhook.status, createdAt=webhook.created_at)
		except Exception as e:
			session.rollback()
			raise ApiException(500, "Error while creating webhook")
		finally:
			session.close()

	def get_webhook(self, id: UUID):

		try:
			webhook = SessionLocal().query(Webhook).filter(Webhook.id == id).one()
		except NoResultFound:
			raise ResourceNotFoundException("Webhook not found")

		if webhook:
			headers = []
			for header_list in webhook.headers.split(";"):
				for header_split in header_list.split(":"):
					headers.append(Header(key=header_split[0], value=header_split[1]))

			query_params = []
			for param_list in webhook.query_params.split(";"):
				for param_split in param_list.split(":"):
					query_params.append(Header(key=param_split[0], value=param_split[1]))

			return WebhookGet(id=webhook.id, status=webhook.status, url=webhook.url,
							  httpMethod=webhook.http_method, body=webhook.body, headers=headers,
							  queryParams=query_params, runCount=webhook.run_count,
							  createdAt=webhook.created_at, updatedAt=webhook.updated_at)
		else:
			raise ResourceNotFoundException("Webhook does not exist")

	def process_ready_webhooks(self):
		logging.info("Starting run_next_available_webhook")
		session = SessionLocal()
		timeout, max_webhook_error_count = settings.REQUEST_TIMEOUT, settings.MAX_WEBHOOK_ERROR_COUNT
		try:
			result = session.execute(f"""
				select surrogate_id
				from webhook
				where status = 'READY'
				or (
					status = 'ERROR'
					and run_count <= {max_webhook_error_count}
					and EXTRACT(EPOCH FROM (current_timestamp - updated_at)) > pow(2, run_count)
				)
			""")
			webhook_surrogate_ids = [w[0] for w in result]
			random.shuffle(webhook_surrogate_ids)
			for surrogate_id in webhook_surrogate_ids:
				if WebhookService.attempt_webhook_lock(surrogate_id, session):
					logging.info(f"processing webhook {surrogate_id}")
					webhook = session.query(Webhook).filter(Webhook.surrogate_id == surrogate_id).one()
					if webhook.status not in [StatusEnum.READY, StatusEnum.ERROR]:
						logging.info(f"webhook: {surrogate_id} no longer ready")
					else:
						response_code = None
						try:
							response_code = self.perform_request(webhook, timeout)
							status = 'FINISHED' if 200 <= response_code < 300 else 'ERROR'
						except Exception as e:
							logging.error(f"Error while performing request: {e}")
							status = 'ERROR'

						webhook.status = status
						webhook.updated_at = datetime.now()
						webhook.run_count += 1

						if response_code:
							webhook.response_code = response_code

					WebhookService.release_webhook_lock(surrogate_id, session)
					session.commit()
					return 1

		except Exception:
			tb = traceback.format_exc()
			logging.error(tb)
		finally:
			session.close()

	def fix_stuck_webhook_jobs(self):
		logging.info("Starting fix_stuck_running_webhook_jobs")
		session = SessionLocal()
		try:
			result = session.execute(f"""
				SELECT surrogate_id FROM webhook
				WHERE locked
				and lock_date < current_timestamp - INTERVAL '1 MIN'
				FOR UPDATE
			""")
			surrogate_id_list = [row[0] for row in result]
			for surrogate_id in surrogate_id_list:
				self.release_webhook_lock(surrogate_id, session)
		except Exception:
			tb = traceback.format_exc()
			logging.error(tb)
		finally:
			session.close()

	@staticmethod
	def perform_request(webhook: Webhook, timeout: int):

		split_headers = [split.split(":") for split in webhook.headers.split(";")] if len(webhook.headers) > 0 else []
		headers = {s[0]: s[1] for s in split_headers} if split_headers else []

		split_query_params = [split.split(":") for split in webhook.query_params.split(";")] if len(
			webhook.query_params) > 0 else []
		query_param_dict = {s[0]: s[1] for s in split_query_params} if split_query_params else []

		if webhook.http_method == HttpMethodEnum.GET:
			r = requests.get(webhook.url, headers=headers, params=query_param_dict, timeout=timeout)
			status_code = r.status_code
		elif webhook.http_method == HttpMethodEnum.POST:
			r = requests.post(webhook.url, headers=headers, params=query_param_dict, data=webhook.body,
							  timeout=timeout)
			status_code = r.status_code
		elif webhook.http_method == HttpMethodEnum.PUT:
			r = requests.put(webhook.url, headers=headers, params=query_param_dict, data=webhook.body, timeout=timeout)
			status_code = r.status_code
		elif webhook.http_method == HttpMethodEnum.DELETE:
			r = requests.delete(webhook.url, headers=headers, params=query_param_dict, timeout=timeout)
			status_code = r.status_code
		else:
			raise NotImplementedError

		logging.info(f"performed {webhook.http_method} request with status {status_code}")
		return status_code

	@staticmethod
	def attempt_webhook_lock(surrogate_id: int, session):
		logging.info(f"Starting attempt of lock: {surrogate_id}")
		result = session.execute(f"select pg_try_advisory_lock('{surrogate_id}')")
		is_leader = [row[0] for row in result][0]
		if is_leader:
			session.execute(f"""
				update webhook
				set
					locked = true,
					lock_date = current_timestamp
				where surrogate_id = {surrogate_id}
			""")
			logging.info(f"locked webhook: {surrogate_id}")
		return is_leader

	@staticmethod
	def release_webhook_lock(surrogate_id: int, session):
		logging.info(f"Starting release of lock: {surrogate_id}")
		session.execute(f"""
			update webhook
			set locked = false,
				lock_date = null
			where surrogate_id = {surrogate_id}
		""")
		session.execute(f"select pg_advisory_unlock('{surrogate_id}')")
		logging.info(f"released lock: {surrogate_id}")

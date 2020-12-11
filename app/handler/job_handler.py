import logging

from app.services.webhook_service import WebhookService

logging.basicConfig(encoding='utf-8', level=logging.INFO)


def process_ready_webhook_jobs():
    logging.debug('Running process_ready_webhook_jobs')
    WebhookService().process_ready_webhooks()


def fix_stuck_running_webhook_jobs():
    logging.debug('Running fix_stuck_running_webhook_jobs')
    WebhookService().fix_stuck_webhook_jobs()



from logging import Logger

from apscheduler.executors.pool import ThreadPoolExecutor
from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.interval import IntervalTrigger
from flask import Flask, Request
from flask_injector import FlaskInjector
from injector import Module

from app.api.webhook_api import webhook_api
from app.handler.job_handler import process_ready_webhook_jobs, fix_stuck_running_webhook_jobs
from app.util.config import settings
from app.util.exception import JSONParseException, ApiException
from app.util.rest_util import CustomJSONEncoder


def on_json_loading_failed(self, e):
	raise JSONParseException()


def register_blueprints(flask_app):
	# Register the blueprints
	flask_app.register_blueprint(webhook_api)


def register_injections(flask_app):
	class InjectorModule(Module):
		def configure(self, binder):
			binder.bind(Logger, to=flask_app.logger)  # TODO: Add dummy logger

	flask_app.injector = FlaskInjector(app=flask_app, modules=[InjectorModule]).injector


def register_json_encoder(flask_app):
	flask_app.json_encoder = CustomJSONEncoder


def run_jobs(flask_app):
	thread_pool_size = flask_app.config["JOB_THREAD_POOL_SIZE"] if "JOB_THREAD_POOL_SIZE" in flask_app.config else 1
	executors = {
		'default': ThreadPoolExecutor(thread_pool_size)
	}

	job_defaults = {
		'coalesce': False,
		'misfire_grace_time': 30,
		'max_instances': 5
	}

	scheduler = BackgroundScheduler(executors=executors, job_defaults=job_defaults)
	scheduler.add_job(func=process_ready_webhook_jobs, trigger=IntervalTrigger(seconds=10))
	scheduler.add_job(func=fix_stuck_running_webhook_jobs, trigger=IntervalTrigger(seconds=10))

	scheduler.start()

	flask_app.scheduler = scheduler


def create_app():
	"""Returns an initialized Flask application."""
	# create console handler with a higher log level
	flask_app = Flask(__name__)
	flask_app.url_map.strict_slashes = False
	if settings.RUN_ASYNC_JOBS:
		run_jobs(flask_app)
	else:
		register_blueprints(flask_app)
		register_json_encoder(flask_app)  # TODO: Add encoder for date formatting

		Request.on_json_loading_failed = on_json_loading_failed

		# TODO: Check connection health

		register_injections(flask_app)

	return flask_app

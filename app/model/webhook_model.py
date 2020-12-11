import datetime
import uuid

from sqlalchemy import Column, Integer, String, DateTime, Text, Enum, BIGINT, Sequence, Boolean
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.ext.declarative import declarative_base

from app.schemas.webhook_schema import HttpMethodEnum, StatusEnum

Base = declarative_base()


class Webhook(Base):
	__tablename__ = 'webhook'
	id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, unique=True, nullable=False)
	# TODO: This uuid generation could be better done in the database (Tech Debt)
	surrogate_id = Column(BIGINT, Sequence('webhook_surrogate_id_seq', start=1, increment=1), unique=True)
	status = Column("status", Enum(StatusEnum))
	url = Column(String(1024))
	http_method = Column(Enum(HttpMethodEnum))
	headers = Column(String(1024))
	query_params = Column(String(1024))
	body = Column(Text)
	run_count = Column(Integer, default=0)
	locked = Column(Boolean, default=False)
	lock_date = Column(DateTime)
	response_code = Column(Integer)
	created_at = Column(DateTime, default=datetime.datetime.utcnow)
	updated_at = Column(DateTime, default=datetime.datetime.utcnow)


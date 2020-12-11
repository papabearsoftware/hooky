from datetime import datetime
from enum import Enum
from typing import Optional, List
from uuid import UUID

from pydantic import BaseModel


class StatusEnum(str, Enum):
	READY = "READY"
	RUNNING = "RUNNING"
	ERROR = "ERROR"
	FINISHED = "FINISHED"


class HttpMethodEnum(str, Enum):
	GET = "GET"
	POST = "POST"
	PUT = "PUT"
	DELETE = "DELETE"


class KeyValuePair(BaseModel):
	key: str = None
	value: str = None


class Header(KeyValuePair):
	pass


class QueryParam(KeyValuePair):
	pass


class WebhookBase(BaseModel):
	url: str = None
	httpMethod: HttpMethodEnum = None
	headers: Optional[List[Header]] = None
	queryParams: Optional[List[QueryParam]] = None
	body: Optional[str] = None


class WebhookCreate(WebhookBase):
	pass


class WebhookGet(WebhookBase):
	id: UUID = None
	status: StatusEnum = None
	runCount: int = None
	createdAt: datetime = None
	updatedAt: datetime = None


class WebhookCreateResponse(BaseModel):
	id: UUID = None
	status: StatusEnum = None
	createdAt: datetime = None

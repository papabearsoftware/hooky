from typing import Any, Dict, Optional

from pydantic import BaseSettings, PostgresDsn, validator


class Settings(BaseSettings):
	API_V1_STR: str = "/api/v1"
	POSTGRES_HOST: str
	POSTGRES_USER: str
	POSTGRES_PASSWORD: str
	POSTGRES_DB: str
	POSTGRES_URI: Optional[PostgresDsn] = None

	@validator("POSTGRES_URI", pre=True)
	def assemble_db_connection(cls, v: Optional[str], values: Dict[str, Any]) -> Any:
		if isinstance(v, str):
			return v
		return PostgresDsn.build(
			scheme="postgresql",
			user=values.get("POSTGRES_USER"),
			password=values.get("POSTGRES_PASSWORD"),
			host=values.get("POSTGRES_HOST"),
			path=f"/{values.get('POSTGRES_DB')}",
		)

	class Config:
		env_file = '.env'

	MAX_WEBHOOK_ERROR_COUNT: int
	RUN_ASYNC_JOBS: bool
	REQUEST_TIMEOUT: int


settings = Settings()

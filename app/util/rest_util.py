
# Add date formatting for json
from datetime import datetime
from json import JSONEncoder
from uuid import UUID

from pydantic import BaseModel


class CustomJSONEncoder(JSONEncoder):
    """
    Custom encoder for special serialization
    """
    def default(self, o):
        if isinstance(o, datetime):
            return '{0:%Y-%m-%d %H:%M:%S}'.format(o)
        if isinstance(o, UUID):
            return str(o)
        if isinstance(o, BaseModel):
            return o.json()
        return JSONEncoder.default(self, o)

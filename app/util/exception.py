import logging
import traceback

from flask import jsonify


class ApiException(Exception):
    def __init__(self, status_code, message):
        self.error = True
        self.status_code = status_code
        self.message = message


class JSONParseException(ApiException):
    def __init__(self):
        ApiException.__init__(self, 400, 'Invalid json body')


class BadRequestException(ApiException):
    def __init__(self, message):
        ApiException.__init__(self, 400, message)


class PreconditionFailedException(ApiException):
    def __init__(self, message):
        ApiException.__init__(self, 412, message)


class UnauthorizedException(ApiException):
    def __init__(self, message):
        ApiException.__init__(self, 401, message)


class InternalServerException(ApiException):
    def __init__(self, message):
        ApiException.__init__(self, 500, message)


class ConflictException(ApiException):
    def __init__(self, message):
        ApiException.__init__(self, 409, message)


class ResourceNotFoundException(ApiException):
    def __init__(self, message):
        ApiException.__init__(self, 404, message)


class ForbiddenException(ApiException):
    def __init__(self, message):
        ApiException.__init__(self, 403, message)


def handle_api_exception(err):
    tb = traceback.format_exc()
    logging.error(tb)
    response = jsonify(err.__dict__)
    return response, err.status_code


def handle_exception(o):
    tb = traceback.format_exc()
    logging.error(tb)
    response_exception = InternalServerException("Internal Server Error")
    return jsonify(response_exception.__dict__), response_exception.status_code

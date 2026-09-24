from rest_framework.views import exception_handler


def api_exception_handler(exc, context):
    response = exception_handler(exc, context)
    if response is not None:
        data = response.data
        if isinstance(data, dict) and "detail" in data:
            data["message"] = data["detail"]
        elif isinstance(data, dict):
            data["message"] = list(data.values())[0] if data else "Invalid request."
        elif isinstance(data, list):
            data = {"message": data[0] if data else "Invalid request."}
        response.data = {"success": False, "error": data.get("message", "Request failed."), "data": None}
    return response


class SeatUnavailableError(Exception):
    pass


class PaymentRequiredError(Exception):
    pass
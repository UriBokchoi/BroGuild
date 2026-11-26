class_name DateText
## Fechas para enseñarlas: día, mes, año y hora en la zona horaria del sistema («26/11/2026 14:03»).


## [param unix_time] (segundos desde 1970, en UTC) como texto, con la hora local.
static func format(unix_time: float) -> String:
	var bias: int = Time.get_time_zone_from_system().get("bias", 0)
	var date := Time.get_datetime_dict_from_unix_time(floori(unix_time) + bias * 60)
	return TranslationServer.translate(&"RECORDS_DATE_VALUE") % [
		date["day"], date["month"], date["year"], date["hour"], date["minute"]
	]

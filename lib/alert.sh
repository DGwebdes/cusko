#!/usr/bin/env bash

######
# Alert.sh is a signle dispatch point for alerts, regardless of source script.
# Source this file (after common and config) don't run it directly

alert(){
	local severity="$1"; shift
	local msg="$*"

	case "$severity" in
		WARN) log_warn "$msg" ;;
		CRIT) log_crit "$msg" ;;
		*) log_info "$msg" ;;
	esac

	case "$ALERT_BACKEND" in
		log) : ;;
		email) _alert_email "$severity" "$msg" ;;
		webhook) _alert_webhook "$severity" "$msg" ;;
		*) log_warn "Unknown ALERT_BACKEND '$ALERT_BACKEND', falling back to log-only" ;;
	esac
}

_alert_email(){
	local severity="$1" msg="$2"
	: "${ALERT_EMAIL_TO:?ALERT_EMAIL_TO must be set to use the email backend}"
	echo "$msg" | mail -s "[$severity] server-toolkit alert" "$ALERT_EMAIL_TO" \
		|| log_warn "Failed to send email alert"
}

_json_escape(){
	local s="$1"
	s="${s//\\/\\\\}"   # backslash first, or it'll double-escape the others
	s="${s//\"/\\\"}"
	s="${s//$'\n'/\\n}"
	s="${s//$'\t'/\\t}"
	printf '%s' "$s"
}

_alert_webhook(){
	local severity="$1" msg="$2" escaped
	: "${ALERT_WEBHOOK_URL:?ALERT_WEBHOOK_URL must be set to use the webhook backend}"
	escaped="$(_json_escape "$msg")"
	curl -sfS -X POST -H "Content-Type: application/json" \
		-d "{\"severity\":\"$severity\",\"message\":\"$escaped\"}" \
		"$ALERT_WEBHOOK_URL" \
		|| log_warn "Failed to send webhook alert"

}

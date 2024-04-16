#!/usr/bin/env bash

SHIPPED_JSON="core/shipped.json"

function ooc() {
	php occ \
		"${@}"
}

function main() {
	# No such app enabled: password_policy
	# ooc app:disable password_policy

	# test required apps are set
	REQS=( php )

	for REQ in "${REQS[@]}"
	do
		which "${REQ}" >/dev/null
		if [ ! $? -eq 0 ]; then
			echo "ERROR: requirement '${REQ}' is missing"
			exit 1
		fi
	done

	echo "Configure NextCloud basics"

	if [[ $(ooc status --output json | jq '.installed') != "true" ]]; then
		echo "NextCloud is not installed, abort"
		exit 1
	fi

	ooc config:system:set lookup_server --value=""
	ooc user:setting admin settings email admin@example.net

	echo "Configure theming"

	ooc theming:config name "EasyStorage"
	ooc theming:config color "#003D8F"
	ooc theming:config disable-user-theming yes
	ooc config:app:set theming backgroundMime --value backgroundColor

	echo "Rebuild mimetype images"

	ooc maintenance:mimetype:update-js

	local enable_apps=(
		"extract"
		"viewer"
	)

	for app in ${enable_apps[@]}; do
		echo "Enable app '${app}' ..."
		ooc app:enable "${app}"
	done

	local disable_apps=(
		"activity"
		"circles"
		"comments"
		"contactsinteraction"
		"dashboard"
		"files_versions"
		"firstrunwizard"
		"logreader"
		"nextcloud_announcements"
		"privacy"
		"recommendations"
		"related_resources"
		"serverinfo"
		"sharebymail"
		"support"
		"survey_client"
		"systemtags"
		"updatenotification"
		"user_status"
		"weather_status"
		"workflowengine"
	)

	echo "Remove apps from 'shipped' list ..."

	for app in "${disable_apps[@]}"; do
		echo "Unship app '${app}' ..."
		cat ${SHIPPED_JSON} \
			| jq --arg toUnforce "${app}" 'del(.defaultEnabled[] | select(. == $toUnforce))' \
			| jq --arg toUnforce "${app}" 'del(.alwaysEnabled[] | select(. == $toUnforce))' > ${SHIPPED_JSON}.tmp \
				&& mv ${SHIPPED_JSON}.tmp ${SHIPPED_JSON}
	done

	echo "Disable apps"

	for app in ${disable_apps[@]}; do
		echo "Disable app '${app}' ..."
		ooc app:disable "${app}"
	done
}

main ${@}

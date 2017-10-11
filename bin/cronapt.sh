#!/bin/sh

#set -e
cd -- "$(dirname -- "$0")/.." || exit 1

#TODO: gerer l'envoie d'email en cas d'info voulue
#TODO: pouvoir utiliser les memes fonctions mais changer l'affichage final ?

# The steps:
# 1) start (done before the action)
# 2) action (make the command, with error managment, take in memory the result)
# 3) stop (done after the action)
# 4) filter (transform the result, done over a pipe command)
# 5) result (the final step to show informations)
# 6) ? email ?

cronapt_lessverbose() { grep -v '^\(Reading package lists...\|Building dependency tree...\|Reading state information...\)'; }
cronapt_changeonly() { grep 'upgraded.*installed.*remove.*'; }
cronapt_drop0change() { grep -v '^0 upgraded, 0 newly installed, 0 to remove and 0 not upgraded\.$'; }
cronapt_result_to_upg_new_rem_kep() {
	local x="$1"
	case "$x" in
		*' upgraded, '*' newly installed, '*' to remove and '*' not upgraded.') ;;
		*) return 1
	esac
	local upg new rem kep

	upg="${x% upgraded,*}"
	x="${x#*, }"
	new="${x% newly installed,*}"
	x="${x#*, }"
	rem="${x% to remove and *}"
	x="${x#* and }"
	kep="${x% not upgraded.*}"
	echo "${upg:-0} ${new:-0} ${rem:-0} ${kep:-0}"
}
#test='1 upgraded, 2 newly installed, 3 to remove and 4 not upgraded.'
#echo "$test"
#printf '[~%s/+%s/-%s/!%s]\n' $(cronapt_result_to_upg_new_rem_kep "$test")
#exit

cronapt_level() {
	case "$1" in
		error) echo 1 ;;
		alert) echo 2 ;;
		info)  echo 3 ;;
		debug) echo 4 ;;
	esac
}

cronapt_aptget() { LC_ALL=C /usr/bin/apt-get "$@"; }

# use: [timestampformat] level
cronapt_putlog() {
	if [ -z "$LOGLEVEL" ] || [ -n "$level" ] && echo " $LOGLEVEL " | grep -q " \($level\|all\) "; then
		printf '%s(%s) %s\n' "$( [ "${timestampformat}" = "no" ] || date +"${timestampformat:-[%Y%m%d-%H:%M:%S] }")" "$level" "$*";
	fi
}

cronapt_lines() {
	#(
		local IFS2="$IFS"
		local IFS="$(printf '\n')"
		while IFS="$IFS" read -r line; do
			IFS="$IFS2" cronapt_putlog "$@" "$line"
		done
		IFS="$IFS2" # useless ?
	#)
}

cronapt_putlog_result_with_prefix() {
	printf '%s\n' "$result" | cronapt_lines "$@"
}


cronapt_putloglevel() {
	local level="$1";shift
	cronapt_putlog "$@"
}


cronapt_default() {
	local r=$?
	case "$action" in
		(start) cronapt_putloglevel debug "$context..." ;;
		(action) ;;
		(stop)	cronapt_putloglevel debug "$context done." ;;
		(filter) ;;
		(result)
			cronapt_putloglevel debug "$context (returned code $r) got:"
			local level=${level:-debug}
			cronapt_putlog_result_with_prefix "$context:"
		;;
		(*)
			echo >&2 "ERROR: Unknown action $action"
			return 1
		;;
	esac
	return $?
}
		

# use: context result
cronapt_hook() {
	local r=$?;
	local action="$1";shift;

	local ignore_error=true use_default=false use_pipe=false;
	case "$action" in
		start|stop) use_default=true ;;
		action) ignore_error=false ;;
		filter) use_pipe=true ;;
		result) use_default=true ;;
	esac

	case "$action" in
		action|result) ;;
		*) shift $#;
	esac

	local r2
	local hookname="cronapt_${action}_${context}"
	if command >/dev/null 2>&1 -v "$hookname"; then
		if $use_pipe; then
			printf '%s\n' "$result" | "$hookname" "$@"
			r2=0
		else
			(
				"$hookname" "$@"
				exit $?
			) 2>&1
			r2=$?
		fi
	elif $use_default; then
		cronapt_default "$@"
		r2=$?
	else
		# no default = do not update result
		return 1
	fi
	if ! $ignore_error; then
		return $r2
	fi
	return $r;
}
cronapt() {
	local context="$1";shift
	local result;
	local ERROR=0
	cronapt_load "$context" || return 1

	cronapt_hook start "$@";
	result="$(cronapt_hook action "$@")"
	ERROR=$?
	cronapt_hook stop "$@";
	local result2;result2="$(cronapt_hook filter "$@")" && result="$result2";
	cronapt_hook result "$@";
	return $ERROR;
}

cronapt_isroot() { [ "$(id -nu)" = "root" ]; }

cronapt_load() {
	. "./commands/$1"
}

main() {
	LOGLEVEL="${*:-alert error}"
	cronapt update
#	cronapt autoclean -s
#	cronapt download
	cronapt available4upgrade upgrade
#	cronapt available4upgrade dist-upgrade
#	cronapt simul_upgrade
}
main "$@"
exit $?


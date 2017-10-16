better_apt_upgrade_list() {
	grep '^Inst' \
	| while read -r i_ p a b_c; do
		# [xxx] => xxx
		a="${a#\[}";a="${a%\]}";
		# b c (...) ...
		b_c="${b_c#\(}"
		b_c="$(printf '%s\n' "$b_c" | cut -d\) -f1 | sed -e 's, \[\(amd64\|all\|\)\],,g')"
		b="$(printf '%s\n' "$b_c" | cut -d\  -f1)"
		c="$(printf '%s\n' "$b_c" | cut -d\  -f2-)"
		case "$c" in
			(*[Ss]ecurity*)
				printf -- '-%s %s\n' "$p" "$a #security"
				printf -- '+%s %s\n' "$p" "$b #security"
			;;
			(*)
				printf -- '-%s %s\n' "$p" "$a"
				printf -- '+%s %s\n' "$p" "$b"
			;;
		esac
	done;
}

#!/bin/sh

. /usr/lib/libmodcgi.sh

check "$DNSCRYPT_PROXY_LOG_SYSLOG" yes:log_syslog_yes "*":log_syslog_no

sec_begin "$(lang de:"Starttyp" en:"Start type")"
cgi_print_radiogroup_service_starttype "enabled" "$DNSCRYPT_PROXY_ENABLED" "" "" 1
sec_end

sec_begin "$(lang de:"dnscrypt-proxy" en:"dnscrypt-proxy")"
cat << EOF
<p>
<label for="bindaddress">$(lang de:"Bind-Adresse" en:"Bind-address"): </label>
<input type="text" name="bindaddress" value="$(html "$DNSCRYPT_PROXY_BINDADDRESS")">
<br><font size="-2">$(lang de:"z.B. 192.168.178.1#53 oder leer lassen f&uuml;r alle" en:"e.g. 192.168.178.1#53 or leave blank for all")</font>
</p>

<p>$(lang de:"Anzahl Verbindungen" en:"Max connections"): <input type="text" name="maxclients" size="5" maxlength="5" value="$(html "$DNSCRYPT_PROXY_MAXCLIENTS")"></p>

<p>
<input id="p1" type="radio" name="log_syslog" value="yes"$log_syslog_yes_chk><label for="x1">$(lang de:"Syslog" en:"Syslog")</label>
<br>
<input id="p2" type="radio" name="log_syslog" value="no"$log_syslog_no_chk><label for="x2">$(lang de:"Datei:&nbsp;&nbsp;" en:"File:&nbsp;&nbsp;&nbsp;")
<input type="text" name="log_file" size="45" maxlength="255" value="$(html "$DNSCRYPT_PROXY_LOG_FILE")"></label>
</p>
EOF
sec_end

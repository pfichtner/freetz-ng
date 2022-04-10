#!/bin/sh

. /usr/lib/libmodcgi.sh

#
sec_begin "$(lang de:"Starttyp" en:"Start type")"
cgi_print_radiogroup_service_starttype "enabled" "$DNSCRYPT_PROXY_ENABLED" "" "" 0
sec_end

#
sec_begin "$(lang de:"Optionen" en:"Options")"
cgi_print_textline_p "bindaddress"  "$DNSCRYPT_PROXY_BINDADDRESS" 20/255  "$(lang de:"Bindadresse" en:"Bind-address"): " \
	"<br>$(lang de:"Beispiel: 127.0.0.1:535" en:"Example: 127.0.0.1:535"): "
cgi_print_textline_p "resolverlist" "$DNSCRYPT_PROXY_RESOLVERLIST" 30/255 "$(lang de:"Resolverliste" en:"Resolver list"): "
cgi_print_textline_p "resolvername" "$DNSCRYPT_PROXY_RESOLVERNAME" 10/255 "$(lang de:"Resolvername" en:"Resolver name"): " \
	"<br>$(lang de:"Leer oder 'random' f&uuml;r zuf&auml;llig" en:"Empty or 'random' for random"): "
cgi_print_textline_p "maxclients"   "$DNSCRYPT_PROXY_MAXCLIENTS" 6/16     "$(lang de:"Maximale Verbindungen" en:"max connections"): "
cgi_print_textline_p "logfile"      "$DNSCRYPT_PROXY_LOGFILE" 30/255      "$(lang de:"Logfile" en:"Logfile"): "
cgi_print_checkbox   "syslog"       "$DNSCRYPT_PROXY_SYSLOG"              "$(lang de:"Syslog benutzen" en:"Use syslog")"

sec_end


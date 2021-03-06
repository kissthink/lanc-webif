#!/usr/bin/webif-page
<?
. /usr/lib/webif/webif.sh

header "Info" "System" "<img src=\"/images/blkbox.jpg\" alt=\"@TR<<System Information>>\"/>@TR<<System Information>>"

[ -z "$_device" ] && _device="unidentified"
_kversion=$(uname -srv 2>/dev/null)
_mac=$(/sbin/ifconfig eth0 2>/dev/null | grep HWaddr | cut -b39-)
board_type=$(cat /proc/cpuinfo 2>/dev/null | sed 2,20d | cut -c16-)
[ -z "$board_type" ] && board_type=$(uname -m 2>/dev/null)
user_string="$REMOTE_USER"
[ -z "$user_string" ] && user_string="not logged in"
machinfo=$(uname -a 2>/dev/null)

package_filename="webif_latest_stable.ipk"
if $(echo "$_firmware_version" | grep -q "r[[:digit:]]*"); then
	svn_path="trunk"
else
	svn_path="tags/kamikaze_$_firmware_version"
fi
version_url=$(sed '/^src[[:space:]]*X-Wrt[[:space:]]*/!d; s/^src[[:space:]]*X-Wrt[[:space:]]*//g; s/\/packages.*$/\//g' /etc/opkg.conf 2>/dev/null)
revision_text=" r$_webif_rev "
this_revision="$_webif_rev"
version_file=".version-stable"
daily_checked=""
upgrade_button=""

equal "$FORM_check_daily" "1" && {
	version_file=".version"
	package_filename="webif_latest.ipk"
	daily_checked="checked=\"checked\""
}

if [ -n "$FORM_update_check" ]; then
	echo "@TR<<Please wait>> ...<br />"
	tmpfile=$(mktemp "/tmp/.webif-XXXXXX")
	rm -f $tmpfile
	wget -q "$version_url$version_file" -O "$tmpfile" 2>&-
	! exists "$tmpfile" && echo "doesn't exist" > "$tmpfile"
	cat $tmpfile | grep -q "doesn't exist"
	if [ $? = 0 ]; then
		revision_text="<em class=\"warning\">@TR<<info_error_checking#ERROR CHECKING FOR UPDATE>></em>"
	else
		latest_revision=$(cat $tmpfile)
		if [ "$this_revision" -lt "$latest_revision" ]; then
			revision_text="<em class=\"warning\">@TR<<info_update_available#webif&sup2; update available>>: r$latest_revision - <a href=\"http://code.google.com/p/x-wrt/source/list?path=/${svn_path}/package/webif/\" target=\"_blank\">@TR<<info_view_changes#view changes>></a></em>"
			upgrade_button="<input type=\"submit\" value=\" @TR<<info_upgrade_webif#Update/Reinstall Webif>> \"  name=\"install_webif\" />"
		else
			revision_text="<em>@TR<<info_already_latest#You have the latest webif&sup2;>>: r$this_revision</em>"
		fi
	fi
	rm -f "$tmpfile"
fi

if [ -n "$FORM_install_webif" ]; then
	echo "@TR<<info_wait_install#Please wait, installation may take a minute>> ... <br />"
	echo "<pre>"
	opkg -V 0 update
	opkg -force-overwrite -force-reinstall -force-defaults install "${version_url}${package_filename}"| uniq
	echo "</pre>"
	this_revision=$(cat "/www/.version")
	# update the active language package
	curlang="$(cat "/etc/config/webif" |grep "lang=" |cut -d'=' -f2)"
	! equal "$(opkg status "webif-lang-${curlang}" |grep "Status:" | grep " installed" )" "" && {
		webif_version=$(opkg status webif | awk '/Version:/ { print $2 }')
		echo "<pre>"
		opkg -force-reinstall -force-overwrite -force-defaults install "${version_url}packages/webif-lang-${curlang}_${webif_version}_mipsel.ipk" | uniq
		echo "</pre>"
	}
fi

config_get_bool show_banner general show_banner 0
[ 1 -eq "$show_banner" ] && {
	echo "<pre>"
	cat /etc/banner 2>/dev/null
	echo "</pre><br />"
}

cat <<EOF
<table summary="System Information">
<tbody>
	<tr>
		<td width="100"><strong>@TR<<Firmware>></strong></td><td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
		<td>$_firmware_name - $_firmware_subtitle $_firmware_version</td>
	</tr>
	<tr>
		<td><strong>@TR<<Kernel>></strong></td><td>&nbsp;</td>
		<td>$_kversion</td>
	</tr>
	<tr>
		<td><strong>@TR<<MAC>></strong></td><td>&nbsp;</td>
		<td>$_mac</td>
	</tr>
	<tr>
		<td><strong>@TR<<Device>></strong></td><td>&nbsp;</td><td>$_device</td>
	</tr>
	<tr>
		<td><strong>@TR<<Board>></strong></td><td>&nbsp;</td><td>$board_type</td>
	</tr>
	<tr>
		<td><strong>@TR<<Username>></strong></td><td>&nbsp;</td>
		<td>$user_string</td>
	</tr>	
</tbody>
</table>
EOF

footer

?>
<!--
##WEBIF:name:Info:010:System
-->

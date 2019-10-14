#!/system/bin/sh

#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is kangboi distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#####################################################################
# init.d support
if [ ! -e /system/etc/init.d ]; then
 if [ "$($BB mount | grep ' /system ' | grep -c 'ro,')" -eq "1" ]; then
    $BB mount -o remount,rw /system
 fi

    mkdir /system/etc/init.d
    chown -R root.root /system/etc/init.d
    chmod -R 755 /system/etc/init.d
 if [ "$($BB mount | grep ' /system ' | grep -c 'ro,')" -eq "1" ]; then
    $BB mount -o remount,ro /system
 fi
fi

# start init.d
for FILE in /system/etc/init.d/*; do
	sh $FILE >/dev/null
done;

if [ ! -f /su/xbin/busybox ]; then
	BB=/system/xbin/busybox;
else
	BB=/su/xbin/busybox;
fi;

# Mount rootfs and system as RW

mount -o rw,remount rootfs;

# Synapse

chmod -R 755 /res/*;

# Create uci link if not present

if [ ! -e /system/bin/uci ]; then
     ln -s /res/synapse/uci /system/bin/uci
fi

#####################################################################

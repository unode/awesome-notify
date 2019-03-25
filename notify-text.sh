#!/usr/bin/env bash
#
# Code released under MIT license transcribed below:
#
# Copyright (c) 2015-2019, Renato Alves
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


usage() {
    echo >&2 ""
    echo >&2 "Usage:"
    echo >&2 "    $0 [parameters ...] -- \"header\" \"message\" [notification_tag]"
    echo >&2 ""
    echo >&2 "Required parameters:"
    echo >&2 "       header           = shown on the notification header/title"
    echo >&2 "       message          = shown on the notification body"
    echo >&2 "       notification_tag = (string) keep this id constant to allow reuse of the same notification"
    echo >&2 ""
    echo >&2 "Optional parameters:"
    echo >&2 "    -t timeout          = (float) time in seconds to display the notification. 0 means forever"
    echo >&2 "    -i icon_path        = (string) path to an icon file (png is preferred)"
    echo >&2 "    -p preset           = (string) theme presets (available: info, warn, critical,"
    echo >&2 "                                                  red, orange, yellow, green, blue, purple"
    echo >&2 "                                                  all colors also available in dark* variant)"
    echo >&2 "    -v                  = enable debugging output"
    echo >&2 ""
}

is_integer() {
    if ! [[ $1 =~ ^-?[0-9]+$ ]]; then
        echo >&2 "ERROR: $1 should be an integer"
        usage
        exit 1
    fi
}

required() {
    echo >&2 "ERROR: $1 is a required argument"
    usage
    exit 1
}

optional() {
    if [ "x$1" == "x" ]; then
        echo "$2"
    else
        echo "$1"
    fi
}

random_string() {
    # NOTE This function produces random hex-strings
    # Twice the size of $1 due to hexdump's behavior
    echo "$(hexdump -n $1 -e '/1 "%02x"' /dev/urandom)"
}

# Parse args using getopt (instead of getopts) to allow arguments before options
ARGS=$(getopt -o t:i:p:v -n "$0" -- "$@")
# reorganize arguments as returned by getopt
eval set -- "$ARGS"

while true; do
    case "$1" in
        # Shift before to throw away option
        # Shift after if option has a required positional argument
        -t)
            shift
            TIMEOUT="$1"
            shift
            ;;
        -i)
            shift
            ICON="$1"
            shift
            ;;
        -p)
            shift
            PRESET="$(echo PRESET_$1 | tr '[:lower:]' '[:upper:]')"
            shift
            ;;
        -v)
            shift
            VERBOSE="1"
            ;;
        --)
            shift
            break
            ;;
    esac
done

# Escaping raw strings in lua. As long as the content doesn't include these
# patterns we are be safe
OPEN_ESC="\[==\["
CLOSE_ESC="\]==\]"

sanitize() {
    # Escapes lua raw string characters to avoid terminating the raw string prematurely
    # Also make \n actually behave like newlines
    echo "$1" | sed -e ':loop' -e "s:${OPEN_ESC}:[=[:g" -e "s:${CLOSE_ESC}:]=]:g" -e 't loop' -e 's:\\n::g'
}

# Required arguments
HEADER=$(sanitize "$1")
MESSAGE=$(sanitize "$2")
NOTIFICATION_TAG="$3"

# Default values if not specified
TIMEOUT="$(optional "$TIMEOUT" 5)"

# Ensure timeout is an integer
is_integer $TIMEOUT "timeout"

# Themed presets
PRESET_NORMAL=""  # Whatever is the theme default
# Color presets
PRESET_RED="bg=\"#aa0000\","
PRESET_DARKRED="bg=\"#660000\","
PRESET_ORANGE="bg=\"#aa7700\","
PRESET_DARKORANGE="bg=\"#aa4400\","
PRESET_YELLOW="bg=\"#aaaa00\","
PRESET_DARKYELLOW="bg=\"#888800\","
PRESET_GREEN="bg=\"#00aa00\","
PRESET_DARKGREEN="bg=\"#006600\","
PRESET_BLUE="bg=\"#0000aa\","
PRESET_DARKBLUE="bg=\"#000066\","
PRESET_PURPLE="bg=\"#aa00aa\","
PRESET_DARKPURPLE="bg=\"#660066\","

PRESET_INFO="$PRESET_BLUE"
PRESET_WARN="$PRESET_YELLOW"
PRESET_CRITICAL="$PRESET_RED"

[ -n "$HEADER" ]           && HEADER="title=${OPEN_ESC}${HEADER}${CLOSE_ESC},"   || required "header"
[ -n "$MESSAGE" ]          && MESSAGE="text=${OPEN_ESC}${MESSAGE}${CLOSE_ESC},"  || required "message"
[ -n "$NOTIFICATION_TAG" ]                                                       || NOTIFICATION_TAG="$(random_string 8)"
[ -n "$TIMEOUT" ]          && TIMEOUT="timeout=$TIMEOUT,"                        || TIMEOUT=""
[ -n "$ICON" ]             && ICON="icon=${OPEN_ESC}${ICON}${CLOSE_ESC},"        || ICON=""
[ -n "$PRESET" ]           && PRESET="${!PRESET}"                                || PRESET=""

# Also clear notification_tags that have expired (1 hour = 3600 seconds) but
# only if a sufficient number of tags is created.
read -d '' PAYLOAD << EOF
if notifications_tags == nil then
    notifications_tags = {}
    notifications_tags_count = 0

    update_notification_tag_timestamp = function(new_id, notify_tag)
        notifications_tags[notify_tag] = {
            id=new_id,
            timestamp=os.time(),
        }
    end
end

local notify_tag = "$NOTIFICATION_TAG"

if notifications_tags[notify_tag] == nil then
    update_notification_tag_timestamp(
        naughty.notify({ $HEADER $MESSAGE $TIMEOUT $ICON $PRESET }).id,
        notify_tag
    )
    notifications_tags_count = notifications_tags_count + 1
else
    update_notification_tag_timestamp(
        naughty.notify({ $HEADER $MESSAGE $TIMEOUT $ICON $PRESET
                         replaces_id=notifications_tags[notify_tag].id }).id,
        notify_tag
    )
end

if notifications_tags_count >= 20 then
    notifications_tags_count = 0
    for k,v in pairs(notifications_tags) do
        local delta = os.time() - v.timestamp
        if delta > 3600 then
            notifications_tags[k] = nil
        else
            notifications_tags_count = notifications_tags_count + 1
        end
    end
end
EOF

echo "$PAYLOAD" | awesome-client

if [ "$VERBOSE" = "1" ]; then
    # Debugging
    echo "Title:      $HEADER"
    echo "Message:    $MESSAGE"
    echo "Notify_Tag: $NOTIFICATION_TAG"
    echo "Timeout:    $TIMEOUT"
    echo "Icon:       $ICON"
    echo "Preset:     $PRESET"

    echo "Payload:
    $PAYLOAD"
fi

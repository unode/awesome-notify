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
    echo >&2 "    $0 [parameters ...] -- \"message\" max_value current_value [notification_tag]"
    echo >&2 ""
    echo >&2 "Required parameters:"
    echo >&2 "       message          = shown on the notification body"
    echo >&2 "       max_value        = (integer) maximum possible value in the bar"
    echo >&2 "       current_value    = (integer) current value to be represented"
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

repeat_char() {
    if [ "$2" -ne "0" ]; then
        printf -- ${1}%.0s $(seq 1 $2)
    fi
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

BAR_WIDTH=20
BAR_ON_SYMBOL="▌"
BAR_OFF_SYMBOL="-"

if [ $# -lt 4 ]; then
    usage
    exit 2
fi

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
            PRESET="$(echo $1 | tr '[:lower:]' '[:upper:]')"
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

# Required arguments
HEADER="$1"
is_integer $2 "max_value" && MAX=$2
is_integer $3 "current_value" && CUR=$3
NOTIFICATION_TAG="$4"
TIMEOUT="$5"
ICON="$6"

# Default values if not specified
TIMEOUT="$(optional "$TIMEOUT" 5)"

# Ensure timeout is an integer
is_integer $TIMEOUT "timeout"

[ -n "$HEADER" ]           || required "header"
[ -n "$NOTIFICATION_TAG" ] || NOTIFICATION_TAG=""
[ -n "$TIMEOUT" ]          || TIMEOUT=""
[ -n "$ICON" ]             || ICON=""
[ -n "$PRESET" ]           || PRESET=""

if [ "$CUR" -gt "$MAX" ]; then
    echo "ERROR: current_value cannot be larger than max_value"
    usage
    exit 1
fi

ON=$(expr \( $CUR \* $BAR_WIDTH \) / $MAX )
OFF=$(expr $BAR_WIDTH - $ON )

MESSAGE="$(repeat_char ${BAR_ON_SYMBOL} $ON)$(repeat_char ${BAR_OFF_SYMBOL} $OFF)"

notify-text.sh -t "$TIMEOUT" -p "$PRESET" -i "$ICON" -- "$HEADER" "$MESSAGE" "$NOTIFICATION_TAG"

if [ "$VERBOSE" = "1" ]; then
    # Debugging
    echo "Title:      $HEADER"
    echo "Notify_Tag: $NOTIFICATION_TAG"
    echo "Timeout:    $TIMEOUT"
    echo "Icon:       $ICON"
    echo "Preset:     $PRESET"

    echo "ON:         $ON"
    echo "OFF:        $OFF"
    echo "Message:    $MESSAGE"
fi

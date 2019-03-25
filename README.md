# Notification utilities for awesomewm

These utilities leverage the fact that awesomewm is written in Lua to provide additional control over notifications, their behavior and style.

These scripts have been written a few years ago and have fulfilled their purpose.  
I do not plan to extend their functionality but feel free to fork, modify or abuse them to fit your needs.  
If you have abused them in any interesting way, a pull request is always welcome.

## notify-text

`notify-text.sh` is the main workhorse and allows generating textual notifications.  
It's main distinguishing feature is the ability to label or tag notifications which allows targeting and replacing active notifications.

It has a similar interface to `notify-send`:

```
Usage:
    notify-text.sh [parameters ...] -- "header" "message" [notification_tag]

Required parameters:
       header           = shown on the notification header/title
       message          = shown on the notification body
       notification_tag = (string) keep this id constant to allow reuse of the same notification

Optional parameters:
    -t timeout          = (float) time in seconds to display the notification. 0 means forever
    -i icon_path        = (string) path to an icon file (png is preferred)
    -p preset           = (string) theme presets (available: info, warn, critical,
                                                  red, orange, yellow, green, blue, purple
                                                  all colors also available in dark* variant)
    -v                  = enable debugging output
```

## notify-bar

`notify-bar.sh` uses `notify-text.sh` to display progress indicators, volume and brightness feedback, among others.

```
Usage:
    notify-bar.sh [parameters ...] -- "message" max_value current_value [notification_tag]

Required parameters:
       message          = shown on the notification body
       max_value        = (integer) maximum possible value in the bar
       current_value    = (integer) current value to be represented
       notification_tag = (string) keep this id constant to allow reuse of the same notification

Optional parameters:
    -t timeout          = (float) time in seconds to display the notification. 0 means forever
    -i icon_path        = (string) path to an icon file (png is preferred)
    -p preset           = (string) theme presets (available: info, warn, critical,
                                                  red, orange, yellow, green, blue, purple
                                                  all colors also available in dark* variant)
    -v                  = enable debugging output

```

## Installation

Simply clone the repository and add it's location to your shell's `PATH` or drop both `notify-text.sh` and `notify-bar.sh` in your favorite `/bin` folder.

Additionally, `naughty` must be imported globally in your `rc.lua`. That is `naughty = require("naughty")` and not `local naughty = require("naughty")`.

## Examples

### Permanent notification

Display a notification forever:

```
notify-text.sh -t 0 "Tea is ready" "in 5 minutes" tea
```

![Tea is ready](https://github.com/unode/awesome-notify/raw/master/images/tea_ready_in_5.png "Tea Ready")

and update it later:

```
notify-text.sh -t 0 "Tea is ready" "in 4 minutes" tea
```

![Tea is ready](https://github.com/unode/awesome-notify/raw/master/images/tea_ready_in_4.png "Tea Ready")

as per awesomewm's behavior, you can still click the notification to dismiss it.

### Volume notification

```
notify-bar.sh "Volume at 72%" 100 72 volume
```

![Volume](https://github.com/unode/awesome-notify/raw/master/images/volume.png "Volume")

or if scripted to trigger on volume keys

![Volume animation](https://github.com/unode/awesome-notify/raw/master/images/volume.gif "Volume animation")

### Color style presets

In addition to the more common `info`, `warn`, `critical` presets, both scripts accept additional colors `red`, `orange`, `yellow`, `green`, `blue`, `purple` as well as `dark...` variants.

![Presets](https://github.com/unode/awesome-notify/raw/master/images/presets.png "Presets")

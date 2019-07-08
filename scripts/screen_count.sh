#!/bin/bash
echoerr() {
  echo "$@" 1>&2
}

screen_count=$(screen -ls | grep -c $'^\t')
if [ "$screen_count" = 3 ]; then
  echoerr "ERROR: startup script already run, so the screens are already started."
  echoerr "To see the running screens, run:"
  echoerr "  screen -ls"
  echoerr "You can enter the screens with:"
  echoerr "  screen -r autolab"
  echoerr "  screen -r tango"
  echoerr "  screen -r redis"
  echoerr "Once you are in the screen, you can detach (which does not kill the screen)"
  echoerr "  by running ^A + d (which is Cmd-A followed by d on Mac)."
  echoerr "To kill the screen you are attached to, you can interrupt the running"
  echoerr "  program with ^C."
  echoerr "To restart any killed screen, just re-run the startup script."
  exit 1
fi

exit 0

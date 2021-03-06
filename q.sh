#!/bin/bash

## q version
Q_VERSION="0.0.6"

## q directory
Q="${Q:-${HOME}/.q}"

## q fifo lock file
LOCK="${LOCK:-${Q}/.LOCK}"

## q fifo
FIFO="${FIFO:-${Q}/fifo}"

## q log
LOG="${LOG:-${Q}/.LOG}"

## intializes q
init () {
  ## ensure Q directory exists
  if ! test -d "${Q}"; then
    mkdir "${Q}"
  fi

  ## ensure fifo exists
  if ! test -p "${FIFO}"; then
    mkfifo "${FIFO}"
  fi

  ## ensure log exists
  if ! test -f "${LOG}"; then
    touch "${LOG}"
  fi

  return $?
}

## outputs usage
usage () {
  echo "usage: q [-hV]"
  echo "   or: q push [data]"
  echo "   or: q shift"
  echo "   or: q lock"
  echo "   or: q unlock"
  echo "   or: q stream"
  echo "   or: q clear"
  return 0
}

## main
main () {
  local arg="${1}"; shift

  ## init
  (init)

  ## parse arg
  case "${arg}" in
    -V|--version) echo "${Q_VERSION}" ;;

    -h|--help) usage ;;

    push) qpush "${@}" ;;

    shift) qshift "${@}" ;;

    lock) qlock "${@}" ;;

    unlock) qunlock "${@}" ;;

    clear) qclear "${@}" ;;

    stream) qstream "${@}" ;;

    *)
      if ! [ -z "${arg}" ]; then
        if [ "-" == "${arg:0:1}" ]; then
          echo >&2 "error: Unknown option \`${arg}'"
        else
          echo >&2 "error: Unknown command \`${arg}'"
        fi
      fi

      usage >&2
      return 1
      ;;
  esac

  return $?
}

## push data to q
qpush () {
  local data="${@}"
  local dest="${FIFO}"

  ## determine if lock is present
  if ! test -f "${LOCK}"; then
    dest="${LOG}"
  fi

  ## write data from command line
  if ! [ -z "${data}" ]; then
    echo -e "${data}" >> "${dest}"
  fi

  ## write data from stdin if stdin is pipe
  if [ ! -t 0 ]; then
    while read -r buffer; do
      echo -e "${buffer}" >> "${dest}"
    done
  fi

  return $?
}

## shift data from q
qshift () {
  declare local op="${1}"
  case "${op}" in
    stream)
      ## stream l og
      cat "${LOG}"
      ## truncate log
      rm -f "${LOG}" && touch "${LOG}"
      ## read from fifo
      while true; do
        if test -f "${LOCK}"; then
          echo poll
          cat "${FIFO}"
        else
          break
        fi
      done
      ;;

    *)
      ## read log
      local log=($(<"${LOG}"))
      ## echo head
      echo "${log[0]}"
      ## truncate log
      rm -f "${LOG}" && touch "${LOG}"
      for (( i = 1; i < "${#log[@]}"; i++ )); do
        echo "${log[${i}]}" >> "${LOG}"
      done
      if test -f "${LOCK}"; then
        ## read from fifo
        cat "${FIFO}"
      elif [ -z "${log[0]}" ]; then
        return 1
      fi
      ;;
  esac

  return $?
}

## lock q
qlock () {
  touch "${LOCK}"
  return $?
}

## unlock q
qunlock () {
  rm -f "${LOCK}"
  return $?
}

## clear q log
qclear () {
  if test -f "${LOG}"; then
    cat "${FIFO}" >/dev/null &
    echo > "${FIFO}"
    rm -f "${FIFO}"
    rm -f "${LOG}"
    touch "${LOG}"
  fi
  return $?
}

## stream queue
qstream () {
  qshift 'stream'
  return $?
}

## run
(main "${@}")
exit $?


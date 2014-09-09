
q(1)
====

Simple message queuing

## install

```sh
$ bpkg install jwerle/q
```

## usage

```
usage: q [-hV]
   or: q push [data]
   or: q shift
   or: q lock
   or: q unlock
   or: q clear
   or: q stream
```

`q(1)` is a dead simple message queue written in bash. You can queue
messages or lock into a fifo. Messgaes are pushed and shifted. Messages
may be persisted in a log file that may be cleared when unlocked.

Push a message:

```sh
$ echo beep | q push
$ echo boop | q push
```

Shift a message off q

```sh
$ q shift
beep

$ q shift
boop

```

You can lock the q so a message must be acknowledged before another
can be pushed on to it.

```sh
$ q lock
$ echo boop | q push
```

```sh
# in another terminal
$ q shift
boop

$ q unlock
```

The q can be streamed as well

```sh
$ unlock
$ q push a
$ q push b
$ q push c
$ q stream
a
b
c

```

## license

MIT


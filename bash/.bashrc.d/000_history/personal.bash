# History tuning.

# Skip duplicate lines and lines starting with whitespace.
HISTCONTROL=ignoreboth:erasedups

# Append to the history file, don't truncate it on shell exit.
shopt -s histappend

# Generous limits — these are still small enough to grep through cheaply.
HISTSIZE=10000
HISTFILESIZE=20000

# Timestamp every entry. Cheap to add, valuable when you go spelunking.
HISTTIMEFORMAT='%F %T  '

# Don't record the noise.
HISTIGNORE='ls:ll:la:cd:pwd:exit:clear:history'

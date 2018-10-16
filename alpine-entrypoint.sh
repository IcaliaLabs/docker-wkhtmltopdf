#! /bin/sh

# The wkhtmltopdf docker container entrypoint script.

# 1: Run wkhtmltopdf if no argument was given, or the first argument is not
# the shell command:
if [ -z "$1" ] || [ "$1" <> "ash" ]; then set -- wkhtmltopdf "$@"; fi

# 2: Execute the command:
exec "$@"

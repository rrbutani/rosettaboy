
set -eo pipefail

if ((BASH_VERSINFO[0] < 5)); then
  echo "error: bash 5+ is required, sorry"
  exit 1
fi

readonly rosettaboy_bash_src_dir="$(dirname "$BASH_SOURCE")"
declare -A rosettaboy_sourced
function rb.source() {
    if ! [[ -v rosettaboy_sourced["$1"] ]]; then
        source "${rosettaboy_bash_src_dir}/$1"
        rosettaboy_sourced["$1"]=1
    else
        warn "'$1' already sourced"
    fi
}

rb.source common.bash
rb.source args.bash

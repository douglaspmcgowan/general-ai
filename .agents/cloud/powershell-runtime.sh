#!/usr/bin/env bash
# Canonical pinned PowerShell runtime component.
#
# Source this file, then call powershell_runtime_install [ARCHIVE]. With no
# ARCHIVE, the official pinned archive is downloaded. The only supported
# product destinations are the defaults below. Tests may select disposable
# absolute destinations with POWERSHELL_RUNTIME_PREFIX and
# POWERSHELL_RUNTIME_LAUNCHER; doing so is component evidence, not provider
# acceptance. The caller must establish PATH before invoking this operation.
#
# Trust boundary: existing path components must be root-owned directories with
# no group/world write. Existing generic roots are never chmodded. An existing
# foreign runtime or launcher is preserved and refused. An implementation-owned
# runtime is reconstructed from the authenticated archive before its wrapper or
# target is executed. This does not defend against hostile concurrent root or
# same-UID mutation and is not a sandbox.

_powershell_runtime_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=tool-versions.sh
. "$_powershell_runtime_dir/tool-versions.sh"

: "${POWERSHELL_RUNTIME_PREFIX:=/opt/microsoft/powershell/7}"
: "${POWERSHELL_RUNTIME_LAUNCHER:=/usr/local/bin/pwsh}"

_powershell_runtime_remove_tree() { [ ! -e "$1" ] || find -P "$1" -depth -delete; }

_powershell_runtime_fail() { printf 'powershell-runtime: %s\n' "$*" >&2; return 1; }

_powershell_runtime_identity() {
  case "$(uname -m)" in
    x86_64|amd64) printf '%s %s\n' x64 "$POWERSHELL_SHA256_AMD64" ;;
    aarch64|arm64) printf '%s %s\n' arm64 "$POWERSHELL_SHA256_ARM64" ;;
    *) _powershell_runtime_fail "unsupported architecture: $(uname -m)" ;;
  esac
}

# Check an existing directory chain without following symlinks. The first
# missing component and everything below it are allowed to be created later.
_powershell_runtime_safe_ancestors() {
  local path=$1 current=/ component rest
  case "$path" in /*) ;; *) _powershell_runtime_fail "path is not absolute: $path"; return ;; esac
  rest=${path#/}
  while [ -n "$rest" ]; do
    component=${rest%%/*}; rest=${rest#"$component"}; rest=${rest#/}
    current=${current%/}/$component
    if [ -e "$current" ] || [ -L "$current" ]; then
      [ ! -L "$current" ] || { _powershell_runtime_fail "symlink in destination chain: $current"; return; }
      [ -d "$current" ] || { _powershell_runtime_fail "non-directory in destination chain: $current"; return; }
      local meta uid mode
      meta=$(stat -c '%u %a' -- "$current") || return 1
      uid=${meta%% *}; mode=${meta#* }
      [ "$uid" = 0 ] || { _powershell_runtime_fail "non-root-owned destination ancestor: $current"; return; }
      # Interpret the final two octal digits; either write bit is unsafe.
      [ $((8#$mode & 0022)) -eq 0 ] || { _powershell_runtime_fail "group/world-writable destination ancestor: $current"; return; }
    else
      return 0
    fi
  done
}

# Establish only missing destination parents, after both chains have first been
# validated. Record each new directory so an unsuccessful install can remove
# empty effects without touching pre-existing roots or unrelated content.
_powershell_runtime_create_parents() {
  local path=$1 current=/ component rest
  rest=${path#/}
  while [ -n "$rest" ]; do
    component=${rest%%/*}; rest=${rest#"$component"}; rest=${rest#/}
    current=${current%/}/$component
    if [ ! -e "$current" ] && [ ! -L "$current" ]; then
      mkdir -m 0755 -- "$current" || return 1
      _powershell_runtime_created="${current}${_powershell_runtime_created:+
}${_powershell_runtime_created}"
    fi
  done
}

_powershell_runtime_remove_empty_parents() {
  local path rest=${_powershell_runtime_created:-}
  while [ -n "$rest" ]; do
    path=${rest%%$'\n'*}
    if [ "$path" = "$rest" ]; then rest=; else rest=${rest#*$'\n'}; fi
    rmdir -- "$path" 2>/dev/null || :
  done
}

_powershell_runtime_safe_owned_file() {
  local path=$1 expected_mode=${2:-} meta uid mode
  [ -f "$path" ] && [ ! -L "$path" ] || return 1
  meta=$(stat -c '%u %a' -- "$path") || return 1
  uid=${meta%% *}; mode=${meta#* }
  [ "$uid" = 0 ] && [ $((8#$mode & 0022)) -eq 0 ] || return 1
  [ -z "$expected_mode" ] || [ "$mode" = "$expected_mode" ]
}

# Run one authentic PowerShell process with its native cache confined to a
# caller-owned private directory.  The directory must already exist: accepting
# an inherited XDG path, or creating through an unvalidated path, would merely
# move the foreign-write boundary.
powershell_runtime_with_cache() {
  local cache=$1 candidate=$2 meta uid mode resolved
  shift 2
  case "$cache" in /*) ;; *) _powershell_runtime_fail "cache path is not absolute: $cache"; return ;; esac
  [ -d "$cache" ] && [ ! -L "$cache" ] || { _powershell_runtime_fail "cache path is not a regular directory: $cache"; return; }
  meta=$(stat -c '%u %a' -- "$cache") || return 1
  uid=${meta%% *}; mode=${meta#* }
  [ "$uid" = "$(id -u)" ] || { _powershell_runtime_fail "cache directory has unexpected owner: $cache"; return; }
  [ "$mode" = 700 ] || { _powershell_runtime_fail "cache directory is not private: $cache"; return; }
  resolved=$(realpath -- "$cache") || return 1
  [ "$resolved" = "$cache" ] || { _powershell_runtime_fail "cache directory is not realpath-stable: $cache"; return; }
  [ -f "$candidate" ] && [ ! -L "$candidate" ] && [ -x "$candidate" ] || { _powershell_runtime_fail "PowerShell target has unsafe shape: $candidate"; return; }
  XDG_CACHE_HOME=$cache "$candidate" "$@"
}

_powershell_runtime_wrapper() {
  printf '%s\n' '#!/bin/sh'
  printf '%s\n' '# Generated by .agents/cloud/powershell-runtime.sh. DO NOT EDIT.'
  printf 'cache=%s/.powershell-cache\n' "'$POWERSHELL_RUNTIME_PREFIX'"
  printf '%s\n' '[ -d "$cache" ] && [ ! -L "$cache" ] || exit 126'
  printf '%s\n' 'meta=$(stat -c '\''%u %a'\'' -- "$cache") || exit 126'
  printf '%s\n' '[ "${meta% *}" = "$(id -u)" ] && [ "${meta#* }" = 700 ] || exit 126'
  printf '%s\n' '[ "$(realpath -- "$cache")" = "$cache" ] || exit 126'
  printf 'exec env XDG_CACHE_HOME="$cache" "%s/pwsh" "$@"\n' "$POWERSHELL_RUNTIME_PREFIX"
}

_powershell_runtime_is_owned_wrapper() {
  [ -f "$POWERSHELL_RUNTIME_LAUNCHER" ] && [ ! -L "$POWERSHELL_RUNTIME_LAUNCHER" ] || return 1
  [ "$(cat -- "$POWERSHELL_RUNTIME_LAUNCHER")" = "$(_powershell_runtime_wrapper)" ]
}

powershell_runtime_install() (
  local supplied_archive=${1:-} identity archive_arch archive_sha archive work stage launcher_tmp old_prefix= cleanup marker marker_value
  _powershell_runtime_created=
  identity=$(_powershell_runtime_identity) || return 1
  archive_arch=${identity%% *}; archive_sha=${identity#* }
  case "$archive_sha" in (*[!0-9a-f]*|'') _powershell_runtime_fail 'invalid pinned archive digest'; return ;; esac
  [ ${#archive_sha} -eq 64 ] || { _powershell_runtime_fail 'invalid pinned archive digest length'; return; }
  case "$POWERSHELL_RUNTIME_PREFIX:$POWERSHELL_RUNTIME_LAUNCHER" in (*$'\n'*|*' '*|*'"'*|*"'"*) _powershell_runtime_fail 'unsafe destination characters'; return ;; esac
  [ "$POWERSHELL_RUNTIME_PREFIX" != / ] || { _powershell_runtime_fail 'runtime prefix cannot be /'; return; }
  [ "${POWERSHELL_RUNTIME_LAUNCHER%/*}" != / ] || { _powershell_runtime_fail 'launcher parent cannot be /'; return; }

  _powershell_runtime_safe_ancestors "${POWERSHELL_RUNTIME_PREFIX%/*}" || return 1
  _powershell_runtime_safe_ancestors "${POWERSHELL_RUNTIME_LAUNCHER%/*}" || return 1
  if [ -e "$POWERSHELL_RUNTIME_PREFIX" ] || [ -L "$POWERSHELL_RUNTIME_PREFIX" ]; then
    [ -d "$POWERSHELL_RUNTIME_PREFIX" ] && [ ! -L "$POWERSHELL_RUNTIME_PREFIX" ] || { _powershell_runtime_fail 'runtime destination has unsafe shape'; return; }
    _powershell_runtime_safe_ancestors "$POWERSHELL_RUNTIME_PREFIX" || return 1
    marker=$POWERSHELL_RUNTIME_PREFIX/.canonical-powershell-runtime
    _powershell_runtime_safe_owned_file "$marker" 644 || { _powershell_runtime_fail 'existing runtime has no safe ownership marker'; return; }
    _powershell_runtime_safe_owned_file "$POWERSHELL_RUNTIME_PREFIX/pwsh" 755 || { _powershell_runtime_fail 'existing runtime target has unsafe ownership or shape'; return; }
    marker_value=$(cat -- "$marker") || return 1
    [ "$marker_value" = "$(printf '%s\n%s' "$archive_sha" "$(realpath -s -- "$POWERSHELL_RUNTIME_PREFIX/pwsh")")" ] || { _powershell_runtime_fail 'owned runtime identity or target relationship does not match'; return; }
    _powershell_runtime_is_owned_wrapper || { _powershell_runtime_fail 'existing runtime lacks its canonical owned launcher'; return; }
  fi
  if [ -e "$POWERSHELL_RUNTIME_LAUNCHER" ] || [ -L "$POWERSHELL_RUNTIME_LAUNCHER" ]; then
    _powershell_runtime_is_owned_wrapper || { _powershell_runtime_fail 'existing launcher is foreign; preserving it'; return; }
    [ -e "$POWERSHELL_RUNTIME_PREFIX" ] || { _powershell_runtime_fail 'owned launcher lacks its canonical runtime'; return; }
  fi

  _powershell_runtime_create_parents "${POWERSHELL_RUNTIME_PREFIX%/*}" || { _powershell_runtime_remove_empty_parents; return 1; }
  _powershell_runtime_create_parents "${POWERSHELL_RUNTIME_LAUNCHER%/*}" || { _powershell_runtime_remove_empty_parents; return 1; }
  _powershell_runtime_safe_ancestors "${POWERSHELL_RUNTIME_PREFIX%/*}" || { _powershell_runtime_remove_empty_parents; return 1; }
  _powershell_runtime_safe_ancestors "${POWERSHELL_RUNTIME_LAUNCHER%/*}" || { _powershell_runtime_remove_empty_parents; return 1; }

  work=$(mktemp -d "${POWERSHELL_RUNTIME_PREFIX%/*}/.powershell-runtime.work.XXXXXX") || { _powershell_runtime_remove_empty_parents; return 1; }
  chmod 0700 "$work" || { _powershell_runtime_remove_tree "$work"; _powershell_runtime_remove_empty_parents; return 1; }
  cleanup=$work
  trap '[ -z "${cleanup:-}" ] || _powershell_runtime_remove_tree "$cleanup"; [ -z "${cleanup:-}" ] || _powershell_runtime_remove_empty_parents' EXIT
  if [ -n "$supplied_archive" ]; then
    archive=$supplied_archive
  else
    archive=$work/powershell.tar.gz
    curl -fsSL -o "$archive" "https://github.com/PowerShell/PowerShell/releases/download/v${POWERSHELL_VERSION}/powershell-${POWERSHELL_VERSION}-linux-${archive_arch}.tar.gz" || { _powershell_runtime_fail 'archive download failed'; return; }
  fi
  [ -f "$archive" ] || { _powershell_runtime_fail 'archive is not a regular file'; return; }
  printf '%s  %s\n' "$archive_sha" "$archive" | sha256sum -c - >/dev/null 2>&1 || { _powershell_runtime_fail 'archive digest mismatch'; return; }

  stage=$work/runtime
  mkdir -m 0700 "$stage" || return 1
  tar -xzf "$archive" -C "$stage" --no-same-owner --no-same-permissions || { _powershell_runtime_fail 'archive extraction failed'; return; }
  [ -f "$stage/pwsh" ] && [ ! -L "$stage/pwsh" ] || { _powershell_runtime_fail 'archive lacks a regular pwsh'; return; }
  chmod 0755 "$stage/pwsh" || return 1
  mkdir -m 0700 "$stage/.powershell-cache" || return 1
  [ "$(powershell_runtime_with_cache "$stage/.powershell-cache" "$stage/pwsh" --version 2>/dev/null)" = "PowerShell $POWERSHELL_VERSION" ] || { _powershell_runtime_fail 'authenticated runtime reports the wrong version'; return; }
  printf '%s\n%s\n' "$archive_sha" "$(realpath -s -- "$POWERSHELL_RUNTIME_PREFIX/pwsh")" > "$stage/.canonical-powershell-runtime" || return 1
  chmod 0644 "$stage/.canonical-powershell-runtime" || return 1

  if [ -e "$POWERSHELL_RUNTIME_PREFIX" ]; then
    old_prefix=$work/old-runtime
    mv -- "$POWERSHELL_RUNTIME_PREFIX" "$old_prefix" || return 1
  fi
  mv -- "$stage" "$POWERSHELL_RUNTIME_PREFIX" || { [ -z "$old_prefix" ] || mv -- "$old_prefix" "$POWERSHELL_RUNTIME_PREFIX"; return 1; }

  mkdir -p -- "${POWERSHELL_RUNTIME_LAUNCHER%/*}" || return 1
  launcher_tmp=$(mktemp "${POWERSHELL_RUNTIME_LAUNCHER%/*}/.pwsh.launcher.XXXXXX") || return 1
  _powershell_runtime_wrapper > "$launcher_tmp" && chmod 0755 "$launcher_tmp" && mv -f -- "$launcher_tmp" "$POWERSHELL_RUNTIME_LAUNCHER" || {
    rm -f -- "$launcher_tmp"; _powershell_runtime_remove_tree "$POWERSHELL_RUNTIME_PREFIX"; [ -z "$old_prefix" ] || mv -- "$old_prefix" "$POWERSHELL_RUNTIME_PREFIX"; return 1;
  }
  [ -z "$old_prefix" ] || _powershell_runtime_remove_tree "$old_prefix"
  cleanup=
  _powershell_runtime_remove_tree "$work"
)

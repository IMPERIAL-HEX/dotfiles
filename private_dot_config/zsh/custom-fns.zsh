monoJpreview() {
  local target="${1:-.}"

  find "$target" \
    \( -type d \( \
      -name node_modules -o \
      -name .next -o \
      -name .dist -o \
      -name dist -o \
      -name .turbo \
    \) -print -prune \) \
    -o \( -type f \( \
      -name ".DS_Store" -o \
      -name "npm-debug.log*" -o \
      -name "yarn-debug.log*" -o \
      -name "yarn-error.log*" -o \
      -name "pnpm-debug.log*" \
    \) -print \)
}

monoJclean() {
  local target="${1:-.}"

  find "$target" \
    \( -type d \( \
      -name node_modules -o \
      -name .next -o \
      -name .dist -o \
      -name dist -o \
      -name .turbo \
    \) -print -prune \) \
    -o \( -type f \( \
      -name ".DS_Store" -o \
      -name "npm-debug.log*" -o \
      -name "yarn-debug.log*" -o \
      -name "yarn-error.log*" -o \
      -name "pnpm-debug.log*" \
    \) -print \) \
    | xargs -r rm -rf
}

# dotfiles

Dotfiles for hex's machines, managed with [chezmoi](https://chezmoi.io). The repo also carries the machine-bootstrap payload in `.install/`.

## What is managed

- zsh: `.zshrc`, `.zshenv`, and the real config in `.config/zsh/` (zoxide initializes last in `tools.zsh`; keep it there)
- git: `.gitconfig` and the global ignore at `.config/git/ignore`
- neovim: `.config/nvim/` (LazyVim; `lazy-lock.json` pins the plugins). The nvim binary itself comes from [bob](https://github.com/MordechaiHadad/bob), never apt — `env.zsh` puts `~/.local/share/bob/nvim-bin` on PATH.
- terminals and editors: `.config/ghostty/config`, `.config/zed/`
- btop: `btop.conf` and `themes/` only — `btop.log` is churn, never add it
- GNOME file-manager bookmarks: `.config/gtk-3.0/bookmarks`
- Claude Code: `.claude/settings.json`, `.claude/rules/`, and the hand-written `.claude/skills/kb/`. Marketplace skills are reinstallable and stay out.
- `.bashrc` as a fallback shell

Never added: `.ssh`, `.gnupg`, `.aws`, `.npmrc`, `.password-store`, any `credentials.json`, `.zsh_history`, `.zcompdump*`, app state under `.config` (Code, Chrome, Slack, and the rest). Credentials are re-created on each machine, not synced.

`.gitconfig` references `~/ws-work/.gitconfig-work` for the work identity. That file lives in the work tree and is not synced.

## Daily use

chezmoi copies files between here (the source) and `$HOME` (the target). Nothing is symlinked.

Add a new file or directory:

    chezmoi add ~/.config/foo/config

Adding a directory recurses. Add specific files when the directory mixes config with state, the way `.config/btop` does.

After editing a managed file in place (the normal case):

    chezmoi re-add        # pull your edits into the source
    chezmoi cd            # subshell in this repo
    git add -A && git commit -m "..." && git push

Or edit through chezmoi and push the other way:

    chezmoi edit ~/.zshrc
    chezmoi diff          # review before touching $HOME
    chezmoi apply

On another machine, pull changes:

    chezmoi update        # git pull + apply

Sanity checks:

    chezmoi managed       # everything under management
    chezmoi diff          # empty means $HOME matches the repo
    chezmoi doctor

File naming in the source: `dot_` becomes a leading dot, `private_` means mode 0600, `.tmpl` files run through templating. `chezmoi add` picks these for you. `.chezmoiignore` lists target paths chezmoi must not manage — `README.md` is there so it stays a repo doc instead of landing in `$HOME`.

There are no templates yet. When a second machine needs a different value (the first candidate is `.gitconfig`), rename the source file to `.tmpl` and branch on `.chezmoi.hostname`.

## New machine

    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin
    ~/.local/bin/chezmoi init https://github.com/IMPERIAL-HEX/dotfiles.git
    SKIP="android" ~/.local/share/chezmoi/.install/bootstrap.sh

The clone is HTTPS on purpose: pushes and private-repo pulls authenticate through git-credential-manager (browser sign-in on first use), not SSH keys. `SKIP` is optional — leave it off to install every group.

`bootstrap.sh` runs phases in order: apt repos, apt, scripted installers (ghostty, gcm, neovim via bob — `.install/installers/`, each fetches the latest release and is safe to rerun), snap/flatpak, node (nvm), oh-my-zsh, `chezmoi apply`, GNOME extensions, dconf, `chsh`. Extensions must install before the dconf load or their settings vanish silently. Failures collect in `failed.txt`; rerun a single phase with `./bootstrap.sh <phase>`. Package choices live in `.install/packages.yml` — edit that file, not the script. Packages under an `apt_group_<name>:` key are optional per machine: `SKIP="android" ./bootstrap.sh` leaves that group out.

After bootstrap, authenticate fresh: `ssh-keygen -t ed25519`, upload the key to GitHub, `gpg --full-generate-key` if needed, sign in to browsers and the password manager through their own sync.

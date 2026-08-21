# dotfiles

Dotfiles for hex's machines, managed with [chezmoi](https://chezmoi.io). The repo also carries the machine-bootstrap payload in `.install/`.

## How it works

This repo is the source. The real dotfiles live in `$HOME`. chezmoi copies between the two — nothing is symlinked.

Sync to GitHub is automatic: every chezmoi command that changes the repo (`add`, `re-add`, `forget`, `destroy`) also commits and pushes. You never type git for dotfiles. The one place you do is the payload files, covered below.

In the repo, file names encode the target: `dot_zshrc` becomes `.zshrc`, `private_` means mode 0600, `.tmpl` runs through templating. `chezmoi add` picks these for you. `.chezmoiignore` lists paths chezmoi pretends do not exist: `README.md` (so this doc never lands in `$HOME`) and `.config/btop/btop.log` (churn).

## The daily habit

Edit any managed dotfile with your normal editor. Then run one command:

    chezmoi re-add

That copies the edit into the repo, commits, and pushes. Done.

To see what changed before syncing it:

    chezmoi status    # which dotfiles differ from the repo (M = modified)
    chezmoi diff      # the exact difference — shown as what `apply` would undo

Regret the edit? Run `chezmoi apply` instead of `re-add`: the repo version wins and your file is restored.

`re-add` only refreshes files already under management. A brand-new file — even inside a managed folder — needs `chezmoi add` once.

On another machine, pull whatever was pushed:

    chezmoi update

## Adding files

    chezmoi add ~/.config/foo/config     # one file
    chezmoi add ~/.config/foo            # a folder, recursively

Both commit and push on their own. Never add a secret — it lands on GitHub immediately.

When a folder mixes config with state, take only what you want: add the keepers by name, and put the junk in `.chezmoiignore` so even a later whole-folder add skips it. That is the btop setup —

    chezmoi add ~/.config/btop/btop.conf ~/.config/btop/themes

with `.config/btop/btop.log` in `.chezmoiignore`. `chezmoi unmanaged ~/.config/btop` shows what a folder still has outside management.

## Removing files

    chezmoi forget ~/.bashrc      # stop syncing; the real file stays in $HOME
    chezmoi destroy ~/.bashrc     # stop syncing AND delete the real file

`forget` when the file should live on unmanaged, `destroy` when it should not exist at all. Git history keeps the old content either way.

## The payload: .install/ and this README

These are repo files, not dotfiles: chezmoi never deploys them and `chezmoi status` never shows them. Editing them is the one case where you type git, through chezmoi's passthrough:

    chezmoi git -- add -A
    chezmoi git -- commit -m "..."
    chezmoi git -- push

Skipping this loses nothing — the next auto-commit stages the whole repo and sweeps the edits along. Pushing yourself gets them a proper commit message and an immediate sync.

## Checks

    chezmoi status        # empty: $HOME matches the repo
    chezmoi git -- status # empty: the repo matches GitHub
    chezmoi managed       # everything under management
    chezmoi doctor        # config and environment health

## What is managed

- zsh: `.zshrc`, `.zshenv`, and the real config in `.config/zsh/` (zoxide initializes last in `tools.zsh`; keep it there)
- git: `.gitconfig` and the global ignore at `.config/git/ignore`
- neovim: `.config/nvim/` (LazyVim; `lazy-lock.json` pins the plugins). The nvim binary itself comes from [bob](https://github.com/MordechaiHadad/bob), never apt — `env.zsh` puts `~/.local/share/bob/nvim-bin` on PATH.
- terminals and editors: `.config/ghostty/config`, `.config/zed/`
- btop: `btop.conf` and `themes/` only
- GNOME file-manager bookmarks: `.config/gtk-3.0/bookmarks`
- Claude Code: `.claude/settings.json`, `.claude/rules/`, and the hand-written `.claude/skills/kb/`. Marketplace skills are reinstallable and stay out.
- `.bashrc` as a fallback shell

Never added: `.ssh`, `.gnupg`, `.aws`, `.npmrc`, `.password-store`, any `credentials.json`, `.zsh_history`, `.zcompdump*`, app state under `.config` (Code, Chrome, Slack, and the rest). Credentials are re-created on each machine, not synced.

`.gitconfig` references `~/ws-work/.gitconfig-work` for the work identity. That file lives in the work tree and is not synced.

There are no templates yet. When a second machine needs a different value (the first candidate is `.gitconfig`), rename the source file to `.tmpl` and branch on `.chezmoi.hostname`.

## New machine

    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin
    ~/.local/bin/chezmoi init https://github.com/IMPERIAL-HEX/dotfiles.git
    SKIP="android" ~/.local/share/chezmoi/.install/bootstrap.sh

The clone is HTTPS on purpose: pushes and private-repo pulls authenticate through git-credential-manager (browser sign-in on first use), not SSH keys. `SKIP` is optional — leave it off to install every group.

`bootstrap.sh` runs phases in order: apt repos, apt, scripted installers (ghostty, gcm, neovim via bob — `.install/installers/`, each fetches the latest release and is safe to rerun), snap/flatpak, node (nvm), oh-my-zsh, `chezmoi apply`, GNOME extensions, dconf, `chsh`. Extensions must install before the dconf load or their settings vanish silently. Failures collect in `failed.txt`; rerun a single phase with `./bootstrap.sh <phase>`. Package choices live in `.install/packages.yml` — edit that file, not the script. Packages under an `apt_group_<name>:` key are optional per machine: `SKIP="android" ./bootstrap.sh` leaves that group out.

After bootstrap, authenticate fresh: `ssh-keygen -t ed25519`, upload the key to GitHub, `gpg --full-generate-key` if needed, sign in to browsers and the password manager through their own sync.

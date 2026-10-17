# dotfiles

Dotfiles managed with [chezmoi](https://chezmoi.io). The repo also carries the machine-bootstrap payload in `.install/`.

## How it works

This repo is the source. The real dotfiles live in `$HOME`. chezmoi copies between the two — nothing is symlinked.

Sync to GitHub is automatic: every chezmoi command that changes the repo (`add`, `re-add`, `forget`, `destroy`) also commits and pushes. You never type git for dotfiles. The one place you do is the payload files, covered below.

The auto-sync setting lives in `.chezmoi.toml.tmpl`, the template chezmoi generates its real config from. Whenever that template changes — edited here, or pulled onto another machine by `chezmoi update` — chezmoi warns `config file template has changed, run chezmoi init to regenerate config file`. That is not an error: chezmoi refuses to rewrite its own config silently and wants you to trigger it. Run `chezmoi init` (no arguments) and the warning clears.

In the repo, file names encode the target: `dot_zshrc` becomes `.zshrc`, `private_` means mode 0600, `.tmpl` runs through templating. `chezmoi add` picks these for you. `.chezmoiignore.tmpl` lists paths chezmoi pretends do not exist: always `README.md`, `.gitignore`, and `.config/btop/btop.log`, plus per-platform exclusions (see Platforms).

`.gitignore` protects common environment files, keys, and credential stores from Git. It is not deployed. Keep secrets out of this public repository; `private_` limits target-file permissions but does not encrypt a file.

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

    chezmoi forget ~/.bashrc      # stop syncing; removes it from the repo and GitHub, the file in $HOME stays
    chezmoi destroy ~/.bashrc     # forget + DELETE the real file from $HOME too

`forget` when the file should live on unmanaged, `destroy` when it should not exist anywhere.

"Stop syncing and remove it from the remote" is just `forget`: the auto-push commits the removal, so the file disappears from GitHub's current version in the same command. Git history still holds the old content either way — if the file held a secret, rotate the secret; only a history rewrite truly scrubs it.

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
- neovim: `.config/nvim/` (LazyVim; `lazy-lock.json` pins the plugins). The nvim binary itself comes from [bob](https://github.com/MordechaiHadad/bob), never apt — `env.zsh` puts `~/.local/share/bob/nvim-bin` on PATH.
- terminals and editors: `.config/ghostty/config`, `.config/zed/`
- btop: `btop.conf` and `themes/` only
- Claude Code: `.claude/settings.json` and `.claude/rules/`. Marketplace skills are reinstallable and stay out.
- `.bashrc` as a fallback shell

Never added: `.ssh`, `.gnupg`, `.aws`, `.npmrc`, `.password-store`, any `credentials.json`, `.zsh_history`, `.zcompdump*`, app state under `.config` (Code, Chrome, Slack, and the rest). Credentials are re-created on each machine, not synced.

## Platforms

The same repo serves three kinds of machine. `.chezmoi.toml.tmpl` detects which one it is on and stores it as `.platform`, which any template can branch on:

- `linux`: native Ubuntu desktop. Everything applies, including GNOME, Ghostty and Zed.
- `wsl`: Ubuntu under WSL2 on a Windows machine. Shell, Neovim and CLI config apply; GNOME bookmarks, Ghostty and Zed are ignored because Windows owns the desktop. Neovim's clipboard goes through `clip.exe` (`options.lua`).
- `windows`: chezmoi running natively on Windows. Linux shell/editor config is ignored. This instance never auto-commits or pushes: WSL is the canonical place to edit the repo, Windows only runs `chezmoi update`.

`bootstrap.sh` detects native Linux vs WSL the same way. Under WSL it skips apt repos, desktop apps, Docker CE, Ghostty, git-credential-manager, snap/flatpak, GNOME extensions and dconf, since Windows provides the desktop and Docker Desktop provides Docker. The Ubuntu codename is read from `/etc/os-release`, so nothing assumes a specific release.

Keys marked `[linux-only]` in `packages.yml` are skipped under WSL.

When a file needs different content per machine (the first candidate is `.gitconfig`), rename the source file to `.tmpl` and branch on `.platform` or `.chezmoi.hostname`.

Note: .gitconfig is not managed because work or personal pc can differ in the root git account.

## New machine

    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin
    ~/.local/bin/chezmoi init <repo-url>
    ~/.local/share/chezmoi/.install/bootstrap.sh

On WSL, authenticate GitHub first so a private repo can be cloned, then run the same commands; the bootstrap picks the WSL phases automatically:

    sudo apt update && sudo apt install -y gh
    gh auth login && gh auth setup-git

`bootstrap.sh` re-applies from whatever repo `chezmoi init` cloned; set `DOTFILES_REPO=<url>` to use a different one.

The clone is HTTPS on purpose. On native Linux, pushes and private-repo pulls authenticate through git-credential-manager (browser sign-in on first use); under WSL, `gh auth setup-git` makes `gh` the credential helper instead. `SKIP` is optional — leave it off to install every group.

On native Linux, `bootstrap.sh` runs phases in order: apt repos, apt, scripted installers (ghostty, gcm, neovim via bob — `.install/installers/`, each fetches the latest release and is safe to rerun), snap/flatpak, node (nvm), oh-my-zsh, `chezmoi apply`, GNOME extensions, dconf, `chsh`. Extensions must install before the dconf load or their settings vanish silently. Failures collect in `failed.txt`; rerun a single phase with `./bootstrap.sh <phase>`. Package choices live in `.install/packages.yml` — edit that file, not the script. Packages under an `apt_group_<name>:` key are optional per machine: `SKIP="<name>" ./bootstrap.sh` leaves that group out.

After bootstrap, authenticate fresh: `ssh-keygen -t ed25519`, upload the key to GitHub, `gpg --full-generate-key` if needed, sign in to browsers and the password manager through their own sync.

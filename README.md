# pathaction.el - Execute the pathaction command-line tool from Emacs
![Build Status](https://github.com/jamescherti/pathaction.el/actions/workflows/ci.yml/badge.svg)
![License](https://img.shields.io/github/license/jamescherti/pathaction.el)
![](https://jamescherti.com/misc/made-for-gnu-emacs.svg)

Execute pathaction.yaml rules using the pathaction command-line tool.

(The [pathaction](https://github.com/jamescherti/pathaction) command-line tool enables the execution of specific commands on targeted files or directories. Its key advantage lies in its flexibility, allowing users to handle various types of files simply by passing the file or directory as an argument to the `pathaction` tool. The tool uses a `.pathaction.yaml` rule-set file to determine which command to execute. Additionally, Jinja2 templating can be employed in the rule-set file to further customize the commands.)

## Requirements

- The [pathaction](https://github.com/jamescherti/pathaction) command-line tool.

## Installation

### Install with straight (Emacs version < 30)

To install `pathaction` with `straight.el`:

1. It if hasn't already been done, [add the straight.el bootstrap code](https://github.com/radian-software/straight.el?tab=readme-ov-file#getting-started) to your init file.
2. Add the following code to the Emacs init file:
```emacs-lisp
(use-package pathaction
  :ensure t
  :straight (pathaction
             :type git
             :host github
             :repo "jamescherti/pathaction.el")
  :config
  (add-to-list 'display-buffer-alist '("\\*pathaction:"
                                       (display-buffer-at-bottom)
                                       (window-height . 0.33))))
```

### Installing with use-package and :vc (Built-in feature in Emacs version >= 30)

To install `pathaction` with `use-package` and `:vc` (Emacs >= 30):

``` emacs-lisp
(use-package pathaction
  :ensure t
  :vc (:url "https://github.com/jamescherti/pathaction.el"
       :rev :newest)
  :config
  (add-to-list 'display-buffer-alist '("\\*pathaction:"
                                         (display-buffer-at-bottom)
                                         (window-height . 0.33))))
```

## Usage

### Run

To execute the `pathaction` action that is tagged with `main`, you can call the following Emacs function:
``` emacs-lisp
(pathaction-run "main")
```

- **`pathaction-run`**: This is the main function for triggering `pathaction` actions.
- **`"main"`**: This is the tag used to identify a specific action. The tag you provide to the function determines which set of actions will be executed. In this case, `"main"` refers to the actions that are specifically tagged with this name.

### Edit the pathaction.yaml file

To edit the `pathaction.yaml` file, use the following function, which will prompt you to select one of the `pathaction.yaml` files in the parent directories:

```emacs-lisp
(pathaction-edit)
```

## Customization

## Making pathaction open a window under the current one?

To configure `pathaction` to open its window under the current one, you can use the `display-buffer-alist` variable to customize how the `pathaction` buffer is displayed. Specifically, you can use the `display-buffer-at-bottom` action, which will display the buffer in a new window at the bottom of the current frame.

Here's the code to do this:
``` emacs-lisp
(add-to-list 'display-buffer-alist '("\\*pathaction:"
                                     (display-buffer-at-bottom)
                                     (window-height . 0.33)))
```

## Hooks

- `pathaction-before-run-hook`: This hook is executed by `pathaction-run` before the `pathaction` command is executed. By default, it calls the `save-some-buffers` function to prompt saving any modified buffers:
  ```emacs-lisp
  (setq pathaction-before-run-hook '(save-some-buffers))
  ```
- `pathaction-after-create-buffer-hook`: This hook is executed after the pathaction buffer is created. It runs from within the pathaction buffer, enabling further customization or actions once the buffer is available.

## Saving all buffers before executing pathaction

By default, `pathaction-before-run-hook` only calls a function to save the current buffer before executing actions or commands that affect the current or any other edited buffer.

To make `pathaction` save all buffers, use the following configuration:
```emacs-lisp
(defun my-save-some-buffers ()
  "Prevent `save-some-buffers' from prompting by passing 1 to it."
  (save-some-buffers))

(add-hook 'pathaction-before-run-hook #'my-save-some-buffers)
```

(If you want to prevent `save-some-buffers` from prompting the user before saving, replace `(save-some-buffers)` with `(save-some-buffers t)`.)

## Author and License

The *pathaction* Emacs package has been written by [James Cherti](https://www.jamescherti.com/) and is distributed under terms of the GNU General Public License version 3, or, at your choice, any later version.

Copyright (C) 2025 James Cherti

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with this program.

## Links

- Emacs package: [pathaction.el @GitHub](https://github.com/jamescherti/pathaction.el)
- The `pathaction` command-line tool (requirement): [pathaction](https://github.com/jamescherti/pathaction)
- For Vim users: [vim-pathaction](https://github.com/jamescherti/vim-pathaction), a Vim plugin that allows executing the `pathaction` command-line tool directly from Vim.

Other Emacs packages by the same author:
- [compile-angel.el](https://github.com/jamescherti/compile-angel.el): **Speed up Emacs!** This package guarantees that all .el files are both byte-compiled and native-compiled, which significantly speeds up Emacs.
- [outline-indent.el](https://github.com/jamescherti/outline-indent.el): An Emacs package that provides a minor mode that enables code folding and outlining based on indentation levels for various indentation-based text files, such as YAML, Python, and other indented text files.
- [easysession.el](https://github.com/jamescherti/easysession.el): Easysession is lightweight Emacs session manager that can persist and restore file editing buffers, indirect buffers/clones, Dired buffers, the tab-bar, and the Emacs frames (with or without the Emacs frames size, width, and height).
- [vim-tab-bar.el](https://github.com/jamescherti/vim-tab-bar.el): Make the Emacs tab-bar Look Like Vim's Tab Bar.
- [elispcomp](https://github.com/jamescherti/elispcomp): A command line tool that allows compiling Elisp code directly from the terminal or from a shell script. It facilitates the generation of optimized .elc (byte-compiled) and .eln (native-compiled) files.
- [tomorrow-night-deepblue-theme.el](https://github.com/jamescherti/tomorrow-night-deepblue-theme.el): The Tomorrow Night Deepblue Emacs theme is a beautiful deep blue variant of the Tomorrow Night theme, which is renowned for its elegant color palette that is pleasing to the eyes. It features a deep blue background color that creates a calming atmosphere. The theme is also a great choice for those who miss the blue themes that were trendy a few years ago.
- [Ultyas](https://github.com/jamescherti/ultyas/): A command-line tool designed to simplify the process of converting code snippets from UltiSnips to YASnippet format.
- [dir-config.el](https://github.com/jamescherti/dir-config.el): Automatically find and evaluate .dir-config.el Elisp files to configure directory-specific settings.
- [flymake-bashate.el](https://github.com/jamescherti/flymake-bashate.el): A package that provides a Flymake backend for the bashate Bash script style checker.
- [flymake-ansible-lint.el](https://github.com/jamescherti/flymake-ansible-lint.el): An Emacs package that offers a Flymake backend for ansible-lint.
- [inhibit-mouse.el](https://github.com/jamescherti/inhibit-mouse.el): A package that disables mouse input in Emacs, offering a simpler and faster alternative to the disable-mouse package.
- [quick-sdcv.el](https://github.com/jamescherti/quick-sdcv.el): This package enables Emacs to function as an offline dictionary by using the sdcv command-line tool directly within Emacs.
- [enhanced-evil-paredit.el](https://github.com/jamescherti/enhanced-evil-paredit.el): An Emacs package that prevents parenthesis imbalance when using *evil-mode* with *paredit*. It intercepts *evil-mode* commands such as delete, change, and paste, blocking their execution if they would break the parenthetical structure.
- [stripspace.el](https://github.com/jamescherti/stripspace.el): Ensure Emacs Automatically removes trailing whitespace before saving a buffer, with an option to preserve the cursor column.
- [persist-text-scale.el](https://github.com/jamescherti/persist-text-scale.el): Ensure that all adjustments made with text-scale-increase and text-scale-decrease are persisted and restored across sessions.

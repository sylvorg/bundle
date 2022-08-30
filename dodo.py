from pathlib import Path
from doit import get_initial_workdir
from subprocess import Popen, PIPE
from collections import namedtuple
from io import TextIOWrapper

DOIT_CONFIG = {
    "verbosity": 2,
    "uptodate": False,
}

output = namedtuple("output", "stdout stderr returncode")

def run(command):
    p = Popen(command, shell = True, stdout = PIPE, stderr = PIPE)
    p.wait()
    return output(TextIOWrapper(p.stdout).read(), TextIOWrapper(p.stderr).read(), p.returncode)

cwf = __file__
cwp = Path.cwd()
cwd = str(cwp)
ind = get_initial_workdir()
preFiles = " ".join(f"{cwd}/{file}" for file in ("nix.org", "flake.org", "tests.org", "README.org"))

removeTangleBackups = f"find {cwd} -name '.\#*.org*' -print | xargs rm &> /dev/null || :"

def fallbackCommand(command, _files):
    return f"""
        {removeTangleBackups}
        {command}
        if [ $? -ne 0 ]; then
            org-tangle -f {_files} > /dev/null
            {command}
        fi
    """

def preFallback(command):
    return fallbackCommand(command, preFiles)

def nixShell(_type):
    return "nix-shell -E '(import $(realfileDir)).devShells.${builtins.currentSystem}.makefile-" + _type + "' --show-trace --run"

def quickShell(pkgs):
    return "nix-shell -E 'with (import $(realfileDir)).pkgs.${builtins.currentSystem}; with lib; mkShell { buildInputs = flatten [ " + pkgs + " ]; }' --show-trace"

projectName = run(preFallback(f"nix eval --show-trace --impure --expr '(import {cwd}).pname")).stdout
type = run(preFallback(f"nix eval --show-trace --impure --expr '(import {cwd}).type")).stdout

files = f"{preFiles} {cwd}/{projectName}"

def fallback(command):
    return fallbackCommand(command, files)

addCommand = f"git -C {cwd} add ."
updateCommand = fallback(f"nix flake update --show-trace {cwd}")

def tangleCommand(_files):
    return f"""
        {removeTangleBackups}
        {nixShell("general")}
        if [ $? -ne 0 ]; then
            org-tangle -f {_files} > /dev/null
        fi
        {addCommand}
    """

def task_add():
    return { "actions": [ addCommand ] }

def task_commit():
    return {
        "actions": [ f'git -C {cwd} commit --allow-empty-message -am ""' ],
        "task_dep": [ "add" ],
    }

def task_push():
    return {
        "actions": [ f"git -C {cwd} push" ],
        "task_dep": [ "commit" ],
    }

def task_update():
    command = "nix eval --impure --expr 'with (import " + cwd + '); with pkgs.${builtins.currentSystem}.lib; "nix flake lock ' + cwd + """
         --update-input ${concatStringsSep " --update-input " (filter (input: ! ((elem input [ "nixos-master" "nixos-unstable" ]) || (hasSuffix "-small" input))) (attrNames inputs))}"' | tr -d '"')
    """
    def update(all, inputs):
        if inputs:
            if ("settings" in inputs) and (projectName == "settings"):
                inputs.remove("settings")
            if inputs:
                return fallback(f'nix flake lock {cwd} --show-trace --update-input {"--update-input ".join(inputs)}')
            else:
                return command
        elif all:
            return updateCommand
        elif projectName == "settings":
            return command
        else:
            return updateCommand
    return {
        "actions": [ (update,) ],
        "params": [{
            "name": "all",
            "short": "a",
            "type": bool,
            "default": False,
        }, {
            "name": "inputs",
            "short": "i",
            "type": list,
            "default": [],
        }],
        "task_dep": [ "add" ],
    }

def task_pre_tangle():
    return {
        "actions": [ removeTangleBackups ],
        "getargs": { { "values": ("update", None, ) } },
    }

def task_tangle():
    def tangle(_files):
        return tangleCommand(_files or files)
    return {
        "actions": [ (tangle,) ],
        "task_dep": [ "pre_tangle" ],
        "params": [{
            "name": "_files",
            "short": "f",
            "long": "files",
            "type": list,
            "default": [],
        }]
    }
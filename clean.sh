#!/bin/sh

find . 2>/dev/null | sed s:'./'::g | grep -vi .sh | grep -vi .git | xargs -I {} rm -rf "{}" 2>/dev/null
rm -rf .gitignore
git checkout .

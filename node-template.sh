# https://github.com/thilllon/template
# --------------------------------
# TODO:
# - @npmcli 이용하기 https://www.npmjs.com/package/@npmcli/git
# - git으로 관리하고 github action 이용해서 gist로 발행하기

# --------------------------------
# setup
# --------------------------------
pnpm init
pnpm add -D typescript @types/node tsx
pnpm tsc --init

echo '# $(basename $(pwd))' >>README.md

echo 'registry=https://registry.npmjs.org/' >>.npmrc
echo '# registry=https://registry.npmjs.cf/' >>.npmrc

mkdir src
touch src/index.ts
echo 'node_modules
dist
.env*
!.env.example
' >>.gitignore

# --------------------------------
# package.json
# --------------------------------
npm pkg set 'license'='MIT'
npm pkg set 'packageManager'="pnpm@$(pnpm -v)"
npm pkg set 'main'='dist/index.js'
npm pkg set 'types'='dist/index.d.ts'
npm pkg set 'files'[]='dist'

npx npm-add-script -f -k "dev" -v "tsx src/index.ts"
npx npm-add-script -f -k "build" -v "tsup"
npx npm-add-script -f -k "build:tsc" -v "tsc"
npx npm-add-script -f -k "start" -v "node dist/index.js"

# --------------------------------
# .vscode
# --------------------------------
mkdir -p .vscode
touch .vscode/settings.json
touch .vscode/extensions.json
echo '{}' >.vscode/settings.json
echo '{
  "recommendations": [
    "dbaeumer.vscode-eslint",
    "esbenp.prettier-vscode",
  ]
}' >.vscode/extensions.json

# --------------------------------
# github action
# --------------------------------
mkdir -p .github/workflows
touch .github/workflows/main.yml

# --------------------------------
# test
# --------------------------------
pnpm add -D jest ts-jest @jest/globals @swc/jest
pnpm ts-jest config:init
npx npm-add-script -f -k "test" -v "jest"
mkdir -p test
touch test/index.test.ts
echo '
import {describe, expect, test} from "@jest/globals";

describe("test", () => {
  test("test", async () => {
    expect(1).toBe(1);
  }); 
});
' >test/index.test.ts

# --------------------------------
# tsup
# https://tsup.egoist.dev/#typescript--javascript
# --------------------------------
pnpm add -D tsup

echo 'import { defineConfig } from "tsup";

export default defineConfig({
  entry: ["src/index.ts"],
  splitting: false,
  sourcemap: true,
  clean: true,
  dts: true,
  minify: false,
  format: ["esm", "cjs"]
})' >tsup.config.ts

# --------------------------------
# commit, format, release
# --------------------------------

pnpm add -D husky lint-staged prettier commitlint @commitlint/config-conventional @commitlint/cli commitizen git-cz release-it

# husky https://typicode.github.io/husky/#/
pnpm dlx husky-init
npx npm-add-script --force --key "prepare" --value "husky install && chmod +x .husky/*"
pnpm install

#### precommit hook

# echo 'echo "[Node $(node -v)] $(dirname "$0")/$(basename "$0")"' >>.husky/pre-commit

echo '# Check if any staged files contain .env*' >>.husky/pre-commit
echo 'env_files=$(git diff --cached --name-only | grep '.env*')' >>.husky/pre-commit
echo 'if [ -n "$env_files" ]; then' >>.husky/pre-commit
echo '  echo "Error: Cannot commit .env files"' >>.husky/pre-commit
echo '  exit 1' >>.husky/pre-commit
echo 'fi' >>.husky/pre-commit

# lint-staged https://github.com/okonet/lint-staged#configuration
echo 'pnpm lint-staged' >>.husky/pre-commit
echo '
{
  "./**/src/**/*": ["prettier -w -l", "eslint --fix"]
}
' >>.lintstagedrc.json
# npm pkg set "lint-staged.**/src/**/*"[]="prettier -w -l"
# npm pkg set "lint-staged.**/src/**/*"[]="eslint --fix"

# commitizen https://github.com/commitizen/cz-cli
echo '
{
  "path": "cz-conventional-changelog"
}
' >>.czrc
# npm pkg set 'config.commitizen.path'='cz-conventional-changelog'

# commitlint https://github.com/conventional-changelog/commitlint
npx husky add .husky/commit-msg 'pnpm commitlint --edit $1'

#### commit-msg hook
# echo 'echo "[Node $(node -v)] $(dirname "$0")/$(basename "$0")"' >>.husky/commit-msg

#### prepare-commit-msg hook
echo 'echo "[Node $(node -v)] $(dirname "$0")/$(basename "$0")"' >>.husky/prepare-commit-msg

echo '
module.exports = {
  extends: ["@commitlint/config-conventional"]
}
' >commitlint.config.js
# npm pkg set 'commitlint.extends'[]='@commitlint/config-conventional'

# prettier
echo 'module.exports = {"printWidth": 100,"singleQuote": true, "jsxSingleQuote":true}' >.prettierrc.js
# npm pkg set 'prettier.printWidth'=100 --json
# npm pkg set 'prettier.singleQuote'=true --json

echo 'dist' >>.prettierignore
echo 'pnpm-lock.yaml' >>.prettierignore
npx npm-add-script --force --key "format" --value "prettier --write --list-different ."

# release-it https://github.com/release-it/release-it
npx npm-add-script --force --key "release" --value "pnpm format && pnpm lint && pnpm test && pnpm build && release-it"
echo '{"git": {"commitMessage": "chore: release ${version}"}, "github": {"release": true}}' >>.release-it.json
# npm pkg set 'release-it.git.commitMessage'='chore: release v${version}'
# npm pkg set 'release-it.github.release'=true

# --------------------------------
# lint
# --------------------------------
pnpm add -D eslint @typescript-eslint/eslint-plugin @typescript-eslint/parser
echo 'npm init @eslint/config' >eslint-init.sh
npx npm-add-script -f -k "lint" -v "eslint --fix ."

# --------------------------------
# github
# https://github.com/new
# --------------------------------

# --move --force
git branch -M main
# git remote add origin git@github.com:<OWNER>/<REPO>.git
# --set-upstream
# git push -u origin main

# --------------------------------
# Github Action: test, biuld, CodeQL
# https://github.com/github/codeql-action
# --------------------------------
mkdir -p .github/workflows
# touch .github/workflows/ci.yml

echo "name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  schedule:
    #        ┌───────────── minute (0 - 59)
    #        │  ┌───────────── hour (0 - 23)
    #        │  │ ┌───────────── day of the month (1 - 31)
    #        │  │ │ ┌───────────── month (1 - 12 or JAN-DEC)
    #        │  │ │ │ ┌───────────── day of the week (0 - 6 or SUN-SAT)
    #        │  │ │ │ │
    #        │  │ │ │ │
    #        │  │ │ │ │
    #        *  * * * *
    - cron: '30 1 * * 0'

jobs:
  Test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node: [16, 18]
    name: Test on Node.js \${{ matrix.node }}
    steps:
      - name: Checkout repository
        uses: actions/checkout@v3 

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: \${{ matrix.node }}

      - name: Installll

      - name: Run tests
        run: pnpm test dependencies
        run: pnpm insta

  Build:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node: [16, 18]
    name: Build on Node.js \${{ matrix.node }} 
    steps:
      - name: Build
        run: pnpm build

  CodeQL:
    runs-on: ubuntu-latest
    permissions:
      security-events: write
      actions: read
      contents: read
    steps:
      - name: Checkout repository
        uses: actions/checkout@v3

      - name: Initialize CodeQL
        uses: github/codeql-action/init@v2
        with:
          languages: go, javascript

      - name: Perform CodeQL Analysis
        uses: github/codeql-action/analyze@v2


" >>.github/workflows/ci.yml

# --------------------------------
# renovate
# https://github.com/renovatebot/tutorial
# --------------------------------
# echo '--------------------------------'
# echo 'Install github app manually'
# echo 'https://github.com/apps/renovate'
# echo '--------------------------------'

# echo '{
#   "rangeStrategy": "pin",
#   "ignorePaths": ["examples/**"],
#   "packageRules": [{
#     "packagePatterns": ["^angular.*"],
#     "groupName": "angular",
#     "automerge": true
#   }]
# }' >>renovate.json

# --------------------------------
# after all
# --------------------------------
pnpm format

# brew install gh
# gh auth login
# gh repo create

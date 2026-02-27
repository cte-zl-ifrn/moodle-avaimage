#!/usr/bin/env bash

filename=$(echo $1 | cut -d '/' -f2)
plugin_name=$(echo $filename | sed 's/_moodle.*//g' | awk '{printf "%-32s\n", $0}')
plugin_version=$(echo $filename | sed 's/.*_moodle//g' | sed 's/.*_//g' | sed 's/\.zip.*//g' | awk '{printf "%-11s\n", $0}')
plugin_type=$(echo $plugin_name | cut -d '_' -f1)
wwwroot=/var/www/html
dir=''
case $plugin_type in
    'auth')
        dir=$wwwroot/auth
        ;;
    'mod')
        dir=$wwwroot/mod
        ;;
    'block')
        dir=$wwwroot/blocks
        ;;
    'booktool')
        dir=$wwwroot/mod/book/tool
        ;;
    'filter')
        dir=$wwwroot/filter
        ;;
    'atto')
        dir=$wwwroot/lib/editor/atto/plugins
        ;;
    'tiny')
        dir=$wwwroot/lib/editor/tiny/plugins
        ;;
    'enrol')
        dir=$wwwroot/enrol
        ;;
    'tool')
        dir=$wwwroot/admin/tool
        ;;
    'availability')
        dir=$wwwroot/availability/condition
        ;;
    'qformat')
        dir=$wwwroot/question/format/
        ;;
    'report')
        dir=$wwwroot/report
        ;;
    'gradereport')
        dir=$wwwroot/grade/report
        ;;
    'gradeexport')
        dir=$wwwroot/grade/export
        ;;
    'format')
        dir=$wwwroot/course/format
        ;;
    'theme')
        dir=$wwwroot/theme
        ;;
    'local')
        dir=$wwwroot/local
        ;;
    'profilefield')
        dir=$wwwroot/user/profile/field
        ;;
    'customfield')
        dir=$wwwroot/customfield/field
        ;;
    'lang')
        dir=$wwwroot/lang
        ;;
    *)
        echo "Tipo de plugin ($plugin_type) não identificado. Tipos de plugins disponíveis: mod, block, booktool, filter, atto, tiny, enrol, tool, availability, qformat, report, gradereport, gradeexport, format, theme, local, profilefield"
        exit 1
        ;;
esac

export TERM=xterm-256color 
export COLOR_LIGHT_GREEN='\e[1;32m'
export COLOR_RED='\033[0;31m'
export COLOR_PURPLE='\033[0;35m'
export COLOR_CIAN='\033[0;36m'
export NC='\033[0m' # No Color
#export URL_BASE='https://ead.ifrn.edu.br/portal/moodle_plugins' # No Color
#export URI_BASE='https://raw.githubusercontent.com/cte-zl-ifrn/.github/refs/heads/main/moodle_plugins' # No Color
export URI_BASE='/tmp/build/plugins/' # No Color

cd $dir && \
echo -e "${COLOR_LIGHT_GREEN}INSTALL ${COLOR_RED}$plugin_name${COLOR_LIGHT_GREEN}, ${COLOR_CIAN}$plugin_version${COLOR_LIGHT_GREEN} at ${COLOR_PURPLE}$dir${NC}, from $URL_BASE/$1" && \
#curl -s -o d.zip $URL_BASE/$1 && \
#unzip -q -o d.zip && \
#rm d.zip
unzip -o "$URI_BASE/$1" -d "$dir"

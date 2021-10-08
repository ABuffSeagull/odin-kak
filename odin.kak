# https://odin-lang.org
#


# Detection
# ‾‾‾‾‾‾‾‾‾

hook global BufCreate .*\.odin %{
    set-option buffer filetype odin
}

# Initialization
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾

hook global WinSetOption filetype=odin %{
    require-module odin

    set-option window static_words %opt{odin_static_words}

    set-option window comment_line '//'
    set-option window comment_block_begin '/*'
    set-option window comment_block_end '*/'

    hook window InsertChar \n -group odin-indent odin-indent-on-new-line
}

hook -group odin-highlight global WinSetOption filetype=odin %{
    add-highlighter window/odin ref odin
    hook -once -always window WinSetOption filetype=.* %{ remove-highlighter window/odin }
}

# Highlighters
# ‾‾‾‾‾‾‾‾‾‾‾‾

provide-module odin %§

add-highlighter shared/odin regions
add-highlighter shared/odin/code default-region group
add-highlighter shared/odin/back_string region '`' '`' fill string
add-highlighter shared/odin/double_string region '"' (?<!\\)(\\\\)*" fill string
add-highlighter shared/odin/single_string region "'" (?<!\\)(\\\\)*' fill string
add-highlighter shared/odin/comment region /\* \*/ fill comment
add-highlighter shared/odin/comment_line region '//' $ fill comment

add-highlighter shared/odin/code/ regex %{\b(?i)(0b[01]+|0o[0-7]+|0x[0-9a-f_]+|-?[0-9_]*(\.[0-9_]+(e[0-9_]+)?)?i?)\b} 0:value

evaluate-commands %sh{
    keywords='package import proc for in if else switch case defer when
              break continue fallthrough return dynamic distinct struct
              enum bit_set using not_in union map or_else or_return context
              foreign where'

    attributes='#no_bounds_check #bounds_check #assert #align #packed #raw_union #soa #unroll'

    types='bool b8 b16 b32 b64
           int i8 i16 i32 i64 i128
           uint u8 u16 u32 u64 u128
           i16le i32le i64le i128le u16le u32le u64le u128le
           i16be i32be i64be i128be u16be u32be u64be u128be
           f32 f64
           complex64 complex128
           quaternion128 quaternion256
           rune
           string cstring
           rawptr
           typeid
           any'

    values='false true nil'

    functions='len cast transmute auto_cast size_of incl excl type_of typeid_of
               type_info_of cap soa_zip soa_unzip new make alloc new_clone free
               free_all delete realloc'

    join() { sep=$2; eval set -- $1; IFS="$sep"; echo "$*"; }

printf %s\\n "declare-option str-list odin_static_words $(join "${keywords} ${attributes} ${types} ${values} ${functions}" ' ')"

    printf %s "
        add-highlighter shared/odin/code/ regex \b($(join "${keywords}" '|'))\b 0:keyword
        add-highlighter shared/odin/code/ regex \b($(join "${attributes}" '|'))\b 0:attribute
        add-highlighter shared/odin/code/ regex \b($(join "${types}" '|'))\b 0:type
        add-highlighter shared/odin/code/ regex \b($(join "${values}" '|'))\b 0:value
        add-highlighter shared/odin/code/ regex \b($(join "${functions}" '|'))\b 0:builtin
    "
}

define-command -hidden odin-indent-on-new-line %~
    evaluate-commands -draft -itersel %=
        # preserve previous line indent
        try %{ execute-keys -draft <semicolon>K<a-&> }
        # indent after lines ending with { or (
        try %[ execute-keys -draft k<a-x> <a-k> [{(]\h*$ <ret> j<a-gt> ]
        # cleanup trailing white spaces on the previous line
        try %{ execute-keys -draft k<a-x> s \h+$ <ret>d }
        # align to opening paren of previous line
        try %{ execute-keys -draft [( <a-k> \A\([^\n]+\n[^\n]*\n?\z <ret> s \A\(\h*.|.\z <ret> '<a-;>' & }
        # indent after a switch's case/default statements
        try %[ execute-keys -draft k<a-x> <a-k> ^\h*(case|default).*:$ <ret> j<a-gt> ]
        # deindent closing brace(s) when after cursor
        try %[ execute-keys -draft <a-x> <a-k> ^\h*[})] <ret> gh / [})] <ret> m <a-S> 1<a-&> ]
    =
~
§

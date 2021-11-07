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
    keywords='asm auto_cast bit_set break case cast context continue defer distinct do
              dynamic else enum fallthrough for foreign if import in map not_in or_else
              or_return package proc return struct switch transmute typeid union using when
              where'
    attributes='#packed #raw_union #align #no_nil #partial #no_alias #caller_location #c_vararg
                #optional_ok #type #bounds_check #no_bounds_check #defined #file #line
                #procedure #load #load_or'

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

    functions='abs align_of append append_elem append_elems append_string #assert assert cap
               card clamp clear clear_dynamic_array clear_map complex conj copy delete
               delete_cstring delete_dynamic_array delete_key delete_map delete_slice
               delete_string excl excl_bit_set excl_elem excl_elems expand_to_tuple free imag
               incl incl_bit_set incl_elem incl_elems init_global_temporary_allocator len
               #location make make_dynamic_array make_dynamic_array_len
               make_dynamic_array_len_cap make_map make_slice max min new new_clone offset_of
               ordered_remove panic pop real reserve reserve_dynamic_array reserve_map resize
               resize_dynamic_array size_of swizzle typeid_of type_info_of type_of
               unimplemented unordered_remove unreachable'

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

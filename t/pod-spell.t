# SPDX-License-Identifier: MIT
use Test::More;
use utf8;
eval "use Test::Spelling";
plan skip_all => "Test::Spelling required for testing POD spelling" if $@;
#set_spell_cmd('hunspell -l -i utf-8');
set_spell_cmd('aspell list --encoding=utf-8');
add_stopwords(<DATA>);
all_pod_files_spelling_ok();

__DATA__
SPDX
cgi
Michal
Špaček

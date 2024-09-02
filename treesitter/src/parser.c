#include "tree_sitter/parser.h"

#if defined(__GNUC__) || defined(__clang__)
#pragma GCC diagnostic ignored "-Wmissing-field-initializers"
#endif

#define LANGUAGE_VERSION 14
#define STATE_COUNT 11
#define LARGE_STATE_COUNT 5
#define SYMBOL_COUNT 10
#define ALIAS_COUNT 0
#define TOKEN_COUNT 6
#define EXTERNAL_TOKEN_COUNT 0
#define FIELD_COUNT 0
#define MAX_ALIAS_SEQUENCE_LENGTH 3
#define PRODUCTION_ID_COUNT 1

enum ts_symbol_identifiers {
  anon_sym_or = 1,
  anon_sym_and = 2,
  anon_sym_LPAREN = 3,
  anon_sym_RPAREN = 4,
  sym_hashtag = 5,
  sym_expression = 6,
  sym_or_expression = 7,
  sym_and_expression = 8,
  sym_parenthesized_expression = 9,
};

static const char * const ts_symbol_names[] = {
  [ts_builtin_sym_end] = "end",
  [anon_sym_or] = "or",
  [anon_sym_and] = "and",
  [anon_sym_LPAREN] = "(",
  [anon_sym_RPAREN] = ")",
  [sym_hashtag] = "hashtag",
  [sym_expression] = "expression",
  [sym_or_expression] = "or_expression",
  [sym_and_expression] = "and_expression",
  [sym_parenthesized_expression] = "parenthesized_expression",
};

static const TSSymbol ts_symbol_map[] = {
  [ts_builtin_sym_end] = ts_builtin_sym_end,
  [anon_sym_or] = anon_sym_or,
  [anon_sym_and] = anon_sym_and,
  [anon_sym_LPAREN] = anon_sym_LPAREN,
  [anon_sym_RPAREN] = anon_sym_RPAREN,
  [sym_hashtag] = sym_hashtag,
  [sym_expression] = sym_expression,
  [sym_or_expression] = sym_or_expression,
  [sym_and_expression] = sym_and_expression,
  [sym_parenthesized_expression] = sym_parenthesized_expression,
};

static const TSSymbolMetadata ts_symbol_metadata[] = {
  [ts_builtin_sym_end] = {
    .visible = false,
    .named = true,
  },
  [anon_sym_or] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_and] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_LPAREN] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_RPAREN] = {
    .visible = true,
    .named = false,
  },
  [sym_hashtag] = {
    .visible = true,
    .named = true,
  },
  [sym_expression] = {
    .visible = true,
    .named = true,
  },
  [sym_or_expression] = {
    .visible = true,
    .named = true,
  },
  [sym_and_expression] = {
    .visible = true,
    .named = true,
  },
  [sym_parenthesized_expression] = {
    .visible = true,
    .named = true,
  },
};

static const TSSymbol ts_alias_sequences[PRODUCTION_ID_COUNT][MAX_ALIAS_SEQUENCE_LENGTH] = {
  [0] = {0},
};

static const uint16_t ts_non_terminal_alias_map[] = {
  0,
};

static const TSStateId ts_primary_state_ids[STATE_COUNT] = {
  [0] = 0,
  [1] = 1,
  [2] = 2,
  [3] = 3,
  [4] = 4,
  [5] = 5,
  [6] = 6,
  [7] = 7,
  [8] = 8,
  [9] = 9,
  [10] = 10,
};

static bool ts_lex(TSLexer *lexer, TSStateId state) {
  START_LEXER();
  eof = lexer->eof(lexer);
  switch (state) {
    case 0:
      if (eof) ADVANCE(5);
      if (lookahead == '#') ADVANCE(4);
      if (lookahead == '(') ADVANCE(8);
      if (lookahead == ')') ADVANCE(9);
      if (lookahead == 'a') ADVANCE(2);
      if (lookahead == 'o') ADVANCE(3);
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') SKIP(0);
      END_STATE();
    case 1:
      if (lookahead == 'd') ADVANCE(7);
      END_STATE();
    case 2:
      if (lookahead == 'n') ADVANCE(1);
      END_STATE();
    case 3:
      if (lookahead == 'r') ADVANCE(6);
      END_STATE();
    case 4:
      if (('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(10);
      END_STATE();
    case 5:
      ACCEPT_TOKEN(ts_builtin_sym_end);
      END_STATE();
    case 6:
      ACCEPT_TOKEN(anon_sym_or);
      END_STATE();
    case 7:
      ACCEPT_TOKEN(anon_sym_and);
      END_STATE();
    case 8:
      ACCEPT_TOKEN(anon_sym_LPAREN);
      END_STATE();
    case 9:
      ACCEPT_TOKEN(anon_sym_RPAREN);
      END_STATE();
    case 10:
      ACCEPT_TOKEN(sym_hashtag);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(10);
      END_STATE();
    default:
      return false;
  }
}

static const TSLexMode ts_lex_modes[STATE_COUNT] = {
  [0] = {.lex_state = 0},
  [1] = {.lex_state = 0},
  [2] = {.lex_state = 0},
  [3] = {.lex_state = 0},
  [4] = {.lex_state = 0},
  [5] = {.lex_state = 0},
  [6] = {.lex_state = 0},
  [7] = {.lex_state = 0},
  [8] = {.lex_state = 0},
  [9] = {.lex_state = 0},
  [10] = {.lex_state = 0},
};

static const uint16_t ts_parse_table[LARGE_STATE_COUNT][SYMBOL_COUNT] = {
  [0] = {
    [ts_builtin_sym_end] = ACTIONS(1),
    [anon_sym_or] = ACTIONS(1),
    [anon_sym_and] = ACTIONS(1),
    [anon_sym_LPAREN] = ACTIONS(1),
    [anon_sym_RPAREN] = ACTIONS(1),
    [sym_hashtag] = ACTIONS(1),
  },
  [1] = {
    [sym_expression] = STATE(9),
    [sym_or_expression] = STATE(5),
    [sym_and_expression] = STATE(5),
    [sym_parenthesized_expression] = STATE(5),
    [anon_sym_LPAREN] = ACTIONS(3),
    [sym_hashtag] = ACTIONS(5),
  },
  [2] = {
    [sym_expression] = STATE(10),
    [sym_or_expression] = STATE(5),
    [sym_and_expression] = STATE(5),
    [sym_parenthesized_expression] = STATE(5),
    [anon_sym_LPAREN] = ACTIONS(3),
    [sym_hashtag] = ACTIONS(5),
  },
  [3] = {
    [sym_expression] = STATE(7),
    [sym_or_expression] = STATE(5),
    [sym_and_expression] = STATE(5),
    [sym_parenthesized_expression] = STATE(5),
    [anon_sym_LPAREN] = ACTIONS(3),
    [sym_hashtag] = ACTIONS(5),
  },
  [4] = {
    [sym_expression] = STATE(8),
    [sym_or_expression] = STATE(5),
    [sym_and_expression] = STATE(5),
    [sym_parenthesized_expression] = STATE(5),
    [anon_sym_LPAREN] = ACTIONS(3),
    [sym_hashtag] = ACTIONS(5),
  },
};

static const uint16_t ts_small_parse_table[] = {
  [0] = 1,
    ACTIONS(7), 4,
      ts_builtin_sym_end,
      anon_sym_or,
      anon_sym_and,
      anon_sym_RPAREN,
  [7] = 1,
    ACTIONS(9), 4,
      ts_builtin_sym_end,
      anon_sym_or,
      anon_sym_and,
      anon_sym_RPAREN,
  [14] = 2,
    ACTIONS(13), 1,
      anon_sym_and,
    ACTIONS(11), 3,
      ts_builtin_sym_end,
      anon_sym_or,
      anon_sym_RPAREN,
  [23] = 1,
    ACTIONS(15), 4,
      ts_builtin_sym_end,
      anon_sym_or,
      anon_sym_and,
      anon_sym_RPAREN,
  [30] = 3,
    ACTIONS(13), 1,
      anon_sym_and,
    ACTIONS(17), 1,
      ts_builtin_sym_end,
    ACTIONS(19), 1,
      anon_sym_or,
  [40] = 3,
    ACTIONS(13), 1,
      anon_sym_and,
    ACTIONS(19), 1,
      anon_sym_or,
    ACTIONS(21), 1,
      anon_sym_RPAREN,
};

static const uint32_t ts_small_parse_table_map[] = {
  [SMALL_STATE(5)] = 0,
  [SMALL_STATE(6)] = 7,
  [SMALL_STATE(7)] = 14,
  [SMALL_STATE(8)] = 23,
  [SMALL_STATE(9)] = 30,
  [SMALL_STATE(10)] = 40,
};

static const TSParseActionEntry ts_parse_actions[] = {
  [0] = {.entry = {.count = 0, .reusable = false}},
  [1] = {.entry = {.count = 1, .reusable = false}}, RECOVER(),
  [3] = {.entry = {.count = 1, .reusable = true}}, SHIFT(2),
  [5] = {.entry = {.count = 1, .reusable = true}}, SHIFT(5),
  [7] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_expression, 1, 0, 0),
  [9] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_parenthesized_expression, 3, 0, 0),
  [11] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_or_expression, 3, 0, 0),
  [13] = {.entry = {.count = 1, .reusable = true}}, SHIFT(4),
  [15] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_and_expression, 3, 0, 0),
  [17] = {.entry = {.count = 1, .reusable = true}},  ACCEPT_INPUT(),
  [19] = {.entry = {.count = 1, .reusable = true}}, SHIFT(3),
  [21] = {.entry = {.count = 1, .reusable = true}}, SHIFT(6),
};

#ifdef __cplusplus
extern "C" {
#endif
#ifdef TREE_SITTER_HIDE_SYMBOLS
#define TS_PUBLIC
#elif defined(_WIN32)
#define TS_PUBLIC __declspec(dllexport)
#else
#define TS_PUBLIC __attribute__((visibility("default")))
#endif

TS_PUBLIC const TSLanguage *tree_sitter_tags_query(void) {
  static const TSLanguage language = {
    .version = LANGUAGE_VERSION,
    .symbol_count = SYMBOL_COUNT,
    .alias_count = ALIAS_COUNT,
    .token_count = TOKEN_COUNT,
    .external_token_count = EXTERNAL_TOKEN_COUNT,
    .state_count = STATE_COUNT,
    .large_state_count = LARGE_STATE_COUNT,
    .production_id_count = PRODUCTION_ID_COUNT,
    .field_count = FIELD_COUNT,
    .max_alias_sequence_length = MAX_ALIAS_SEQUENCE_LENGTH,
    .parse_table = &ts_parse_table[0][0],
    .small_parse_table = ts_small_parse_table,
    .small_parse_table_map = ts_small_parse_table_map,
    .parse_actions = ts_parse_actions,
    .symbol_names = ts_symbol_names,
    .symbol_metadata = ts_symbol_metadata,
    .public_symbol_map = ts_symbol_map,
    .alias_map = ts_non_terminal_alias_map,
    .alias_sequences = &ts_alias_sequences[0][0],
    .lex_modes = ts_lex_modes,
    .lex_fn = ts_lex,
    .primary_state_ids = ts_primary_state_ids,
  };
  return &language;
}
#ifdef __cplusplus
}
#endif

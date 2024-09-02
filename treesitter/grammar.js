module.exports = grammar({
    name: 'tags_query',

    rules: {
        expression: $ => choice(
            $.or_expression,
            $.and_expression,
            $.parenthesized_expression,
            $.hashtag
        ),

        or_expression: $ => prec.left(1, seq(
            $.expression,
            'or',
            $.expression
        )),

        and_expression: $ => prec.left(2, seq(
            $.expression,
            'and',
            $.expression
        )),

        parenthesized_expression: $ => seq(
            '(',
            $.expression,
            ')'
        ),

        hashtag: $ => /#[a-zA-Z_][a-zA-Z0-9_]*/
    }
});

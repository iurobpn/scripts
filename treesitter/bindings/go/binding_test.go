package tree_sitter_tags_query_test

import (
	"testing"

	tree_sitter "github.com/smacker/go-tree-sitter"
	"github.com/tree-sitter/tree-sitter-tags_query"
)

func TestCanLoadGrammar(t *testing.T) {
	language := tree_sitter.NewLanguage(tree_sitter_tags_query.Language())
	if language == nil {
		t.Errorf("Error loading TagsQuery grammar")
	}
}

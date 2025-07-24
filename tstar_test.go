package tstar

import (
	"testing"
)

func TestTstarBasic(t *testing.T) {
	Run(t, Params{
		Dir: "examples/testdata",
	})
}

func TestTstarWithCommands(t *testing.T) {
	Run(t, Params{
		Dir: "examples/testdata",
		Commands: map[string]func(*TestScript, bool, []string){
			"custom": func(ts *TestScript, neg bool, args []string) {
				ts.Logf("Custom command executed with args: %v", args[1:])
			},
		},
	})
}

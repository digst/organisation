package org

import (
	"net/http"
	"fmt"
)

type Developers struct {

}

func SearchInventory(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json; charset=UTF-8")
		w.WriteHeader(http.StatusOK)
		fmt.Fprintf(w,"Hej i sommerhuset (%s)\n",r.URL.Path )

}

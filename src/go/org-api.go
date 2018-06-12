package main

import (
	"net/http"
	"github.com/gorilla/handlers"
	"github.com/gorilla/mux"
	"io/ioutil"
	"github.com/ghodss/yaml"
	"fmt"
	"log"
	"encoding/json"
	"bytes"
	"io"
	"path"
)

// Utility to read from filesystem
func ReadFromFile(path string)(org map[string] interface{}, err error) {
	data, err := ioutil.ReadFile("./data/"+path)
	if err!=nil { return }
	j, err := yaml.YAMLToJSON(data)
	if err != nil { return }
	err = json.Unmarshal(j, &org)
	return
}

// Utility to write to filesystem
func WriteToFile(org map[string] interface{})(err error) {
	fpath := "./data/"+org["id"].(string)+".yaml"
	b, err := json.Marshal(org)
	y, err := yaml.JSONToYAML(b)

	// rotate existing files...?
	return ioutil.WriteFile(fpath,y, 0644)
}

// Utility to index on elastic search
func IndexOrg(result []byte)(err error) {
	response, err := http.Post("http://localhost:9200/index/org/", "application/json", bytes.NewBuffer(result))
	_, err = ioutil.ReadAll(response.Body)
	return err
	//fmt.Println(string(data))
}


// Display a single document describing an Organisation
// Served directly from filesystem
func GetOrganisation(w http.ResponseWriter, r *http.Request) {
    params := mux.Vars(r)
    fpath := params["id"]+".yaml"
    println("asking for "+fpath)
    org, err := ReadFromFile(fpath)
    if err!=nil {
    	// should test for missing id 404
		w.WriteHeader(500)
		w.Write([]byte ("\n" + err.Error()+"\n"))
		return
	}
	j, err := json.Marshal(org)
	w.Write(j)
}

// Display a list of all organisations matching municipalities
// TODO: Re-write to take advantage of ES
func GetAllMunicipalities(w http.ResponseWriter, r *http.Request) {
	GetAuthorityByType(w, "Kommune", true)
}

// Display a list of all organisations not matching municipalities
// TODO: Re-write to take advantage of ES
func GetAllNonMunicipalities(w http.ResponseWriter, r *http.Request) {
	GetAuthorityByType(w, "Kommune", false)
}

func GetAuthorityByType(w http.ResponseWriter, poclass string, match bool) {
	files, err := ioutil.ReadDir("./data")
	HandleInternalError(err, w)
	w.Write([]byte("[\n"))
	var first = true
	for _, file := range files {
		if path.Ext(file.Name()) != ".yaml" { continue }
		org, err := ReadFromFile(file.Name())
		HandleInternalError(err, w)
		if match {
			if org["po-classification"] == poclass {
				if !first {
					w.Write([]byte("\n,\n"))
				} else {
					first = false
				}
				j, err := json.Marshal(org)
				HandleInternalError(err, w)
				w.Write(j)
			}
		} else {
			if org["po-classification"] != poclass && org["isSubOrganizationOf"] == nil{
				if !first {
					w.Write([]byte("\n,\n"))
				} else {
					first = false
				}
				j, err := json.Marshal(org)
				HandleInternalError(err, w)
				w.Write(j)
			}
		}
	}
	w.Write([]byte("\n]"))
}

// Write or Update an Organisation to filesystem and index
func UpdateOrganisation(w http.ResponseWriter, r *http.Request) {
	r.ParseMultipartForm(6400000)
	var Buf bytes.Buffer
	file, _, err := r.FormFile("file")
	defer file.Close()

	if err != nil {
		w.WriteHeader(400)
		w.Write([]byte("Did not receive a file in MultipartForm in key 'file'"))
		return
	}

	io.Copy(&Buf, file)

	// validate that the uploaded file can be parsed as YAML to JSON.
	var org map[string]interface{}
	j, err := yaml.YAMLToJSON([]byte(Buf.String()))
	if err != nil {
		w.WriteHeader(500)
		fmt.Fprintf(w,"%s Could not parse data file as YAML\n",http.StatusText(500))
		fmt.Fprintf(w,"Got this error from the parser \n%s\n",err.Error())
		return
	}
	if json.Unmarshal(j, &org) != nil {
		w.WriteHeader(500)
		fmt.Fprintf(w,"%s Could not convert YAML to JSON\n",http.StatusText(500))
		return
	}



	w.WriteHeader(200)
	result, err := json.Marshal(org)
	fmt.Fprintf(w,"%s\n", result)
	err = WriteToFile(org)
	err = IndexOrg(result)

}

func HandleInternalError(err error, w http.ResponseWriter) {
	if err == nil {return}
	println(err)
	println()
	w.WriteHeader(500)
	w.Write([]byte("500 Could not read directory - " + http.StatusText(500)))

}

// Starting up a HTTP server
func main() {
    router := mux.NewRouter()
    router.HandleFunc("/org/{id}", GetOrganisation).Methods("GET")
		router.HandleFunc("/org/{id}", UpdateOrganisation).Methods("POST")

	router.HandleFunc("/municipalities", GetAllMunicipalities).Methods("GET")
	router.HandleFunc("/others", GetAllNonMunicipalities).Methods("GET")

    // CORS to allow serveed from localhost
    log.Fatal(http.ListenAndServe(":8000", handlers.CORS(handlers.AllowedOrigins([]string{"*"}))(router)))
}

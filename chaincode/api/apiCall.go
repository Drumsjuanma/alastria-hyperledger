// Package helloworld displays helloworld and the amount of time the invoke method as been called
package main

import (
	"errors"
	"fmt"
	"io/ioutil"
    "net/http"

	"github.com/hyperledger/fabric/core/chaincode/shim"
)

// SimpleChaincode example 
type SimpleChaincode struct {
}

// Init is called during Deploy transaction after the container has been created
func (t *SimpleChaincode) Init(stub *shim.ChaincodeStub, function string, args []string) ([]byte, error) {
	if len(args) != 0 {
		return nil, errors.New("Incorrect number of arguments. Expecting 0")
	}

	// Set the admin
	// The metadata will contain the certificate of the administrator

	err := stub.PutState("logs", []byte("0"))
	if err != nil {
		return nil, err
	}

	return nil, nil
}

// Invoke is called for every Invoke transactions. The chaincode may change
// its state variables
func (t *SimpleChaincode) Invoke(stub *shim.ChaincodeStub, function string, args []string) ([]byte, error) {
	fmt.Printf("SimpleChaincode in Invoke with function %s!\n", function)
	if function != "invoke" {
		return nil, errors.New("Invalid invoke function name. Expecting \"invoke\"")
	}

	b, err := stub.GetState("logs")
	if err != nil {
		return nil, errors.New("Failed to get state")
	}

	var call string
	call = args[0]
    response, _ := http.Get(call)
    data, _ := ioutil.ReadAll(response.Body)
    fmt.Printf(string(data))

	err = stub.PutState("logs ", data)
	if err != nil {
		return nil, err
	}

	return nil, nil
}

// Query is called for Query transactions. The chaincode may only read
// (but not modify) its state variables and return the result
func (t *SimpleChaincode) Query(stub *shim.ChaincodeStub, function string, args []string) ([]byte, error) {
	if function != "query" {
		return nil, errors.New("Invalid query function name. Expecting \"query\"")
	}

	b, err := stub.GetState("logs")
	if err != nil {
		return nil, errors.New("Failed to get state")
	}

	jsonResp := "{\"SimpleChaincode\":\"" + string(b) + "\"}"
	return []byte(jsonResp), nil
}

func main() {
	err := shim.Start(new(SimpleChaincode))
	if err != nil {
		fmt.Printf("Error starting SimpleChaincode chaincode: %s\n", err)
	}
}

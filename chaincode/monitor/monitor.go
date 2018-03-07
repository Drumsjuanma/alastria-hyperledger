/*
Copyright IBM Corp. 2016 All Rights Reserved.
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
                 http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package main

//WARNING - this chaincode's ID is hard-coded in chaincode_example04 to illustrate one way of
//calling chaincode from a chaincode. If this example is modified, chaincode_example04.go has
//to be modified as well with the new ID of chaincode_example02.
//chaincode_example05 show's how chaincode ID can be passed in as a parameter instead of
//hard-coding.

import (
        "fmt"
        "strconv"
        "net/http"
        "io/ioutil"

        "github.com/hyperledger/fabric/core/chaincode/shim"
        pb "github.com/hyperledger/fabric/protos/peer"
)

// SimpleChaincode example simple Chaincode implementation
type SimpleChaincode struct {
}

func (t *SimpleChaincode) Init(stub shim.ChaincodeStubInterface) pb.Response {
        fmt.Println("Alastria Monitor Init")
        _, args := stub.GetFunctionAndParameters()
        var entityName string
        var err error

        if len(args) != 1 {
                return shim.Error("Incorrect number of arguments. Expecting 1")
        }

        // Initialize the chaincode
        entityName = args[0]
        fmt.Printf("Entity name: " + entityName)

        // Write the state to the ledger
        err = stub.PutState(entityName, " null ")
        if err != nil {
                return shim.Error(err.Error())
        }

        return shim.Success(nil)
}

func (t *SimpleChaincode) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
        fmt.Println("Alastria Monitor Invoke")
        function, args := stub.GetFunctionAndParameters()
        if function == "invoke" {
                // Make payment of X units from A to B
                return t.invoke(stub, args)
        } else if function == "delete" {
                // Deletes an entity from its state
                return t.delete(stub, args)
        } else if function == "query" {
                // the old "Query" is now implemtned in invoke
                return t.query(stub, args)
        }

        return shim.Error("Invalid invoke function name. Expecting \"invoke\" \"delete\" \"query\"")
}

// Transaction makes payment of X units from A to B
func (t *SimpleChaincode) invoke(stub shim.ChaincodeStubInterface, args []string) pb.Response {
        var entityName string
        var api string
        var err error

        if len(args) != 2 {
                return shim.Error("Incorrect number of arguments. Expecting 2")
        }

        entityName = args[0]
        api = args[1]
        

        // Perform the execution 
  
        //////////////////////////////////////////////////////
        //CUSTOM
        //////////////////////////////////////////////////////
        response, err := http.Get(api)
        if err != nil {
                jsonResp := "{\"Error\":\"Failed to GET " + A + "\"}"
                return shim.Error(jsonResp)
        }
  
        data, err := ioutil.ReadAll(response.Body)
        if err != nil {
                jsonResp := "{\"Error\":\"Failed to READALL " + A + "\"}"
                return shim.Error(jsonResp)
        }
        fmt.Printf("Valor obtenido:" + string(data))

        err = stub.PutState(entityName, string(data))
        if err != nil {
                return shim.Error(err.Error())
        }

        return shim.Success(nil)
}

// Deletes an entity from state
func (t *SimpleChaincode) delete(stub shim.ChaincodeStubInterface, args []string) pb.Response {
        if len(args) != 1 {
                return shim.Error("Incorrect number of arguments. Expecting 1")
        }

        A := args[0]

        // Delete the key from the state in ledger
        err := stub.DelState(A)
        if err != nil {
                return shim.Error("Failed to delete state")
        }

        return shim.Success(nil)
}

// query callback representing the query of a chaincode
func (t *SimpleChaincode) query(stub shim.ChaincodeStubInterface, args []string) pb.Response {
        var entityName string // Entities
        var err error

        if len(args) != 1 {
                return shim.Error("Incorrect number of arguments. Expecting name of the person to query")
        }

        entityName = args[0]

        // Get the state from the ledger
        Avalbytes, err := stub.GetState(entityName)
        if err != nil {
                jsonResp := "{\"Error\":\"Failed to get state for " + entityName + "\"}"
                return shim.Error(jsonResp)
        }

        if Avalbytes == nil {
                jsonResp := "{\"Error\":\"Nil amount for " + entityName + "\"}"
                return shim.Error(jsonResp)
        }

        jsonResp := "{\"Name\":\"" + entityName + "\",\"Amount\":\"" + string(Avalbytes) + "\"}"
        fmt.Printf("Query Response:%s\n", jsonResp)


        

        return shim.Success(Avalbytes)
}

func main() {
        err := shim.Start(new(SimpleChaincode))
        if err != nil {
                fmt.Printf("Error starting Simple chaincode: %s", err)
        }
}

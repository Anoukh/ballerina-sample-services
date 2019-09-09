import ballerina/http;
import ballerina/log;
import ballerinax/java.jdbc;
import ballerina/'lang\.int as integer;

type Inventory record {|
    int productId;
    int stock;
|};

@http:ServiceConfig {
    basePath: "/InventoryService"
}
service InventoryService on new http:Listener(9093) {
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/checkInventory"
    }
    resource function getProduct(http:Caller outboundEP, http:Request req) returns error? {
        map<anydata> qParams = req.getQueryParams();
        string[] s1 = <string[]> qParams["productId"];
        string s = s1[0];
        int|error productId = integer:fromString(s);
        if (productId is int && productId > 0) {
            Inventory|error inventory = checkInventoryForStock(productId);
            if (inventory is error) {
                log:printError("error in retrieving inventory details.", err = inventory);
                respond(outboundEP, "error in retrieving inventory details.", statusCode = 500);
                return;
            } else {
                json payload = check json.constructFrom(inventory);
                respond(outboundEP, <@untainted> payload);
            }
        } else {
            log:printError("invalid input query parameter. expected a positive integer.");
            respond(outboundEP, "invalid input query parameter. expected a positive integer.", statusCode = 400);
        }
    }
}

jdbc:Client clientDB = new({
    url: "jdbc:mysql://localhost/testdb",
    // host: "localhost",
    // port: 3306,
    // name: "testdb",
    username: "root",
    password: "root",
    poolOptions: { maximumPoolSize: 5 },
    dbOptions: { useSSL: false }
});

function checkInventoryForStock(int id) returns @tainted Inventory | error {
    jdbc:Parameter param = {
        sqlType: jdbc:TYPE_INTEGER,
        value: id
    };
    var result = clientDB->select("SELECT productId, stock FROM INVENTORY WHERE productId = ?", Inventory, param);
    table<Inventory> dataTable = check result;
    Inventory inventory = <Inventory> dataTable.getNext();
    dataTable.close();
    return inventory;
}

function respond(http:Caller outboundEP, json | string payload, int statusCode = 200) {
    http:Response res = new;
    res.statusCode = statusCode;
    res.setJsonPayload(payload, contentType = "application/json");
    error? responseStatus = outboundEP->respond(res);
    if (responseStatus is error) {
        log:printError("error in sending response.", err = responseStatus);
    }
}

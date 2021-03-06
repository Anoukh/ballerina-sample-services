import ballerina/http;
import ballerina/log;
import ballerinax/java.jdbc;
import ballerina/'lang\.int as integer;

type Product record {|
    int id;
    string name;
    float price;
|};

@http:ServiceConfig {
    basePath: "/ProductService"
}
service ProductService on new http:Listener(9092) {
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/getProduct"
    }
    resource function getProduct(http:Caller outboundEP, http:Request req) returns error? {
        map<anydata> qParams = req.getQueryParams();
        string[] s1 = <string[]> qParams["productId"];
        string s = s1[0];
        var productId = integer:fromString(s);
        if (productId is int && productId > 0) {
            var product = getProductFromDB(productId);
            if (product is error) {
                log:printError("error in retrieving product details.", err = product);
                respond(outboundEP, "error in retrieving product details.", statusCode = 500);
                return;
            } else {
                json payload = check json.constructFrom(product);
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
    poolOptions: { maximumPoolSize: 10 },
    dbOptions: { useSSL: false }
});

function getProductFromDB(int id) returns @tainted Product | error {
    jdbc:Parameter param = {
        sqlType: jdbc:TYPE_INTEGER,
        value: id
    };
    var result = clientDB->select("SELECT * FROM PRODUCT WHERE id = ?", Product, param);
    table<Product> dataTable = check result;
    Product product = <Product> dataTable.getNext();
    dataTable.close();
    return product;
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

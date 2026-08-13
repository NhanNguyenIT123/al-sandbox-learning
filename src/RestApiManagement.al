codeunit 50100 "APSS REST API Management"
{
    trigger OnRun()
    begin
    end;

    procedure FetchExternalData()
    var
        Client: HttpClient;
        ResponseMessage: HttpResponseMessage;
        ResponseString: Text;
        JObject: JsonObject;
        JToken: JsonToken;
        Title: Text;
    begin
        if Client.Get('https://jsonplaceholder.typicode.com/todos/1', ResponseMessage) then begin
            if ResponseMessage.IsSuccessStatusCode() then begin
                ResponseMessage.Content().ReadAs(ResponseString);
                if JObject.ReadFrom(ResponseString) then begin
                    if JObject.Get('title', JToken) then begin
                        Title := JToken.AsValue().AsText();
                        Message('Success! Fetched Title: %1', Title);
                    end;
                end;
            end else begin
                Error('Failed to fetch data. Status Code: %1', ResponseMessage.HttpStatusCode());
            end;
        end else begin
            Error('HTTP GET request failed.');
        end;
    end;

    procedure SendDataToExternalApi(CustomerNo: Code[20]; CustomerName: Text[100])
    var
        Client: HttpClient;
        Content: HttpContent;
        Headers: HttpHeaders;
        ResponseMessage: HttpResponseMessage;
        ResponseString: Text;
        JObject: JsonObject;
        PayloadText: Text;
    begin
        JObject.Add('title', StrSubstNo('Customer %1: %2', CustomerNo, CustomerName));
        JObject.Add('body', 'Test data sent from Business Central');
        JObject.Add('userId', 1);
        
        JObject.WriteTo(PayloadText);
        Content.WriteFrom(PayloadText);

        Content.GetHeaders(Headers);
        Headers.Clear();
        Headers.Add('Content-Type', 'application/json; charset=utf-8');

        if Client.Post('https://jsonplaceholder.typicode.com/posts', Content, ResponseMessage) then begin
            if ResponseMessage.IsSuccessStatusCode() then begin
                ResponseMessage.Content().ReadAs(ResponseString);
                Message('Success! POST Response:\n%1', ResponseString);
            end else begin
                Error('Failed to send data. Status Code: %1', ResponseMessage.HttpStatusCode());
            end;
        end else begin
            Error('HTTP POST request failed.');
        end;
    end;
}

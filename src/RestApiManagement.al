codeunit 50100 "APSS REST API Management"
{
    procedure FetchTodoCollection()
    var
        Client: HttpClient;
        ResponseMessage: HttpResponseMessage;
        ResponseText: Text;
        ClientErrorText: Text;
        TempExternalTodo: Record "APSS External Todo" temporary;
        JsonArrayParser: Codeunit "APSS Json Array Parser";
    begin
        ClearLastError();

        if not Client.Get(
            'https://jsonplaceholder.typicode.com/todos',
            ResponseMessage)
        then begin
            ClientErrorText := GetLastErrorText();

            if ClientErrorText <> '' then
                Error(
                    'Unable to fetch the Todo collection. Details: %1',
                    ClientErrorText);

            Error(
                'Unable to fetch the Todo collection because the HTTP GET request failed.');
        end;

        if not ResponseMessage.IsSuccessStatusCode() then
            Error(
                'Unable to fetch the Todo collection. HTTP status code: %1.',
                ResponseMessage.HttpStatusCode());

        if not ResponseMessage.Content().ReadAs(ResponseText) then
            Error('Unable to read the Todo collection response body.');

        if ResponseText.Trim() = '' then
            Error('The Todo collection response body is empty.');

        JsonArrayParser.ParseTodoArray(
            ResponseText,
            TempExternalTodo);

        PersistTodos(TempExternalTodo);
    end;

    local procedure PersistTodos(
        var TempExternalTodo: Record "APSS External Todo" temporary)
    var
        ExternalTodo: Record "APSS External Todo";
        SyncDateTime: DateTime;
    begin
        if not TempExternalTodo.FindSet() then
            exit;

        SyncDateTime := CurrentDateTime();

        repeat
            if ExternalTodo.Get(
                TempExternalTodo."External Todo ID")
            then begin
                ExternalTodo."External User ID" :=
                    TempExternalTodo."External User ID";
                ExternalTodo.Title := TempExternalTodo.Title;
                ExternalTodo.Completed := TempExternalTodo.Completed;
                ExternalTodo."Last Synced At" := SyncDateTime;
                ExternalTodo.Modify(true);
            end else begin
                ExternalTodo.Init();
                ExternalTodo."External Todo ID" :=
                    TempExternalTodo."External Todo ID";
                ExternalTodo."External User ID" :=
                    TempExternalTodo."External User ID";
                ExternalTodo.Title := TempExternalTodo.Title;
                ExternalTodo.Completed := TempExternalTodo.Completed;
                ExternalTodo."Last Synced At" := SyncDateTime;
                ExternalTodo.Insert(true);
            end;
        until TempExternalTodo.Next() = 0;
    end;

    procedure FetchExternalData()
    var
        Client: HttpClient;
        ResponseMessage: HttpResponseMessage;
        ResponseString: Text;
        JObject: JsonObject;
        JToken: JsonToken;
        JValue: JsonValue;
        Title: Text;
    begin
        if not Client.Get(
            'https://jsonplaceholder.typicode.com/todos/1',
            ResponseMessage)
        then
            Error('HTTP GET request failed.');

        if not ResponseMessage.IsSuccessStatusCode() then
            Error(
                'Failed to fetch data. Status Code: %1',
                ResponseMessage.HttpStatusCode());

        if not ResponseMessage.Content().ReadAs(ResponseString) then
            Error('Unable to read the REST API response body.');

        if ResponseString.Trim() = '' then
            Error('The REST API response body is empty.');

        if not JObject.ReadFrom(ResponseString) then
            Error('The REST API returned invalid JSON.');

        if not JObject.Get('title', JToken) then
            Error('The REST API response does not contain a title.');

        if not JToken.IsValue() then
            Error('The title property has an invalid JSON type.');

        JValue := JToken.AsValue();

        if JValue.IsNull() then
            Error('The title property contains a null value.');

        Title := JValue.AsText();

        if Title.Trim() = '' then
            Error('The title property is empty.');

        Message(
            'Success! Fetched Title: %1',
            Title);
    end;

    procedure SendDataToExternalApi(
        CustomerNo: Code[20];
        CustomerName: Text[100])
    var
        Client: HttpClient;
        Content: HttpContent;
        Headers: HttpHeaders;
        ResponseMessage: HttpResponseMessage;
        ResponseString: Text;
        JObject: JsonObject;
        PayloadText: Text;
    begin
        JObject.Add(
            'title',
            StrSubstNo(
                'Customer %1: %2',
                CustomerNo,
                CustomerName));

        JObject.Add(
            'body',
            'Test data sent from Business Central');

        JObject.Add(
            'userId',
            1);

        JObject.WriteTo(PayloadText);
        Content.WriteFrom(PayloadText);

        Content.GetHeaders(Headers);
        Headers.Clear();
        Headers.Add(
            'Content-Type',
            'application/json; charset=utf-8');

        if not Client.Post(
            'https://jsonplaceholder.typicode.com/posts',
            Content,
            ResponseMessage)
        then
            Error('HTTP POST request failed.');

        if not ResponseMessage.IsSuccessStatusCode() then
            Error(
                'Failed to send data. Status Code: %1',
                ResponseMessage.HttpStatusCode());

        if not ResponseMessage.Content().ReadAs(ResponseString) then
            Error('Unable to read the REST API POST response body.');

        if ResponseString.Trim() = '' then
            Error('The REST API POST response body is empty.');

        Message(
            'Success! POST Response:\%1',
            ResponseString);
    end;
}
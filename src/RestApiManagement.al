codeunit 50100 "APSS REST API Management"
{
    /// <summary>
    /// Fetches the Todo collection from the external API and synchronizes
    /// valid Todo records into Business Central.
    /// </summary>
    procedure FetchTodoCollection()
    var
        Client: HttpClient;
        ResponseMessage: HttpResponseMessage;
        ResponseText: Text;
        ClientErrorText: Text;
        TempExternalTodo: Record "APSS External Todo" temporary;
        JsonArrayParser: Codeunit "APSS Json Array Parser";
        APIErrorLogMgt: Codeunit "APSS API Error Log Mgt.";
        ProcessedCount: Integer;
        SuccessfulCount: Integer;
        FailedCount: Integer;
    begin
        ClearLastError();

        if not Client.Get(
            'https://jsonplaceholder.typicode.com/todos',
            ResponseMessage)
        then begin
            ClientErrorText := GetLastErrorText();

            if ClientErrorText = '' then
                ClientErrorText :=
                    'The HTTP GET request failed without a detailed error message.';

            APIErrorLogMgt.LogHttpError(
                'JSONPlaceholder Todos',
                ClientErrorText,
                0);

            Message(
                'Todo synchronization failed. The error has been recorded in API Error Logs.');

            exit;
        end;

        if not ResponseMessage.IsSuccessStatusCode() then begin
            APIErrorLogMgt.LogHttpError(
                'JSONPlaceholder Todos',
                StrSubstNo(
                    'The Todo API returned HTTP status code %1.',
                    ResponseMessage.HttpStatusCode()),
                ResponseMessage.HttpStatusCode());

            Message(
                'Todo synchronization failed with HTTP status code %1. The error has been recorded in API Error Logs.',
                ResponseMessage.HttpStatusCode());

            exit;
        end;

        if not ResponseMessage.Content().ReadAs(ResponseText) then begin
            APIErrorLogMgt.LogHttpError(
                'JSONPlaceholder Todos',
                'Unable to read the Todo collection response body.',
                ResponseMessage.HttpStatusCode());

            Message(
                'Todo synchronization failed while reading the API response. The error has been recorded in API Error Logs.');

            exit;
        end;

        if ResponseText.Trim() = '' then begin
            APIErrorLogMgt.LogHttpError(
                'JSONPlaceholder Todos',
                'The Todo collection response body is empty.',
                ResponseMessage.HttpStatusCode());

            Message(
                'Todo synchronization failed because the API returned an empty response. The error has been recorded in API Error Logs.');

            exit;
        end;

        if not JsonArrayParser.ParseTodoArray(
            ResponseText,
            TempExternalTodo,
            ProcessedCount,
            SuccessfulCount,
            FailedCount)
        then begin
            Message(
                'Todo synchronization failed because the API response could not be processed. The error has been recorded in API Error Logs.');

            exit;
        end;

        PersistTodos(TempExternalTodo);

        ShowSyncSummary(
            ProcessedCount,
            SuccessfulCount,
            FailedCount);
    end;

    /// <summary>
    /// Inserts new Todo records and updates existing records using
    /// the external Todo ID as the primary key.
    /// </summary>
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

                ExternalTodo.Title :=
                    TempExternalTodo.Title;

                ExternalTodo.Completed :=
                    TempExternalTodo.Completed;

                ExternalTodo."Last Synced At" :=
                    SyncDateTime;

                ExternalTodo.Modify(true);
            end else begin
                ExternalTodo.Init();

                ExternalTodo."External Todo ID" :=
                    TempExternalTodo."External Todo ID";

                ExternalTodo."External User ID" :=
                    TempExternalTodo."External User ID";

                ExternalTodo.Title :=
                    TempExternalTodo.Title;

                ExternalTodo.Completed :=
                    TempExternalTodo.Completed;

                ExternalTodo."Last Synced At" :=
                    SyncDateTime;

                ExternalTodo.Insert(true);
            end;
        until TempExternalTodo.Next() = 0;
    end;

    /// <summary>
    /// Displays the result of the Todo synchronization.
    /// </summary>
    local procedure ShowSyncSummary(
        ProcessedCount: Integer;
        SuccessfulCount: Integer;
        FailedCount: Integer)
    begin
        if FailedCount = 0 then begin
            Message(
                'Todo synchronization completed successfully.\' +
                'Records processed: %1.\' +
                'Records synchronized: %2.',
                ProcessedCount,
                SuccessfulCount);

            exit;
        end;

        Message(
            'Todo synchronization completed with errors.\' +
            'Records processed: %1.\' +
            'Records synchronized: %2.\' +
            'Records failed: %3.\' +
            'See API Error Logs for details.',
            ProcessedCount,
            SuccessfulCount,
            FailedCount);
    end;

    /// <summary>
    /// Tests a simple GET request against the training REST API.
    /// </summary>
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

        if not JObject.Get(
            'title',
            JToken)
        then
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

    /// <summary>
    /// Tests a POST request using the current Business Central customer.
    /// </summary>
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
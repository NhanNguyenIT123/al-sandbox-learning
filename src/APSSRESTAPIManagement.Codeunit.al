codeunit 50100 "APSS REST API Management"
{
    Permissions =
        tabledata "APSS API Error Log" = RIMD,
        tabledata "APSS External User" = RIMD;

    trigger OnRun()
    begin
    end;

    /// <summary>
    /// Fetches one sample todo from the external REST API and displays its title.
    /// </summary>
    procedure FetchExternalData()
    var
        Client: HttpClient;
        ResponseMessage: HttpResponseMessage;
        ResponseString: Text;
        JObject: JsonObject;
        JToken: JsonToken;
        Title: Text;
    begin
        if not Client.Get(TodoEndpointLbl, ResponseMessage) then
            Error(HttpRequestFailedErr, TodoEndpointLbl);
        if not ResponseMessage.IsSuccessStatusCode() then
            Error(HttpStatusErr, ResponseMessage.HttpStatusCode(), TodoEndpointLbl);

        ResponseMessage.Content().ReadAs(ResponseString);
        if not JObject.ReadFrom(ResponseString) then
            Error(InvalidObjectJsonErr, TodoEndpointLbl);
        if not JObject.Get('title', JToken) then
            Error(MissingResponsePropertyErr, 'title', TodoEndpointLbl);
        if not JToken.IsValue() then
            Error(InvalidResponsePropertyErr, 'title', TodoEndpointLbl);

        Title := JToken.AsValue().AsText();
        Message(FetchSucceededMsg, Title);
    end;

    /// <summary>
    /// Sends a non-identifying sample payload to the external REST API.
    /// </summary>
    procedure SendDataToExternalApi()
    var
        Client: HttpClient;
        Content: HttpContent;
        Headers: HttpHeaders;
        ResponseMessage: HttpResponseMessage;
        JObject: JsonObject;
        PayloadText: Text;
    begin
        JObject.Add('title', PostTitleLbl);
        JObject.Add('body', PostBodyLbl);
        JObject.Add('userId', 1);

        JObject.WriteTo(PayloadText);
        Content.WriteFrom(PayloadText);

        Content.GetHeaders(Headers);
        Headers.Clear();
        Headers.Add(ContentTypeHeaderLbl, JsonContentTypeLbl);

        if not Client.Post(PostsEndpointLbl, Content, ResponseMessage) then
            Error(HttpPostFailedErr, PostsEndpointLbl);
        if not ResponseMessage.IsSuccessStatusCode() then
            Error(HttpStatusErr, ResponseMessage.HttpStatusCode(), PostsEndpointLbl);

        Message(PostSucceededMsg);
    end;

    /// <summary>
    /// Fetches, validates, and synchronizes external users without raising errors for HTTP or item-level failures.
    /// </summary>
    /// <param name="InsertedCount">Returns the number of users inserted.</param>
    /// <param name="ModifiedCount">Returns the number of users whose external data changed.</param>
    /// <param name="DeletedCount">Returns the number of users deleted because they are no longer returned by the API.</param>
    /// <param name="ErrorCount">Returns the number of errors written to the API Error Log.</param>
    procedure SyncExternalUsers(var InsertedCount: Integer; var ModifiedCount: Integer; var DeletedCount: Integer; var ErrorCount: Integer)
    var
        TempExternalUser: Record "APSS External User" temporary;
        Client: HttpClient;
        ResponseMessage: HttpResponseMessage;
        AllowDelete: Boolean;
        ResponseText: Text;
        SyncDateTime: DateTime;
    begin
        Clear(InsertedCount);
        Clear(ModifiedCount);
        Clear(DeletedCount);
        Clear(ErrorCount);

        ClearLastError();
        if not Client.Get(UsersEndpointLbl, ResponseMessage) then begin
            LogApiError(UsersResourceLbl, SynchronizeOperationLbl, UsersEndpointLbl, 0, -1, 0, HttpErrorTypeLbl, GetHttpFailureMessage());
            ErrorCount += 1;
            exit;
        end;

        if not ResponseMessage.IsSuccessStatusCode() then begin
            LogApiError(UsersResourceLbl, SynchronizeOperationLbl, UsersEndpointLbl, 0, -1, ResponseMessage.HttpStatusCode(), HttpErrorTypeLbl,
                StrSubstNo(HttpStatusErr, ResponseMessage.HttpStatusCode(), UsersEndpointLbl));
            ErrorCount += 1;
            exit;
        end;

        if not ResponseMessage.Content().ReadAs(ResponseText) then begin
            LogApiError(UsersResourceLbl, SynchronizeOperationLbl, UsersEndpointLbl, 0, -1, ResponseMessage.HttpStatusCode(), ResponseErrorTypeLbl, ReadResponseFailedErr);
            ErrorCount += 1;
            exit;
        end;

        if not ParseExternalUsers(ResponseText, TempExternalUser, ErrorCount, AllowDelete) then
            exit;

        SyncDateTime := CurrentDateTime();
        UpsertExternalUsers(TempExternalUser, SyncDateTime, InsertedCount, ModifiedCount);
        if AllowDelete then
            DeleteMissingExternalUsers(TempExternalUser, DeletedCount);
    end;

    /// <summary>
    /// Deletes all synchronized external users from the local Business Central table.
    /// </summary>
    /// <returns>The number of deleted external users.</returns>
    procedure ClearExternalUsers(): Integer
    var
        ExternalUser: Record "APSS External User";
        DeletedCount: Integer;
    begin
        DeletedCount := ExternalUser.Count();
        if DeletedCount = 0 then
            exit(0);

        ExternalUser.DeleteAll(true);
        exit(DeletedCount);
    end;

    /// <summary>
    /// Deletes all entries from the API Error Log.
    /// </summary>
    /// <returns>The number of deleted log entries.</returns>
    procedure ClearApiErrorLog(): Integer
    var
        ApiErrorLog: Record "APSS API Error Log";
        DeletedCount: Integer;
    begin
        DeletedCount := ApiErrorLog.Count();
        if DeletedCount = 0 then
            exit(0);

        ApiErrorLog.DeleteAll(true);
        exit(DeletedCount);
    end;

    /// <summary>
    /// Writes a handled integration failure to the shared API Error Log.
    /// </summary>
    /// <param name="ApiResource">Specifies the external resource, such as Users or Todos.</param>
    /// <param name="Operation">Specifies the integration operation that failed.</param>
    /// <param name="Endpoint">Specifies the endpoint used by the operation.</param>
    /// <param name="ExternalRecordId">Specifies the external record ID, or zero when unavailable.</param>
    /// <param name="ArrayIndex">Specifies the zero-based response array index, or -1 when unavailable.</param>
    /// <param name="HttpStatusCode">Specifies the HTTP status code, or zero when unavailable.</param>
    /// <param name="ErrorType">Specifies the error category.</param>
    /// <param name="ErrorMessage">Specifies the captured error details.</param>
    procedure LogApiError(ApiResource: Text[50]; Operation: Text[50]; Endpoint: Text[250]; ExternalRecordId: Integer; ArrayIndex: Integer; HttpStatusCode: Integer; ErrorType: Text[50]; ErrorMessage: Text)
    var
        ApiErrorLog: Record "APSS API Error Log";
    begin
        ApiErrorLog.Init();
        ApiErrorLog."Occurred At" := CurrentDateTime();
        ApiErrorLog."API Resource" := ApiResource;
        ApiErrorLog.Operation := Operation;
        ApiErrorLog.Endpoint := Endpoint;
        ApiErrorLog."External Record ID" := ExternalRecordId;
        ApiErrorLog."Array Index" := ArrayIndex;
        ApiErrorLog."HTTP Status Code" := HttpStatusCode;
        ApiErrorLog."Error Type" := ErrorType;
        ApiErrorLog."Error Message" := CopyStr(ErrorMessage, 1, MaxStrLen(ApiErrorLog."Error Message"));
        ApiErrorLog.Insert(true);
    end;

    /// <summary>
    /// Parses the users response into a temporary table and logs item-level validation failures.
    /// </summary>
    /// <param name="ResponseText">Specifies the JSON response body.</param>
    /// <param name="TempExternalUser">Receives the valid parsed users.</param>
    /// <param name="ErrorCount">Returns the number of errors logged while parsing.</param>
    /// <param name="AllowDelete">Returns whether the response is complete enough to safely delete missing local users.</param>
    /// <returns>True when the response is a valid non-empty JSON array; otherwise, false.</returns>
    local procedure ParseExternalUsers(ResponseText: Text; var TempExternalUser: Record "APSS External User" temporary; var ErrorCount: Integer; var AllowDelete: Boolean): Boolean
    var
        UserArray: JsonArray;
        UserObject: JsonObject;
        UserToken: JsonToken;
        ExternalRecordId: Integer;
        Index: Integer;
    begin
        TempExternalUser.Reset();
        TempExternalUser.DeleteAll();
        AllowDelete := true;

        if not UserArray.ReadFrom(ResponseText) then begin
            LogApiError(UsersResourceLbl, SynchronizeOperationLbl, UsersEndpointLbl, 0, -1, 0, ResponseErrorTypeLbl, InvalidJsonErr);
            ErrorCount += 1;
            AllowDelete := false;
            exit(false);
        end;

        if UserArray.Count() = 0 then begin
            LogApiError(UsersResourceLbl, SynchronizeOperationLbl, UsersEndpointLbl, 0, -1, 0, ResponseErrorTypeLbl, EmptyResponseErr);
            ErrorCount += 1;
            AllowDelete := false;
            exit(false);
        end;

        for Index := 0 to UserArray.Count() - 1 do
            if not UserArray.Get(Index, UserToken) then
                LogUserItemError(Index, 0, StrSubstNo(ArrayItemErr, Index), ErrorCount, AllowDelete)
            else
                if not UserToken.IsObject() then
                    LogUserItemError(Index, 0, StrSubstNo(ArrayItemTypeErr, Index), ErrorCount, AllowDelete)
                else begin
                    UserObject := UserToken.AsObject();
                    ExternalRecordId := GetExternalIdForLog(UserObject);
                    ClearLastError();
                    if not TryParseExternalUser(UserObject, TempExternalUser, Index) then
                        LogUserItemError(Index, ExternalRecordId, GetLastErrorText(), ErrorCount, AllowDelete)
                    else
                        if not TempExternalUser.Insert() then
                            LogUserItemError(Index, TempExternalUser."External ID", StrSubstNo(DuplicateIdErr, TempExternalUser."External ID"), ErrorCount, AllowDelete);
                end;

        exit(true);
    end;

    /// <summary>
    /// Validates and maps one JSON user to a temporary external-user record.
    /// </summary>
    /// <param name="UserObject">Specifies the JSON user object.</param>
    /// <param name="TempExternalUser">Receives the mapped user fields.</param>
    /// <param name="Index">Specifies the zero-based JSON array index.</param>
    [TryFunction]
    local procedure TryParseExternalUser(UserObject: JsonObject; var TempExternalUser: Record "APSS External User" temporary; Index: Integer)
    var
        AddressObject: JsonObject;
        CompanyObject: JsonObject;
        GeoObject: JsonObject;
    begin
        TempExternalUser.Init();
        TempExternalUser."External ID" := GetRequiredInteger(UserObject, 'id', Index);
        TempExternalUser.Name := CopyStr(GetRequiredText(UserObject, 'name', MaxStrLen(TempExternalUser.Name), Index), 1, MaxStrLen(TempExternalUser.Name));
        TempExternalUser."User Name" := CopyStr(GetOptionalText(UserObject, 'username', MaxStrLen(TempExternalUser."User Name"), Index), 1, MaxStrLen(TempExternalUser."User Name"));
        TempExternalUser."E-mail" := CopyStr(GetRequiredText(UserObject, 'email', MaxStrLen(TempExternalUser."E-mail"), Index), 1, MaxStrLen(TempExternalUser."E-mail"));
        TempExternalUser.Phone := CopyStr(GetOptionalText(UserObject, 'phone', MaxStrLen(TempExternalUser.Phone), Index), 1, MaxStrLen(TempExternalUser.Phone));
        TempExternalUser.Website := CopyStr(GetOptionalText(UserObject, 'website', MaxStrLen(TempExternalUser.Website), Index), 1, MaxStrLen(TempExternalUser.Website));

        if TryGetObject(UserObject, 'company', CompanyObject) then
            TempExternalUser."Company Name" := CopyStr(GetOptionalText(CompanyObject, 'name', MaxStrLen(TempExternalUser."Company Name"), Index), 1, MaxStrLen(TempExternalUser."Company Name"));

        if TryGetObject(UserObject, 'address', AddressObject) then begin
            TempExternalUser.Street := CopyStr(GetOptionalText(AddressObject, 'street', MaxStrLen(TempExternalUser.Street), Index), 1, MaxStrLen(TempExternalUser.Street));
            TempExternalUser.Suite := CopyStr(GetOptionalText(AddressObject, 'suite', MaxStrLen(TempExternalUser.Suite), Index), 1, MaxStrLen(TempExternalUser.Suite));
            TempExternalUser.City := CopyStr(GetOptionalText(AddressObject, 'city', MaxStrLen(TempExternalUser.City), Index), 1, MaxStrLen(TempExternalUser.City));
            TempExternalUser."Post Code" := CopyStr(GetOptionalText(AddressObject, 'zipcode', MaxStrLen(TempExternalUser."Post Code"), Index), 1, MaxStrLen(TempExternalUser."Post Code"));
            if TryGetObject(AddressObject, 'geo', GeoObject) then begin
                TempExternalUser.Latitude := GetOptionalDecimal(GeoObject, 'lat', Index);
                TempExternalUser.Longitude := GetOptionalDecimal(GeoObject, 'lng', Index);
            end;
        end;
    end;

    /// <summary>
    /// Inserts new users and refreshes existing users from the validated temporary table.
    /// </summary>
    /// <param name="TempExternalUser">Specifies the validated users.</param>
    /// <param name="SyncDateTime">Specifies the synchronization timestamp.</param>
    /// <param name="InsertedCount">Returns the number of inserted users.</param>
    /// <param name="ModifiedCount">Returns the number of users whose external data changed.</param>
    local procedure UpsertExternalUsers(var TempExternalUser: Record "APSS External User" temporary; SyncDateTime: DateTime; var InsertedCount: Integer; var ModifiedCount: Integer)
    var
        ExternalUser: Record "APSS External User";
        RecordChanged: Boolean;
    begin
        if not TempExternalUser.FindSet() then
            exit;

        repeat
            if ExternalUser.Get(TempExternalUser."External ID") then begin
                RecordChanged := ExternalUserChanged(ExternalUser, TempExternalUser);
                CopyExternalUser(TempExternalUser, ExternalUser, SyncDateTime);
                ExternalUser.Modify(true);
                if RecordChanged then
                    ModifiedCount += 1;
            end else begin
                ExternalUser.Init();
                CopyExternalUser(TempExternalUser, ExternalUser, SyncDateTime);
                ExternalUser.Insert(true);
                InsertedCount += 1;
            end;
        until TempExternalUser.Next() = 0;
    end;

    /// <summary>
    /// Deletes local users that are absent from a fully valid API response.
    /// </summary>
    /// <param name="TempExternalUser">Specifies the complete validated API result.</param>
    /// <param name="DeletedCount">Returns the number of deleted users.</param>
    local procedure DeleteMissingExternalUsers(var TempExternalUser: Record "APSS External User" temporary; var DeletedCount: Integer)
    var
        ExternalUser: Record "APSS External User";
    begin
        if not ExternalUser.FindSet(true) then
            exit;

        repeat
            if not TempExternalUser.Get(ExternalUser."External ID") then begin
                ExternalUser.Delete(true);
                DeletedCount += 1;
            end;
        until ExternalUser.Next() = 0;
    end;

    /// <summary>
    /// Copies all synchronized fields from a temporary user to a stored user.
    /// </summary>
    /// <param name="TempExternalUser">Specifies the source user.</param>
    /// <param name="ExternalUser">Specifies the destination user.</param>
    /// <param name="SyncDateTime">Specifies the synchronization timestamp.</param>
    local procedure CopyExternalUser(TempExternalUser: Record "APSS External User" temporary; var ExternalUser: Record "APSS External User"; SyncDateTime: DateTime)
    begin
        ExternalUser."External ID" := TempExternalUser."External ID";
        ExternalUser.Name := TempExternalUser.Name;
        ExternalUser."User Name" := TempExternalUser."User Name";
        ExternalUser."E-mail" := TempExternalUser."E-mail";
        ExternalUser.Phone := TempExternalUser.Phone;
        ExternalUser.Website := TempExternalUser.Website;
        ExternalUser."Company Name" := TempExternalUser."Company Name";
        ExternalUser.Street := TempExternalUser.Street;
        ExternalUser.Suite := TempExternalUser.Suite;
        ExternalUser.City := TempExternalUser.City;
        ExternalUser."Post Code" := TempExternalUser."Post Code";
        ExternalUser.Latitude := TempExternalUser.Latitude;
        ExternalUser.Longitude := TempExternalUser.Longitude;
        ExternalUser."Last Synced At" := SyncDateTime;
    end;

    /// <summary>
    /// Determines whether externally supplied user fields have changed.
    /// </summary>
    /// <param name="ExternalUser">Specifies the stored user.</param>
    /// <param name="TempExternalUser">Specifies the latest external user.</param>
    /// <returns>True when any externally supplied field differs; otherwise, false.</returns>
    local procedure ExternalUserChanged(ExternalUser: Record "APSS External User"; TempExternalUser: Record "APSS External User" temporary): Boolean
    begin
        exit(
            (ExternalUser.Name <> TempExternalUser.Name) or
            (ExternalUser."User Name" <> TempExternalUser."User Name") or
            (ExternalUser."E-mail" <> TempExternalUser."E-mail") or
            (ExternalUser.Phone <> TempExternalUser.Phone) or
            (ExternalUser.Website <> TempExternalUser.Website) or
            (ExternalUser."Company Name" <> TempExternalUser."Company Name") or
            (ExternalUser.Street <> TempExternalUser.Street) or
            (ExternalUser.Suite <> TempExternalUser.Suite) or
            (ExternalUser.City <> TempExternalUser.City) or
            (ExternalUser."Post Code" <> TempExternalUser."Post Code") or
            (ExternalUser.Latitude <> TempExternalUser.Latitude) or
            (ExternalUser.Longitude <> TempExternalUser.Longitude));
    end;

    /// <summary>
    /// Writes one handled user-item validation failure and marks delete reconciliation as unsafe.
    /// </summary>
    /// <param name="Index">Specifies the zero-based response array index.</param>
    /// <param name="ExternalRecordId">Specifies the external user ID, or zero when unavailable.</param>
    /// <param name="ErrorMessage">Specifies the validation failure details.</param>
    /// <param name="ErrorCount">Returns the updated logged-error count.</param>
    /// <param name="AllowDelete">Returns false to prevent deletion based on an incomplete valid-item set.</param>
    local procedure LogUserItemError(Index: Integer; ExternalRecordId: Integer; ErrorMessage: Text; var ErrorCount: Integer; var AllowDelete: Boolean)
    begin
        if ErrorMessage = '' then
            ErrorMessage := StrSubstNo(UnknownUserValidationErr, Index);

        LogApiError(UsersResourceLbl, SynchronizeOperationLbl, UsersEndpointLbl, ExternalRecordId, Index, 0, ValidationErrorTypeLbl, ErrorMessage);
        ErrorCount += 1;
        AllowDelete := false;
    end;

    /// <summary>
    /// Reads a user ID for logging without raising a validation error.
    /// </summary>
    /// <param name="UserObject">Specifies the JSON user object.</param>
    /// <returns>The user ID, or zero when the ID is unavailable or invalid.</returns>
    local procedure GetExternalIdForLog(UserObject: JsonObject): Integer
    var
        JsonToken: JsonToken;
        JsonValue: JsonValue;
        ExternalRecordId: Integer;
    begin
        if not UserObject.Get('id', JsonToken) then
            exit(0);
        if not JsonToken.IsValue() then
            exit(0);

        JsonValue := JsonToken.AsValue();
        if JsonValue.IsNull() then
            exit(0);
        if not Evaluate(ExternalRecordId, JsonValue.AsText(), 9) then
            exit(0);

        exit(ExternalRecordId);
    end;

    /// <summary>
    /// Returns the transport error reported by the runtime or a stable fallback message.
    /// </summary>
    /// <returns>The HTTP transport failure details.</returns>
    local procedure GetHttpFailureMessage(): Text
    var
        FailureMessage: Text;
    begin
        FailureMessage := GetLastErrorText();
        if FailureMessage = '' then
            FailureMessage := StrSubstNo(HttpRequestFailedErr, UsersEndpointLbl);

        exit(FailureMessage);
    end;

    /// <summary>
    /// Reads and validates a required integer JSON property.
    /// </summary>
    /// <param name="JsonObject">Specifies the source JSON object.</param>
    /// <param name="PropertyName">Specifies the property name.</param>
    /// <param name="ItemIndex">Specifies the zero-based response array index.</param>
    /// <returns>The validated integer value.</returns>
    local procedure GetRequiredInteger(JsonObject: JsonObject; PropertyName: Text; ItemIndex: Integer): Integer
    var
        JsonToken: JsonToken;
        JsonValue: JsonValue;
        IntegerValue: Integer;
    begin
        if not JsonObject.Get(PropertyName, JsonToken) then
            Error(MissingPropertyErr, PropertyName, ItemIndex);
        if not JsonToken.IsValue() then
            Error(InvalidPropertyErr, PropertyName, ItemIndex);

        JsonValue := JsonToken.AsValue();
        if JsonValue.IsNull() then
            Error(MissingPropertyErr, PropertyName, ItemIndex);
        if not Evaluate(IntegerValue, JsonValue.AsText(), 9) then
            Error(InvalidPropertyErr, PropertyName, ItemIndex);

        exit(IntegerValue);
    end;

    /// <summary>
    /// Reads and validates a required text JSON property.
    /// </summary>
    /// <param name="JsonObject">Specifies the source JSON object.</param>
    /// <param name="PropertyName">Specifies the property name.</param>
    /// <param name="MaximumLength">Specifies the maximum supported field length.</param>
    /// <param name="ItemIndex">Specifies the zero-based response array index.</param>
    /// <returns>The validated text value.</returns>
    local procedure GetRequiredText(JsonObject: JsonObject; PropertyName: Text; MaximumLength: Integer; ItemIndex: Integer): Text
    var
        JsonToken: JsonToken;
        PropertyValue: Text;
    begin
        if not JsonObject.Get(PropertyName, JsonToken) then
            Error(MissingPropertyErr, PropertyName, ItemIndex);

        PropertyValue := GetOptionalText(JsonObject, PropertyName, MaximumLength, ItemIndex);
        if PropertyValue = '' then
            Error(EmptyPropertyErr, PropertyName, ItemIndex);

        exit(PropertyValue);
    end;

    /// <summary>
    /// Reads an optional text JSON property and validates its type and length.
    /// </summary>
    /// <param name="JsonObject">Specifies the source JSON object.</param>
    /// <param name="PropertyName">Specifies the property name.</param>
    /// <param name="MaximumLength">Specifies the maximum supported field length.</param>
    /// <param name="ItemIndex">Specifies the zero-based response array index.</param>
    /// <returns>The text value, or blank when the property is missing or null.</returns>
    local procedure GetOptionalText(JsonObject: JsonObject; PropertyName: Text; MaximumLength: Integer; ItemIndex: Integer): Text
    var
        JsonToken: JsonToken;
        JsonValue: JsonValue;
        PropertyValue: Text;
    begin
        if not JsonObject.Get(PropertyName, JsonToken) then
            exit('');
        if not JsonToken.IsValue() then
            Error(InvalidPropertyErr, PropertyName, ItemIndex);

        JsonValue := JsonToken.AsValue();
        if JsonValue.IsNull() then
            exit('');

        PropertyValue := JsonValue.AsText();
        if StrLen(PropertyValue) > MaximumLength then
            Error(PropertyTooLongErr, PropertyName, ItemIndex, StrLen(PropertyValue), MaximumLength);

        exit(PropertyValue);
    end;

    /// <summary>
    /// Reads an optional decimal JSON property.
    /// </summary>
    /// <param name="JsonObject">Specifies the source JSON object.</param>
    /// <param name="PropertyName">Specifies the property name.</param>
    /// <param name="ItemIndex">Specifies the zero-based response array index.</param>
    /// <returns>The decimal value, or zero when the property is missing or blank.</returns>
    local procedure GetOptionalDecimal(JsonObject: JsonObject; PropertyName: Text; ItemIndex: Integer): Decimal
    var
        DecimalValue: Decimal;
        PropertyText: Text;
    begin
        PropertyText := GetOptionalText(JsonObject, PropertyName, 50, ItemIndex);
        if PropertyText = '' then
            exit(0);
        if not Evaluate(DecimalValue, PropertyText, 9) then
            Error(InvalidPropertyErr, PropertyName, ItemIndex);

        exit(DecimalValue);
    end;

    /// <summary>
    /// Attempts to read a nested JSON object without raising an error when it is unavailable.
    /// </summary>
    /// <param name="JsonObject">Specifies the parent JSON object.</param>
    /// <param name="PropertyName">Specifies the nested property name.</param>
    /// <param name="NestedObject">Receives the nested JSON object.</param>
    /// <returns>True when the nested object exists and has the correct type; otherwise, false.</returns>
    local procedure TryGetObject(JsonObject: JsonObject; PropertyName: Text; var NestedObject: JsonObject): Boolean
    var
        JsonToken: JsonToken;
    begin
        if not JsonObject.Get(PropertyName, JsonToken) then
            exit(false);
        if not JsonToken.IsObject() then
            exit(false);

        NestedObject := JsonToken.AsObject();
        exit(true);
    end;

    var
        ArrayItemErr: Label 'Could not read external user at array index %1.', Comment = '%1 = zero-based JSON array index';
        ArrayItemTypeErr: Label 'The external user at array index %1 is not a JSON object.', Comment = '%1 = zero-based JSON array index';
        DuplicateIdErr: Label 'The external API returned duplicate user ID %1.', Comment = '%1 = external user ID';
        EmptyResponseErr: Label 'The external API returned an empty user list. Existing data was not changed.';
        ContentTypeHeaderLbl: Label 'Content-Type', Locked = true;
        EmptyPropertyErr: Label 'Required property %1 on external user at array index %2 is empty.', Comment = '%1 = JSON property name, %2 = zero-based JSON array index';
        FetchSucceededMsg: Label 'Success! Fetched title: %1', Comment = '%1 = title returned by the external API';
        HttpPostFailedErr: Label 'The HTTP POST request to %1 failed. Verify the endpoint, network connection, and the extension HTTP client permission.', Comment = '%1 = API endpoint URL';
        HttpRequestFailedErr: Label 'The HTTP GET request to %1 failed. Verify the endpoint, network connection, and the extension HTTP client permission.', Comment = '%1 = API endpoint URL';
        HttpStatusErr: Label 'The external API returned HTTP status %1 for %2. Existing data was not changed.', Comment = '%1 = HTTP status code, %2 = API endpoint URL';
        InvalidObjectJsonErr: Label 'The response from %1 is not a valid JSON object.', Comment = '%1 = API endpoint URL';
        InvalidJsonErr: Label 'The external API response is not a valid JSON array. Existing data was not changed.';
        InvalidPropertyErr: Label 'Property %1 on external user at array index %2 has an invalid value.', Comment = '%1 = JSON property name, %2 = zero-based JSON array index';
        InvalidResponsePropertyErr: Label 'Property %1 in the response from %2 is not a JSON value.', Comment = '%1 = JSON property name, %2 = API endpoint URL';
        JsonContentTypeLbl: Label 'application/json; charset=utf-8', Locked = true;
        HttpErrorTypeLbl: Label 'HTTP', Locked = true;
        MissingPropertyErr: Label 'Required property %1 is missing from external user at array index %2.', Comment = '%1 = JSON property name, %2 = zero-based JSON array index';
        MissingResponsePropertyErr: Label 'Property %1 is missing from the response from %2.', Comment = '%1 = JSON property name, %2 = API endpoint URL';
        PostBodyLbl: Label 'Test data sent from Business Central';
        PostsEndpointLbl: Label 'https://jsonplaceholder.typicode.com/posts', Locked = true;
        PostSucceededMsg: Label 'The test POST request succeeded.';
        PostTitleLbl: Label 'Business Central REST API test';
        PropertyTooLongErr: Label 'Property %1 on external user at array index %2 contains %3 characters; the maximum supported length is %4.', Comment = '%1 = JSON property name, %2 = zero-based JSON array index, %3 = actual length, %4 = maximum length';
        ReadResponseFailedErr: Label 'The external API response body could not be read. Existing data was not changed.';
        ResponseErrorTypeLbl: Label 'Response', Locked = true;
        SynchronizeOperationLbl: Label 'Synchronize', Locked = true;
        TodoEndpointLbl: Label 'https://jsonplaceholder.typicode.com/todos/1', Locked = true;
        UnknownUserValidationErr: Label 'The external user at array index %1 could not be validated.', Comment = '%1 = zero-based JSON array index';
        UsersResourceLbl: Label 'Users', Locked = true;
        UsersEndpointLbl: Label 'https://jsonplaceholder.typicode.com/users', Locked = true;
        ValidationErrorTypeLbl: Label 'Validation', Locked = true;
}
